
from django.db import transaction
from django.shortcuts import get_object_or_404

from rest_framework import generics, permissions
from rest_framework.exceptions import PermissionDenied, ValidationError

from .models import (
    Logement,
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


# =====================================
# LOGEMENTS
# =====================================

class LogementListCreateView(generics.ListCreateAPIView):

    serializer_class = LogementSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):

        user = self.request.user

        if user.role == 'proprietaire':
            return Logement.objects.filter(
                proprietaire=user
            )

        return Logement.objects.all()

    def perform_create(self, serializer):

        serializer.save(
            proprietaire=self.request.user
        )


class LogementRetrieveUpdateDeleteView(
    generics.RetrieveUpdateDestroyAPIView
):

    serializer_class = LogementSerializer
    permission_classes = [permissions.IsAuthenticated]
    queryset = Logement.objects.all()


# =====================================
# RESERVATIONS
# =====================================

class ReservationListCreateView(generics.ListCreateAPIView):

    serializer_class = ReservationSerializer
    permission_classes = [permissions.IsAuthenticated]

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

    @transaction.atomic
    def perform_create(self, serializer):

        if self.request.user.role != 'visiteur':
            raise PermissionDenied(
                "Seul un visiteur peut réserver un logement."
            )

        logement_id = serializer.validated_data['logement'].pk

        # Verrouiller le logement pour éviter les demandes simultanées
        logement = Logement.objects.select_for_update().get(
            pk=logement_id
        )

        date_arrivee = serializer.validated_data['date_arrivee']
        date_depart = serializer.validated_data['date_depart']

        # Nouvelle vérification après le verrouillage
        conflit = Reservation.objects.filter(
            logement=logement,
            statut__in=['en_attente', 'acceptee'],
            date_arrivee__lt=date_depart,
            date_depart__gt=date_arrivee,
        ).exists()

        if conflit:
            raise ValidationError(
                "Ce logement n'est pas disponible pour ces dates. "
                "Veuillez choisir une autre période."
            )

        serializer.save(
            visiteur=self.request.user,
            logement=logement
        )


class ReservationDetailView(generics.RetrieveUpdateAPIView):

    permission_classes = [permissions.IsAuthenticated]

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

            # Verrouiller le logement avant de vérifier
            logement = Logement.objects.select_for_update().get(
                pk=reservation.logement_id
            )

            # Une autre réservation acceptée ne doit pas
            # occuper les mêmes dates
            conflit = Reservation.objects.filter(
                logement=logement,
                statut='acceptee',
                date_arrivee__lt=reservation.date_depart,
                date_depart__gt=reservation.date_arrivee,
            ).exclude(
                pk=reservation.pk
            ).exists()

            if conflit:
                raise ValidationError(
                    "Une autre réservation est déjà acceptée "
                    "pour ces dates."
                )

        serializer.save()


# =====================================
# FAVORIS
# =====================================

class FavoriListCreateView(generics.ListCreateAPIView):

    serializer_class = FavoriSerializer
    permission_classes = [permissions.IsAuthenticated]

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
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):

        return Favori.objects.filter(
            visiteur=self.request.user
        )


# =====================================
# AVIS
# =====================================

class AvisLogementListView(generics.ListAPIView):

    serializer_class = AvisSerializer
    permission_classes = [permissions.IsAuthenticated]

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
    permission_classes = [permissions.IsAuthenticated]

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
