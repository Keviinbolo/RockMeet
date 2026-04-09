import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:myapp/core/services/chat_service.dart';

class Message {
  final int id;
  final String text;
  final String sender; // user or other
  final DateTime timestamp;

  Message({
    required this.id,
    required this.text,
    required this.sender,
    required this.timestamp,
  });
}

class Chat {
  final int id;
  final String peerUid;
  final String username;
  final String avatar;
  String lastMessage;
  DateTime lastMessageTime;
  int unread;
  final bool online;
  List<Message> messages;
  String? chatId;

  Chat({
    required this.id,
    required this.peerUid,
    required this.username,
    required this.avatar,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unread,
    required this.online,
    required this.messages,
    this.chatId,
  });
}

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
  StreamSubscription<List<ChatMessage>>? _messagesSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _chatsSubscription;
  bool _hasEnteredChat = false;
  bool _hasHandledInitialPeer = false;
  bool _isEnsuringInitialChat = false;

  @override
  void initState() {
    super.initState();
    // TODO: Datos de chats ahora se cargan de Firestore mediante _subscribeToUserChats()
    // _initializeData() eliminado - ya no usar datos mock locales
    chats = [];
    _subscribeToUserChats();
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

        if (!_hasEnteredChat) {
          setState(() {
            chats = updatedChats;
            // Inicializar activeChat con el primer chat cuando se cargan por primera vez
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

  String _formatTime(DateTime value) {
    return '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildChatList(BuildContext context, {bool closeOnSelect = false}) {
    final colorScheme = Theme.of(context).colorScheme;

    if (chats.isEmpty) {
      return Center(
        child: Text(
          'No tienes conversaciones aún',
          style: TextStyle(color: colorScheme.onSurface.withOpacity(0.7)),
        ),
      );
    }

    return ListView.builder(
      itemCount: chats.length,
      itemBuilder: (context, index) {
        final chat = chats[index];
        final selected = chat.id == activeChat.id;
        return ListTile(
          selected: selected,
          selectedTileColor: colorScheme.primary.withOpacity(0.12),
          leading: CircleAvatar(backgroundImage: NetworkImage(chat.avatar)),
          title: Text(
            chat.username,
            style: TextStyle(color: colorScheme.onSurface),
          ),
          subtitle: Text(
            chat.lastMessage,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: colorScheme.onSurface.withOpacity(0.7)),
          ),
          onTap: () {
            _handleChatSelect(chat);
            if (closeOnSelect) {
              Navigator.pop(context);
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (!_hasEnteredChat) {
      return Scaffold(
        appBar: AppBar(title: const Text('Selecciona un usuario')),
        body: _buildChatList(context),
      );
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
            title: Text(activeChat.username),
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
