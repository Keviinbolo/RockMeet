import 'package:myapp/features/events/class_event.dart';
import 'package:uuid/uuid.dart';

class EventService {
  static final EventService _instance = EventService._internal();
  final List<Event> _events = [];

  factory EventService() {
    return _instance;
  }

  EventService._internal();

  // Obtener todos los eventos
  List<Event> getAllEvents() => _events;

  // Obtener eventos activos
  List<Event> getActiveEvents() =>
      _events.where((e) => e.status == EventStatus.active).toList();

  // Obtener eventos creados por un staff
  List<Event> getEventsByStaff(String staffId) =>
      _events.where((e) => e.staffOrganizerId == staffId).toList();

  // Obtener eventos a los que asiste un usuario
  List<Event> getUserAttendingEvents(String userId) {
    return _events.where((e) => e.attendeeIds.contains(userId)).toList();
  }

  // Crear evento (solo staff)
  Event createEvent({
    required String title,
    required String description,
    required DateTime dateTime,
    required String location,
    required String staffOrganizerId,
    String? imageUrl,
    int maxAttendees = 100,
  }) {
    final event = Event(
      id: const Uuid().v4(),
      title: title,
      description: description,
      dateTime: dateTime,
      location: location,
      imageUrl: imageUrl,
      staffOrganizerId: staffOrganizerId,
      maxAttendees: maxAttendees,
      createdAt: DateTime.now(),
    );

    _events.add(event);
    return event;
  }

  // Editar evento
  Event? updateEvent(
    String eventId, {
    String? title,
    String? description,
    DateTime? dateTime,
    String? location,
    String? imageUrl,
    int? maxAttendees,
  }) {
    final index = _events.indexWhere((e) => e.id == eventId);
    if (index == -1) return null;

    final updatedEvent = _events[index].copyWith(
      title: title,
      description: description,
      dateTime: dateTime,
      location: location,
      imageUrl: imageUrl,
      maxAttendees: maxAttendees,
      updatedAt: DateTime.now(),
    );

    _events[index] = updatedEvent;
    return updatedEvent;
  }

  // Cancelar evento
  Event? cancelEvent(String eventId) {
    final index = _events.indexWhere((e) => e.id == eventId);
    if (index == -1) return null;

    final cancelledEvent = _events[index].copyWith(
      status: EventStatus.cancelled,
    );
    _events[index] = cancelledEvent;
    return cancelledEvent;
  }

  // Marcar asistencia
  Event? markUserAsAttendee(String eventId, String userId) {
    final event = _events.firstWhere(
      (e) => e.id == eventId,
      orElse: () => throw Exception('Event not found'),
    );

    if (event.attendeeIds.contains(userId)) return event;
    if (event.attendeeIds.length >= event.maxAttendees) {
      throw Exception('Event is full');
    }

    final attendees = [...event.attendeeIds, userId];
    final index = _events.indexWhere((e) => e.id == eventId);
    final updatedEvent = _events[index].copyWith(
      attendeeIds: attendees,
      updatedAt: DateTime.now(),
    );

    _events[index] = updatedEvent;
    return updatedEvent;
  }

  // Desmarcar asistencia
  Event? removeUserAsAttendee(String eventId, String userId) {
    final index = _events.indexWhere((e) => e.id == eventId);
    if (index == -1) return null;

    final attendees = _events[index].attendeeIds
        .where((id) => id != userId)
        .toList();

    final updatedEvent = _events[index].copyWith(
      attendeeIds: attendees,
      updatedAt: DateTime.now(),
    );

    _events[index] = updatedEvent;
    return updatedEvent;
  }

  Event createSuggestedEvent({
    required String title,
    required String description,
    required DateTime dateTime,
    required String location,
    required String suggestedByUserId,
    String? imageUrl,
    int maxAttendees = 100,
  }) {
    final event = Event(
      id: const Uuid().v4(),
      title: title,
      description: description,
      dateTime: dateTime,
      location: location,
      imageUrl: imageUrl,
      staffOrganizerId: '', // Se asignará cuando apruebe staff
      suggestedByUserId: suggestedByUserId,
      maxAttendees: maxAttendees,
      status: EventStatus.pending, // Estado pendiente de aprobación
      createdAt: DateTime.now(),
    );

    _events.add(event);
    return event;
  }

