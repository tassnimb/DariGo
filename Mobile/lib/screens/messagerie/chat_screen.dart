import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../config/api_config.dart';

class ChatScreen extends StatefulWidget {
  final int conversationId;
  final String username;
  final String logementTitre;
  final String? profilePhotoUrl;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.username,
    required this.logementTitre,
    this.profilePhotoUrl,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // ===========================================================================
  // THÈME DARIGO
  // ===========================================================================
  static const Color _fondCreme = Color(0xFFF5F2EB);
  static const Color _surfaceClaire = Color(0xFFFAF8F3);
  static const Color _sableClair = Color(0xFFEAE3D5);
  static const Color _vertSapin = Color(0xFF1F3D2B);
  static const Color _vertSauge = Color(0xFF6E8F79);
  static const Color _brunTerre = Color(0xFF6F5E4E);
  static const Color _textePrincipal = Color(0xFF1D2B22);
  static const Color _texteSecondaire = Color(0xFF677068);
  static const Color _rougeErreur = Color(0xFFB5483C);

  static String get _baseUrl => ApiConfig.baseUrl;

  // ===========================================================================
  // ÉTAT & CONTRÔLEURS
  // ===========================================================================
  final TextEditingController _messageController =
      TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, dynamic>> messages = [];

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _messagesTimer;

  bool _isLoading = true;
  bool _isSending = false;
  bool _isConnected = false;

