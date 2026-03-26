import 'package:flutter/material.dart';
import 'package:myapp/config/Theme/app_theme.dart';
import 'package:myapp/config/Theme/constants/colors.dart';
import 'package:myapp/config/Theme/constants/text_styles.dart';

// --- 1. MODELOS ---

class Message {
  final int id;
  final String text;
  final String sender; // 'user' o 'other'
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
  final String username;
  final String avatar;
  String lastMessage;
  DateTime lastMessageTime;
  int unread;
  final bool online;
  final List<Message> messages;

  Chat({
    required this.id,
    required this.username,
    required this.avatar,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unread,
    required this.online,
    required this.messages,
  });
}

// --- 2. PANTALLA DE LISTA DE CHATS (MENÚ) ---

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late List<Chat> _chats;

  @override
  void initState() {
    super.initState();
    _chats = _generateMockData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: ListView.builder(
        itemCount: _chats.length,
        itemBuilder: (context, index) {
          final chat = _chats[index];
          return Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(
                bottom: BorderSide(
                  color: AppColors.divider,
                  width: 0.5,
                ),
              ),
            ),
            child: ListTile(
              leading: Stack(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundImage: NetworkImage(chat.avatar),
                  ),
                  if (chat.online)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.surface,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      chat.username,
                      style: AppTextStyles.titleLarge,
                    ),
                  ),
                  Text(
                    "${chat.lastMessageTime.hour}:${chat.lastMessageTime.minute.toString().padLeft(2, '0')}",
                    style: AppTextStyles.labelSmall,
                  ),
                ],
              ),
              subtitle: Row(
                children: [
                  Expanded(
                    child: Text(
                      chat.lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  if (chat.unread > 0)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        chat.unread.toString(),
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                ],
              ),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatDetailScreen(chat: chat),
                  ),
                );
                // Al volver, marcamos como leído
                setState(() {
                  chat.unread = 0;
                });
              },
            ),
          );
        },
      ),
    );
  }

  List<Chat> _generateMockData() {
    return [
      Chat(
        id: 1,
        username: 'Ana García',
        avatar: 'https://i.pravatar.cc/150?u=ana',
        lastMessage: '¡Nos vemos luego!',
        lastMessageTime: DateTime.now(),
        unread: 0,
        online: true,
        messages: [
          Message(
            id: 1,
            text: 'Hola!',
            sender: 'other',
            timestamp: DateTime.now(),
          ),
        ],
      ),
      Chat(
        id: 2,
        username: 'Carlos Méndez',
        avatar: 'https://i.pravatar.cc/150?u=carlos',
        lastMessage: '¿Cómo va el proyecto?',
        lastMessageTime: DateTime.now().subtract(const Duration(hours: 1)),
        unread: 3,
        online: false,
        messages: [
          Message(
            id: 1,
            text: '¿Cómo va el proyecto?',
            sender: 'other',
            timestamp: DateTime.now().subtract(const Duration(hours: 1)),
          ),
        ],
      ),
    ];
  }
}

// --- 3. PANTALLA DE DETALLE (EL CHAT SELECCIONADO) ---

class ChatDetailScreen extends StatefulWidget {
  final Chat chat;
  const ChatDetailScreen({super.key, required this.chat});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _controller = TextEditingController();

  // ÚNICO handleSend
  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      final newMessage = Message(
        id: DateTime.now().millisecondsSinceEpoch,
        text: text,
        sender: 'user',
        timestamp: DateTime.now(),
      );
      widget.chat.messages.add(newMessage);
      widget.chat.lastMessage = text;
      widget.chat.lastMessageTime = newMessage.timestamp;
      widget.chat.unread = 0; // este usuario ya lo ve como leído
      _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: NetworkImage(widget.chat.avatar),
            ),
            const SizedBox(width: 12),
            Text(
              widget.chat.username,
              style: AppTextStyles.titleLarge,
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.chat.messages.length,
              itemBuilder: (context, index) {
                final msg = widget.chat.messages[index];
                final isUser = msg.sender == 'user';
                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isUser
                          ? AppColors.primary
                          : AppColors.surface,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isUser ? 16 : 4),
                        bottomRight: Radius.circular(isUser ? 4 : 16),
                      ),
                    ),
                    child: Text(
                      msg.text,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.surface,
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _controller,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Escribe un mensaje...',
                    hintStyle: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textHint,
                    ),
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) => _handleSend(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: AppTheme.primaryGradientBox.copyWith(
                borderRadius: BorderRadius.circular(24),
              ),
              child: IconButton(
                icon: const Icon(Icons.send),
                color: AppColors.textPrimary,
                onPressed: _handleSend,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
