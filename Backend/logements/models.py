from django.db import models

class Logement(models.Model):
    titre = models.CharField(max_length=100)
    ville = models.CharField(max_length=100)
    adresse = models.TextField()
    prix = models.DecimalField(max_digits=10, decimal_places=2)
    description = models.TextField()
    disponible = models.BooleanField(default=True)

    def __str__(self):
        return self.titre