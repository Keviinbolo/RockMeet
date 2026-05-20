import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ScheduleService {
  ScheduleService._();
  static final ScheduleService instance = ScheduleService._();

  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

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

  Future<void> uploadScheduleImage(String className, File imageFile) async {
    final ref = _storage.ref('class_schedules/$className.jpg');
    await ref.putFile(imageFile);
    final url = await ref.getDownloadURL();
    await _firestore.collection('class_schedules').doc(className).set({
      'className': className,
      'scheduleImageUrl': url,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeScheduleImage(String className) async {
    try {
      await _storage.ref('class_schedules/$className.jpg').delete();
    } catch (_) {}
    await _firestore.collection('class_schedules').doc(className).set({
      'className': className,
      'scheduleImageUrl': null,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
