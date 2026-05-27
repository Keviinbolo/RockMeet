import 'package:cloud_firestore/cloud_firestore.dart';

class InteractionService {
  InteractionService._();
  static final InteractionService instance = InteractionService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Returns (likedUserIds, passTimestamps).
  /// Likes are permanent exclusions; passes include the timestamp so the caller
  /// can expire them after a configurable timeout.
  Future<(Set<String>, Map<String, DateTime>)> loadInteractionData(
    String userId,
  ) async {
    final snapshot = await _firestore
        .collection('interactions')
        .where('fromUserId', isEqualTo: userId)
        .get();

    final Set<String> likedIds = {};
    final Map<String, DateTime> passTimestamps = {};

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final toUserId = data['toUserId'] as String?;
      if (toUserId == null) continue;
      final type = data['type'] as String?;
      if (type == 'like') {
        likedIds.add(toUserId);
      } else if (type == 'pass') {
        final ts = data['createdAt'];
        passTimestamps[toUserId] =
            ts is Timestamp ? ts.toDate() : DateTime.now();
      }
    }

    return (likedIds, passTimestamps);
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
