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

  // Controladores para el formulario
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  late TextEditingController _maxAttendeesController;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _locationController = TextEditingController();
    _maxAttendeesController = TextEditingController(text: '100');

    if (_eventService.getAllEvents().isEmpty) {
      _eventService.initWithMockData();
    }
    _updateFilteredEvents();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _maxAttendeesController.dispose();
    super.dispose();
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
          style: AppTheme.eventTitle.copyWith(color: AppColors.primary),
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
              if (event.imageUrl != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Imagen del evento', style: AppTheme.eventDetailLabel),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        event.imageUrl!,
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
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

  void _showCreateEventDialog() {
    _titleController.clear();
    _descriptionController.clear();
    _locationController.clear();
    _maxAttendeesController.text = '100';
    _selectedDate = null;
    _selectedTime = null;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppColors.surface
            : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Crear Evento',
          style: AppTheme.eventTitle.copyWith(color: AppColors.primary),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Título del evento',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.event),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Descripción',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.description),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: 'Ubicación',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.location_on),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _maxAttendeesController,
                decoration: InputDecoration(
                  labelText: 'Máximo de asistentes',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.people),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          setState(() => _selectedDate = date);
                        }
                      },
                      icon: const Icon(Icons.calendar_today),
                      label: Text(_selectedDate == null
                          ? 'Seleccionar fecha'
                          : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (time != null) {
                          setState(() => _selectedTime = time);
                        }
                      },
                      icon: const Icon(Icons.schedule),
                      label: Text(_selectedTime == null
                          ? 'Seleccionar hora'
                          : '${_selectedTime!.hour}:${_selectedTime!.minute.toString().padLeft(2, '0')}'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar',
              style: AppTheme.filterButtonLabel.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (_titleController.text.isEmpty ||
                  _descriptionController.text.isEmpty ||
                  _locationController.text.isEmpty ||
                  _selectedDate == null ||
                  _selectedTime == null) {
                _showSnackBar('Por favor completa todos los campos',
                    isError: true);
                return;
              }

              final dateTime = DateTime(
                _selectedDate!.year,
                _selectedDate!.month,
                _selectedDate!.day,
                _selectedTime!.hour,
                _selectedTime!.minute,
              );

              try {
                _eventService.createSuggestedEvent(
                  title: _titleController.text,
                  description: _descriptionController.text,
                  dateTime: dateTime,
                  location: _locationController.text,
                  suggestedByUserId: _currentUserId,
                  maxAttendees: int.parse(_maxAttendeesController.text),
                );

                Navigator.pop(context);
                _showSnackBar(
                    '¡Evento sugerido! Espera la aprobación del staff');
              } catch (e) {
                _showSnackBar('Error al crear el evento', isError: true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('Crear'),
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
                      final isAttending = event.attendeeIds.contains(
                        _currentUserId,
                      );

                      return EventCard(
                        event: event,
                        onTap: () => _showEventDetails(event),
                        onAttendanceToggle: () =>
                            _toggleAttendance(event.id),
                        isUserAttending: isAttending,
                        isStaffView: false,
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateEventDialog,
        tooltip: 'Crear evento',
        child: const Icon(Icons.add),
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

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTheme.eventDetailLabel),
        const SizedBox(height: 4),
        Text(value, style: AppTheme.eventDetailValue),
      ],
    );
  }
}