class Event {
  final String id;
  final String title;
  final String description;
  final DateTime dateTime;
  final String location;
  final String? imageUrl;
  final String staffOrganizerId;
  final List<String> attendeeIds; // Usuarios que van a asistir
  final List<String> suggestedByIds; // Usuarios que sugirieron el evento
  final int maxAttendees;
  final EventStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.dateTime,
    required this.location,
    this.imageUrl,
    required this.staffOrganizerId,
    this.attendeeIds = const [],
    this.suggestedByIds = const [],
    this.maxAttendees = 100,
    this.status = EventStatus.active,
    required this.createdAt,
    this.updatedAt,
  });

  Event copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dateTime,
    String? location,
    String? imageUrl,
    String? staffOrganizerId,
    List<String>? attendeeIds,
    List<String>? suggestedByIds,
    int? maxAttendees,
    EventStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dateTime: dateTime ?? this.dateTime,
      location: location ?? this.location,
      imageUrl: imageUrl ?? this.imageUrl,
      staffOrganizerId: staffOrganizerId ?? this.staffOrganizerId,
      attendeeIds: attendeeIds ?? this.attendeeIds,
      suggestedByIds: suggestedByIds ?? this.suggestedByIds,
      maxAttendees: maxAttendees ?? this.maxAttendees,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

enum EventStatus { active, cancelled, completed }