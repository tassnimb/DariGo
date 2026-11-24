
from django.shortcuts import get_object_or_404
from django.utils import timezone

from rest_framework import generics, permissions, status
from rest_framework.exceptions import PermissionDenied
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import Conversation, Message
from .serializers import (
    ConversationSerializer,
    CreateConversationSerializer,
    MessageSerializer,
)


class IsConversationParticipant(permissions.BasePermission):

    def has_object_permission(self, request, view, obj):
        user = request.user

        return (
            obj.visiteur_id == user.id
            or obj.logement.proprietaire_id == user.id
        )


class ConversationListCreateView(APIView):

    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        user = request.user

        if user.role == 'visiteur':
            conversations = Conversation.objects.filter(
                visiteur=user
            )
        elif user.role == 'proprietaire':
            conversations = Conversation.objects.filter(
                logement__proprietaire=user
            )
        else:
            return Response(
                {"error": "Rôle non autorisé."},
                status=status.HTTP_403_FORBIDDEN
            )

        conversations = conversations.select_related(
            'logement',
            'visiteur',
            'logement__proprietaire'
        ).prefetch_related('messages')

        serializer = ConversationSerializer(
            conversations,
            many=True
        )

        return Response(serializer.data)

    def post(self, request):
        if request.user.role != 'visiteur':
            return Response(
                {"error": "Seuls les visiteurs peuvent démarrer une conversation."},
                status=status.HTTP_403_FORBIDDEN
            )

        serializer = CreateConversationSerializer(
            data=request.data,
            context={'request': request}
        )

        serializer.is_valid(raise_exception=True)
        conversation = serializer.save()

        output = ConversationSerializer(conversation)

        response_status = (
            status.HTTP_201_CREATED
            if serializer.context.get('created')
            else status.HTTP_200_OK
        )

        return Response(output.data, status=response_status)


class MessageListCreateView(APIView):

    permission_classes = [permissions.IsAuthenticated]

    def get_conversation(self, request, conversation_id):
        conversation = get_object_or_404(
            Conversation.objects.select_related(
                'logement',
                'visiteur'
            ),
            id=conversation_id
        )

        participant = (
            conversation.visiteur_id == request.user.id
            or conversation.logement.proprietaire_id == request.user.id
        )

        if not participant:
            raise PermissionDenied(
                "Vous ne pouvez pas accéder à cette conversation."
            )

        return conversation

    def get(self, request, conversation_id):
        conversation = self.get_conversation(
            request,
            conversation_id
        )

        messages = conversation.messages.select_related(
            'auteur'
        ).all()

        # Marquer comme lus les messages reçus par l'utilisateur.
        messages.filter(
            date_lecture__isnull=True
        ).exclude(
            auteur=request.user
        ).update(
            date_lecture=timezone.now()
        )

        serializer = MessageSerializer(
            messages,
            many=True
        )

        return Response(serializer.data)

    def post(self, request, conversation_id):
        conversation = self.get_conversation(
            request,
            conversation_id
        )

        contenu = request.data.get('contenu')

        if not isinstance(contenu, str) or not contenu.strip():
            return Response(
                {"error": "Le message ne peut pas être vide."},
                status=status.HTTP_400_BAD_REQUEST
            )

        message = Message(
            conversation=conversation,
            auteur=request.user,
            contenu=contenu.strip()
        )

        message.full_clean()
        message.save()

        conversation.save(update_fields=['date_modification'])

        serializer = MessageSerializer(message)

        return Response(
            serializer.data,
            status=status.HTTP_201_CREATED
        )
