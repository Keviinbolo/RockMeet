import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final List<String>? interests;
  final Map<String, List<String>>? interestsDetail;
  final String name;
  final String? email;
  final String? bio;
  final String? twitter;
  final String? instagram;
  final String? tiktok;
  final String? spotify;
  final String? favoriteSong;
  final String? favoriteArtist;
  final String? likes;
  final String? matches;
  final String? activities;
  final String? friends;
  final int age;
  final String? photoURL;
  final List<String>? photos;
  final bool isStaff;
  final String? gender;
  final String? course;

  UserProfile({
    required this.uid,
    required this.name,
    required this.age,
    required this.isStaff,
    this.interests,
    this.interestsDetail,
    this.photoURL,
    this.photos,
    this.email,
    this.bio,
    this.twitter,
    this.instagram,
    this.tiktok,
    this.spotify,
    this.favoriteSong,
    this.favoriteArtist,
    this.likes,
    this.matches,
    this.activities,
    this.friends,
    this.gender,
    this.course,
  });

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    String? asNullableString(dynamic value) {
      if (value == null) return null;
      final text = value.toString().trim();
      return text.isEmpty ? null : text;
    }

    final gallery =
        (data['gallery'] as List?)?.whereType<String>().toList() ?? <String>[];
    final interests = (data['interests'] as List?)
        ?.whereType<String>()
        .toList();
    final interestsDetail = <String, List<String>>{};
    final rawInterestsDetail = data['interestsDetail'];
    if (rawInterestsDetail is Map) {
      for (final entry in rawInterestsDetail.entries) {
        final key = entry.key.toString();
        final value = entry.value;
        if (key.trim().isEmpty) continue;
        if (value is List) {
          interestsDetail[key] = value.whereType<String>().toList();
        }
      }
    }
    final photoUrl = (data['photoURL'] as String?)?.trim();
    final photos = <String>[
      if (photoUrl != null && photoUrl.isNotEmpty) photoUrl,
      ...gallery,
    ];
    final rawAge = data['age'];
    final parsedAge = rawAge is int ? rawAge : int.tryParse('$rawAge') ?? 0;
    return UserProfile(
      uid: doc.id,
      name: asNullableString(data['displayName']) ?? '',
      age: parsedAge,
      isStaff: data['isStaff'] as bool? ?? false,
      interests: interests,
      interestsDetail: interestsDetail.isNotEmpty ? interestsDetail : null,
      photoURL: asNullableString(data['photoURL']),
      photos: photos.isNotEmpty ? photos : null,
      email: asNullableString(data['email']),
      bio: asNullableString(data['bio']),
      twitter: asNullableString(data['twitter']),
      instagram: asNullableString(data['instagram']),
      tiktok: asNullableString(data['tiktok']),
      spotify: asNullableString(data['spotify']),
      favoriteSong: asNullableString(data['favoriteSong']),
      favoriteArtist: asNullableString(data['favoriteArtist']),
      likes: asNullableString(data['likes']),
      matches: asNullableString(data['matches']),
      activities: asNullableString(data['activities']),
      friends: asNullableString(data['friends']),
      gender: asNullableString(data['gender']),
      course: asNullableString(data['course']),
    );
  }
}
