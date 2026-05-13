import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/core/models/class_event.dart';
import 'package:myapp/core/services/profile_service.dart';
import 'package:uuid/uuid.dart';

class EventService {
  static final EventService _instance = EventService._internal();

  factory EventService() {
    return _instance;
  }

  EventService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Crear evento
  Future<String> createEvent({
    required String title,
    required String description,
    required DateTime dateTime,
    required String location,
    required String staffOrganizerId,
    int maxAttendees = 100,
    String? imageUrl,
    String? suggestedByUserId,
  }) async {
    try {
      final eventId = const Uuid().v4();
      await _firestore.collection('events').doc(eventId).set({
        'id': eventId,
        'title': title,
        'description': description,
        'dateTime': Timestamp.fromDate(dateTime),
        'location': location,
        'staffOrganizerId': staffOrganizerId,
        'suggestedByUserId': suggestedByUserId,
        'attendeeIds': [],
        'maxAttendees': maxAttendees,
        'status': EventStatus.active.toString(),
        'imageUrl': imageUrl ?? '',
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });
      return eventId;
    } catch (e) {
      print('Error creando evento: $e');
      rethrow;
    }
  }

  // Obtener evento por ID
  Future<Event?> getEventById(String eventId) async {
    try {
      final doc = await _firestore.collection('events').doc(eventId).get();
      if (doc.exists) {
        return _eventFromMap(doc.data()!, eventId);
      }
      return null;
    } catch (e) {
      print('Error obteniendo evento: $e');
      return null;
    }
  }

  // Stream de todos los eventos
  Stream<List<Event>> getAllEventsStream() {
    return _firestore
        .collection('events')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => _eventFromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // Stream de eventos del staff
  Stream<List<Event>> getEventsByStaffStream(String staffId) {
    return _firestore
        .collection('events')
        .where('staffOrganizerId', isEqualTo: staffId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => _eventFromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // Stream de eventos activos
  Stream<List<Event>> getActiveEventsStream() {
    return _firestore
        .collection('events')
        .where('status', isEqualTo: EventStatus.active.toString())
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => _eventFromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // Stream de eventos pendientes
  Stream<List<Event>> getPendingEventsStream() {
    return _firestore
        .collection('events')
        .where('status', isEqualTo: EventStatus.pending.toString())
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => _eventFromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // Stream de eventos en los que un usuario está registrado
  Stream<List<Event>> getUserAttendingEventsStream(String userId) {
    return _firestore
        .collection('events')
        .where('attendeeIds', arrayContains: userId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => _eventFromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // Marcar usuario como asistente (con transacción).
  Future<void> markUserAsAttendee(String eventId, String userId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final eventRef = _firestore.collection('events').doc(eventId);
        final eventSnapshot = await transaction.get(eventRef);

        if (!eventSnapshot.exists) {
          throw Exception('Evento no encontrado');
        }

        final event = _eventFromMap(eventSnapshot.data()!, eventSnapshot.id);

        if (event.attendeeIds.length >= event.maxAttendees) {
          throw Exception('El evento está lleno');
        }

        if (!event.attendeeIds.contains(userId)) {
          transaction.update(eventRef, {
            'attendeeIds': FieldValue.arrayUnion([userId]),
            'updatedAt': Timestamp.now(),
          });
        }
      });

      try {
        await ProfileService.instance.incrementActivitiesCountForUser(userId);
      } catch (e) {
        rethrow;
      }
    } catch (e) {
      rethrow;
    }
  }

  // Remover usuario como asistente
  Future<void> removeUserAsAttendee(String eventId, String userId) async {
    try {
      await _firestore.collection('events').doc(eventId).update({
        'attendeeIds': FieldValue.arrayRemove([userId]),
        'updatedAt': Timestamp.now(),
      });

      try {
        await ProfileService.instance.decrementActivitiesCountForUser(userId);
      } catch (e) {
        rethrow;
      }
    } catch (e) {
      rethrow;
    }
  }

  // Actualizar evento
  Future<void> updateEvent(
    String eventId, {
    String? title,
    String? description,
    DateTime? dateTime,
    String? location,
    int? maxAttendees,
    String? imageUrl,
  }) async {
    try {
      Map<String, dynamic> updates = {'updatedAt': Timestamp.now()};

      if (title != null) updates['title'] = title;
      if (description != null) updates['description'] = description;
      if (dateTime != null) updates['dateTime'] = Timestamp.fromDate(dateTime);
      if (location != null) updates['location'] = location;
      if (maxAttendees != null) updates['maxAttendees'] = maxAttendees;
      if (imageUrl != null) updates['imageUrl'] = imageUrl;

      await _firestore.collection('events').doc(eventId).update(updates);
    } catch (e) {
      print('Error actualizando evento: $e');
      rethrow;
    }
  }

  // Aprobar evento
  Future<void> approveEvent(String eventId, String staffId) async {
    try {
      await _firestore.collection('events').doc(eventId).update({
        'status': EventStatus.active.toString(),
        'staffOrganizerId': staffId,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Rechazar evento
  Future<void> rejectEvent(String eventId) async {
    try {
      await _firestore.collection('events').doc(eventId).update({
        'status': EventStatus.cancelled.toString(),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Activar evento
  Future<void> activateEvent(String eventId) async {
    try {
      await _firestore.collection('events').doc(eventId).update({
        'status': EventStatus.active.toString(),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Desactivar evento
  Future<void> deactivateEvent(String eventId) async {
    try {
      await _firestore.collection('events').doc(eventId).update({
        'status': EventStatus.inactive.toString(),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Cancelar evento
  Future<void> cancelEvent(String eventId) async {
    try {
      await _firestore.collection('events').doc(eventId).update({
        'status': EventStatus.cancelled.toString(),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Helper privado para convertir documento a Event
  Event _eventFromMap(Map<String, dynamic> data, String docId) {
    return Event(
      id: data['id'] ?? docId,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      dateTime: (data['dateTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      location: data['location'] ?? '',
      staffOrganizerId: data['staffOrganizerId'] ?? '',
      suggestedByUserId: data['suggestedByUserId'],
      attendeeIds: List<String>.from(data['attendeeIds'] ?? []),
      maxAttendees: data['maxAttendees'] ?? 100,
      status: _parseEventStatus(data['status']),
      imageUrl: data['imageUrl'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  EventStatus _parseEventStatus(String? statusString) {
    if (statusString == null) return EventStatus.active;
    try {
      return EventStatus.values.firstWhere(
        (e) => e.toString() == statusString,
        orElse: () => EventStatus.active,
      );
    } catch (e) {
      return EventStatus.active;
    }
  }

  // Crear evento sugerido por usuario (requiere aprobación)
  Future<String> createSuggestedEvent({
    required String title,
    required String description,
    required DateTime dateTime,
    required String location,
    required String suggestedByUserId,
    int maxAttendees = 100,
    String? imageUrl,
  }) async {
    try {
      final eventId = const Uuid().v4();
      await _firestore.collection('events').doc(eventId).set({
        'id': eventId,
        'title': title,
        'description': description,
        'dateTime': Timestamp.fromDate(dateTime),
        'location': location,
        'staffOrganizerId': 'pending', // Temporal, hasta que sea aprobado
        'suggestedByUserId': suggestedByUserId,
        'attendeeIds': [],
        'maxAttendees': maxAttendees,
        'status': EventStatus.pending.toString(), // ← ESTADO PENDIENTE
        'imageUrl': imageUrl ?? '',
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });
      return eventId;
    } catch (e) {
      rethrow;
    }
  }
}
