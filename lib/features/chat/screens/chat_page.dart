import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:myapp/core/models/chat_message.dart';
import 'package:myapp/core/services/chat_service.dart';

// Asume que existe esta pantalla; si no, créala o cambia la ruta.
// import 'package:myapp/ui/screens/profile_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    this.initialPeerUid,
    this.initialPeerName,
    this.initialPeerAvatarUrl,
  });

  final String? initialPeerUid;
  final String? initialPeerName;
  final String? initialPeerAvatarUrl;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late List<Chat> chats;
  late Chat activeChat;

  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  StreamSubscription<List<ChatMessage>>? _messagesSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _chatsSubscription;
  bool _hasEnteredChat = false;
  bool _hasHandledInitialPeer = false;
  bool _isEnsuringInitialChat = false;

  @override
  void initState() {
    super.initState();
    chats = [];
    _subscribeToUserChats();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  Future<void> _tryOpenInitialPeerChat(List<Chat> updatedChats) async {
    final initialPeerUid = widget.initialPeerUid;
    if (initialPeerUid == null || initialPeerUid.isEmpty) {
      return;
    }

    if (_hasHandledInitialPeer) {
      return;
    }

    Chat? matchedChat;
    for (final chat in updatedChats) {
      if (chat.peerUid == initialPeerUid) {
        matchedChat = chat;
        break;
      }
    }

    if (matchedChat != null) {
      _hasHandledInitialPeer = true;
      _handleChatSelect(matchedChat);
      return;
    }

    if (_isEnsuringInitialChat) {
      return;
    }

    _isEnsuringInitialChat = true;
    try {
      await ChatService.instance.ensureDirectChat(
        peerUid: initialPeerUid,
        peerName: widget.initialPeerName ?? 'Usuario',
        peerAvatarUrl: widget.initialPeerAvatarUrl,
      );
    } catch (_) {
      // Si falla la creación, el usuario aún puede entrar manualmente a chats existentes.
    } finally {
      _isEnsuringInitialChat = false;
    }
  }

  @override
  void dispose() {
    _chatsSubscription?.cancel();
    _messagesSubscription?.cancel();
    _inputController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _subscribeToUserChats() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    _chatsSubscription?.cancel();
    _chatsSubscription = ChatService.instance.streamCurrentUserChats().listen(
      (snapshot) {
        if (!mounted) return;

        if (snapshot.docs.isEmpty) {
          setState(() {
            chats = [];
            _hasEnteredChat = false;
          });
          return;
        }

        final previousByChatId = <String, Chat>{
          for (final chat in chats)
            if (chat.chatId != null) chat.chatId!: chat,
        };

        final updatedChats = <Chat>[];
        for (var index = 0; index < snapshot.docs.length; index++) {
          final doc = snapshot.docs[index];
          final data = doc.data();

          final participants =
              (data['participants'] as List?)?.whereType<String>().toList() ??
              const <String>[];
          final peerUid = participants.firstWhere(
            (uid) => uid != currentUserId,
            orElse: () => 'unknown_peer',
          );

          final participantProfiles =
              data['participantProfiles'] as Map<String, dynamic>?;
          final peerProfile = participantProfiles != null
              ? participantProfiles[peerUid] as Map<String, dynamic>?
              : null;

          final previous = previousByChatId[doc.id];
          updatedChats.add(
            Chat(
              id: index + 1,
              peerUid: peerUid,
              username:
                  (peerProfile?['displayName'] as String?)?.trim().isNotEmpty ==
                      true
                  ? (peerProfile!['displayName'] as String)
                  : 'Usuario',
              avatar:
                  (peerProfile?['photoURL'] as String?) ??
                  'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?q=80&w=1080',
              lastMessage: (data['lastMessage'] as String?) ?? '',
              lastMessageTime:
                  (data['lastMessageTime'] as Timestamp?)?.toDate() ??
                  DateTime.now(),
              unread: previous?.unread ?? 0,
              online: previous?.online ?? false,
              messages: previous?.messages ?? <Message>[],
              chatId: doc.id,
            ),
          );
        }

        // Ordenar chats por último mensaje más reciente
        updatedChats.sort(
          (a, b) => b.lastMessageTime.compareTo(a.lastMessageTime),
        );

        if (!_hasEnteredChat) {
          setState(() {
            chats = updatedChats;
            if (updatedChats.isNotEmpty) {
              activeChat = updatedChats.first;
            }
          });
          _tryOpenInitialPeerChat(updatedChats);
          return;
        }

        final activeChatId = activeChat.chatId;
        var nextActive = updatedChats.first;
        for (final chat in updatedChats) {
          if (chat.chatId == activeChatId) {
            nextActive = chat;
            break;
          }
        }

        final changedActiveChat = nextActive.chatId != activeChat.chatId;
        setState(() {
          chats = updatedChats;
          activeChat = nextActive;
        });

        if (changedActiveChat) {
          _subscribeToActiveChat();
        }
      },
      onError: (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error cargando chats: $error')));
      },
    );
  }

  Future<void> _subscribeToActiveChat() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    var chatId = activeChat.chatId;
    chatId ??= await ChatService.instance.ensureDirectChat(
      peerUid: activeChat.peerUid,
      peerName: activeChat.username,
      peerAvatarUrl: activeChat.avatar,
    );

    activeChat.chatId = chatId;
    await _messagesSubscription?.cancel();
    _messagesSubscription = ChatService.instance
        .streamMessages(chatId)
        .listen(
          (items) {
            if (!mounted) return;

            final mapped = items
                .map(
                  (m) => Message(
                    id: Object.hash(
                      m.senderId,
                      m.timestamp.millisecondsSinceEpoch,
                      m.text,
                    ),
                    text: m.text,
                    sender: m.senderId == uid ? 'user' : 'other',
                    timestamp: m.timestamp,
                  ),
                )
                .toList();

            setState(() {
              activeChat.messages = mapped;
              if (mapped.isNotEmpty) {
                activeChat.lastMessage = mapped.last.text;
                activeChat.lastMessageTime = mapped.last.timestamp;
              }
            });

            _scrollToBottom();
          },
          onError: (error) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error cargando mensajes: $error')),
            );
          },
        );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes iniciar sesion para usar el chat')),
      );
      return;
    }

    var chatId = activeChat.chatId;
    chatId ??= await ChatService.instance.ensureDirectChat(
      peerUid: activeChat.peerUid,
      peerName: activeChat.username,
      peerAvatarUrl: activeChat.avatar,
    );

    await ChatService.instance.sendMessage(
      chatId: chatId,
      receiverId: activeChat.peerUid,
      text: text,
    );

    setState(() {
      activeChat.chatId = chatId;
      activeChat.lastMessage = text;
      activeChat.lastMessageTime = DateTime.now();
      _inputController.clear();
    });

    _scrollToBottom();
  }

  void _handleChatSelect(Chat chat) {
    setState(() {
      activeChat = chat;
      activeChat.unread = 0;
      _hasEnteredChat = true;
    });
    _subscribeToActiveChat();
    _scrollToBottom();
  }

  /// Navega a la pantalla de perfil del usuario con el que se está chateando.
  void _goToProfile() {
    if (activeChat.peerUid.isEmpty) return;

    // Ajusta esta línea según el nombre real de tu pantalla de perfil y sus parámetros.
    // Ejemplo: ProfileScreen(uid: activeChat.peerUid, username: activeChat.username, avatarUrl: activeChat.avatar)
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileScreen(
          uid: activeChat.peerUid,
          username: activeChat.username,
          avatarUrl: activeChat.avatar,
          photos: [
            'https://images.unsplash.com/photo-1503023345310-bd7c1de61c7d?q=80&w=1080',
            'https://images.unsplash.com/photo-1494790108377-be9c29b29330?q=80&w=1080',
            'https://images.unsplash.com/photo-1508214751196-bcfd4ca60f91?q=80&w=1080',
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime value) {
    return '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildChatList(BuildContext context, {bool closeOnSelect = false}) {
    final colorScheme = Theme.of(context).colorScheme;
    // Filtrar por búsqueda (nombre o último mensaje)
    final filtered = _searchQuery.isEmpty
        ? chats
        : chats.where((c) {
            final name = c.username.toLowerCase();
            final last = c.lastMessage.toLowerCase();
            return name.contains(_searchQuery) || last.contains(_searchQuery);
          }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'Buscar...',
              prefixIcon: Icon(Icons.search),
            ),
          ),
        ),
        if (filtered.isEmpty)
          Expanded(
            child: Center(
              child: Text(
                'No tienes conversaciones aún',
                style: TextStyle(color: colorScheme.onSurface.withOpacity(0.7)),
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final chat = filtered[index];
                final selected =
                    chat.id == (chats.isNotEmpty ? activeChat.id : -1);
                return ListTile(
                  selected: selected,
                  selectedTileColor: colorScheme.primary.withOpacity(0.12),
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(chat.avatar),
                  ),
                  title: Text(
                    chat.username,
                    style: TextStyle(color: colorScheme.onSurface),
                  ),
                  subtitle: Text(
                    chat.lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  trailing: Text(_formatTime(chat.lastMessageTime)),
                  onTap: () {
                    _handleChatSelect(chat);
                    if (closeOnSelect) {
                      Navigator.pop(context);
                    }
                  },
                );
              },
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (!_hasEnteredChat) {
      return Scaffold(body: _buildChatList(context));
    }

    return Scaffold(
      body: Column(
        children: [
          AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                setState(() {
                  _hasEnteredChat = false;
                });
              },
            ),
            // 👇 Aquí se agrega el tap al nombre del usuario
            title: GestureDetector(
              onTap: _goToProfile,
              child: Text(activeChat.username),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: activeChat.messages.length,
              itemBuilder: (context, index) {
                final message = activeChat.messages[index];
                final mine = message.sender == 'user';
                return Align(
                  alignment: mine
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: mine
                          ? colorScheme.primary
                          : colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: mine
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        Text(
                          message.text,
                          style: TextStyle(
                            color: mine
                                ? colorScheme.onPrimary
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatTime(message.timestamp),
                          style: TextStyle(
                            fontSize: 11,
                            color:
                                (mine
                                        ? colorScheme.onPrimary
                                        : colorScheme.onSurfaceVariant)
                                    .withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      decoration: const InputDecoration(
                        hintText: 'Escribe un mensaje...',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _handleSendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _handleSendMessage,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Define esta pantalla en tu proyecto o ajusta la importación.
class ProfileScreen extends StatefulWidget {
  final String uid;
  final String username;
  final String avatarUrl;
  final List<String> photos;

  const ProfileScreen({
    super.key,
    required this.uid,
    required this.username,
    required this.avatarUrl,
    required this.photos,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? userProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .get();

      if (mounted) {
        setState(() {
          userProfile = userDoc.data();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(widget.username), elevation: 0),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Header con avatar
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          colorScheme.primary.withOpacity(0.1),
                          colorScheme.surface,
                        ],
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundImage: NetworkImage(widget.avatarUrl),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.username,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        if (userProfile?['displayName'] != null &&
                            userProfile!['displayName'] != widget.username)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              userProfile!['displayName'] ?? '',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: colorScheme.onSurface.withOpacity(
                                      0.7,
                                    ),
                                  ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Información del perfil
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Bio o descripción
                        if (userProfile?['bio'] != null &&
                            (userProfile!['bio'] as String).isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Acerca de',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                userProfile!['bio'],
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        // Edad y Localización
                        if (userProfile?['age'] != null ||
                            userProfile?['location'] != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  if (userProfile?['age'] != null)
                                    Expanded(
                                      child: _buildInfoCard(
                                        context,
                                        Icons.cake,
                                        'Edad',
                                        '${userProfile!['age']} años',
                                      ),
                                    ),
                                  if (userProfile?['location'] != null)
                                    const SizedBox(width: 12),
                                  if (userProfile?['location'] != null)
                                    Expanded(
                                      child: _buildInfoCard(
                                        context,
                                        Icons.location_on,
                                        'Ubicación',
                                        userProfile!['location'],
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        // Intereses
                        if (userProfile?['interests'] != null &&
                            (userProfile!['interests'] as List).isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Intereses',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (final interest
                                      in userProfile!['interests'] as List)
                                    Chip(
                                      label: Text(interest),
                                      backgroundColor:
                                          colorScheme.primaryContainer,
                                      labelStyle: TextStyle(
                                        color: colorScheme.onPrimaryContainer,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                      ],
                    ),
                  ),
                  // Fotos
                  if (widget.photos.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Galería',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              for (final photo in widget.photos)
                                Padding(
                                  padding: const EdgeInsets.only(right: 12),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: GestureDetector(
                                      onTap: () =>
                                          _showImagePreview(context, photo),
                                      child: Image.network(
                                        photo,
                                        width: 150,
                                        height: 150,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (
                                              context,
                                              error,
                                              stackTrace,
                                            ) => Container(
                                              width: 150,
                                              height: 150,
                                              color: colorScheme.surfaceVariant,
                                              child: const Icon(Icons.image),
                                            ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(label, style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  void _showImagePreview(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Image.network(imageUrl, fit: BoxFit.contain),
        ),
      ),
    );
  }
}
