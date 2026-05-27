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
    'ASIX',
    'SMX',
    'AU',
    'IDMN',
    'HB',
    'MP',
    'EDI',
  ];

  /// Nombre completo para mostrar en la UI. Si no existe devuelve el propio key.
  static const Map<String, String> classDisplayNames = {
    'DAM':  'DAM — Desarrollo de Aplicaciones Multiplataforma',
    'DAW':  'DAW — Desarrollo de Aplicaciones Web',
    'ASIX': 'ASIX — Administración de Sistemas Informáticos en Red',
    'SMX':  'SMX — Sistemas Microinformáticos y Redes',
    'AU':   'AU — Automoción',
    'IDMN': 'IDMN — Imagen para el Diagnóstico y Medicina Nuclear',
    'HB':   'HB — Higiene Bucodental',
    'MP':   'MP — Marketing y Publicidad',
    'EDI':  'EDI — Educación Infantil',
  };

  static String displayNameFor(String className) =>
      classDisplayNames[className] ?? className;

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
    await _firestore.collection('class_schedules').doc(className).update({
      'scheduleImageUrl': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
