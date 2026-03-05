import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myapp/config/Theme/app_theme.dart';
import 'package:myapp/config/Theme/constants/colors.dart';
import 'package:myapp/core/services/event_service.dart';
import 'package:myapp/core/widgets/event_card.dart';
import 'package:myapp/features/events/class_event.dart';

class EventScreen extends StatefulWidget {
  const EventScreen({super.key});

  @override
  State<EventScreen> createState() => _EventScreenState();
}

class _EventScreenState extends State<EventScreen> {
  final EventService _eventService = EventService();
  final String _currentUserId = 'user_001';
  late List<Event> _filteredEvents;
  String _filterType = 'all';

  @override
  void initState() {
    super.initState();
    if (_eventService.getAllEvents().isEmpty) {
      _eventService.initWithMockData();
    }
    _updateFilteredEvents();
  }

  void _updateFilteredEvents() {
    final allEvents = _eventService.getActiveEvents();
    setState(() {
      switch (_filterType) {
        case 'attending':
          _filteredEvents = allEvents
              .where((e) => e.attendeeIds.contains(_currentUserId))
              .toList();
          break;
        case 'suggested':
          _filteredEvents = allEvents
              .where((e) => e.suggestedByIds.contains(_currentUserId))
              .toList();
          break;
        default:
          _filteredEvents = allEvents;
      }
      _filteredEvents.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    });
  }

  void _toggleAttendance(String eventId) {
    final event = _eventService.getEventById(eventId);
    if (event != null) {
      if (event.attendeeIds.contains(_currentUserId)) {
        _eventService.removeUserAsAttendee(eventId, _currentUserId);
      } else {
        try {
          _eventService.markUserAsAttendee(eventId, _currentUserId);
          _showSnackBar('¡Te has apuntado al evento!');
        } catch (e) {
          _showSnackBar('Error: El evento está lleno', isError: true);
        }
      }
      _updateFilteredEvents();
    }
  }

  void _toggleSuggestion(String eventId) {
    final event = _eventService.getEventById(eventId);
    if (event != null) {
      if (event.suggestedByIds.contains(_currentUserId)) {
        _eventService.removeSuggestEvent(eventId, _currentUserId);
        _showSnackBar('Sugerencia removida');
      } else {
        _eventService.suggestEvent(eventId, _currentUserId);
        _showSnackBar('¡Evento sugerido!');
      }
      _updateFilteredEvents();
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        backgroundColor: isError ? AppColors.error : Colors.green,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showEventDetails(Event event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppColors.surface
            : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          event.title,
          style: AppTheme.eventTitle.copyWith(
            color: AppColors.primary,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              _DetailRow(label: 'Descripción', value: event.description),
              const SizedBox(height: 12),
              _DetailRow(
                label: 'Fecha',
                value: event.dateTime.toString().split('.').first,
              ),
              const SizedBox(height: 12),
              _DetailRow(label: 'Ubicación', value: event.location),
              const SizedBox(height: 12),
              _DetailRow(
                label: 'Asistentes',
                value: '${event.attendeeIds.length}/${event.maxAttendees}',
              ),
              const SizedBox(height: 12),
              _DetailRow(
                label: 'Sugerencias',
                value: '${event.suggestedByIds.length}',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cerrar',
              style: AppTheme.filterButtonLabel.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      body: Column(
        children: [
          // Filtros
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterOption(
                    label: 'Todos',
                    isSelected: _filterType == 'all',
                    onTap: () {
                      setState(() => _filterType = 'all');
                      _updateFilteredEvents();
                    },
                  ),
                  const SizedBox(width: 8),
                  _FilterOption(
                    label: 'Asistiendo',
                    isSelected: _filterType == 'attending',
                    onTap: () {
                      setState(() => _filterType = 'attending');
                      _updateFilteredEvents();
                    },
                  ),
                  const SizedBox(width: 8),
                  _FilterOption(
                    label: 'Sugeridos',
                    isSelected: _filterType == 'suggested',
                    onTap: () {
                      setState(() => _filterType = 'suggested');
                      _updateFilteredEvents();
                    },
                  ),
                ],
              ),
            ),
          ),

          // Lista de eventos
          Expanded(
            child: _filteredEvents.isEmpty
                ? _EmptyState(filterType: _filterType)
                : ListView.builder(
                    itemCount: _filteredEvents.length,
                    itemBuilder: (context, index) {
                      final event = _filteredEvents[index];
                      final isAttending =
                          event.attendeeIds.contains(_currentUserId);
                      final isSuggesting =
                          event.suggestedByIds.contains(_currentUserId);

                      return EventCard(
                        event: event,
                        onTap: () => _showEventDetails(event),
                        onAttendanceToggle: () => _toggleAttendance(event.id),
                        onSuggestToggle: () => _toggleSuggestion(event.id),
                        isUserAttending: isAttending,
                        isUserSuggesting: isSuggesting,
                        isStaffView: false,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _FilterOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: isSelected
            ? AppTheme.filterButtonActive
            : AppTheme.filterButtonInactive,
        child: Text(
          label,
          style: AppTheme.filterButtonLabel.copyWith(
            color: isSelected ? Colors.white : AppColors.primary,
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String filterType;

  const _EmptyState({required this.filterType});

  @override
  Widget build(BuildContext context) {
    String message = 'No hay eventos disponibles';
    if (filterType == 'attending') {
      message = 'No estás apuntado a ningún evento';
    } else if (filterType == 'suggested') {
      message = 'No has sugerido ningún evento';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy,
            size: 64,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[600]
                : Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: AppTheme.emptyStateTitle.copyWith(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[400]
                  : Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.eventDetailLabel,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTheme.eventDetailValue,
        ),
      ],
    );
  }
}