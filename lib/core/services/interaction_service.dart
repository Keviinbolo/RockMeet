import 'package:cloud_firestore/cloud_firestore.dart';

class InteractionService {
  InteractionService._();
  static final InteractionService instance = InteractionService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Set<String>> loadInteractedUserIds(String userId) async {
    final snapshot = await _firestore
        .collection('interactions')
        .where('fromUserId', isEqualTo: userId)
        .get();
    return snapshot.docs
        .map((doc) => doc.data()['toUserId'] as String?)
        .whereType<String>()
        .toSet();
  }

  Future<void> save({
    required String fromUserId,
    required String toUserId,
    required String type,
  }) async {
    final interactionId = '${fromUserId}_$toUserId';
    await _firestore
        .collection('interactions')
        .doc(interactionId)
        .set({
          'fromUserId': fromUserId,
          'toUserId': toUserId,
          'type': type,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  Future<bool> isMutualLike({
    required String fromUserId,
    required String toUserId,
  }) async {
    final inverseId = '${toUserId}_$fromUserId';
    final doc = await _firestore.collection('interactions').doc(inverseId).get();
    if (!doc.exists) return false;
    return doc.data()?['type'] == 'like';
  }

  Future<void> deleteAllForUser(String userId) async {
    final sentSnap = await _firestore
        .collection('interactions')
        .where('fromUserId', isEqualTo: userId)
        .get();
    final receivedSnap = await _firestore
        .collection('interactions')
        .where('toUserId', isEqualTo: userId)
        .get();

    final allDocs = {
      for (final d in sentSnap.docs) d.id: d,
      for (final d in receivedSnap.docs) d.id: d,
    }.values.toList();

    for (var i = 0; i < allDocs.length; i += 450) {
      final batch = _firestore.batch();
      for (final doc in allDocs.skip(i).take(450)) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }
}
