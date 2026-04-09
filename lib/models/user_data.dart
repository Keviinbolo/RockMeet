class UserData {
  String name;
  String email;
  String bio;
  String twitter;
  String instagram;
  String tiktok;
  String likes;
  String matches;
  String activities;

  UserData({
    required this.name,
    required this.email,
    required this.bio,
    required this.twitter,
    required this.instagram,
    required this.tiktok,
    required this.likes,
    required this.matches,
    required this.activities,
  });

  factory UserData.fromMap(Map<String, dynamic> map) {
    return UserData(
      name: map['displayName'] ?? '',
      email: map['email'] ?? '',
      bio: map['bio'] ?? '',
      twitter: map['twitter'] ?? '',
      instagram: map['instagram'] ?? '',
      tiktok: map['tiktok'] ?? '',
      likes: map['likes']?.toString() ?? '0',
      matches: map['matches']?.toString() ?? '0',
      activities: map['activities']?.toString() ?? '0',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'displayName': name,
      'email': email,
      'bio': bio,
      'twitter': twitter,
      'instagram': instagram,
      'tiktok': tiktok,
      'likes': likes,
      'matches': matches,
      'activities': activities,
    };
  }
}