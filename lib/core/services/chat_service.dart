import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatMessage {
  final String id;
  final String senderId;
  final String receiverId;
  final String text;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.timestamp,
  });

  factory ChatMessage.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return ChatMessage(
      id: doc.id,
      senderId: data['senderId'] as String? ?? '',
      receiverId: data['receiverId'] as String? ?? '',
      text: data['text'] as String? ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class ChatService {
  ChatService._();

  static final ChatService instance = ChatService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  String buildDirectChatId(String uidA, String uidB) {
    final sorted = [uidA, uidB]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  Future<String> ensureDirectChat({
    required String peerUid,
    required String peerName,
    String? peerAvatarUrl,
  }) async {
    final uid = currentUserId;
    if (uid == null) {
      throw StateError('Usuario no autenticado');
    }

    final chatId = buildDirectChatId(uid, peerUid);
    final chatRef = _firestore.collection('chats').doc(chatId);
    final chatDoc = await chatRef.get();

    if (!chatDoc.exists) {
      await chatRef.set({
        'participants': [uid, peerUid],
        'participantProfiles': {
          uid: {
            'displayName': _auth.currentUser?.displayName ?? '',
            'photoURL': _auth.currentUser?.photoURL ?? '',
          },
          peerUid: {
            'displayName': peerName,
            'photoURL': peerAvatarUrl ?? '',
          },
        },
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    return chatId;
  }

  Stream<List<ChatMessage>> streamMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map(ChatMessage.fromFirestore).toList());
  }

  Future<List<ChatMessage>> fetchRecentMessages(String chatId, {int limit = 25}) async {
    final snapshot = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .get();

    final messages = snapshot.docs.map(ChatMessage.fromFirestore).toList();
    return messages.reversed.toList();
  }

  Future<void> sendMessage({
    required String chatId,
    required String receiverId,
    required String text,
  }) async {
    final uid = currentUserId;
    if (uid == null) {
      throw StateError('Usuario no autenticado');
    }

    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final chatRef = _firestore.collection('chats').doc(chatId);
    final messageRef = chatRef.collection('messages').doc();

    final batch = _firestore.batch();

    batch.set(messageRef, {
      'senderId': uid,
      'receiverId': receiverId,
      'text': trimmed,
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
    });

    batch.set(chatRef, {
      'lastMessage': trimmed,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await batch.commit();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamCurrentUserChats() {
    final uid = currentUserId;
    if (uid == null) {
      return const Stream<QuerySnapshot<Map<String, dynamic>>>.empty();
    }

    return _firestore
        .collection('chats')
        .where('participants', arrayContains: uid)
        .snapshots();
  }
}
