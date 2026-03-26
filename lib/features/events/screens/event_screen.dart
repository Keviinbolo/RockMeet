import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
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
  String? get _currentUserId => FirebaseAuth.instance.currentUser?.uid;
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
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _maxAttendeesController.dispose();
    super.dispose();
  }

  void _toggleAttendance(String eventId) async {
    final currentUserId = _currentUserId;
    if (currentUserId == null) {
      _showSnackBar('Debes iniciar sesion para apuntarte a eventos', isError: true);
      return;
    }

    try {
      final event = await _eventService.getEventById(eventId);
      if (event != null) {
        if (event.attendeeIds.contains(currentUserId)) {
          await _eventService.removeUserAsAttendee(eventId, currentUserId);
          _showSnackBar('Te has desapuntado del evento');
        } else {
          if (event.attendeeIds.length >= event.maxAttendees) {
            _showSnackBar('Error: El evento está lleno', isError: true);
            return;
          }
          await _eventService.markUserAsAttendee(eventId, currentUserId);
          _showSnackBar('¡Te has apuntado al evento!');
        }
      }
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}', isError: true);
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
                value: DateFormat('dd/MM/yyyy HH:mm').format(event.dateTime),
              ),
              const SizedBox(height: 12),
              _DetailRow(label: 'Ubicación', value: event.location),
              const SizedBox(height: 12),
              _DetailRow(
                label: 'Asistentes',
                value: '${event.attendeeIds.length}/${event.maxAttendees}',
              ),
              const SizedBox(height: 12),
              if (event.imageUrl != null && event.imageUrl!.isNotEmpty)
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
          child: StatefulBuilder(
            builder: (context, setState) => Column(
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
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                          );
                          if (date != null) {
                            setState(() => _selectedDate = date);
                          }
                        },
                        icon: const Icon(Icons.calendar_today),
                        label: Text(
                          _selectedDate == null
                              ? 'Seleccionar fecha'
                              : DateFormat('dd/MM/yyyy').format(_selectedDate!),
                        ),
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
                            initialEntryMode: TimePickerEntryMode.input,
                            builder: (context, child) {
                              return MediaQuery(
                                data: MediaQuery.of(
                                  context,
                                ).copyWith(alwaysUse24HourFormat: true),
                                child: child!,
                              );
                            },
                          );
                          if (time != null) {
                            setState(() => _selectedTime = time);
                          }
                        },
                        icon: const Icon(Icons.schedule),
                        label: Text(
                          _selectedTime == null
                              ? 'Seleccionar hora'
                              : '${_selectedTime!.hour}:${_selectedTime!.minute.toString().padLeft(2, '0')}',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
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
                _showSnackBar(
                  'Por favor completa todos los campos',
                  isError: true,
                );
                return;
              }

              final dateTime = DateTime(
                _selectedDate!.year,
                _selectedDate!.month,
                _selectedDate!.day,
                _selectedTime!.hour,
                _selectedTime!.minute,
              );

              _eventService.createSuggestedEvent(
                title: _titleController.text,
                description: _descriptionController.text,
                dateTime: dateTime,
                location: _locationController.text,
                suggestedByUserId: _currentUserId ?? '',
                maxAttendees: int.parse(_maxAttendeesController.text),
              );

              Navigator.pop(context);
              _showSnackBar('¡Evento sugerido! Espera la aprobación del staff');
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
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
                    },
                  ),
                  const SizedBox(width: 8),
                  _FilterOption(
                    label: 'Asistiendo',
                    isSelected: _filterType == 'attending',
                    onTap: () {
                      setState(() => _filterType = 'attending');
                    },
                  ),
                ],
              ),
            ),
          ),

          // Lista de eventos
          Expanded(
            child: StreamBuilder<List<Event>>(
              stream: _filterType == 'attending'
                ? (_currentUserId == null
                  ? const Stream<List<Event>>.empty()
                  : _eventService.getUserAttendingEventsStream(_currentUserId!))
                : _eventService.getActiveEventsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final events = snapshot.data ?? [];

                if (events.isEmpty) {
                  return _EmptyState(filterType: _filterType);
                }

                return ListView.builder(
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final event = events[index];
                    final isAttending = _currentUserId != null &&
                        event.attendeeIds.contains(_currentUserId);

                    return EventCard(
                      event: event,
                      onTap: () => _showEventDetails(event),
                      onAttendanceToggle: () => _toggleAttendance(event.id),
                      isUserAttending: isAttending,
                      isStaffView: false,
                    );
                  },
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
