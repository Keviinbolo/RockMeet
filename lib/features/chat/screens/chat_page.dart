import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const ChatApp());
}

class ChatApp extends StatelessWidget {
  const ChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat App UI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF18181B), // zinc-900
      ),
      home: const ChatScreen(),
    );
  }
}

// --- Modelos ---

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
  List<Message> messages;
  final List<String> gallery;

  Chat({
    required this.id,
    required this.username,
    required this.avatar,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unread,
    required this.online,
    required this.messages,
    required this.gallery,
  });
}

// --- Pantalla Principal ---

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // Datos iniciales
  late List<Chat> chats;
  late Chat activeChat;
  
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  bool _showGallery = false;
  bool _sidebarOpen = true;

  @override
  void initState() {
    super.initState();
    _initializeData();
    activeChat = chats[0];
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleChatSelect(Chat chat) {
    setState(() {
      activeChat = chat;
      chat.unread = 0; // Marcar como leído
    });
    _scrollToBottom();
  }

  void _handleSendMessage() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      final newMessage = Message(
        id: activeChat.messages.length + 1,
        text: text,
        sender: 'user',
        timestamp: DateTime.now(),
      );
      activeChat.messages.add(newMessage);
      activeChat.lastMessage = text;
      activeChat.lastMessageTime = newMessage.timestamp;
      _inputController.clear();
    });

    _scrollToBottom();

    // Simular respuesta del bot
    Timer(const Duration(seconds: 1), () {
      if (!mounted) return;
      
      final responses = [
        '¡Interesante! Cuéntame más',
        'Entiendo lo que dices',
        '¡Qué bueno!',
        'Sí, tienes razón',
        '¡Genial! 😊'
      ];
      final randomResponse = responses[Random().nextInt(responses.length)];

      setState(() {
        final botMessage = Message(
          id: activeChat.messages.length + 2,
          text: randomResponse,
          sender: 'other',
          timestamp: DateTime.now(),
        );
        activeChat.messages.add(botMessage);
        activeChat.lastMessage = randomResponse;
        activeChat.lastMessageTime = botMessage.timestamp;
      });
      _scrollToBottom();
    });
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatLastMessageTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Row(
            children: [
              // Sidebar
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: _sidebarOpen ? 320 : 0,
                decoration: const BoxDecoration(
                  color: Color(0xFF27272A), // zinc-800
                  border: Border(
                    right: BorderSide(color: Color(0xFF3F3F46)), // zinc-700
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sidebar Header
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Mensajes',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF3F3F46), // zinc-700
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const TextField(
                              style: TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Buscar conversaciones...',
                                hintStyle: TextStyle(color: Color(0xFFA1A1AA)), // zinc-400
                                prefixIcon: Icon(Icons.search, color: Color(0xFFA1A1AA), size: 20),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFF3F3F46)),
                    
                    // Chat List
                    Expanded(
                      child: ListView.builder(
                        itemCount: chats.length,
                        itemBuilder: (context, index) {
                          final chat = chats[index];
                          final isActive = activeChat.id == chat.id;

                          return InkWell(
                            onTap: () => _handleChatSelect(chat),
                            child: Container(
                              color: isActive ? const Color(0xFF3F3F46) : Colors.transparent,
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  // Avatar
                                  Stack(
                                    children: [
                                      CircleAvatar(
                                        radius: 24,
                                        backgroundImage: NetworkImage(chat.avatar),
                                      ),
                                      if (chat.online)
                                        Positioned(
                                          bottom: 0,
                                          right: 0,
                                          child: Container(
                                            width: 14,
                                            height: 14,
                                            decoration: BoxDecoration(
                                              color: Colors.greenAccent[400],
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: const Color(0xFF27272A),
                                                width: 2,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(width: 12),
                                  // Textos
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                chat.username,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Text(
                                              _formatLastMessageTime(chat.lastMessageTime),
                                              style: const TextStyle(
                                                color: Color(0xFFA1A1AA),
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                chat.lastMessage,
                                                style: const TextStyle(
                                                  color: Color(0xFFA1A1AA),
                                                  fontSize: 14,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (chat.unread > 0)
                                              Container(
                                                margin: const EdgeInsets.only(left: 8),
                                                padding: const EdgeInsets.all(6),
                                                decoration: const BoxDecoration(
                                                  color: Colors.blue,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Text(
                                                  '${chat.unread}',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Main Chat Area
              Expanded(
                child: Column(
                  children: [
                    // Chat Header
                    Container(
                      color: const Color(0xFF27272A), // zinc-800
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: Row(
                        children: [
                          if (!_sidebarOpen || MediaQuery.of(context).size.width < 800)
                            IconButton(
                              icon: const Icon(Icons.menu, color: Color(0xFFA1A1AA)),
                              onPressed: () => setState(() => _sidebarOpen = !_sidebarOpen),
                            ),
                          GestureDetector(
                            onTap: () => setState(() => _showGallery = true),
                            child: Stack(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundImage: NetworkImage(activeChat.avatar),
                                ),
                                if (activeChat.online)
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: Colors.greenAccent[400],
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: const Color(0xFF27272A),
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                activeChat.username,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                activeChat.online ? 'En línea' : 'Desconectado',
                                style: const TextStyle(
                                  color: Color(0xFFA1A1AA),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFF3F3F46)),

                    // Messages Area
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(24),
                        itemCount: activeChat.messages.length,
                        itemBuilder: (context, index) {
                          final message = activeChat.messages[index];
                          final isUser = message.sender == 'user';

                          return Align(
                            alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width * 0.7,
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: isUser ? Colors.blue[600] : const Color(0xFF3F3F46),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment:
                                    isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    message.text,
                                    style: const TextStyle(color: Colors.white, fontSize: 15),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatTime(message.timestamp),
                                    style: TextStyle(
                                      color: isUser ? Colors.blue[200] : const Color(0xFFA1A1AA),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // Input Area
                    Container(
                      color: const Color(0xFF27272A),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF3F3F46),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: TextField(
                                controller: _inputController,
                                style: const TextStyle(color: Colors.white),
                                onSubmitted: (_) => _handleSendMessage(),
                                decoration: const InputDecoration(
                                  hintText: 'Escribe un mensaje...',
                                  hintStyle: TextStyle(color: Color(0xFFA1A1AA)),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.blue[600],
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.send, color: Colors.white),
                              onPressed: _handleSendMessage,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Gallery Modal (Overlay)
          if (_showGallery)
            GestureDetector(
              onTap: () => setState(() => _showGallery = false),
              child: Container(
                color: Colors.black.withOpacity(0.9),
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 32),
                        onPressed: () => setState(() => _showGallery = false),
                      ),
                    ),
                    Text(
                      activeChat.username,
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${activeChat.gallery.length} fotos',
                      style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 800),
                        child: GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: activeChat.gallery.length,
                          itemBuilder: (context, index) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                activeChat.gallery[index],
                                fit: BoxFit.cover,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // --- Inicializador de datos (Mock Data traducida) ---
  void _initializeData() {
    final now = DateTime.now();
    chats = [
      Chat(
        id: 1,
        username: 'Ana García',
        avatar: 'https://images.unsplash.com/photo-1649589244330-09ca58e4fa64?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHx3b21hbiUyMHBvcnRyYWl0JTIwcHJvZmVzc2lvbmFsfGVufDF8fHx8MTc3MjAxNTUyMHww&ixlib=rb-4.1.0&q=80&w=1080',
        lastMessage: '¡Genial! 😊',
        lastMessageTime: now.subtract(const Duration(minutes: 5)),
        unread: 2,
        online: true,
        gallery: [
          'https://images.unsplash.com/photo-1649589244330-09ca58e4fa64?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHx3b21hbiUyMHBvcnRyYWl0JTIwcHJvZmVzc2lvbmFsfGVufDF8fHx8MTc3MjAxNTUyMHww&ixlib=rb-4.1.0&q=80&w=1080',
          'https://images.unsplash.com/photo-1722718827199-bb595ab51a0b?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHx3b21hbiUyMGxpZmVzdHlsZSUyMHBob3RvfGVufDF8fHx8MTc3MjAzNDkzNnww&ixlib=rb-4.1.0&q=80&w=1080',
          'https://images.unsplash.com/photo-1598186951851-bddc3089d68b?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHx3b21hbiUyMHRyYXZlbCUyMGFkdmVudHVyZXxlbnwxfHx8fDE3NzIxMTg0MTl8MA&ixlib=rb-4.1.0&q=80&w=1080',
        ],
        messages: [
          Message(id: 1, text: '¡Hola! ¿Cómo estás?', sender: 'other', timestamp: now.subtract(const Duration(minutes: 10))),
          Message(id: 2, text: '¡Muy bien! ¿Y tú?', sender: 'user', timestamp: now.subtract(const Duration(minutes: 8))),
          Message(id: 3, text: 'Todo perfecto, gracias por preguntar', sender: 'other', timestamp: now.subtract(const Duration(minutes: 6))),
          Message(id: 4, text: 'Me alegro 😊', sender: 'user', timestamp: now.subtract(const Duration(minutes: 5, seconds: 30))),
          Message(id: 5, text: '¡Genial! 😊', sender: 'other', timestamp: now.subtract(const Duration(minutes: 5))),
        ],
      ),
      Chat(
        id: 2,
        username: 'Carlos Méndez',
        avatar: 'https://images.unsplash.com/photo-1554765345-6ad6a5417cde?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxtYW4lMjBwb3J0cmFpdCUyMHByb2Zlc3Npb25hbHxlbnwxfHx8fDE3NzIxMDU5NTF8MA&ixlib=rb-4.1.0&q=80&w=1080',
        lastMessage: 'Nos vemos mañana',
        lastMessageTime: now.subtract(const Duration(hours: 1)),
        unread: 0,
        online: false,
        gallery: [
          'https://images.unsplash.com/photo-1554765345-6ad6a5417cde?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxtYW4lMjBwb3J0cmFpdCUyMHByb2Zlc3Npb25hbHxlbnwxfHx8fDE3NzIxMDU5NTF8MA&ixlib=rb-4.1.0&q=80&w=1080'
        ],
        messages: [
          Message(id: 1, text: 'Hola, ¿tienes tiempo para hablar?', sender: 'other', timestamp: now.subtract(const Duration(hours: 2))),
          Message(id: 2, text: 'Claro, dime', sender: 'user', timestamp: now.subtract(const Duration(hours: 1, minutes: 50))),
          Message(id: 3, text: 'Perfecto, entonces quedamos mañana', sender: 'other', timestamp: now.subtract(const Duration(hours: 1, minutes: 40))),
          Message(id: 4, text: 'De acuerdo', sender: 'user', timestamp: now.subtract(const Duration(hours: 1, minutes: 30))),
          Message(id: 5, text: 'Nos vemos mañana', sender: 'other', timestamp: now.subtract(const Duration(hours: 1))),
        ],
      ),
    ];
  }
}