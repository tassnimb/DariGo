
from rest_framework import generics, permissions
from rest_framework.exceptions import PermissionDenied, ValidationError
from rest_framework.parsers import MultiPartParser, FormParser, JSONParser

from django.db import transaction
from django.shortcuts import get_object_or_404

from .models import (
    Logement,
    PhotoLogement,
    Reservation,
    Favori,
    Avis,
)

from .serializers import (
    LogementSerializer,
    ReservationSerializer,
    ReservationStatutSerializer,
    FavoriSerializer,
    AvisSerializer,
)

import json
from rest_framework.response import Response
# ==========================================
# LOGEMENTS
# ==========================================

class LogementListCreateView(generics.ListCreateAPIView):

    serializer_class = LogementSerializer

    permission_classes = [
        permissions.IsAuthenticated
    ]

    parser_classes = [
        MultiPartParser,
        FormParser,
        JSONParser,
    ]

    def get_queryset(self):

        user = self.request.user

        if user.role == 'proprietaire':
            return Logement.objects.filter(
                proprietaire=user
            ).prefetch_related('photos')

        return Logement.objects.all().prefetch_related('photos')

    @transaction.atomic
    def perform_create(self, serializer):

        photos = self.request.FILES.getlist('photos')

        if len(photos) > 10:
            raise ValidationError(
                "Vous pouvez ajouter au maximum 10 photos."
            )

        # Création du logement
        logement = serializer.save(
            proprietaire=self.request.user
        )

        # Enregistrement de toutes les photos
        for photo in photos:
            PhotoLogement.objects.create(
                logement=logement,
                image=photo
            )



class LogementRetrieveUpdateDeleteView(generics.RetrieveUpdateDestroyAPIView):

    serializer_class = LogementSerializer
    permission_classes = [permissions.IsAuthenticated]

    parser_classes = [
        MultiPartParser,
        FormParser,
        JSONParser,
    ]

    queryset = Logement.objects.all().prefetch_related('photos')

    def update(self, request, *args, **kwargs):

        logement = self.get_object()

        if logement.proprietaire != request.user:
            raise PermissionDenied(
                "Vous ne pouvez modifier que vos propres logements."
            )

        # Récupérer les photos à supprimer
        try:
            photos_a_supprimer = json.loads(
                request.data.get('photos_a_supprimer', '[]')
            )
        except (TypeError, ValueError):
            raise ValidationError("Liste de photos à supprimer invalide.")

        if not isinstance(photos_a_supprimer, list):
            raise ValidationError("Liste de photos invalide.")

        # Vérifier que les photos à supprimer appartiennent au logement
        photos_existantes = PhotoLogement.objects.filter(
            logement=logement
        )

        ids_existants = set(
            photos_existantes.values_list('id', flat=True)
        )

        try:
            ids_a_supprimer = {int(photo_id) for photo_id in photos_a_supprimer}
        except (TypeError, ValueError):
            raise ValidationError("Identifiant de photo invalide.")

        if not ids_a_supprimer.issubset(ids_existants):
            raise ValidationError("Une ou plusieurs photos sont invalides.")

        nouvelles_photos = request.FILES.getlist('photos')

        nombre_restant = (
            photos_existantes.exclude(id__in=ids_a_supprimer).count()
        )

        if nombre_restant + len(nouvelles_photos) > 10:
            raise ValidationError(
                "Vous pouvez conserver ou ajouter au maximum 10 photos."
            )

        with transaction.atomic():

            # Modifier les informations du logement
            serializer = self.get_serializer(
                logement,
                data=request.data,
                partial=True
            )
            serializer.is_valid(raise_exception=True)
            serializer.save()

            # Supprimer les anciennes photos sélectionnées
            for photo in photos_existantes.filter(
                id__in=ids_a_supprimer
            ):
                photo.image.delete(save=False)
                photo.delete()

            # Ajouter les nouvelles photos
            for photo in nouvelles_photos:
                PhotoLogement.objects.create(
                    logement=logement,
                    image=photo
                )

        return Response(
            LogementSerializer(logement).data,
            status=200
        )

    def destroy(self, request, *args, **kwargs):

        logement = self.get_object()

        if logement.proprietaire != request.user:
            raise PermissionDenied(
                "Vous ne pouvez supprimer que vos propres logements."
            )

        return super().destroy(request, *args, **kwargs)


# ==========================================
# RESERVATIONS
# ==========================================

