
import json
import logging

from decimal import Decimal, InvalidOperation

from django.conf import settings

from google import genai
from google.genai import types

from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated

from logements.models import Logement
from logements.serializers import LogementSerializer


logger = logging.getLogger(__name__)


class ChatBotView(APIView):

    permission_classes = [IsAuthenticated]

    def post(self, request):

        # =====================================
        # 1. VALIDATION DU MESSAGE
        # =====================================

        message = request.data.get('message', '')

        if not isinstance(message, str):
            return Response(
                {'error': 'Message invalide.'},
                status=400
            )

        message = message.strip()

        if not message:
            return Response(
                {'error': 'Veuillez saisir un message.'},
                status=400
            )

        if len(message) > 3000:
            return Response(
                {'error': 'Message trop long.'},
                status=400
            )

        # =====================================
        # 2. VALIDATION DE L'HISTORIQUE
        # =====================================

        history = request.data.get('history', [])

        if not isinstance(history, list):
            history = []

        conversation = []

        for item in history[-10:]:

            if not isinstance(item, dict):
                continue

            role = item.get('role')
            content = item.get('content')

            if role not in ['user', 'assistant']:
                continue

            if not isinstance(content, str):
                continue

            content = content.strip()

            if not content:
                continue

            role_name = (
                'Utilisateur'
                if role == 'user'
                else 'Assistant'
            )

            conversation.append(
                f"{role_name}: {content[:2000]}"
            )

        conversation.append(
            f"Utilisateur: {message}"
        )

        prompt = "\n".join(conversation)

        # =====================================
        # 3. VÉRIFICATION DE LA CLÉ GEMINI
        # =====================================

        api_key = getattr(
            settings,
            'GEMINI_API_KEY',
            None
        )

        if not api_key:
            logger.error("GEMINI_API_KEY absente.")

            return Response(
                {'error': 'Service chatbot indisponible.'},
                status=503
            )

        # =====================================
        # 4. INSTRUCTIONS DU CHATBOT
        # =====================================

        instructions = """
Tu es DariGo Smart Assistant, un conseiller immobilier
intelligent intégré dans une application de location
de logements en Tunisie.

TON OBJECTIF :

Comprendre les besoins de l'utilisateur et l'aider
à trouver le logement qui lui convient.

INFORMATIONS À IDENTIFIER :

- Budget maximum en dinars tunisiens.
- Ville souhaitée pour habiter.
- Gouvernorat souhaité.
- Lieu de travail.
- École des enfants.
- Nombre minimum de chambres.
- Type de logement souhaité.

RÈGLES IMPORTANTES :

1. Réponds toujours en français.
2. Sois naturel, sympathique et professionnel.
3. Pose des questions progressivement.
4. Ne demande pas toutes les informations en même temps.
5. Conserve les informations déjà données dans l'historique.
6. Extrais uniquement les informations réellement données.
7. Ne transforme jamais le lieu de travail en ville souhaitée.
8. Ne transforme jamais l'école en ville souhaitée.
9. Renseigne ville uniquement si l'utilisateur indique
   explicitement où il souhaite habiter.
10. Le budget doit être un nombre en dinars tunisiens.
11. Si l'utilisateur demande au moins 2 chambres,
    utilise chambres_min = 2.
12. N'invente jamais de logements, de prix ou de distances.
13. Les logements réels sont recherchés dans la base Django.
14. Les informations inconnues doivent être null.
15. Pour type_logement, utilise uniquement :
    maison, appartement, grange, chambre_hotes, bateau,
    cabane, camping_car, villa, chateau, grotte, autre.

FORMAT OBLIGATOIRE :

Retourne uniquement un objet JSON valide :

{
    "reply": "Réponse destinée à l'utilisateur",
    "filters": {
        "budget_max": null,
        "ville": null,
        "gouvernorat": null,
        "chambres_min": null,
        "type_logement": null,
        "travail": null,
        "ecole": null
    }
}

Ne retourne aucun texte avant ou après le JSON.
"""

        # =====================================
        # 5. APPEL À GEMINI
        # =====================================

        try:

            client = genai.Client(
                api_key=api_key
            )

            ai_response = client.models.generate_content(
                model="gemini-3.5-flash-lite",
                contents=prompt,
                config=types.GenerateContentConfig(
                    system_instruction=instructions,
                    response_mime_type="application/json",
                    temperature=0.3,
                    max_output_tokens=1000
                )
            )

            if not ai_response.text:
                logger.error("Gemini a retourné une réponse vide.")

                return Response(
                    {'error': 'Le chatbot n’a pas pu générer une réponse.'},
                    status=502
                )

            result = json.loads(
                ai_response.text
            )

            if not isinstance(result, dict):
                raise ValueError(
                    "La réponse Gemini doit être un objet JSON."
                )

        except json.JSONDecodeError:

            logger.exception(
                "Réponse JSON invalide de Gemini."
            )

            return Response(
                {'error': 'La réponse du chatbot est invalide.'},
                status=502
            )

        except Exception as e:

            logger.exception(
                "Erreur lors de l'appel Gemini : %s",
                str(e)
            )

            error_text = str(e).lower()

            if '429' in error_text or 'quota' in error_text:
                return Response(
                    {
                        'error': 'Limite d’utilisation Gemini atteinte. Réessayez plus tard.'
                    },
                    status=429
                )

            if '503' in error_text or 'unavailable' in error_text:
                return Response(
                    {
                        'error': 'Le service Gemini est temporairement indisponible. Réessayez dans quelques instants.'
                    },
                    status=503
                )

            return Response(
                {
                    'error': 'Impossible de contacter le service intelligent.'
                },
                status=502
            )

        # =====================================
        # 6. RÉCUPÉRATION ET VALIDATION DES FILTRES
        # =====================================

        filters = result.get('filters', {})

        reply = result.get('reply', '')

        if not isinstance(filters, dict):
            filters = {}

        if not isinstance(reply, str) or not reply.strip():
            reply = (
                "Bonjour ! Je suis DariGo Smart Assistant. "
                "Comment puis-je vous aider à trouver un logement ?"
            )

        # Ne conserver que les filtres autorisés.
        allowed_filters = {
            'budget_max',
            'ville',
            'gouvernorat',
            'chambres_min',
            'type_logement',
            'travail',
            'ecole'
        }

        filters = {
            key: filters.get(key)
            for key in allowed_filters
        }

        # =====================================
        # 7. RECHERCHE DES LOGEMENTS
        # =====================================

        try:

            logements = Logement.objects.all().prefetch_related(
                'photos'
            )

            # ---------------------------------
            # Budget maximum
            # ---------------------------------

            budget = filters.get('budget_max')

            if budget is not None:

                try:

                    if isinstance(budget, bool):
                        raise InvalidOperation()

                    budget = Decimal(str(budget))

                    if not budget.is_finite() or budget <= 0:
                        raise InvalidOperation()

                    logements = logements.filter(
                        prix__lte=budget
                    )

                    filters['budget_max'] = float(budget)

                except (InvalidOperation, ValueError, TypeError):
                    filters['budget_max'] = None

            # ---------------------------------
            # Ville
            # ---------------------------------

            ville = filters.get('ville')

            if isinstance(ville, str) and ville.strip():

                ville = ville.strip()[:100]

                logements = logements.filter(
                    ville__icontains=ville
                )

                filters['ville'] = ville

            else:
                filters['ville'] = None

            # ---------------------------------
            # Gouvernorat
            # ---------------------------------

            gouvernorat = filters.get('gouvernorat')

            if isinstance(gouvernorat, str) and gouvernorat.strip():

                gouvernorat = gouvernorat.strip()[:100]

                logements = logements.filter(
                    gouvernorat__icontains=gouvernorat
                )

                filters['gouvernorat'] = gouvernorat

            else:
                filters['gouvernorat'] = None

            # ---------------------------------
            # Nombre minimum de chambres
            # ---------------------------------

            chambres = filters.get('chambres_min')

            if chambres is not None:

                try:

                    if isinstance(chambres, bool):
                        raise ValueError()

                    chambres = int(chambres)

                    if chambres < 1 or chambres > 50:
                        raise ValueError()

                    logements = logements.filter(
                        chambres__gte=chambres
                    )

                    filters['chambres_min'] = chambres

                except (ValueError, TypeError):
                    filters['chambres_min'] = None

            # ---------------------------------
            # Type de logement
            # ---------------------------------

            type_logement = filters.get('type_logement')

            types_valides = dict(
                Logement.TYPE_LOGEMENT_CHOICES
            )

            if (
                isinstance(type_logement, str)
                and type_logement in types_valides
            ):

                logements = logements.filter(
                    type_logement=type_logement
                )

            else:
                filters['type_logement'] = None

            # ---------------------------------
            # Travail et école
            # ---------------------------------
            # Ces informations ne sont pas des
            # champs de filtrage du modèle Logement.

            travail = filters.get('travail')

            if not isinstance(travail, str):
                filters['travail'] = None
            else:
                filters['travail'] = travail.strip()[:150] or None

            ecole = filters.get('ecole')

            if not isinstance(ecole, str):
                filters['ecole'] = None
            else:
                filters['ecole'] = ecole.strip()[:150] or None

            # =====================================
            # 8. LIMITATION DES RÉSULTATS
            # =====================================

            logements = logements.order_by(
                'prix',
                '-date_creation'
            )[:20]

            # =====================================
            # 9. SÉRIALISATION
            # =====================================

            serializer = LogementSerializer(
                logements,
                many=True,
                context={
                    'request': request
                }
            )

            results = serializer.data

        except Exception:

            logger.exception(
                "Erreur lors de la recherche ou sérialisation des logements."
            )

            return Response(
                {
                    'error': 'Impossible de récupérer les logements.'
                },
                status=500
            )

        # =====================================
        # 10. CONSTRUCTION DE LA RÉPONSE
        # =====================================

        criteres = [
            'budget_max',
            'ville',
            'gouvernorat',
            'chambres_min',
            'type_logement'
        ]

        recherche_effectuee = any(
            filters.get(key) is not None
            for key in criteres
        )

        if recherche_effectuee:

            if results:

                reply += (
                    f"\n\nJ'ai trouvé {len(results)} "
                    "logement(s) correspondant à vos critères."
                )

            else:

                reply += (
                    "\n\nJe n'ai trouvé aucun logement "
                    "correspondant exactement à ces critères. "
                    "Essayons d'élargir votre recherche."
                )

        return Response(
            {
                'reply': reply,
                'filters': filters,
                'logements': results
            },
            status=200
        )
