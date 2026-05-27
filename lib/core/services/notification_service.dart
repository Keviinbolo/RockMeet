import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> send({
    required String toUserId,
    required String type, // 'like' | 'match' | 'message'
    required String fromUserId,
    required String fromName,
    String? fromPhotoUrl,
    String? preview,
  }) async {
    if (toUserId == fromUserId) return;
    await _firestore.collection('notifications').add({
      'toUserId': toUserId,
      'fromUserId': fromUserId,
      'fromName': fromName,
      'fromPhotoUrl': fromPhotoUrl ?? '',
      'type': type,
      'preview': preview ?? '',
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Map<String, dynamic>>> streamForUser(String userId) {
    return _firestore
        .collection('notifications')
        .where('toUserId', isEqualTo: userId)
        .limit(50)
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((d) => {'id': d.id, ...d.data()})
              .toList();
          list.sort((a, b) {
            final aTs = a['createdAt'] as Timestamp?;
            final bTs = b['createdAt'] as Timestamp?;
            if (aTs == null) return 1;
            if (bTs == null) return -1;
            return bTs.compareTo(aTs);
          });
          return list;
        });
  }

  Stream<int> unreadCountStream(String userId) {
    return _firestore
        .collection('notifications')
        .where('toUserId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  Future<void> markAllRead(String userId) async {
    final snap = await _firestore
        .collection('notifications')
        .where('toUserId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .get();
    if (snap.docs.isEmpty) return;
    final batch = _firestore.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }

  Future<void> deleteNotification(String docId) async {
    await _firestore.collection('notifications').doc(docId).delete();
  }

  Future<void> deleteAllForUser(String userId) async {
    final snap = await _firestore
        .collection('notifications')
        .where('toUserId', isEqualTo: userId)
        .get();
    if (snap.docs.isEmpty) return;
    final batch = _firestore.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
