import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileService {
  ProfileService._();

  static final ProfileService instance = ProfileService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    final uid = currentUserId;
    if (uid == null) return null;

    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.data();
  }

  Future<void> updateCurrentUserProfile({
    String? displayName,
    String? bio,
    String? photoURL,
    String? twitter,
    String? instagram,
    String? tiktok,
    List<String>? gallery,
    List<String>? interests,
  }) async {
    final uid = currentUserId;
    if (uid == null) {
      throw StateError('Usuario no autenticado');
    }

    final updates = <String, dynamic>{
      'updatedAt': Timestamp.now(),
    };

    if (displayName != null) updates['displayName'] = displayName;
    if (bio != null) updates['bio'] = bio;
    if (photoURL != null) updates['photoURL'] = photoURL;
    if (twitter != null) updates['twitter'] = twitter;
    if (instagram != null) updates['instagram'] = instagram;
    if (tiktok != null) updates['tiktok'] = tiktok;
    if (gallery != null) updates['gallery'] = gallery;
    if (interests != null) updates['interests'] = interests;

    await _firestore.collection('users').doc(uid).set(updates, SetOptions(merge: true));

    if (displayName != null) {
      await _auth.currentUser?.updateDisplayName(displayName);
    }
    if (photoURL != null) {
      await _auth.currentUser?.updatePhotoURL(photoURL);
    }
  }

  /// Incrementa el contador de amigos del usuario actual en +1
  Future<void> incrementFriendsCount() async {
    final uid = currentUserId;
    if (uid == null) {
      throw StateError('Usuario no autenticado');
    }

    await _firestore.collection('users').doc(uid).update({
      'friends': FieldValue.increment(1),
      'updatedAt': Timestamp.now(),
    });
  }

  /// Incrementa el contador de amigos de un usuario específico
  Future<void> incrementFriendsCountForUser(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'friends': FieldValue.increment(1),
      'updatedAt': Timestamp.now(),
    });
  }
}
