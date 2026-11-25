
from rest_framework import serializers
from django.contrib.auth import get_user_model

from .models import Conversation, Message

User = get_user_model()


class ParticipantSerializer(serializers.ModelSerializer):

    class Meta:
        model = User
        fields = [
            'id',
            'username',
            'first_name',
            'last_name',
            'role',
            'profile_photo',
        ]


class MessageSerializer(serializers.ModelSerializer):

    auteur = ParticipantSerializer(read_only=True)

    class Meta:
        model = Message
        fields = [
            'id',
            'conversation',
            'auteur',
            'contenu',
            'date_creation',
            'date_lecture',
        ]
        read_only_fields = [
            'id',
            'conversation',
            'auteur',
            'date_creation',
            'date_lecture',
        ]


class ConversationSerializer(serializers.ModelSerializer):

    visiteur = ParticipantSerializer(read_only=True)
    proprietaire = serializers.SerializerMethodField()

    logement_titre = serializers.CharField(
        source='logement.titre',
        read_only=True
    )

    dernier_message = serializers.SerializerMethodField()
    messages_non_lus = serializers.SerializerMethodField()

    class Meta:
        model = Conversation
        fields = [
            'id',
            'logement',
            'logement_titre',
            'visiteur',
            'proprietaire',
            'date_creation',
            'date_modification',
            'dernier_message',
            'messages_non_lus',
        ]
        read_only_fields = fields

    def get_proprietaire(self, obj):
        return ParticipantSerializer(
            obj.logement.proprietaire
        ).data

    def get_dernier_message(self, obj):
        message = obj.messages.order_by(
            '-date_creation'
        ).first()

        if message:
            return MessageSerializer(message).data

        return None

    def get_messages_non_lus(self, obj):
        request = self.context.get('request')

        if request is None or not request.user.is_authenticated:
            return 0

        return obj.messages.filter(
            date_lecture__isnull=True
        ).exclude(
            auteur=request.user
        ).count()


class CreateConversationSerializer(serializers.ModelSerializer):

    class Meta:
        model = Conversation
        fields = ['logement']

    def validate_logement(self, logement):
        user = self.context['request'].user

        if logement.proprietaire_id == user.id:
            raise serializers.ValidationError(
                "Vous ne pouvez pas contacter votre propre logement."
            )

        if user.role != 'visiteur':
            raise serializers.ValidationError(
                "Seuls les visiteurs peuvent créer une conversation."
            )

        if logement.proprietaire.role != 'proprietaire':
            raise serializers.ValidationError(
                "Ce logement n'est pas associé à un propriétaire valide."
            )

        return logement

    def create(self, validated_data):
        conversation, created = Conversation.objects.get_or_create(
            logement=validated_data['logement'],
            visiteur=self.context['request'].user
        )

        self.context['created'] = created

        return conversation
