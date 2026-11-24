
from rest_framework import generics, permissions
from rest_framework.exceptions import PermissionDenied, ValidationError
from django.db import transaction
from .models import Favori
from .serializers import FavoriSerializer
from .models import (
    Logement,
    Reservation,
    Favori,
)
from .serializers import (
    LogementSerializer,
    ReservationSerializer,
    ReservationStatutSerializer,
    FavoriSerializer,
)


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

    def perform_create(self, serializer):
        if self.request.user.role != 'visiteur':
            raise PermissionDenied(
                "Seul un visiteur peut réserver un logement."
            )

        serializer.save(visiteur=self.request.user)


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

class FavoriListCreateView(
    generics.ListCreateAPIView
):

    serializer_class = FavoriSerializer
    permission_classes = [
        permissions.IsAuthenticated
    ]

    def get_queryset(self):
        return Favori.objects.filter(
            visiteur=self.request.user
        )

    def perform_create(
        self,
        serializer
    ):
        serializer.save(
            visiteur=self.request.user
        )


class FavoriDeleteView(
    generics.DestroyAPIView
):

    serializer_class = FavoriSerializer
    permission_classes = [
        permissions.IsAuthenticated
    ]

    def get_queryset(self):
        return Favori.objects.filter(
            visiteur=self.request.user
        )      