  String? _errorMessage;
  String? _token;
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    debugPrint('CONVERSATION ID : ${widget.conversationId}');
    _initialiserChat();
  }

  @override
  void dispose() {
    _messagesTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ===========================================================================
  // INITIALISATION & RÉSEAU
  // ===========================================================================
  Future<void> _initialiserChat() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('access');

      if (_token == null || _token!.isEmpty) {
        throw Exception('Utilisateur non connecté.');
      }

      try {
        final parts = _token!.split('.');
        if (parts.length == 3) {
          final payload = jsonDecode(
            utf8.decode(
              base64Url.decode(
                base64Url.normalize(parts[1]),
              ),
            ),
          );

          final id = payload['user_id'];
          _currentUserId = id is num ? id.toInt() : int.tryParse('$id');
        }
      } catch (e) {
        debugPrint('Erreur décodage JWT : $e');
      }

      await _chargerMessages();
      if (!mounted) return;

      await _connecterWebSocket();

      _messagesTimer?.cancel();
      _messagesTimer = Timer.periodic(
        const Duration(seconds: 3),
        (_) {
          if (mounted) {
            _chargerMessages(silencieux: true);
          }
        },
      );
    } catch (e) {
      debugPrint('Erreur initialisation chat : $e');
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _chargerMessages({bool silencieux = false}) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl/api/messagerie/conversations/'
          '${widget.conversationId}/messages/',
        ),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('GET MESSAGES : ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> liste = data is List
            ? data
            : data is Map && data['results'] is List
                ? data['results']
                : [];

        final nouveauxMessages = liste
            .whereType()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();

        if (!mounted) return;

        final anciensIds = messages.map((m) => '${m['id']}').toList();
        final nouveauxIds =
            nouveauxMessages.map((m) => '${m['id']}').toList();

        if (anciensIds.toString() != nouveauxIds.toString()) {
          setState(() {
            messages
              ..clear()
              ..addAll(nouveauxMessages);
          });
          _defilerVersBas();
        }

        if (_isLoading) {
          setState(() => _isLoading = false);
        }
      } else if (response.statusCode == 401) {
        throw Exception('Session expirée. Reconnectez-vous.');
      } else {
        debugPrint('Réponse API : ${response.body}');
        throw Exception(
          'Erreur chargement messages : ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Erreur chargerMessages : $e');
      if (!silencieux && mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _connecterWebSocket() async {
    try {
      final baseUri = Uri.parse(_baseUrl);
      final uri = Uri(
        scheme: baseUri.scheme == 'https' ? 'wss' : 'ws',
        host: baseUri.host,
        port: baseUri.port,
        path: '/ws/messagerie/conversations/${widget.conversationId}/',
        queryParameters: {'token': _token!},
      );

      _channel = WebSocketChannel.connect(uri);
      await _channel!.ready;

      _subscription = _channel!.stream.listen(
        (data) {
          try {
            final decoded = jsonDecode(data as String);
            if (decoded is Map) {
              _ajouterMessage(Map<String, dynamic>.from(decoded));
            }
          } catch (e) {
            debugPrint('Erreur réception WebSocket : $e');
          }
        },
        onError: (error) {
          debugPrint('Erreur WebSocket : $error');
          if (mounted) {
            setState(() => _isConnected = false);
          }
        },
        onDone: () {
          debugPrint('WebSocket déconnecté');
          if (mounted) {
            setState(() => _isConnected = false);
          }
        },
      );

      if (mounted) {
        setState(() => _isConnected = true);
      }
    } catch (e) {
      debugPrint('Connexion WebSocket impossible : $e');
      if (mounted) {
        setState(() => _isConnected = false);
      }
    }
  }

  void _ajouterMessage(Map<String, dynamic> message) {
    final id = message['id'];
    if (id != null && messages.any((m) => '${m['id']}' == '$id')) {
      return;
    }
    if (!mounted) return;

    setState(() => messages.add(message));
    _defilerVersBas();
  }

  Future<void> _envoyerMessage() async {
    final contenu = _messageController.text.trim();
    if (contenu.isEmpty || _isSending) return;

    if (_token == null || _token!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vous devez vous reconnecter.'),
        ),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      final response = await http.post(
        Uri.parse(
          '$_baseUrl/api/messagerie/conversations/'
          '${widget.conversationId}/messages/',
        ),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'contenu': contenu}),
      );

      debugPrint('POST MESSAGE : ${response.statusCode}');
      debugPrint('POST REPONSE : ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        _messageController.clear();
        await _chargerMessages(silencieux: true);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur envoi : ${response.statusCode}'),
          ),
        );
      }
    } catch (e) {
      debugPrint('Erreur envoi message : $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible d’envoyer le message.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  // ===========================================================================
  // FORMATAGE & DÉFILEMENT
  // ===========================================================================
  bool _estMonMessage(Map<String, dynamic> message) {
    if (_currentUserId == null) return false;

    final auteur = message['auteur'];
    final auteurId = auteur is Map ? auteur['id'] : auteur;
    final id = auteurId is num
        ? auteurId.toInt()
        : int.tryParse('$auteurId');

    return id == _currentUserId;
  }

  String _formaterHeure(dynamic date) {
    if (date == null) return '';

    try {
      final parsed = DateTime.parse(date.toString()).toLocal();
      return '${parsed.hour.toString().padLeft(2, '0')}:'
          '${parsed.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  void _defilerVersBas() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  // ===========================================================================
  // COMPOSANTS UI
  // ===========================================================================
  Widget _construirePhotoProfil() {
    final photo = widget.profilePhotoUrl?.trim();

    Widget photoParDefaut() {
      return const CircleAvatar(
        radius: 20,
        backgroundColor: _sableClair,
        child: Icon(
          Icons.person_outline,
          color: _vertSapin,
          size: 21,
        ),
      );
    }

    if (photo == null || photo.isEmpty) {
      return photoParDefaut();
    }

    final uri = Uri.tryParse(photo);
    final url = uri != null && uri.hasScheme
        ? photo
        : '${ApiConfig.baseUrl}'
            '${photo.startsWith('/') ? '' : '/'}'
            '$photo';

    return CircleAvatar(
      radius: 20,
      backgroundColor: _sableClair,
      child: ClipOval(
        child: Image.network(
          url,
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => photoParDefaut(),
        ),
      ),
    );
  }

  PreferredSizeWidget _construireAppBar() {
    return AppBar(
      backgroundColor: _fondCreme,
      foregroundColor: _vertSapin,
      elevation: 0,
      scrolledUnderElevation: 0,
      title: Row(
        children: [
          _construirePhotoProfil(),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.username,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: _textePrincipal,
                  ),
                ),
                Text(
                  widget.logementTitre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: _texteSecondaire,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Tooltip(
            message: _isConnected ? 'Connecté' : 'Hors ligne',
            child: Icon(
              Icons.circle,
              size: 11,
              color: _isConnected ? _vertSauge : _brunTerre,
            ),
          ),
        ),
      ],
    );
  }

  Widget _construireBulleMessage(Map<String, dynamic> message) {
    final mine = _estMonMessage(message);
    final contenu = message['contenu']?.toString() ?? '';
    final heure = _formaterHeure(message['date_creation']);
    final estLu = mine && message['date_lecture'] != null;

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: mine ? _vertSapin : _surfaceClaire,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(mine ? 16 : 4),
            bottomRight: Radius.circular(mine ? 4 : 16),
          ),
          border: mine ? null : Border.all(color: _sableClair),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              contenu,
              style: TextStyle(
                color: mine ? Colors.white : _textePrincipal,
                fontSize: 15,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 5),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  heure,
                  style: TextStyle(
                    color: mine
                        ? Colors.white.withValues(alpha: 0.75)
                        : _texteSecondaire,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (estLu) ...[
                  const SizedBox(width: 6),
                  Text(
                    'Lu',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _construireZoneSaisie() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: const BoxDecoration(
        color: _surfaceClaire,
        border: Border(
          top: BorderSide(color: _sableClair),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                minLines: 1,
                maxLines: 4,
                style: const TextStyle(color: _textePrincipal),
                decoration: InputDecoration(
                  hintText: 'Écrire un message...',
                  hintStyle: const TextStyle(color: _texteSecondaire),
                  filled: true,
                  fillColor: _fondCreme,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: _sableClair),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(
                      color: _vertSapin,
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 11,
                  ),
                ),
                onSubmitted: (_) => _envoyerMessage(),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: _isSending ? _vertSauge : _vertSapin,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _isSending ? null : _envoyerMessage,
                child: const SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(
                    Icons.send_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _fondCreme,
      appBar: _construireAppBar(),
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
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: _textePrincipal,
                            ),
                          ),
                          const SizedBox(height: 14),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _isLoading = true;
                                _errorMessage = null;
                              });
                              _initialiserChat();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _vertSapin,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text('Réessayer'),
                          ),
                        ],
                      ),
                    ),
                  )
                : Column(
                    children: [
                      Expanded(
                        child:messages.isEmpty
                            ? const Center(
                                child: Text(
                                  'Aucun message pour le moment.',
                                  style: TextStyle(
                                    color: _texteSecondaire,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                controller: _scrollController,
                                padding: const EdgeInsets.all(14),
                                itemCount: messages.length,
                                itemBuilder: (_, index) =>
                                    _construireBulleMessage(
                                  messages[index],
                                ),
                              ),
                      ),
                      _construireZoneSaisie(),
                    ],
                  ),
      ),
    );
  }
}