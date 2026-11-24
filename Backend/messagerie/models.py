
from django.db import models
from django.conf import settings
from django.core.exceptions import ValidationError


class Conversation(models.Model):

    logement = models.ForeignKey(
        'logements.Logement',
        on_delete=models.CASCADE,
        related_name='conversations'
    )

    visiteur = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='conversations_visiteur'
    )

    date_creation = models.DateTimeField(
        auto_now_add=True
    )

    date_modification = models.DateTimeField(
        auto_now=True
    )

    class Meta:
        ordering = ['-date_modification']
        constraints = [
            models.UniqueConstraint(
                fields=['logement', 'visiteur'],
                name='unique_conversation_visiteur_logement'
            )
        ]

    @property
    def proprietaire(self):
        return self.logement.proprietaire

    def clean(self):
        if self.logement_id and self.visiteur_id:
            if self.logement.proprietaire_id == self.visiteur_id:
                raise ValidationError(
                    "Le propriétaire ne peut pas être son propre visiteur."
                )

            if self.visiteur.role != 'visiteur':
                raise ValidationError(
                    "Seul un visiteur peut créer une conversation."
                )

            if self.logement.proprietaire.role != 'proprietaire':
                raise ValidationError(
                    "Le logement doit appartenir à un propriétaire."
                )

    def __str__(self):
        return f"Conversation {self.id} - {self.logement.titre}"


class Message(models.Model):

    conversation = models.ForeignKey(
        Conversation,
        on_delete=models.CASCADE,
        related_name='messages'
    )

    auteur = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='messages_envoyes'
    )

    contenu = models.TextField()

    date_creation = models.DateTimeField(
        auto_now_add=True
    )

    date_lecture = models.DateTimeField(
        null=True,
        blank=True
    )

    class Meta:
        ordering = ['date_creation']

    def clean(self):
        if self.conversation_id and self.auteur_id:
            participants = [
                self.conversation.visiteur_id,
                self.conversation.logement.proprietaire_id
            ]

            if self.auteur_id not in participants:
                raise ValidationError(
                    "Cet utilisateur ne participe pas à cette conversation."
                )

    def __str__(self):
        return f"Message {self.id} - {self.auteur.username}"
