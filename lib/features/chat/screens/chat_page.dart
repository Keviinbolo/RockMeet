import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:RockMeet/core/models/chat_message.dart';
import 'package:RockMeet/core/services/chat_service.dart';
import 'package:RockMeet/core/services/presence_service.dart';
import 'package:RockMeet/features/chat/screens/peer_profile_screen.dart';
import 'package:RockMeet/features/chat/widgets/chat_input_bar.dart';
import 'package:RockMeet/core/services/supabase_service.dart';
import 'package:RockMeet/features/chat/widgets/message_bubble.dart';


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
                  SupabaseService.instance.randomFallbackUrl ??
                  '',
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

  void _goToProfile() {
    if (activeChat.peerUid.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PeerProfileScreen(
          uid: activeChat.peerUid,
          username: activeChat.username,
          avatarUrl: activeChat.avatar,
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
                  leading: StreamBuilder<bool>(
                    stream: PresenceService.instance
                        .watchOnlineStatus(chat.peerUid),
                    builder: (context, onlineSnap) {
                      final isOnline = onlineSnap.data ?? false;
                      return Stack(
                        children: [
                          CircleAvatar(
                            backgroundImage: NetworkImage(chat.avatar),
                          ),
                          if (isOnline)
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: colorScheme.surface,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
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
            title: StreamBuilder<bool>(
              stream: PresenceService.instance
                  .watchOnlineStatus(activeChat.peerUid),
              builder: (context, onlineSnap) {
                final isOnline = onlineSnap.data ?? false;
                return GestureDetector(
                  onTap: _goToProfile,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(activeChat.username),
                      Text(
                        isOnline ? 'En línea' : 'Desconectado',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.normal,
                          color: isOnline
                              ? Colors.greenAccent
                              : Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: activeChat.messages.length,
              itemBuilder: (context, index) {
                final message = activeChat.messages[index];
                return MessageBubble(
                  text: message.text,
                  isFromMe: message.sender == 'user',
                  timestamp: message.timestamp,
                );
              },
            ),
          ),
          ChatInputBar(
            controller: _inputController,
            onSend: _handleSendMessage,
          ),
        ],
      ),
    );
  }
}
