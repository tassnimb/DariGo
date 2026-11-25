
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
  static String get baseUrl => ApiConfig.baseUrl;

  final TextEditingController messageController =
      TextEditingController();

  final ScrollController scrollController =
      ScrollController();

  final List<Map<String, dynamic>> messages = [];

  WebSocketChannel? channel;
  StreamSubscription? subscription;
  Timer? messagesTimer;

  bool isLoading = true;
  bool isSending = false;
  bool isConnected = false;

  String? errorMessage;
  String? token;
  int? currentUserId;

  @override
  void initState() {
    super.initState();

    debugPrint(
      'CONVERSATION ID : ${widget.conversationId}',
    );

    initialiserChat();
  }

  Future<void> initialiserChat() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      token = prefs.getString('access');

      if (token == null || token!.isEmpty) {
        throw Exception('Utilisateur non connecté.');
      }

      // Récupération de l'identifiant utilisateur depuis le JWT.
      try {
        final parts = token!.split('.');

        if (parts.length == 3) {
          final payload = jsonDecode(
            utf8.decode(
              base64Url.decode(
                base64Url.normalize(parts[1]),
              ),
            ),
          );

          final id = payload['user_id'];

          if (id is num) {
            currentUserId = id.toInt();
          } else {
            currentUserId = int.tryParse('$id');
          }
        }
      } catch (e) {
        debugPrint('Erreur décodage JWT : $e');
      }

      await chargerMessages();

      if (!mounted) return;

      await connecterWebSocket();

      // Synchronisation automatique avec l'API REST.
      messagesTimer?.cancel();

      messagesTimer = Timer.periodic(
        const Duration(seconds: 3),
        (_) {
          if (mounted) {
            chargerMessages(silencieux: true);
          }
        },
      );
    } catch (e) {
      debugPrint('Erreur initialisation chat : $e');

      if (!mounted) return;

      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> chargerMessages({
    bool silencieux = false,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/api/messagerie/conversations/'
          '${widget.conversationId}/messages/',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint(
        'GET MESSAGES : ${response.statusCode}',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final List<dynamic> liste =
            data is List
                ? data
                : data is Map &&
                        data['results'] is List
                    ? data['results']
                    : [];

        final nouveauxMessages = liste
            .whereType<Map>()
            .map(
              (e) => Map<String, dynamic>.from(e),
            )
            .toList();

        if (!mounted) return;

        final anciensIds = messages
            .map((m) => '${m['id']}')
            .toList();

        final nouveauxIds = nouveauxMessages
            .map((m) => '${m['id']}')
            .toList();

        if (anciensIds.toString() !=
            nouveauxIds.toString()) {
          setState(() {
            messages
              ..clear()
              ..addAll(nouveauxMessages);
          });

          defilerVersBas();
        }

        if (isLoading) {
          setState(() {
            isLoading = false;
          });
        }
      } else if (response.statusCode == 401) {
        throw Exception(
          'Session expirée. Reconnectez-vous.',
        );
      } else {
        debugPrint(
          'Réponse API : ${response.body}',
        );

        throw Exception(
          'Erreur chargement messages : '
          '${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Erreur chargerMessages : $e');

      if (!silencieux && mounted) {
        setState(() {
          errorMessage = e.toString();
          isLoading = false;
        });
      }
    }
  }

  Future<void> connecterWebSocket() async {
    try {
      final baseUri = Uri.parse(baseUrl);

      final uri = Uri(
        scheme:
            baseUri.scheme == 'https' ? 'wss' : 'ws',
        host: baseUri.host,
        port: baseUri.port,
        path:
            '/ws/messagerie/conversations/'
            '${widget.conversationId}/',
        queryParameters: {
          'token': token!,
        },
      );

      channel = WebSocketChannel.connect(uri);

      // Attendre que la connexion soit établie.
      await channel!.ready;

      subscription = channel!.stream.listen(
        (data) {
          try {
            final decoded = jsonDecode(data as String);

            if (decoded is Map) {
              ajouterMessage(
                Map<String, dynamic>.from(decoded),
              );
            }
          } catch (e) {
            debugPrint(
              'Erreur réception WebSocket : $e',
            );
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
          debugPrint('WebSocket déconnecté');

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
    } catch (e) {
      debugPrint(
        'Connexion WebSocket impossible : $e',
      );

      if (mounted) {
        setState(() {
          isConnected = false;
        });
      }
    }
  }

  void ajouterMessage(
    Map<String, dynamic> message,
  ) {
    final id = message['id'];

    // Éviter les doublons.
    if (id != null &&
        messages.any(
          (m) => '${m['id']}' == '$id',
        )) {
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

    if (contenu.isEmpty || isSending) {
      return;
    }

    if (token == null || token!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Vous devez vous reconnecter.',
          ),
        ),
      );

      return;
    }

    setState(() {
      isSending = true;
    });

    try {
      final response = await http.post(
        Uri.parse(
          '$baseUrl/api/messagerie/conversations/'
          '${widget.conversationId}/messages/',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contenu': contenu,
        }),
      );

      debugPrint(
        'POST MESSAGE : ${response.statusCode}',
      );

      debugPrint(
        'POST REPONSE : ${response.body}',
      );

      if (response.statusCode == 200 ||
          response.statusCode == 201) {
        messageController.clear();

        // Recharger depuis la base de données.
        await chargerMessages(silencieux: true);
      } else {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erreur envoi : ${response.statusCode}',
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Erreur envoi message : $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Impossible d’envoyer le message.',
          ),
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

  bool estMonMessage(
    Map<String, dynamic> message,
  ) {
    if (currentUserId == null) {
      return false;
    }

    final auteur = message['auteur'];

    final auteurId =
        auteur is Map ? auteur['id'] : auteur;

    final id = auteurId is num
        ? auteurId.toInt()
        : int.tryParse('$auteurId');

    return id == currentUserId;
  }

  String formaterHeure(dynamic date) {
    if (date == null) return '';

    try {
      final parsed =
          DateTime.parse(date.toString()).toLocal();

      return '${parsed.hour.toString().padLeft(2, '0')}:'
          '${parsed.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  Widget construirePhotoProfil() {
    final photo = widget.profilePhotoUrl?.trim();

    Widget photoParDefaut() {
      return const CircleAvatar(
        radius: 22,
        backgroundColor: Colors.white24,
        child: Icon(
          Icons.person,
          color: Colors.white,
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

    return ClipOval(
      child: SizedBox(
        width: 44,
        height: 44,
        child: Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (
            context,
            error,
            stackTrace,
          ) {
            return photoParDefaut();
          },
        ),
      ),
    );
  }

  void defilerVersBas() {
    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        if (!mounted ||
            !scrollController.hasClients) {
          return;
        }

        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration:
              const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      },
    );
  }

  @override
  void dispose() {
    messagesTimer?.cancel();
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
      backgroundColor:
          const Color(0xFFF7F6FA),
      appBar: AppBar(
        backgroundColor: violet,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            construirePhotoProfil(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
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
                    style: const TextStyle(
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding:
                const EdgeInsets.only(right: 15),
            child: Icon(
              Icons.circle,
              size: 12,
              color: isConnected
                  ? Colors.greenAccent
                  : Colors.grey,
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : errorMessage != null
              ? Center(
                  child: Padding(
                    padding:
                        const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize:
                          MainAxisSize.min,
                      children: [
                        Text(errorMessage!),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              isLoading = true;
                              errorMessage = null;
                            });

                            initialiserChat();
                          },
                          child: const Text(
                            'Réessayer',
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: messages.isEmpty
                          ? const Center(
                              child: Text(
                                'Aucun message pour le moment.',
                              ),
                            )
                          : ListView.builder(
                              controller:
                                  scrollController,
                              padding:
                                  const EdgeInsets.all(14),
                              itemCount:
                                  messages.length,
                              itemBuilder:
                                  (context, index) {
                                final message =
                                    messages[index];

                                final mine =
                                    estMonMessage(
                                  message,
                                );

                                final contenu =
                                    message['contenu']
                                        ?.toString() ??
                                    '';

                                return Align(
                                  alignment: mine
                                      ? Alignment
                                          .centerRight
                                      : Alignment
                                          .centerLeft,
                                  child: Container(
                                    constraints:
                                        BoxConstraints(
                                      maxWidth:
                                          MediaQuery.of(
                                                context,
                                              )
                                              .size
                                              .width *
                                          0.75,
                                    ),
                                    margin:
                                        const EdgeInsets
                                            .symmetric(
                                      vertical: 5,
                                    ),
                                    padding:
                                        const EdgeInsets
                                            .symmetric(
                                      horizontal: 14,
                                      vertical: 10,
                                    ),
                                    decoration:
                                        BoxDecoration(
                                      color: mine
                                          ? violet
                                          : Colors.white,
                                      borderRadius:
                                          BorderRadius
                                              .circular(
                                        16,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisSize:
                                          MainAxisSize
                                              .min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment
                                              .end,
                                      children: [
                                        Text(
                                          contenu,
                                          style:
                                              TextStyle(
                                            color: mine
                                                ? Colors
                                                    .white
                                                : Colors
                                                    .black87,
                                            fontSize:
                                                15,
                                          ),
                                        ),
                                        const SizedBox(
                                          height: 5,
                                        ),
                                        Text(
                                          formaterHeure(
                                            message[
                                                'date_creation'],
                                          ),
                                          style:
                                              TextStyle(
                                            color: mine
                                                ? Colors
                                                    .white70
                                                : Colors
                                                    .grey,
                                            fontSize:
                                                10,
                                          ),
                                        ),
                                        if (mine &&
                                            message[
                                                    'date_lecture'] !=
                                                null)
                                          const Padding(
                                            padding:
                                                EdgeInsets
                                                    .only(
                                              top: 3,
                                            ),
                                            child:
                                                Text(
                                              'Lu',
                                              style:
                                                  TextStyle(
                                                color: Colors
                                                    .white70,
                                                fontSize:
                                                    10,
                                              ),
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
                      padding:
                          const EdgeInsets.fromLTRB(
                        12,
                        10,
                        12,
                        12,
                      ),
                      color: Colors.white,
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller:
                                  messageController,
                              minLines: 1,
                              maxLines: 4,
                              decoration:
                                  InputDecoration(
                                hintText:
                                    'Écrire un message...',
                                filled: true,
                                fillColor:
                                    const Color(
                                  0xFFF2F0F6,
                                ),
                                border:
                                    OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                    25,
                                  ),
                                  borderSide:
                                      BorderSide.none,
                                ),
                                contentPadding:
                                    const EdgeInsets
                                        .symmetric(
                                  horizontal: 18,
                                  vertical: 12,
                                ),
                              ),
                              onSubmitted: (_) =>
                                  envoyerMessage(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          CircleAvatar(
                            backgroundColor: violet,
                            child: IconButton(
                              onPressed: isSending
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
