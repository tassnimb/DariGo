
from urllib.parse import parse_qs

from channels.db import database_sync_to_async
from channels.middleware import BaseMiddleware
from django.contrib.auth.models import AnonymousUser
from django.contrib.auth import get_user_model

from rest_framework_simplejwt.tokens import AccessToken
from rest_framework_simplejwt.exceptions import InvalidToken, TokenError


@database_sync_to_async
def get_user_from_token(token):
    User = get_user_model()

    try:
        access_token = AccessToken(token)
        user_id = access_token["user_id"]

        return User.objects.get(
            id=user_id,
            is_active=True
        )

    except (InvalidToken, TokenError, User.DoesNotExist, KeyError) as error:
        print("JWT AUTH ERROR:", type(error).__name__)
        return AnonymousUser()


class JWTAuthMiddleware(BaseMiddleware):

    async def __call__(self, scope, receive, send):
        print(">>> MON JWT MIDDLEWARE EST EXECUTE <<<")

        query_string = scope.get("query_string", b"").decode()
        query_params = parse_qs(query_string)

        token = query_params.get("token", [None])[0]

        print("WS TOKEN RECEIVED:", bool(token))

        if token:
            scope["user"] = await get_user_from_token(token)
        else:
            scope["user"] = AnonymousUser()

        print("WS USER AUTHENTICATED:", scope["user"].is_authenticated)

        return await super().__call__(scope, receive, send)


def JWTAuthMiddlewareStack(inner):
    return JWTAuthMiddleware(inner)
