
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/api_config.dart';
import '../../services/messagerie_service.dart';
import 'chat_screen.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() =>
      _ConversationsScreenState();
}

class _ConversationsScreenState
    extends State<ConversationsScreen> {
  List<dynamic> conversations = [];
  bool isLoading = true;
  String? errorMessage;
  String role = '';

  @override
  void initState() {
    super.initState();
    loadConversations();
  }

  // CHARGER LES CONVERSATIONS
  Future<void> loadConversations() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      role = prefs.getString('role') ?? '';

      final result =
          await MessagerieService.getConversations();

      if (!mounted) return;

      setState(() {
        conversations = result;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  // NOM DE L'INTERLOCUTEUR
  String getOtherUsername(
    Map<String, dynamic> conversation,
  ) {
    final visitor = conversation['visiteur'] ?? {};
    final owner = conversation['proprietaire'] ?? {};

    if (role == 'visiteur') {
      return owner['username'] ?? 'Propriétaire';
    }

    return visitor['username'] ?? 'Visiteur';
  }

  // PHOTO DE PROFIL DE L'INTERLOCUTEUR
  String? getOtherProfilePhoto(
    Map<String, dynamic> conversation,
  ) {
    final visitor = conversation['visiteur'] ?? {};
    final owner = conversation['proprietaire'] ?? {};

    final otherUser =
        role == 'visiteur' ? owner : visitor;

    final photo = otherUser['profile_photo'];

    // Photo par défaut
    if (photo == null || photo.toString().trim().isEmpty) {
      return '${ApiConfig.baseUrl}/media/profiles/photo.png';
    }

    final photoPath = photo.toString();
    final photoUri = Uri.tryParse(photoPath);

    // URL complète renvoyée par Django
    if (photoUri != null && photoUri.hasScheme) {
      if (photoUri.host == '127.0.0.1' ||
          photoUri.host == 'localhost') {
        return Uri.parse(ApiConfig.baseUrl)
            .resolve(photoUri.path)
            .toString();
      }

      return photoPath;
    }

    // Chemin relatif
    return Uri.parse(ApiConfig.baseUrl)
        .resolve(photoPath)
        .toString();
  }

  // AVATAR AVEC PHOTO OU ICÔNE PAR DÉFAUT
  Widget construireAvatar(String? photoUrl) {
    return CircleAvatar(
      radius: 27,
      backgroundColor: const Color(0xFF6C4AB6),
      child: ClipOval(
        child: photoUrl == null
            ? const SizedBox(
                width: 54,
                height: 54,
                child: Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 30,
                ),
              )
            : Image.network(
                photoUrl,
                width: 54,
                height: 54,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const SizedBox(
                    width: 54,
                    height: 54,
                    child: Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 30,
                    ),
                  );
                },
              ),
      ),
    );
  }

  // DERNIER MESSAGE
  String getLastMessage(
    Map<String, dynamic> conversation,
  ) {
    final message = conversation['dernier_message'];

    if (message == null) {
      return 'Aucun message pour le moment';
    }

    return message['contenu'] ?? '';
  }

  // FORMATER LA DATE
  String formatDate(dynamic date) {
    if (date == null) return '';

    try {
      final parsedDate =
          DateTime.parse(date.toString()).toLocal();

      final now = DateTime.now();

      if (parsedDate.year == now.year &&
          parsedDate.month == now.month &&
          parsedDate.day == now.day) {
        return '${parsedDate.hour.toString().padLeft(2, '0')}:'
            '${parsedDate.minute.toString().padLeft(2, '0')}';
      }

      return '${parsedDate.day.toString().padLeft(2, '0')}/'
          '${parsedDate.month.toString().padLeft(2, '0')}/'
          '${parsedDate.year}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mes conversations',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),

      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )

          : errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(errorMessage!),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: loadConversations,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )

              : conversations.isEmpty
                  ? const Center(
                      child: Text(
                        'Vous n’avez aucune conversation.',
                        style: TextStyle(fontSize: 16),
                      ),
                    )

                  : RefreshIndicator(
                      onRefresh: loadConversations,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: conversations.length,

                        itemBuilder: (context, index) {
                          final conversation =
                              Map<String, dynamic>.from(
                            conversations[index],
                          );

                          final username =
                              getOtherUsername(conversation);

                          final photoUrl =
                              getOtherProfilePhoto(conversation);

                          final logement =
                              conversation['logement_titre'] ??
                                  'Logement';

                          final lastMessage =
                              getLastMessage(conversation);

                          final lastMessageData =
                              conversation['dernier_message'];

                          final date = formatDate(
                            lastMessageData?['date_creation'],
                          );

                          return Card(
                            margin: const EdgeInsets.only(
                              bottom: 12,
                            ),
                            elevation: 2,

                            child: ListTile(
                              contentPadding:
                                  const EdgeInsets.all(12),

                              // PHOTO DE PROFIL
                              leading: construireAvatar(
                                photoUrl,
                              ),

                              // NOM
                              title: Text(
                                username,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              // INFORMATIONS
                              subtitle: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),

                                  Text('Logement : $logement'),

                                  const SizedBox(height: 4),

                                  Text(
                                    lastMessage,
                                    maxLines: 1,
                                    overflow:
                                        TextOverflow.ellipsis,
                                  ),
                                ],
                              ),

                              // DATE ET FLÈCHE
                              trailing: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  Text(
                                    date,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),

                                  const SizedBox(height: 6),

                                  const Icon(
                                    Icons.arrow_forward_ios,
                                    size: 16,
                                  ),
                                ],
                              ),

                              // OUVRIR LA CONVERSATION
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ChatScreen(
                                      conversationId:
                                          conversation['id'],
                                      username: username,
                                      logementTitre: logement,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
