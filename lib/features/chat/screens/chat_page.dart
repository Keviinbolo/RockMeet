import 'dart:ui';
import 'package:flutter/material.dart';

// INTERFAZ MESSAGE - Vincular con tu tabla de mensajes en la BD
class Message {
  final int id;
  final String text;
  final String time;
  final bool sent;

  Message({
    required this.id,
    required this.text,
    required this.time,
    required this.sent,
  });
}

// INTERFAZ CHAT - Vincular con tu tabla de chats/conversaciones en la BD
class Chat {
  final int id;
  final String name;
  final String avatar;
  final String lastMessage;
  final String time;
  final int unread;
  final List<Message> messages;

  Chat({
    required this.id,
    required this.name,
    required this.avatar,
    required this.lastMessage,
    required this.time,
    required this.unread,
    required this.messages,
  });
}

// DATOS DE EJEMPLO - Reemplazar con datos de tu BD
final List<Chat> mockChats = [
  Chat(
    id: 1,
    name: 'María González',
    avatar: 'MG',
    lastMessage: 'Nos vemos mañana!',
    time: '10:30',
    unread: 2,
    messages: [
      Message(id: 1, text: 'Hola! Cómo estás?', time: '10:15', sent: false),
      Message(id: 2, text: 'Muy bien! Y tú?', time: '10:20', sent: true),
      Message(id: 3, text: 'Genial! Quedamos mañana?', time: '10:25', sent: false),
      Message(id: 4, text: 'Nos vemos mañana!', time: '10:30', sent: false),
    ],
  ),
  Chat(
    id: 2,
    name: 'Carlos Ruiz',
    avatar: 'CR',
    lastMessage: 'Perfecto, gracias!',
    time: '09:45',
    unread: 0,
    messages: [
      Message(id: 1, text: 'Enviaste el archivo?', time: '09:30', sent: true),
      Message(id: 2, text: 'Sí, ya está en tu correo', time: '09:40', sent: false),
      Message(id: 3, text: 'Perfecto, gracias!', time: '09:45', sent: false),
    ],
  ),
  Chat(
    id: 3,
    name: 'Ana Martínez',
    avatar: 'AM',
    lastMessage: 'Claro, sin problema',
    time: 'Ayer',
    unread: 1,
    messages: [
      Message(id: 1, text: 'Me puedes ayudar con algo?', time: 'Ayer 15:30', sent: true),
      Message(id: 2, text: 'Claro, sin problema', time: 'Ayer 15:35', sent: false),
    ],
  ),
  Chat(
    id: 4,
    name: 'Luis Fernández',
    avatar: 'LF',
    lastMessage: 'Hasta luego!',
    time: 'Ayer',
    unread: 0,
    messages: [
      Message(id: 1, text: 'Ya saliste de la oficina?', time: 'Ayer 18:00', sent: false),
      Message(id: 2, text: 'Sí, voy de camino a casa', time: 'Ayer 18:05', sent: true),
      Message(id: 3, text: 'Hasta luego!', time: 'Ayer 18:10', sent: false),
    ],
  ),
  Chat(
    id: 5,
    name: 'Sofia López',
    avatar: 'SL',
    lastMessage: 'Te llamo después',
    time: 'Lunes',
    unread: 0,
    messages: [
      Message(id: 1, text: 'Tienes tiempo para hablar?', time: 'Lunes 12:00', sent: false),
      Message(id: 2, text: 'Ahora estoy ocupado', time: 'Lunes 12:05', sent: true),
      Message(id: 3, text: 'Te llamo después', time: 'Lunes 12:10', sent: false),
    ],
  ),
];

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, String? initialPeerUid, String? initialPeerName, String? initialPeerAvatarUrl});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  Chat? selectedChat;
  String message = '';
  List<Message> messages = [];
  String searchQuery = '';
  
  final TextEditingController _messageController = TextEditingController();

  // Filtrar chats basado en la búsqueda
  List<Chat> get filteredChats {
    if (searchQuery.trim().isEmpty) {
      return mockChats;
    }
    return mockChats.where((chat) {
      return chat.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
             chat.lastMessage.toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();
  }

  // FUNCIÓN PARA ENVIAR MENSAJE
  void handleSend() {
    if (message.trim().isNotEmpty) {
      final now = DateTime.now();
      final timeString = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

      final newMessage = Message(
        id: messages.length + 1, // Reemplazar con el ID que devuelva tu BD al insertar
        text: message,
        time: timeString,
        sent: true,
      );

      // TODO: Guardar mensaje en la BD
      // await saveMessageToDatabase(selectedChat.id, newMessage.text, currentUserId);

      setState(() {
        messages.add(newMessage);
        message = '';
        _messageController.clear();
      });
    }
  }

  // FUNCIÓN PARA SELECCIONAR CHAT
  void handleSelectChat(Chat chat) {
    setState(() {
      selectedChat = chat;
      messages = List.from(chat.messages);
    });

    // TODO: Cargar mensajes del chat desde la BD
    // const messagesFromDB = await fetchMessagesFromDatabase(chat.id);
    // setMessages(messagesFromDB);
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: selectedChat != null ? _buildChatDetail() : _buildChatList(),
      ),
    );
  }

  // ============================================================
  // PANTALLA 1: LISTA DE CHATS
  // ============================================================
  Widget _buildChatList() {
    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF18181B), // bg-zinc-900
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: "Buscar",
                hintStyle: TextStyle(color: Color(0xFF71717A)), // text-zinc-500
                prefixIcon: Icon(Icons.search, color: Color(0xFF71717A)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ),

        // Chat List
        Expanded(
          child: ListView.builder(
            itemCount: filteredChats.length,
            itemBuilder: (context, index) {
              final chat = filteredChats[index];
              return InkWell(
                onTap: () => handleSelectChat(chat),
                splashColor: const Color(0xFF18181B),
                highlightColor: const Color(0xFF18181B),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Row(
                    children: [
                      // Avatar
                      Container(
                        width: 56,
                        height: 56,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFF97316), Color(0xFFEA580C)], // from-orange-500 to-orange-600
                          ),
                        ),
                        child: Center(
                          child: Text(
                            chat.avatar,
                            style: const TextStyle(color: Colors.white, fontSize: 18),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      
                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    chat.name,
                                    style: const TextStyle(color: Colors.white, fontSize: 16),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  chat.time,
                                  style: const TextStyle(color: Color(0xFF71717A), fontSize: 12),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              chat.lastMessage,
                              style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 14), // text-zinc-400
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      
                      // Unread Badge
                      if (chat.unread > 0) ...[
                        const SizedBox(width: 12),
                        Container(
                          width: 24,
                          height: 24,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF97316), // bg-orange-500
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              chat.unread.toString(),
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ============================================================
  // PANTALLA 2: DETALLE DEL CHAT
  // ============================================================
  Widget _buildChatDetail() {
    return Stack(
      children: [
        Column(
          children: [
            // Messages Area (con padding top para el header flotante)
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 80, left: 16, right: 16, bottom: 16),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Row(
                      mainAxisAlignment: msg.sent ? MainAxisAlignment.end : MainAxisAlignment.start,
                      children: [
                        Flexible(
                          child: Container(
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.75,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: msg.sent ? const Color(0xFFF97316) : const Color(0xFF27272A), // orange-500 : zinc-800
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(16),
                                topRight: const Radius.circular(16),
                                bottomLeft: Radius.circular(msg.sent ? 16 : 4),
                                bottomRight: Radius.circular(msg.sent ? 4 : 16),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  msg.text,
                                  style: const TextStyle(color: Colors.white),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  msg.time,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: msg.sent ? const Color(0xFFFFEDD5) : const Color(0xFF71717A), // orange-100 : zinc-500
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Input Area
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF18181B), // bg-zinc-900
                border: Border(top: BorderSide(color: Color(0xFF27272A))), // border-zinc-800
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF27272A), // bg-zinc-800
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              onChanged: (val) {
                                setState(() {
                                  message = val;
                                });
                              },
                              onSubmitted: (_) => handleSend(),
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                hintText: "Mensaje...",
                                hintStyle: TextStyle(color: Color(0xFF71717A)), // text-zinc-500
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.sentiment_satisfied, color: Color(0xFF71717A)),
                            onPressed: () {},
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: message.trim().isNotEmpty ? handleSend : null,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: message.trim().isNotEmpty ? const Color(0xFFF97316) : const Color(0xFF3F3F46), // orange-500 : zinc-700
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send, color: Colors.white, size: 24),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        // Floating Header (absolute top-0 left-0 right-0 z-10)
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
              child: Container(
                color: Colors.black.withOpacity(0.5), // bg-black/50
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => selectedChat = null),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_back, color: Color(0xFFF97316)), // orange-500
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFFF97316), Color(0xFFEA580C)],
                              ),
                            ),
                            child: Center(
                              child: Text(
                                selectedChat!.avatar,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            selectedChat!.name,
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}