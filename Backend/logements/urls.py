
from django.urls import path

from .views import (
    LogementListCreateView,
    LogementRetrieveUpdateDeleteView,
    ReservationListCreateView,
    ReservationDetailView,
    FavoriListCreateView,
    FavoriDeleteView,
    AvisLogementListView,
AvisReservationCreateView,
)

urlpatterns = [
    # LOGEMENTS
    path(
        'logements/',
        LogementListCreateView.as_view(),
        name='logement-list',
    ),

    path(
        'logements/<int:pk>/',
        LogementRetrieveUpdateDeleteView.as_view(),
        name='logement-detail',
    ),

    # RESERVATIONS
    path(
        'reservations/',
        ReservationListCreateView.as_view(),
        name='reservation-list',
    ),

    path(
        'reservations/<int:pk>/',
        ReservationDetailView.as_view(),
        name='reservation-detail',
    ),
    path(
    'favoris/',
    FavoriListCreateView.as_view()
),

path(
    'favoris/<int:pk>/',
    FavoriDeleteView.as_view()
),
# AVIS
path(
    'logements/<int:logement_id>/avis/',
    AvisLogementListView.as_view(),
    name='avis-logement-list',
),

path(
    'reservations/<int:reservation_id>/avis/',
    AvisReservationCreateView.as_view(),
    name='avis-reservation-create',
),
]
