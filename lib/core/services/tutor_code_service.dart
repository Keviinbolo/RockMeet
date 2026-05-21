import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class TutorCodeService {
  static final TutorCodeService _instance = TutorCodeService._internal();
  factory TutorCodeService() => _instance;
  TutorCodeService._internal();

  final _firestore = FirebaseFirestore.instance;
  static const _docPath = 'app_config/tutor_code';
  static const _validityHours = 24;

  Future<String> generateCode(String staffId) async {
    final code = (Random().nextInt(900000) + 100000).toString();
    final now = DateTime.now().toUtc();
    await _firestore.doc(_docPath).set({
      'code': code,
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(now.add(const Duration(hours: _validityHours))),
      'createdBy': staffId,
    });
    return code;
  }

  Future<bool> validateCode(String code) async {
    final doc = await _firestore.doc(_docPath).get();
    if (!doc.exists) return false;
    final data = doc.data()!;
    if (data['code'] != code.trim()) return false;
    final expiresAt = (data['expiresAt'] as Timestamp?)?.toDate();
    if (expiresAt == null) return false;
    return DateTime.now().toUtc().isBefore(expiresAt);
  }

  /// Returns null if no code exists or it's expired.
  /// Returns a [TutorCodeInfo] with the code and remaining duration otherwise.
  TutorCodeInfo? parseCodeInfo(Map<String, dynamic>? data) {
    if (data == null) return null;
    final code = data['code'] as String?;
    final expiresAt = (data['expiresAt'] as Timestamp?)?.toDate().toLocal();
    if (code == null || expiresAt == null) return null;
    final remaining = expiresAt.difference(DateTime.now());
    return TutorCodeInfo(code: code, expiresAt: expiresAt, remaining: remaining);
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchCode() {
    return _firestore.doc(_docPath).snapshots();
  }
}

class TutorCodeInfo {
  final String code;
  final DateTime expiresAt;
  final Duration remaining;

  const TutorCodeInfo({
    required this.code,
    required this.expiresAt,
    required this.remaining,
  });

  bool get isExpired => remaining.isNegative;

  String get remainingLabel {
    if (isExpired) return 'Caducado';
    final h = remaining.inHours;
    final m = remaining.inMinutes % 60;
    if (h > 0) return '${h}h ${m}min restantes';
    return '${m}min restantes';
  }
}
