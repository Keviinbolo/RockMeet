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
    String? spotify,
    String? favoriteSong,
    String? favoriteArtist,
    List<String>? gallery,
    List<String>? interests,
    Map<String, List<String>>? interestsWithSubInterests,
    String? clase,
    bool updateClase = false,
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
    if (spotify != null) updates['spotify'] = spotify;
    if (favoriteSong != null) updates['favoriteSong'] = favoriteSong;
    if (favoriteArtist != null) updates['favoriteArtist'] = favoriteArtist;
    if (gallery != null) updates['gallery'] = gallery;
    if (interests != null) updates['interests'] = interests;
    if (interestsWithSubInterests != null) updates['interestsDetail'] = interestsWithSubInterests;
    if (updateClase) updates['clase'] = clase;

    await _firestore.collection('users').doc(uid).set(updates, SetOptions(merge: true));

    if (displayName != null) {
      await _auth.currentUser?.updateDisplayName(displayName);
    }
    if (photoURL != null) {
      await _auth.currentUser?.updatePhotoURL(photoURL);
    }
  }

  Future<void> markProfileComplete() async {
    final uid = currentUserId;
    if (uid == null) throw StateError('Usuario no autenticado');
    await _firestore.collection('users').doc(uid).set(
      {'profileComplete': true, 'updatedAt': Timestamp.now()},
      SetOptions(merge: true),
    );
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

  /// Incrementa el contador de actividades (eventos) del usuario actual en +1
  Future<void> incrementActivitiesCount() async {
    final uid = currentUserId;
    if (uid == null) {
      throw StateError('Usuario no autenticado');
    }

    await _firestore.collection('users').doc(uid).set(
      {
        'activities': FieldValue.increment(1),
        'updatedAt': Timestamp.now(),
      },
      SetOptions(merge: true),
    );
  }

  /// Decrementa el contador de actividades (eventos) del usuario actual en -1
  Future<void> decrementActivitiesCount() async {
    final uid = currentUserId;
    if (uid == null) {
      throw StateError('Usuario no autenticado');
    }

    await _firestore.collection('users').doc(uid).set(
      {
        'activities': FieldValue.increment(-1),
        'updatedAt': Timestamp.now(),
      },
      SetOptions(merge: true),
    );
  }

  /// Incrementa el contador de actividades (eventos) de un usuario específico
  Future<void> incrementActivitiesCountForUser(String userId) async {
    await _firestore.collection('users').doc(userId).set(
      {
        'activities': FieldValue.increment(1),
        'updatedAt': Timestamp.now(),
      },
      SetOptions(merge: true),
    );
  }

  /// Decrementa el contador de actividades (eventos) de un usuario específico
  Future<void> decrementActivitiesCountForUser(String userId) async {
    await _firestore.collection('users').doc(userId).set(
      {
        'activities': FieldValue.increment(-1),
        'updatedAt': Timestamp.now(),
      },
      SetOptions(merge: true),
    );
  }

  /// Incrementa el contador de "me gusta" del usuario actual en +1
  Future<void> incrementLikesCount() async {
    final uid = currentUserId;
    if (uid == null) {
      throw StateError('Usuario no autenticado');
    }

    await _firestore.collection('users').doc(uid).set(
      {
        'likes': FieldValue.increment(1),
        'updatedAt': Timestamp.now(),
      },
      SetOptions(merge: true),
    );
  }

  /// Incrementa el contador de "me gusta" de un usuario específico en +1
  Future<void> incrementLikesCountForUser(String userId) async {
    await _firestore.collection('users').doc(userId).set(
      {
        'likes': FieldValue.increment(1),
        'updatedAt': Timestamp.now(),
      },
      SetOptions(merge: true),
    );
  }

  /// Decrementa el contador de "me gusta" de un usuario específico en -1
  Future<void> decrementLikesCountForUser(String userId) async {
    await _firestore.collection('users').doc(userId).set(
      {
        'likes': FieldValue.increment(-1),
        'updatedAt': Timestamp.now(),
      },
      SetOptions(merge: true),
    );
  }
}
