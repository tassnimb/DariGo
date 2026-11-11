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