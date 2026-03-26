import 'package:flutter/material.dart';

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
      backgroundColor: const Color(0xFF18181B),
      body: ListView.builder(
        itemCount: _chats.length,
        itemBuilder: (context, index) {
          final chat = _chats[index];
          return ListTile(
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
                        color: Colors.greenAccent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF18181B),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            title: Text(
              chat.username,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              chat.lastMessage,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFFA1A1AA)),
            ),
            trailing: Text(
              "${chat.lastMessageTime.hour}:${chat.lastMessageTime.minute.toString().padLeft(2, '0')}",
              style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 12),
            ),
            onTap: () {
              // Al tocar, navegamos a la pantalla de detalle (el menú desaparece)
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatDetailScreen(chat: chat),
                ),
              );
            },
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
        unread: 1,
        online: false,
        messages: [],
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

  void _handleSend() {
    if (_controller.text.trim().isEmpty) return;
    setState(() {
      widget.chat.messages.add(
        Message(
          id: DateTime.now().millisecondsSinceEpoch,
          text: _controller.text,
          sender: 'user',
          timestamp: DateTime.now(),
        ),
      );
      _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF18181B),
      // Muestra solo el usuario seleccionado y el botón de volver
      appBar: AppBar(
        backgroundColor: const Color(0xFF27272A),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: NetworkImage(widget.chat.avatar),
            ),
            const SizedBox(width: 12),
            Text(widget.chat.username, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Mensajes
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.chat.messages.length,
              itemBuilder: (context, index) {
                final msg = widget.chat.messages[index];
                final isUser = msg.sender == 'user';
                return Align(
                  alignment: isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser
                          ? Colors.blue[600]
                          : const Color(0xFF3F3F46),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      msg.text,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                );
              },
            ),
          ),
          // Barra de escritura
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFF27272A),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF3F3F46),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _controller,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Escribe un mensaje...',
                    hintStyle: TextStyle(color: Colors.grey),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.send, color: Colors.blue),
              onPressed: _handleSend,
            ),
          ],
        ),
      ),
    );
  }
}
