import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String name;
  final int age;
  final String? photoURL;

  UserProfile({
    required this.uid,
    required this.name,
    required this.age,
    this.photoURL,
  });

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserProfile(
      uid: doc.id,
      name: data['displayName'] ?? 'Usuario',
      age: data['age'] ?? 0,
      photoURL: data['photoURL'],
    );
  }
}