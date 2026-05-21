import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:RockMeet/core/services/supabase_service.dart';

class ScheduleService {
  ScheduleService._();
  static final ScheduleService instance = ScheduleService._();

  final _firestore = FirebaseFirestore.instance;

  static const List<String> availableClasses = [
    'DAM',
    'DAW',
    'Administración de Empresa',
    'Atención a Personas en Situación de Dependencia',
    'Educación Infantil',
    'Integración Social',
  ];

  Stream<String?> watchScheduleImageUrl(String className) {
    return _firestore
        .collection('class_schedules')
        .doc(className)
        .snapshots()
        .map((doc) => doc.data()?['scheduleImageUrl'] as String?);
  }

  Future<void> uploadScheduleImage(String className, Uint8List bytes) async {
    final url = await SupabaseService.instance.uploadImage(
      path: 'class-schedules/$className.jpg',
      bytes: bytes,
    );
    await _firestore.collection('class_schedules').doc(className).set({
      'className': className,
      'scheduleImageUrl': url,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeScheduleImage(String className) async {
    try {
      await SupabaseService.instance
          .deleteImage('class-schedules/$className.jpg');
    } catch (_) {}
    await _firestore.collection('class_schedules').doc(className).set({
      'className': className,
      'scheduleImageUrl': null,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
