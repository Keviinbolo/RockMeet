import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myapp/config/Theme/app_theme.dart';
import 'package:myapp/config/Theme/constants/colors.dart';
import 'package:myapp/features/events/class_event.dart';

class EventCard extends StatelessWidget {
  final Event event;
  final VoidCallback? onTap;
  final VoidCallback? onAttendanceToggle;
  final VoidCallback? onSuggestToggle;
  final bool isUserAttending;
  final bool isUserSuggesting;
  final bool isStaffView;

  const EventCard({
    super.key,
    required this.event,
    this.onTap,
    this.onAttendanceToggle,
    this.onSuggestToggle,
    this.isUserAttending = false,
    this.isUserSuggesting = false,
    this.isStaffView = false,
  });

  IconData _getEventIcon() {
    final title = event.title.toLowerCase();
    if (title.contains('fútbol') || title.contains('futbol')) {
      return Icons.sports_soccer;
    } else if (title.contains('voleibol')) {
      return Icons.sports_volleyball;
    } else if (title.contains('atletismo') || title.contains('carrera')) {
      return Icons.directions_run;
    } else if (title.contains('debate') || title.contains('académico')) {
      return Icons.school;
    } else if (title.contains('ciencias')) {
      return Icons.science;
    }
    return Icons.sports_basketball;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(12),
        decoration: AppTheme.eventCardBox,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado con gradiente
            Container(
              decoration: AppTheme.eventHeaderGradient,
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Icon(
                      _getEventIcon(),
                      size: 32,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: AppTheme.eventTitle.copyWith(
                            color: Colors.white,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: Text(
                            'Aforo: ${event.attendeeIds.length}/${event.maxAttendees}',
                            style: AppTheme.eventLabel.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Contenido principal
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Descripción
                  Text(
                    event.description,
                    style: AppTheme.eventDescription,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),

                  // Información de fecha
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('dd/MM/yyyy HH:mm').format(event.dateTime),
                        style: AppTheme.eventLabel.copyWith(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[300]
                              : Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Información de ubicación
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          event.location,
                          style: AppTheme.eventLabel.copyWith(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey[300]
                                : Colors.grey[700],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Botones de acción para usuarios
                  if (!isStaffView)
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: onAttendanceToggle,
                            icon: Icon(isUserAttending
                                ? Icons.check_circle
                                : Icons.add_circle_outline),
                            label: Text(
                              isUserAttending ? 'Asistiendo' : 'Ir',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  isUserAttending ? Colors.green : AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: onSuggestToggle,
                            icon: Icon(isUserSuggesting
                                ? Icons.favorite
                                : Icons.favorite_outline),
                            label: Text(
                              isUserSuggesting ? 'Sugerido' : 'Sugerir',
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: isUserSuggesting
                                    ? Colors.red
                                    : AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                  // Información para staff
                  if (isStaffView)
                    Wrap(
                      spacing: 8,
                      children: [
                        Chip(
                          label: Text(
                            '${event.suggestedByIds.length} sugerencias',
                          ),
                          avatar: const Icon(Icons.favorite, size: 18),
                          backgroundColor:
                              AppColors.primary.withOpacity(0.2),
                        ),
                        Chip(
                          label: Text(
                            event.status.toString().split('.').last.toUpperCase(),
                          ),
                          backgroundColor: event.status == EventStatus.active
                              ? Colors.green.withOpacity(0.2)
                              : Colors.red.withOpacity(0.2),
                          labelStyle: TextStyle(
                            color: event.status == EventStatus.active
                                ? Colors.green
                                : Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}