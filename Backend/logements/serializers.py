from rest_framework import serializers
from .models import Logement
from rest_framework import serializers
from django.utils import timezone
from .models import Logement, Reservation
from django.db import transaction
from rest_framework.exceptions import ValidationError
class LogementSerializer(serializers.ModelSerializer):
    class Meta:
        model = Logement
        fields = "__all__"
        read_only_fields = ["proprietaire", "date_creation"]

class ReservationSerializer(serializers.ModelSerializer):

    visiteur_username = serializers.CharField(
        source='visiteur.username',
        read_only=True
    )

    visiteur_email = serializers.EmailField(
        source='visiteur.email',
        read_only=True
    )

    visiteur_phone = serializers.CharField(
        source='visiteur.phone',
        read_only=True
    )

    logement_titre = serializers.CharField(
        source='logement.titre',
        read_only=True
    )

    class Meta:
        model = Reservation

        fields = [
            'id',
            'logement',
            'logement_titre',
            'visiteur_username',
            'visiteur_email',
            'visiteur_phone',
            'date_arrivee',
            'date_depart',
            'nombre_personnes',
            'besoins',
            'message',
            'statut',
            'date_creation',
        ]

        read_only_fields = [
            'id',
            'statut',
            'date_creation',
        ]

    def validate(self, attrs):

        date_arrivee = attrs.get('date_arrivee')
        date_depart = attrs.get('date_depart')
        logement = attrs.get('logement')

        if date_arrivee < timezone.localdate():
            raise serializers.ValidationError(
                "La date d'arrivée doit être aujourd'hui ou ultérieure."
            )

        if date_depart <= date_arrivee:
            raise serializers.ValidationError(
                "La date de départ doit être après la date d'arrivée."
            )

        if attrs.get('nombre_personnes', 1) < 1:
            raise serializers.ValidationError(
                "Le nombre de personnes doit être supérieur à zéro."
            )

        request = self.context.get('request')

        if request and logement.proprietaire_id == request.user.id:
            raise serializers.ValidationError(
                "Vous ne pouvez pas réserver votre propre logement."
            )

        conflit = Reservation.objects.filter(
            logement=logement,
            statut='acceptee',
            date_arrivee__lt=date_depart,
            date_depart__gt=date_arrivee,
        ).exists()

        if conflit:
            raise serializers.ValidationError(
                "Ce logement est déjà réservé pour ces dates."
            )

        return attrs

class ReservationStatutSerializer(serializers.ModelSerializer):

    class Meta:
        model = Reservation
        fields = ['statut']

    def validate_statut(self, value):
        if value not in ['acceptee', 'refusee']:
            raise serializers.ValidationError(
                "Statut non autorisé."
            )

        return value
