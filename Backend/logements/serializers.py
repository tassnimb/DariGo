
from rest_framework import serializers
from django.utils import timezone

from .models import (
    Logement,
    PhotoLogement,
    Reservation,
    Favori,
    Avis,
)
from django.db import transaction
from rest_framework.exceptions import ValidationError
class LogementSerializer(serializers.ModelSerializer):
    class Meta:
        model = Logement
        fields = '__all__'
        read_only_fields = [
            'proprietaire',
            'date_creation',
        ]



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

    # Photo de profil du visiteur
    visiteur_photo = serializers.SerializerMethodField()

    def get_visiteur_photo(self, obj):
        if obj.visiteur and obj.visiteur.profile_photo:
            request = self.context.get('request')
            photo_url = obj.visiteur.profile_photo.url

            if request:
                return request.build_absolute_uri(photo_url)

            return photo_url

        return None

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
            'visiteur_photo',
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

        # Vérifier les réservations en attente et acceptées
        conflit = Reservation.objects.filter(
            logement=logement,
            statut__in=['en_attente', 'acceptee'],
            date_arrivee__lt=date_depart,
            date_depart__gt=date_arrivee,
        ).exists()

        if conflit:
            raise serializers.ValidationError(
                "Ce logement n'est pas disponible pour ces dates. "
                "Veuillez choisir une autre période."
            )

        return attrs


class ReservationStatutSerializer(serializers.ModelSerializer):

    class Meta:
        model = Reservation
        fields = ['statut']

    def validate_statut(self, value):

        if value not in ['acceptee', 'refusee', 'annulee']:
            raise serializers.ValidationError(
                "Statut non autorisé."
            )

        return value


class FavoriSerializer(serializers.ModelSerializer):

    logement_titre = serializers.CharField(
        source='logement.titre',
        read_only=True
    )

    class Meta:
        model = Favori
        fields = [
            'id',
            'logement',
            'logement_titre',
            'date_creation',
        ]


class AvisSerializer(serializers.ModelSerializer):

    visiteur_username = serializers.CharField(
        source='reservation.visiteur.username',
        read_only=True
    )

    logement_titre = serializers.CharField(
        source='reservation.logement.titre',
        read_only=True
    )

    class Meta:
        model = Avis

        fields = [
            'id',
            'reservation',
            'note',
            'commentaire',
            'date_creation',
            'visiteur_username',
            'logement_titre',
        ]

        read_only_fields = [
            'id',
            'reservation',
            'date_creation',
            'visiteur_username',
            'logement_titre',
        ]

    def validate_note(self, value):

        if value < 1 or value > 5:
            raise serializers.ValidationError(
                "La note doit être comprise entre 1 et 5."
            )

        return value
