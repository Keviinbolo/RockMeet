class Event {
  final String id;
  final String title;
  final String description;
  final DateTime dateTime;
  final String location;
  final String? imageUrl;
  final String staffOrganizerId;
  final String? suggestedByUserId; // Nuevo: Usuario que sugirió/creó el evento
  final List<String> attendeeIds;
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
    this.suggestedByUserId,
    this.attendeeIds = const [],
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
    String? suggestedByUserId,
    List<String>? attendeeIds,
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
      suggestedByUserId: suggestedByUserId ?? this.suggestedByUserId,
      attendeeIds: attendeeIds ?? this.attendeeIds,
      maxAttendees: maxAttendees ?? this.maxAttendees,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

enum EventStatus { pending, active, inactive, cancelled, completed }