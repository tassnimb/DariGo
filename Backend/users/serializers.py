from rest_framework import serializers
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer

from .models import User


class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(
        write_only=True,
        min_length=6
    )

    class Meta:
        model = User
        fields = [
            'id',
            'username',
            'first_name',
            'last_name',
            'email',
            'phone',
            'birth_date',
            'profile_photo',
            'password',
            'role',
        ]

    def create(self, validated_data):
        profile_photo = validated_data.pop(
            'profile_photo',
            None
        )

        user = User.objects.create_user(
            username=validated_data['username'],
            first_name=validated_data['first_name'],
            last_name=validated_data['last_name'],
            email=validated_data['email'],
            phone=validated_data['phone'],
            birth_date=validated_data.get(
                'birth_date'
            ),
            password=validated_data['password'],
            role=validated_data['role'],
        )

        if profile_photo:
            user.profile_photo = profile_photo
            user.save()

        return user


class CustomTokenObtainPairSerializer(
    TokenObtainPairSerializer
):

    def validate(self, attrs):
        data = super().validate(attrs)

        data['id'] = self.user.id
        data['username'] = self.user.username
        data['first_name'] = self.user.first_name
        data['last_name'] = self.user.last_name
        data['email'] = self.user.email
        data['phone'] = self.user.phone
        data['role'] = self.user.role

        data['birth_date'] = (
            self.user.birth_date.isoformat()
            if self.user.birth_date
            else None
        )

        data['profile_photo'] = (
            self.user.profile_photo.url
            if self.user.profile_photo
            else None
        )

        return data