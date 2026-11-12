from django.db import models
from django.conf import settings


class Logement(models.Model):
    titre = models.CharField(max_length=200)
    description = models.TextField()
    adresse = models.CharField(max_length=255)
    prix = models.DecimalField(max_digits=10, decimal_places=2)

    proprietaire = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="logements"
    )

    date_creation = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.titre
    
class Reservation(models.Model):

    STATUT_CHOICES = [
        ('en_attente', 'En attente'),
        ('acceptee', 'Acceptée'),
        ('refusee', 'Refusée'),
    ]

    logement = models.ForeignKey(
        Logement,
        on_delete=models.CASCADE,
        related_name='reservations'
    )

    visiteur = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='reservations'
    )

    date_arrivee = models.DateField()
    date_depart = models.DateField()

    nombre_personnes = models.PositiveIntegerField(default=1)

    besoins = models.TextField(blank=True)
    message = models.TextField(blank=True)

    statut = models.CharField(
        max_length=20,
        choices=STATUT_CHOICES,
        default='en_attente'
    )

    date_creation = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Réservation {self.id} - {self.logement.titre}"
