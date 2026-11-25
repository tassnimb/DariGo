
from django.db import models
from django.conf import settings


class Logement(models.Model):

    TYPE_LOGEMENT_CHOICES = [
        ('maison', 'Maison'),
        ('appartement', 'Appartement'),
        ('grange', 'Grange'),
        ('chambre_hotes', 'Chambre d’hôtes'),
        ('bateau', 'Bateau'),
        ('cabane', 'Cabane'),
        ('camping_car', 'Camping-car'),
        ('villa', 'Villa'),
        ('chateau', 'Château'),
        ('grotte', 'Grotte'),
        ('autre', 'Autre'),
    ]

    TYPE_HEBERGEMENT_CHOICES = [
        ('entier', 'Logement entier'),
        ('privee', 'Chambre privée'),
        ('partagee', 'Chambre partagée'),
    ]

    # Informations principales
    titre = models.CharField(max_length=200)
    description = models.TextField()
    adresse = models.CharField(max_length=255)
    prix = models.DecimalField(max_digits=10, decimal_places=2)

    latitude = models.FloatField(null=True, blank=True)
    longitude = models.FloatField(null=True, blank=True)

    # Type de logement
    type_logement = models.CharField(
        max_length=30,
        choices=TYPE_LOGEMENT_CHOICES,
        default='appartement'
    )

    # Type d'hébergement
    type_hebergement = models.CharField(
        max_length=20,
        choices=TYPE_HEBERGEMENT_CHOICES,
        default='entier'
    )

    # Adresse détaillée
    pays = models.CharField(max_length=100, default='Tunisie')
    ville = models.CharField(max_length=100, blank=True, default='')
    gouvernorat = models.CharField(max_length=100, blank=True, default='')
    code_postal = models.CharField(max_length=20, blank=True, default='')

    # Capacité
    nombre_voyageurs = models.PositiveIntegerField(default=1)
    chambres = models.PositiveIntegerField(default=1)
    lits = models.PositiveIntegerField(default=1)
    salles_bain = models.PositiveIntegerField(default=1)

    # Propriétaire
    proprietaire = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="logements"
    )

    date_creation = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.titre


# PHOTOS DU LOGEMENT
class PhotoLogement(models.Model):

    logement = models.ForeignKey(
        Logement,
        on_delete=models.CASCADE,
        related_name='photos'
    )

    image = models.ImageField(
        upload_to='logements/'
    )

    date_creation = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Photo de {self.logement.titre}"


class Reservation(models.Model):

    STATUT_CHOICES = [
        ('en_attente', 'En attente'),
        ('acceptee', 'Acceptée'),
        ('refusee', 'Refusée'),
        ('annulee', 'Annulée'),
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


class Favori(models.Model):

    visiteur = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='favoris'
    )

    logement = models.ForeignKey(
        Logement,
        on_delete=models.CASCADE,
        related_name='favoris'
    )

    date_creation = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = (
            'visiteur',
            'logement'
        )

    def __str__(self):
        return f"{self.visiteur} - {self.logement}"


class Avis(models.Model):

    NOTE_CHOICES = [
        (1, '1 étoile'),
        (2, '2 étoiles'),
        (3, '3 étoiles'),
        (4, '4 étoiles'),
        (5, '5 étoiles'),
    ]

    reservation = models.OneToOneField(
        Reservation,
        on_delete=models.CASCADE,
        related_name='avis'
    )

    note = models.PositiveSmallIntegerField(
        choices=NOTE_CHOICES
    )

    commentaire = models.TextField(blank=True)

    date_creation = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Avis {self.note}/5 - {self.reservation.logement.titre}"
