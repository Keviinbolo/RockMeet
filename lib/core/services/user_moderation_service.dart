import 'package:cloud_firestore/cloud_firestore.dart';

class ModeratedUser {
  ModeratedUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.photoURL,
    required this.type,
    required this.blockedBy,
    required this.createdAt,
  });

  final String id;
  final String email;
  final String displayName;
  final String photoURL;
  final String type;
  final List<String> blockedBy;
  final DateTime? createdAt;

  bool get isStaff => type == 'staff';
  bool get isBlocked => blockedBy.isNotEmpty;

  factory ModeratedUser.fromMap(String id, Map<String, dynamic> data) {
    final blockedBy = List<String>.from(
      data['blockedBy'] as List? ?? const <String>[],
    );
    final createdAtValue = data['createdAt'];

    DateTime? createdAt;
    if (createdAtValue is Timestamp) {
      createdAt = createdAtValue.toDate();
    } else if (createdAtValue is DateTime) {
      createdAt = createdAtValue;
    }

    return ModeratedUser(
      id: id,
      email: data['email'] as String? ?? '',
      displayName: data['displayName'] as String? ?? 'Usuario',
      photoURL: data['photoURL'] as String? ?? '',
      type: data['type'] as String? ?? 'user',
      blockedBy: blockedBy,
      createdAt: createdAt,
    );
  }
}

class UserModerationService {
  UserModerationService._();

  static final UserModerationService instance = UserModerationService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<ModeratedUser>> watchUsers() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      final users = snapshot.docs
          .map((doc) => ModeratedUser.fromMap(doc.id, doc.data()))
          .toList(growable: false);

      users.sort((left, right) {
        final leftName = left.displayName.toLowerCase();
        final rightName = right.displayName.toLowerCase();
        return leftName.compareTo(rightName);
      });

      return users;
    });
  }

  Future<void> blockUser({
    required String userId,
    required String staffId,
  }) async {
    await _firestore.runTransaction((transaction) async {
      final userRef = _firestore.collection('users').doc(userId);
      final snapshot = await transaction.get(userRef);

      if (!snapshot.exists) {
        throw Exception('Usuario no encontrado');
      }

      final data =
          snapshot.data() as Map<String, dynamic>? ?? <String, dynamic>{};
      final userType = (data['type'] as String?)?.trim() ?? 'user';

      if (userType == 'staff') {
        throw Exception('No se puede bloquear a un usuario staff');
      }

      final blockedBy = List<String>.from(
        data['blockedBy'] as List? ?? const <String>[],
      );
      if (!blockedBy.contains(staffId)) {
        blockedBy.add(staffId);
      }

      transaction.update(userRef, {
        'blockedBy': blockedBy,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> unblockUser({
    required String userId,
    required String staffId,
  }) async {
    await _firestore.runTransaction((transaction) async {
      final userRef = _firestore.collection('users').doc(userId);
      final snapshot = await transaction.get(userRef);

      if (!snapshot.exists) {
        throw Exception('Usuario no encontrado');
      }

      final data =
          snapshot.data() as Map<String, dynamic>? ?? <String, dynamic>{};
      final blockedBy = List<String>.from(
        data['blockedBy'] as List? ?? const <String>[],
      );
      blockedBy.remove(staffId);

      transaction.update(userRef, {
        'blockedBy': blockedBy,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
