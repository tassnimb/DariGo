from rest_framework import generics, permissions
from .models import Logement
from .serializers import LogementSerializer


class LogementListCreateView(generics.ListCreateAPIView):
    serializer_class = LogementSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return Logement.objects.all()

    def perform_create(self, serializer):
        serializer.save(proprietaire=self.request.user)


class LogementRetrieveUpdateDeleteView(
    generics.RetrieveUpdateDestroyAPIView
):
    serializer_class = LogementSerializer
    permission_classes = [permissions.IsAuthenticated]
    queryset = Logement.objects.all()