class ReservationListCreateView(generics.ListCreateAPIView):

    serializer_class = ReservationSerializer

    permission_classes = [
        permissions.IsAuthenticated
    ]

    def get_queryset(self):

        user = self.request.user

        if user.role == 'visiteur':
            return Reservation.objects.filter(
                visiteur=user
            ).select_related('logement', 'visiteur')

        if user.role == 'proprietaire':
            return Reservation.objects.filter(
                logement__proprietaire=user
            ).select_related('logement', 'visiteur')

        return Reservation.objects.none()

    def perform_create(self, serializer):

        if self.request.user.role != 'visiteur':
            raise PermissionDenied(
                "Seul un visiteur peut réserver un logement."
            )

        serializer.save(
            visiteur=self.request.user
        )


class ReservationDetailView(generics.RetrieveUpdateAPIView):

    permission_classes = [
        permissions.IsAuthenticated
    ]

    def get_queryset(self):

        user = self.request.user

        if user.role == 'visiteur':
            return Reservation.objects.filter(
                visiteur=user
            )

        if user.role == 'proprietaire':
            return Reservation.objects.filter(
                logement__proprietaire=user
            )

        return Reservation.objects.none()

    def get_serializer_class(self):

        if self.request.method in ['PUT', 'PATCH']:
            return ReservationStatutSerializer

        return ReservationSerializer

    def update(self, request, *args, **kwargs):

        reservation = self.get_object()

        # Propriétaire : accepte ou refuse
        if request.user.role == 'proprietaire':

            if request.data.get('statut') not in [
                'acceptee',
                'refusee',
            ]:
                raise PermissionDenied(
                    "Statut non autorisé."
                )

            return super().update(
                request,
                *args,
                **kwargs,
            )

        # Visiteur : annule uniquement sa réservation
        if request.user.role == 'visiteur':

            if (
                reservation.visiteur == request.user
                and request.data.get('statut') == 'annulee'
            ):
                return super().update(
                    request,
                    *args,
                    **kwargs,
                )

        raise PermissionDenied(
            "Action non autorisée."
        )

    @transaction.atomic
    def perform_update(self, serializer):

        reservation = serializer.instance

        nouveau_statut = serializer.validated_data.get(
            'statut',
            reservation.statut
        )

        if nouveau_statut == 'acceptee':

            Logement.objects.select_for_update().get(
                pk=reservation.logement_id
            )

            conflit = Reservation.objects.filter(
                logement=reservation.logement,
                statut='acceptee',
                date_arrivee__lt=reservation.date_depart,
                date_depart__gt=reservation.date_arrivee,
            ).exclude(
                pk=reservation.pk
            ).exists()

            if conflit:
                raise ValidationError(
                    "Ce logement est déjà réservé pour ces dates."
                )

        serializer.save()


# ==========================================
# FAVORIS
# ==========================================

class FavoriListCreateView(generics.ListCreateAPIView):

    serializer_class = FavoriSerializer

    permission_classes = [
        permissions.IsAuthenticated
    ]

    def get_queryset(self):

        return Favori.objects.filter(
            visiteur=self.request.user
        )

    def perform_create(self, serializer):

        serializer.save(
            visiteur=self.request.user
        )


class FavoriDeleteView(generics.DestroyAPIView):

    serializer_class = FavoriSerializer

    permission_classes = [
        permissions.IsAuthenticated
    ]

    def get_queryset(self):

        return Favori.objects.filter(
            visiteur=self.request.user
        )


# ==========================================
# AVIS
# ==========================================

class AvisLogementListView(generics.ListAPIView):

    serializer_class = AvisSerializer

    permission_classes = [
        permissions.IsAuthenticated
    ]

    def get_queryset(self):

        logement_id = self.kwargs['logement_id']

        return Avis.objects.filter(
            reservation__logement_id=logement_id
        ).select_related(
            'reservation__visiteur',
            'reservation__logement'
        )


class AvisReservationCreateView(generics.CreateAPIView):

    serializer_class = AvisSerializer

    permission_classes = [
        permissions.IsAuthenticated
    ]

    def perform_create(self, serializer):

        if self.request.user.role != 'visiteur':
            raise PermissionDenied(
                "Seul un visiteur peut publier un avis."
            )

        reservation = get_object_or_404(
            Reservation,
            pk=self.kwargs['reservation_id'],
            visiteur=self.request.user,
            statut='acceptee',
        )

        if Avis.objects.filter(reservation=reservation).exists():
            raise ValidationError(
                "Vous avez déjà publié un avis pour cette réservation."
            )

        serializer.save(
            reservation=reservation
        )
