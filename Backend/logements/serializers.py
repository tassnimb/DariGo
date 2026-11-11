from rest_framework import serializers
from .models import Logement

class LogementSerializer(serializers.ModelSerializer):
    class Meta:
        model = Logement
        fields = "__all__"
        read_only_fields = ["proprietaire", "date_creation"]