  // Obtener eventos pendientes de aprobación
  List<Event> getPendingEvents() =>
      _events.where((e) => e.status == EventStatus.pending).toList();

  // Aprobar evento sugerido (solo staff)
  Event? approveEvent(String eventId, String staffId) {
    final index = _events.indexWhere((e) => e.id == eventId);
    if (index == -1) return null;

    final approvedEvent = _events[index].copyWith(
      status: EventStatus.active,
      staffOrganizerId: staffId,
      updatedAt: DateTime.now(),
    );

    _events[index] = approvedEvent;
    return approvedEvent;
  }

  // Rechazar evento sugerido (solo staff)
  Event? rejectEvent(String eventId) {
    final index = _events.indexWhere((e) => e.id == eventId);
    if (index == -1) return null;

    _events.removeAt(index);
    return null;
  }

  // Desactivar evento
  Event? deactivateEvent(String eventId) {
    final index = _events.indexWhere((e) => e.id == eventId);
    if (index == -1) return null;

    final inactiveEvent = _events[index].copyWith(
      status: EventStatus.inactive,
      updatedAt: DateTime.now(),
    );
    _events[index] = inactiveEvent;
    return inactiveEvent;
  }

  // Activar evento
  Event? activateEvent(String eventId) {
    final index = _events.indexWhere((e) => e.id == eventId);
    if (index == -1) return null;

    final activeEvent = _events[index].copyWith(
      status: EventStatus.active,
      updatedAt: DateTime.now(),
    );
    _events[index] = activeEvent;
    return activeEvent;
  }

  // Obtener un evento por ID
  Event? getEventById(String eventId) {
    try {
      return _events.firstWhere((e) => e.id == eventId);
    } catch (e) {
      return null;
    }
  }

  // Limpiar eventos (útil para testing)
  void clearEvents() => _events.clear();
  //Prueba de datos utilizando el constructor de eventos para crear eventos de ejemplo
  void initWithMockData() {
    final now = DateTime.now();
    _events.addAll([
      Event(
        id: '1',
        title: 'Fútbol - Partido de Prácticas',
        description:
            'Partido amistoso para todos los estudiantes interesados en fútbol. Se juega en el patio principal.',
        dateTime: now.add(const Duration(days: 7)),
        location: 'Patio Principal - Instituto ROCA',
        staffOrganizerId: 'staff_001',
        maxAttendees: 30,
        createdAt: now,
      ),
      Event(
        id: '2',
        title: 'Torneo de Voleibol Inter-Cursos',
        description:
            'Competencia de voleibol entre los diferentes cursos. Inscripción por equipos de 6 personas.',
        dateTime: now.add(const Duration(days: 14)),
        location: 'Cancha de Voleibol - Instituto ROCA',
        staffOrganizerId: 'staff_002',
        maxAttendees: 100,
        createdAt: now,
      ),
      Event(
        id: '3',
        title: 'Taller de Debate Académico',
        description:
            'Sesión de debate sobre temas de actualidad. Mejora tu oratoria y argumentación.',
        dateTime: now.add(const Duration(days: 3)),
        location: 'Aula Magna - Instituto ROCA',
        staffOrganizerId: 'staff_001',
        maxAttendees: 40,
        createdAt: now,
      ),
      Event(
        id: '4',
        title: 'Carrera de Atletismo 100m',
        description:
            'Carrera de velocidad abierta para todos los estudiantes. Hay premios para los ganadores.',
        dateTime: now.add(const Duration(days: 10)),
        location: 'Pista de Atletismo - Instituto ROCA',
        staffOrganizerId: 'staff_003',
        maxAttendees: 50,
        createdAt: now,
      ),
      Event(
        id: '5',
        title: 'Jornada de Ciencias',
        description:
            'Presenta tus proyectos científicos y aprende de otros estudiantes. Muestra de trabajos prácticos.',
        dateTime: now.add(const Duration(days: 21)),
        location: 'Laboratorios - Instituto ROCA',
        staffOrganizerId: 'staff_002',
        maxAttendees: 80,
        createdAt: now,
      ),
    ]);
  }
}
