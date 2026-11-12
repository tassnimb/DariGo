
from django.contrib.auth.models import AbstractUser
from django.db import models

class User(AbstractUser):
    phone = models.CharField(max_length=20)

    ROLE_CHOICES = [
        ('visiteur', 'Visiteur'),
        ('proprietaire', 'Propriétaire'),
    ]

    role = models.CharField(
        max_length=20,
        choices=ROLE_CHOICES,
        default='visiteur'
    )


    def __str__(self):
        return self.username