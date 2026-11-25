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
  // ===========================================================================
  // THÈME DARIGO
  // ===========================================================================
  static const Color _fondCreme = Color(0xFFF5F2EB);
  static const Color _surfaceClaire = Color(0xFFFAF8F3);
  static const Color _sableClair = Color(0xFFEAE3D5);
  static const Color _vertSapin = Color(0xFF1F3D2B);
  static const Color _brunTerre = Color(0xFF6F5E4E);
  static const Color _textePrincipal = Color(0xFF1D2B22);
  static const Color _texteSecondaire = Color(0xFF677068);
  static const Color _rougeErreur = Color(0xFFB5483C);

  // ===========================================================================
  // ÉTAT
  // ===========================================================================
  List<dynamic> _conversations = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _role = '';

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  // ===========================================================================
  // CHARGEMENT DES DONNÉES
  // ===========================================================================
  Future<void> _loadConversations() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedRole = prefs.getString('role') ?? '';
      final result = await MessagerieService.getConversations();

      if (!mounted) return;

      setState(() {
        _role = savedRole;
        _conversations = result;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  // ===========================================================================
  // HELPERS & FORMATAGE
  // ===========================================================================
  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return {};
  }

  String _asString(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  String _getOtherUsername(Map<String, dynamic> conversation) {
    final visitor = _asMap(conversation['visiteur']);
    final owner = _asMap(conversation['proprietaire']);

    if (_role == 'visiteur') {
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

  String? _getOtherProfilePhoto(Map<String, dynamic> conversation) {
    final visitor = _asMap(conversation['visiteur']);
    final owner = _asMap(conversation['proprietaire']);

    final otherUser = _role == 'visiteur' ? owner : visitor;
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

  String _getLastMessage(Map<String, dynamic> conversation) {
    final message = _asMap(conversation['dernier_message']);
    if (message.isEmpty) {
      return 'Aucun message pour le moment';
    }
    return _asString(
      message['contenu'],
      fallback: 'Aucun message pour le moment',
    );
  }

  int _getUnreadCount(Map<String, dynamic> conversation) {
    return _asInt(conversation['messages_non_lus']) ?? 0;
  }

  String _formatDate(dynamic date) {
    if (date == null) return '';

    try {
      final parsedDate = DateTime.parse(date.toString()).toLocal();
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

  Future<void> _ouvrirConversation({
    required int? conversationId,
    required String username,
    required String logement,
    required String? photoUrl,
  }) async {
    if (conversationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Identifiant de conversation invalide.'),
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
      _loadConversations();
    }
  }

  // ===========================================================================
  // COMPOSANTS UI
  // ===========================================================================
  Widget _construireAvatar(String? photoUrl) {
    const fallback = Icon(
      Icons.person_outline,
      color: _vertSapin,
      size: 28,
    );

    return CircleAvatar(
      radius: 27,
      backgroundColor: _sableClair,
      child: ClipOval(
        child: photoUrl == null || photoUrl.isEmpty
            ? fallback
            : Image.network(
                photoUrl,
                width: 54,
                height: 54,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => fallback,
              ),
      ),
    );
  }

  Widget _construireBadgeNonLus(int count) {
    if (count <= 0) {
      return const SizedBox.shrink();
    }

    return Container(
      constraints: const BoxConstraints(
        minWidth: 22,
        minHeight: 22,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 2,
      ),
      decoration: const BoxDecoration(
        color: _vertSapin,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        count > 99 ? '99+' : count.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _construireCarteConversation(Map<String, dynamic> conversation) {
    final conversationId = _asInt(conversation['id']);
    final username = _getOtherUsername(conversation);
    final photoUrl = _getOtherProfilePhoto(conversation);
    final logement = _asString(
      conversation['logement_titre'],
      fallback: 'Logement',
    );
    final lastMessage = _getLastMessage(conversation);
    final lastMessageData = _asMap(conversation['dernier_message']);
    final date = _formatDate(lastMessageData['date_creation']);
    final unreadCount = _getUnreadCount(conversation);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _surfaceClaire,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _sableClair),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          _ouvrirConversation(
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
              _construireAvatar(photoUrl),
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
                        fontWeight: FontWeight.w700,
                        color: _textePrincipal,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Logement : $logement',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: _brunTerre,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        color: unreadCount > 0
                            ? _textePrincipal
                            : _texteSecondaire,
                        fontWeight: unreadCount > 0
                            ? FontWeight.w600
                            : FontWeight.w400,
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
                        color: _texteSecondaire,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _construireBadgeNonLus(unreadCount),
                    const SizedBox(height: 8),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: _brunTerre,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _construireListeConversations() {
    return RefreshIndicator(
      color: _vertSapin,
      backgroundColor: _surfaceClaire,
      onRefresh: _loadConversations,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
        itemCount: _conversations.length,
        itemBuilder: (_, index) =>
            _construireCarteConversation(_asMap(_conversations[index])),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _fondCreme,
      appBar: AppBar(
        title: const Text(
          'Mes conversations',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: _fondCreme,
        foregroundColor: _vertSapin,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: _vertSapin,
                ),
              )
            : _errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: _rougeErreur,
                            size: 44,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _errorMessage ?? 'Erreur inconnue',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: _textePrincipal,
                            ),
                          ),
                          const SizedBox(height: 14),
                          ElevatedButton(
                            onPressed: _loadConversations,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _vertSapin,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text('Réessayer'),
                          ),
                        ],
                      ),
                    ),
                  )
                : _conversations.isEmpty
                    ? RefreshIndicator(
                        color: _vertSapin,
                        backgroundColor: _surfaceClaire,
                        onRefresh: _loadConversations,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 220),
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 54,
                              color: _vertSapin,
                            ),
                            SizedBox(height: 12),
                            Center(
                              child: Text(
                                'Vous n’avez aucune conversation.',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: _texteSecondaire,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : _construireListeConversations(),
      ),
    );
  }
}