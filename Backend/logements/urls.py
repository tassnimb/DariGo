from django.urls import path
from .views import LogementListCreateView, LogementRetrieveUpdateDeleteView

urlpatterns = [
    path(
        '',
        LogementListCreateView.as_view(),
        name='logements',),
    path(
        '<int:pk>/',
        LogementRetrieveUpdateDeleteView.as_view(),
        name='logement-detail',
    ),

]