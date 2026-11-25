
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

class _ConversationsScreenState extends State<ConversationsScreen> {
  List<dynamic> conversations = [];
  bool isLoading = true;
  String? errorMessage;
  String role = '';

  @override
  void initState() {
    super.initState();
    loadConversations();
  }

  Future<void> loadConversations() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedRole = prefs.getString('role') ?? '';

      final result = await MessagerieService.getConversations();

      if (!mounted) return;

      setState(() {
        role = savedRole;
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

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return {};
  }

  String _asString(
    dynamic value, {
    String fallback = '',
  }) {
    if (value == null) return fallback;

    final text = value.toString().trim();

    return text.isEmpty ? fallback : text;
  }

  int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();

    return int.tryParse(value?.toString() ?? '');
  }

  String getOtherUsername(
    Map<String, dynamic> conversation,
  ) {
    final visitor = _asMap(conversation['visiteur']);
    final owner = _asMap(conversation['proprietaire']);

    if (role == 'visiteur') {
      return _asString(
        owner['username'],
        fallback: 'Propriétaire',
      );
    }

    return _asString(
      visitor['username'],
      fallback: 'Visiteur',
    );
  }

  String? getOtherProfilePhoto(
    Map<String, dynamic> conversation,
  ) {
    final visitor = _asMap(conversation['visiteur']);
    final owner = _asMap(conversation['proprietaire']);

    final otherUser = role == 'visiteur' ? owner : visitor;
    final photo = otherUser['profile_photo'];

    if (photo == null || photo.toString().trim().isEmpty) {
      return '${ApiConfig.baseUrl}/media/profiles/photo.png';
    }

    final photoPath = photo.toString().trim();
    final photoUri = Uri.tryParse(photoPath);

    if (photoUri != null && photoUri.hasScheme) {
      if (photoUri.host == '127.0.0.1' ||
          photoUri.host == 'localhost') {
        return Uri.parse(ApiConfig.baseUrl)
            .resolve(photoUri.path)
            .toString();
      }

      return photoPath;
    }

    return Uri.parse(ApiConfig.baseUrl)
        .resolve(photoPath)
        .toString();
  }

  Widget construireAvatar(String? photoUrl) {
    const fallback = SizedBox(
      width: 54,
      height: 54,
      child: Icon(
        Icons.person,
        color: Colors.white,
        size: 30,
      ),
    );

    return CircleAvatar(
      radius: 27,
      backgroundColor: const Color(0xFF6C4AB6),
      child: ClipOval(
        child: photoUrl == null || photoUrl.isEmpty
            ? fallback
            : Image.network(
                photoUrl,
                width: 54,
                height: 54,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return fallback;
                },
              ),
      ),
    );
  }

  String getLastMessage(
    Map<String, dynamic> conversation,
  ) {
    final message = _asMap(conversation['dernier_message']);

    if (message.isEmpty) {
      return 'Aucun message pour le moment';
    }

    return _asString(
      message['contenu'],
      fallback: 'Aucun message pour le moment',
    );
  }

  int getUnreadCount(
    Map<String, dynamic> conversation,
  ) {
    return _asInt(conversation['messages_non_lus']) ?? 0;
  }

  Widget construireBadgeNonLus(int count) {
    if (count <= 0) {
      return const SizedBox.shrink();
    }

    return Container(
      constraints: const BoxConstraints(
        minWidth: 24,
        minHeight: 24,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 3,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF6C4AB6),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        count > 99 ? '99+' : count.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

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

  Future<void> ouvrirConversation({
    required int? conversationId,
    required String username,
    required String logement,
    required String? photoUrl,
  }) async {
    if (conversationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Identifiant de conversation invalide.',
          ),
        ),
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          conversationId: conversationId,
          username: username,
          logementTitre: logement,
          profilePhotoUrl: photoUrl,
        ),
      ),
    );

    if (mounted) {
      loadConversations();
    }
  }

  Widget construireListeConversations() {
    return RefreshIndicator(
      onRefresh: loadConversations,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: conversations.length,
        itemBuilder: (context, index) {
          final conversation = _asMap(conversations[index]);

          final conversationId =
              _asInt(conversation['id']);

          final username =
              getOtherUsername(conversation);

          final photoUrl =
              getOtherProfilePhoto(conversation);

          final logement = _asString(
            conversation['logement_titre'],
            fallback: 'Logement',
          );

          final lastMessage =
              getLastMessage(conversation);

          final lastMessageData =
              _asMap(conversation['dernier_message']);

          final date = formatDate(
            lastMessageData['date_creation'],
          );

          final unreadCount =
              getUnreadCount(conversation);

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            shadowColor: Colors.black.withOpacity(0.08),
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () {
                ouvrirConversation(
                  conversationId: conversationId,
                  username: username,
                  logement: logement,
                  photoUrl: photoUrl,
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    construireAvatar(photoUrl),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            username,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF24212B),
                            ),
                          ),

                          const SizedBox(height: 5),

                          Text(
                            'Logement : $logement',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF77717F),
                            ),
                          ),

                          const SizedBox(height: 7),

                          Text(
                            lastMessage,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF514B59),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 10),

                    SizedBox(
                      width: 48,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            date,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF9993A0),
                            ),
                          ),

                          const SizedBox(height: 8),

                          construireBadgeNonLus(unreadCount),

                          const SizedBox(height: 8),

                          const Icon(
                            Icons.arrow_forward_ios,
                            size: 15,
                            color: Color(0xFF77717F),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
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
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          errorMessage ?? 'Erreur inconnue',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: loadConversations,
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  ),
                )
              : conversations.isEmpty
                  ? RefreshIndicator(
                      onRefresh: loadConversations,
                      child: ListView(
                        physics:
                            const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 250),
                          Center(
                            child: Text(
                              'Vous n’avez aucune conversation.',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                    )
                  : construireListeConversations(),
    );
  }
}
