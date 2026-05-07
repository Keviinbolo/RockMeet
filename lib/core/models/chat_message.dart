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
