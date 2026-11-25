
import logging

from django.db import transaction
from django.utils import timezone
from django.db.models import Q

from channels.generic.websocket import AsyncJsonWebsocketConsumer
from channels.db import database_sync_to_async

from .models import Conversation, Message


logger = logging.getLogger(__name__)


class ChatConsumer(AsyncJsonWebsocketConsumer):

    async def connect(self):
        self.conversation_id = self.scope["url_route"]["kwargs"]["conversation_id"]
        self.room_group_name = f"conversation_{self.conversation_id}"

        user = self.scope["user"]

        if not user.is_authenticated:
            await self.close(code=4001)
            return

        if not await self.is_participant(user.id):
            await self.close(code=4003)
            return

        await self.channel_layer.group_add(
            self.room_group_name,
            self.channel_name,
        )

        await self.accept()

    async def disconnect(self, close_code):
        if hasattr(self, "room_group_name"):
            await self.channel_layer.group_discard(
                self.room_group_name,
                self.channel_name,
            )

    async def receive_json(self, content):
        contenu = content.get("contenu", "")

        if not isinstance(contenu, str):
            await self.send_json({
                "error": "Le contenu du message est invalide."
            })
            return

        contenu = contenu.strip()

        if not contenu:
            await self.send_json({
                "error": "Le message ne peut pas être vide."
            })
            return

        user = self.scope["user"]

        message = await self.create_message(
            self.conversation_id,
            user.id,
            contenu,
        )

        if message is None:
            await self.send_json({
                "error": "Impossible d'enregistrer le message."
            })
            return

        # Diffuse le message à tous les membres connectés
        # au groupe de cette conversation, expéditeur inclus.
        await self.channel_layer.group_send(
            self.room_group_name,
            {
                "type": "chat_message",
                "message": message,
            },
        )

    async def chat_message(self, event):
        await self.send_json(event["message"])

    @database_sync_to_async
    def is_participant(self, user_id):
        return Conversation.objects.filter(
            Q(visiteur_id=user_id)
            | Q(logement__proprietaire_id=user_id),
            id=self.conversation_id,
        ).exists()

    @database_sync_to_async
    def create_message(self, conversation_id, user_id, contenu):
        try:
            with transaction.atomic():
                conversation = Conversation.objects.get(
                    id=conversation_id
                )

                # Vérification supplémentaire des participants.
                est_participant = (
                    conversation.visiteur_id == user_id
                    or conversation.logement.proprietaire_id == user_id
                )

                if not est_participant:
                    return None

                message = Message(
                    conversation=conversation,
                    auteur_id=user_id,
                    contenu=contenu,
                )

                message.full_clean()
                message.save()

                conversation.date_modification = timezone.now()
                conversation.save(
                    update_fields=["date_modification"]
                )

                return {
                    "id": message.id,
                    "conversation": conversation.id,
                    "auteur": user_id,
                    "contenu": message.contenu,
                    "date_creation": message.date_creation.isoformat(),
                    "date_lecture": (
                        message.date_lecture.isoformat()
                        if message.date_lecture
                        else None
                    ),
                }

        except Exception:
            logger.exception(
                "Erreur lors de la création du message "
                "dans la conversation %s",
                conversation_id,
            )
            return None
