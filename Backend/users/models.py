from django.contrib.auth.models import AbstractUser
from django.db import models


class User(AbstractUser):
    first_name = models.CharField(max_length=100)
    last_name = models.CharField(max_length=100)

    phone = models.CharField(max_length=20)

    birth_date = models.DateField(
        null=True,
        blank=True,
    )

    profile_photo = models.ImageField(
        upload_to='profiles/',
        null=True,
        blank=True,
    )

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