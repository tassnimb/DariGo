import 'dart:async';
import 'dart:convert';
import '../../config/api_config.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class ChatScreen extends StatefulWidget {
  final int conversationId;
  final String username;
  final String logementTitre;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.username,
    required this.logementTitre,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
static String get baseUrl => ApiConfig.baseUrl;

  final TextEditingController messageController =
      TextEditingController();

  final ScrollController scrollController = ScrollController();

  final List<Map<String, dynamic>> messages = [];

  WebSocketChannel? channel;
  StreamSubscription? subscription;

  bool isLoading = true;
  bool isSending = false;
  bool isConnected = false;

  String? errorMessage;
  String? token;
  int? currentUserId;

  @override
  void initState() {
    super.initState();
    initialiserChat();
  }

  Future<void> initialiserChat() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      token = prefs.getString('access');

      if (token == null || token!.isEmpty) {
        throw Exception('Utilisateur non connecté.');
      }

      // Identification locale pour distinguer les messages.
      // Le serveur reste responsable de l'authentification.
      try {
        final parts = token!.split('.');
        if (parts.length == 3) {
          final payload = jsonDecode(
            utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
          );

          final id = payload['user_id'];
          if (id is num) {
            currentUserId = id.toInt();
          } else {
            currentUserId = int.tryParse('$id');
          }
        }
      } catch (_) {}

      await chargerMessages();
      await connecterWebSocket();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> chargerMessages() async {
    final response = await http.get(
      Uri.parse(
'$baseUrl/api/messagerie/conversations/${widget.conversationId}/messages/',
      ),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      final List<dynamic> liste =
          data is List ? data :
          data is Map && data['results'] is List
              ? data['results']
              : [];

      if (!mounted) return;

      setState(() {
        messages
          ..clear()
          ..addAll(
            liste.map((e) => Map<String, dynamic>.from(e)),
          );
        isLoading = false;
      });

      defilerVersBas();
    } else if (response.statusCode == 401) {
      throw Exception('Session expirée. Reconnectez-vous.');
    } else {
      throw Exception(
        'Erreur lors du chargement des messages : ${response.statusCode}',
      );
    }
  }

  Future<void> connecterWebSocket() async {
 final baseUri = Uri.parse(baseUrl);

final uri = Uri(
  scheme: baseUri.scheme == 'https' ? 'wss' : 'ws',
  host: baseUri.host,
  port: baseUri.port,
  path:
      '/ws/messagerie/conversations/${widget.conversationId}/',
  queryParameters: {
    'token': token!,
  },
);

    channel = WebSocketChannel.connect(uri);

    subscription = channel!.stream.listen(
      (data) {
        try {
          final decoded = jsonDecode(data as String);

          if (decoded is Map<String, dynamic>) {
            ajouterMessage(decoded);
          }
        } catch (e) {
          debugPrint('Erreur réception WebSocket : $e');
        }
      },
      onError: (error) {
        debugPrint('Erreur WebSocket : $error');

        if (mounted) {
          setState(() {
            isConnected = false;
          });
        }
      },
      onDone: () {
        if (mounted) {
          setState(() {
            isConnected = false;
          });
        }
      },
    );

    if (mounted) {
      setState(() {
        isConnected = true;
      });
    }
  }

  void ajouterMessage(Map<String, dynamic> message) {
    final id = message['id'];

    // Éviter les doublons.
    if (id != null &&
        messages.any((m) => '${m['id']}' == '$id')) {
      return;
    }

    if (!mounted) return;

    setState(() {
      messages.add(message);
    });

    defilerVersBas();
  }

  Future<void> envoyerMessage() async {
    final contenu = messageController.text.trim();

    if (contenu.isEmpty || channel == null || !isConnected) {
      return;
    }

    setState(() {
      isSending = true;
    });

    try {
      channel!.sink.add(
        jsonEncode({
          'contenu': contenu,
        }),
      );

      messageController.clear();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible d’envoyer le message.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSending = false;
        });
      }
    }
  }

  bool estMonMessage(Map<String, dynamic> message) {
    if (currentUserId == null) return false;

    final auteur = message['auteur'];

    final auteurId = auteur is Map
        ? auteur['id']
        : auteur;

    final id = auteurId is num
        ? auteurId.toInt()
        : int.tryParse('$auteurId');

    return id == currentUserId;
  }

  String formaterHeure(dynamic date) {
    if (date == null) return '';

    try {
      final parsed = DateTime.parse(date).toLocal();

      return '${parsed.hour.toString().padLeft(2, '0')}:'
          '${parsed.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  void defilerVersBas() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !scrollController.hasClients) return;

      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    subscription?.cancel();
    channel?.sink.close();
    messageController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const violet = Color(0xFF6C4AB6);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F6FA),
      appBar: AppBar(
        backgroundColor: violet,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.username,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
            Text(
              widget.logementTitre,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 15),
            child: Icon(
              Icons.circle,
              size: 12,
              color: isConnected ? Colors.greenAccent : Colors.grey,
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(errorMessage!),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: initialiserChat,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: messages.isEmpty
                          ? const Center(
                              child: Text('Aucun message pour le moment.'),
                            )
                          : ListView.builder(
                              controller: scrollController,
                              padding: const EdgeInsets.all(14),
                              itemCount: messages.length,
                              itemBuilder: (context, index) {
                                final message = messages[index];
                                final mine = estMonMessage(message);

                                return Align(
                                  alignment: mine
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft,
                                  child: Container(
                                    constraints: BoxConstraints(
                                      maxWidth:
                                          MediaQuery.of(context).size.width * 0.75,
                                    ),
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 5,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: mine
                                          ? violet
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          message['contenu'] ?? '',
                                          style: TextStyle(
                                            color: mine
                                                ? Colors.white
                                                : Colors.black87,
                                            fontSize: 15,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          formaterHeure(
                                            message['date_creation'],
                                          ),
                                          style: TextStyle(
                                            color: mine
                                                ? Colors.white70
                                                : Colors.grey,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                    Container(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                      color: Colors.white,
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: messageController,
                              minLines: 1,
                              maxLines: 4,
                              decoration: InputDecoration(
                                hintText: 'Écrire un message...',
                                filled: true,
                                fillColor: const Color(0xFFF2F0F6),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(25),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 12,
                                ),
                              ),
                              onSubmitted: (_) => envoyerMessage(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          CircleAvatar(
                            backgroundColor: violet,
                            child: IconButton(
                              onPressed: isSending || !isConnected
                                  ? null
                                  : envoyerMessage,
                              icon: const Icon(
                                Icons.send,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}