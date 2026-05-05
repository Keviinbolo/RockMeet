import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:myapp/config/Theme/app_theme.dart';
import 'package:myapp/config/Theme/constants/colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myapp/core/services/auth_service.dart';
import 'package:myapp/core/services/event_service.dart';
import 'package:myapp/features/events/class_event.dart';
import 'package:myapp/features/settings/screens/ajustes.dart';
import 'package:intl/intl.dart';

class HomeStaffPage extends StatefulWidget {
  const HomeStaffPage({Key? key}) : super(key: key);

  @override
  State<HomeStaffPage> createState() => _HomeStaffPageState();
}

class _HomeStaffPageState extends State<HomeStaffPage> {
  final EventService _eventService = EventService();
  String? get _staffId => FirebaseAuth.instance.currentUser?.uid;
  List<Event> _staffEvents = [];
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel Staff - RockMeet'),
        centerTitle: true,
        elevation: 2,
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<List<Event>>(
        stream: _staffId == null
            ? const Stream<List<Event>>.empty()
            : _eventService.getEventsByStaffStream(_staffId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            _staffEvents = [];
          } else {
            _staffEvents = snapshot.data!;
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sección de Resumen
                _buildSummarySection(context),

                const SizedBox(height: 28),

                // Sección de Gestión de Eventos
                _buildEventManagementSection(context),

                const SizedBox(height: 28),

                // Sección adicional
                _buildAdditionalSection(context),

                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  // Sección de Resumen
  Widget _buildSummarySection(BuildContext context) {
    return StreamBuilder<List<Event>>(
      stream: _staffId == null
          ? const Stream<List<Event>>.empty()
          : _eventService.getEventsByStaffStream(_staffId!),
      builder: (context, staffSnapshot) {
        final staffEvents = staffSnapshot.data ?? [];
        final activeEvents = staffEvents
            .where((e) => e.status == EventStatus.active)
            .length;

        return StreamBuilder<List<Event>>(
          stream: _eventService.getPendingEventsStream(),
          builder: (context, pendingSnapshot) {
            final pendingEvents = pendingSnapshot.data ?? [];

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Resumen del Panel',
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        context,
                        title: 'Eventos',
                        value: staffEvents.length.toString(),
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        context,
                        title: 'Activos',
                        value: activeEvents.toString(),
                        color: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        context,
                        title: 'Pendientes',
                        value: pendingEvents.length.toString(),
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Card de estadísticas
  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: isDark ? AppColors.surface : Colors.white,
        border: Border.all(color: color.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // Sección de Gestión de Eventos
  Widget _buildEventManagementSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gestión de Eventos',
          style: GoogleFonts.outfit(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        _buildEventManagementButton(
          context,
          icon: Icons.add_circle,
          title: 'Crear Evento',
          subtitle: 'Registrar un nuevo evento',
          onTap: _handleCreateEvent,
        ),
        const SizedBox(height: 12),
        _buildEventManagementButton(
          context,
          icon: Icons.list_alt,
          title: 'Ver Eventos',
          subtitle: 'Lista de todos tus eventos',
          onTap: _handleViewEvents,
        ),
        const SizedBox(height: 12),
        _buildEventManagementButton(
          context,
          icon: Icons.approval,
          title: 'Aprobar Eventos',
          subtitle: 'Revisar eventos sugeridos por usuarios',
          onTap: _handleApproveEvents,
        ),
      ],
    );
  }

  // Botón de gestión de evento
  Widget _buildEventManagementButton(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isDark ? AppColors.surface : Colors.white,
          border: Border.all(color: AppColors.border, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.4 : 0.08),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: Icon(icon, color: AppColors.primary, size: 28),
          title: Text(
            title,
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
          trailing: Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: AppColors.primary,
          ),
          onTap: onTap,
        ),
      ),
    );
  }

  // Sección adicional
  Widget _buildAdditionalSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Opciones Rápidas',
          style: GoogleFonts.outfit(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        _buildOptionButton(
          context,
          icon: Icons.people,
          title: 'Gestionar Usuarios',
          onTap: () => _showSnackBar('Gestionar usuarios'),
        ),
        const SizedBox(height: 12),
        _buildOptionButton(
          context,
          icon: Icons.bar_chart,
          title: 'Reportes',
          onTap: () => _showSnackBar('Reportes'),
        ),
        const SizedBox(height: 12),
        _buildOptionButton(
          context,
          icon: Icons.settings,
          title: 'Configuración',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SettingsScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        _buildOptionButton(
          context,
          icon: Icons.logout,
          title: 'Cerrar sesión',
          onTap: () => _showLogoutConfirmationDialog(context),
        ),
      ],
    );
  }

  void _showLogoutConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Cerrar sesión',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            '¿Estás seguro de que quieres cerrar sesión?',
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancelar',
                style: GoogleFonts.outfit(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Sesión cerrada exitosamente',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    backgroundColor: Colors.grey.shade800,
                    duration: const Duration(seconds: 2),
                  ),
                );
                await AuthService().logout();
                if (!mounted) return;
                Navigator.pushReplacementNamed(context, '/login');
              },
              child: Text(
                'Cerrar sesión',
                style: GoogleFonts.outfit(
                  color: const Color(0xFFFF6B6B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Botón de opción simple
  Widget _buildOptionButton(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isDark ? AppColors.surface : Colors.white,
          border: Border.all(color: AppColors.border, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.4 : 0.08),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: Icon(icon, color: AppColors.secondary, size: 26),
          title: Text(
            title,
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          trailing: Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: AppColors.secondary,
          ),
          onTap: onTap,
        ),
      ),
    );
  }

  // Handlers
  void _handleCreateEvent() {
    _showCreateEventDialog();
  }

  void _handleViewEvents() {
    final staffId = _staffId;
    if (staffId == null) {
      _showSnackBar('Debes iniciar sesión para ver tus eventos');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _StaffEventsPage(
          staffId: staffId,
          eventService: _eventService,
          onEventUpdated: () {},
        ),
      ),
    );
  }

  void _handleApproveEvents() {
    final staffId = _staffId;
    if (staffId == null) {
      _showSnackBar('Debes iniciar sesión para aprobar eventos');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _PendingEventsPage(
          staffId: staffId,
          eventService: _eventService,
          onEventUpdated: () {},
        ),
      ),
    );
  }

  void _showCreateEventDialog() {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final locationController = TextEditingController();
    final maxAttendeesController = TextEditingController(text: '100');
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = TimeOfDay.now();

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
        content: StatefulBuilder(
          builder: (context, setState) => SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'Título del Evento',
                      hintText: 'Ej: Partido de Fútbol',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Campo requerido' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descriptionController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Descripción',
                      hintText: 'Describe el evento...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Campo requerido' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: locationController,
                    decoration: InputDecoration(
                      labelText: 'Ubicación',
                      hintText: 'Ej: Patio Principal',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Campo requerido' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: maxAttendeesController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Máximo de Asistentes',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Campo requerido';
                      if (int.tryParse(value!) == null) {
                        return 'Debe ser un número';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Fecha: ${DateFormat('dd/MM/yyyy').format(selectedDate)}',
                      style: AppTheme.eventLabel,
                    ),
                    trailing: Icon(
                      Icons.calendar_today,
                      color: AppColors.primary,
                    ),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setState(() => selectedDate = picked);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Hora: ${selectedTime.format(context)}',
                      style: AppTheme.eventLabel,
                    ),
                    trailing: Icon(Icons.access_time, color: AppColors.primary),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: selectedTime,
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
                      if (picked != null) {
                        setState(() => selectedTime = picked);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar',
              style: AppTheme.filterButtonLabel.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final staffId = _staffId;
              if (staffId == null) {
                _showSnackBar('Debes iniciar sesión para crear eventos');
                return;
              }

              if (formKey.currentState!.validate()) {
                final dateTime = DateTime(
                  selectedDate.year,
                  selectedDate.month,
                  selectedDate.day,
                  selectedTime.hour,
                  selectedTime.minute,
                );

                _eventService.createEvent(
                  title: titleController.text,
                  description: descriptionController.text,
                  dateTime: dateTime,
                  location: locationController.text,
                  staffOrganizerId: staffId,
                  maxAttendees: int.parse(maxAttendeesController.text),
                );

                Navigator.pop(context);
                _showSnackBar('Evento creado exitosamente');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

// Página para aprobar eventos pendientes
class _PendingEventsPage extends StatefulWidget {
  final String staffId;
  final EventService eventService;
  final VoidCallback onEventUpdated;

  const _PendingEventsPage({
    required this.staffId,
    required this.eventService,
    required this.onEventUpdated,
  });

  @override
  State<_PendingEventsPage> createState() => _PendingEventsPageState();
}

class _PendingEventsPageState extends State<_PendingEventsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Eventos Pendientes de Aprobación'),
        elevation: 0,
      ),
      body: StreamBuilder<List<Event>>(
        stream: widget.eventService.getPendingEventsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final pendingEvents = snapshot.data ?? [];

          if (pendingEvents.isEmpty) {
            return _buildEmptyState(context);
          }

          return ListView.builder(
            itemCount: pendingEvents.length,
            itemBuilder: (context, index) {
              final event = pendingEvents[index];
              return _buildPendingEventTile(context, event);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, size: 64, color: Colors.green[400]),
          const SizedBox(height: 16),
          Text('No hay eventos pendientes', style: AppTheme.emptyStateTitle),
          const SizedBox(height: 8),
          Text(
            'Todos los eventos sugeridos han sido revisados',
            style: AppTheme.eventLabel,
          ),
        ],
      ),
    );
  }

  Widget _buildPendingEventTile(BuildContext context, Event event) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.all(12),
      decoration: AppTheme.eventCardBox,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange[600]!, Colors.orange[400]!],
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                          'Sugerido por: ${event.suggestedByUserId ?? "Usuario"}',
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.description,
                  style: AppTheme.eventDescription,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('dd/MM/yyyy HH:mm').format(event.dateTime),
                      style: AppTheme.eventLabel.copyWith(
                        color: isDark ? Colors.grey[300] : Colors.grey[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        event.location,
                        style: AppTheme.eventLabel.copyWith(
                          color: isDark ? Colors.grey[300] : Colors.grey[700],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Máximo de asistentes: ${event.maxAttendees}',
                  style: AppTheme.eventLabel.copyWith(
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showApproveConfirmation(event),
                        icon: const Icon(Icons.check_circle),
                        label: const Text('Aceptar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showRejectConfirmation(event),
                        icon: const Icon(Icons.cancel),
                        label: const Text('Rechazar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showApproveConfirmation(Event event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppColors.surface
            : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          '¿Aprobar evento?',
          style: AppTheme.eventTitle.copyWith(color: Colors.green),
        ),
        content: Text(
          'El evento "${event.title}" será aprobado y estará disponible para que otros usuarios se apunten.',
          style: AppTheme.eventDescription,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar',
              style: AppTheme.filterButtonLabel.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              widget.eventService.approveEvent(event.id, widget.staffId);
              widget.onEventUpdated();
              Navigator.pop(context);
              _showSnackBar('Evento aprobado exitosamente');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Sí, Aprobar'),
          ),
        ],
      ),
    );
  }

  void _showRejectConfirmation(Event event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppColors.surface
            : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          '¿Rechazar evento?',
          style: AppTheme.eventTitle.copyWith(color: AppColors.error),
        ),
        content: Text(
          'El evento "${event.title}" será rechazado y no estará disponible. Esta acción no se puede deshacer.',
          style: AppTheme.eventDescription,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar',
              style: AppTheme.filterButtonLabel.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              widget.eventService.rejectEvent(event.id);
              widget.onEventUpdated();
              Navigator.pop(context);
              _showSnackBar('Evento rechazado');
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Sí, Rechazar'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

// Página para ver eventos del staff
class _StaffEventsPage extends StatefulWidget {
  final String staffId;
  final EventService eventService;
  final VoidCallback onEventUpdated;

  const _StaffEventsPage({
    required this.staffId,
    required this.eventService,
    required this.onEventUpdated,
  });

  @override
  State<_StaffEventsPage> createState() => _StaffEventsPageState();
}

class _StaffEventsPageState extends State<_StaffEventsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis Eventos'), elevation: 0),
      body: StreamBuilder<List<Event>>(
        stream: widget.eventService.getEventsByStaffStream(widget.staffId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final staffEvents = snapshot.data ?? [];

          if (staffEvents.isEmpty) {
            return _buildEmptyState(context);
          }

          return ListView.builder(
            itemCount: staffEvents.length,
            itemBuilder: (context, index) {
              final event = staffEvents[index];
              return _buildEventTile(context, event);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('No has creado eventos aún', style: AppTheme.emptyStateTitle),
        ],
      ),
    );
  }

  Widget _buildEventTile(BuildContext context, Event event) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.all(12),
      decoration: AppTheme.eventCardBox,
      child: Column(
        children: [
          // Encabezado
          Container(
            decoration: AppTheme.eventHeaderGradient,
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                          event.status.toString().split('.').last.toUpperCase(),
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
          // Contenido
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.description,
                  style: AppTheme.eventDescription,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('dd/MM/yyyy HH:mm').format(event.dateTime),
                      style: AppTheme.eventLabel.copyWith(
                        color: isDark ? Colors.grey[300] : Colors.grey[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        event.location,
                        style: AppTheme.eventLabel.copyWith(
                          color: isDark ? Colors.grey[300] : Colors.grey[700],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Asistentes: ${event.attendeeIds.length}/${event.maxAttendees}',
                  style: AppTheme.eventLabel.copyWith(
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed:
                            event.status == EventStatus.active ||
                                event.status == EventStatus.inactive
                            ? () => _showEditEventDialog(event)
                            : null,
                        icon: const Icon(Icons.edit),
                        label: const Text('Editar'),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: event.status == EventStatus.active
                                ? AppColors.primary
                                : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed:
                            event.status == EventStatus.active ||
                                event.status == EventStatus.inactive
                            ? () => _showDeleteConfirmation(event)
                            : null,
                        icon: const Icon(Icons.delete),
                        label: const Text('Cancelar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              event.status == EventStatus.active ||
                                  event.status == EventStatus.inactive
                              ? Colors.red
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEditEventDialog(Event event) {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController(text: event.title);
    final descriptionController = TextEditingController(
      text: event.description,
    );

    final locationController = TextEditingController(text: event.location);
    final maxAttendeesController = TextEditingController(
      text: event.maxAttendees.toString(),
    );
    DateTime selectedDate = event.dateTime;
    TimeOfDay selectedTime = TimeOfDay(
      hour: event.dateTime.hour,
      minute: event.dateTime.minute,
    );
    EventStatus currentStatus = event.status;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppColors.surface
            : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Editar Evento',
          style: AppTheme.eventTitle.copyWith(color: AppColors.primary),
        ),
        content: StatefulBuilder(
          builder: (context, setState) => SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'Título del Evento',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Campo requerido' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descriptionController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Descripción',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Campo requerido' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: locationController,
                    decoration: InputDecoration(
                      labelText: 'Ubicación',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Campo requerido' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: maxAttendeesController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Máximo de Asistentes',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Campo requerido';
                      if (int.tryParse(value!) == null) {
                        return 'Debe ser un número';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Fecha: ${DateFormat('dd/MM/yyyy').format(selectedDate)}',
                      style: AppTheme.eventLabel,
                    ),
                    trailing: Icon(
                      Icons.calendar_today,
                      color: AppColors.primary,
                    ),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setState(() => selectedDate = picked);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Hora: ${selectedTime.format(context)}',
                      style: AppTheme.eventLabel,
                    ),
                    trailing: Icon(Icons.access_time, color: AppColors.primary),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: selectedTime,
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
                      if (picked != null) {
                        setState(() => selectedTime = picked);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        if (currentStatus == EventStatus.active) {
                          currentStatus = EventStatus.inactive;
                        } else if (currentStatus == EventStatus.inactive) {
                          currentStatus = EventStatus.active;
                        }
                      });
                    },
                    icon: Icon(
                      currentStatus == EventStatus.active
                          ? Icons.check_circle
                          : Icons.pause_circle,
                    ),
                    label: Text(
                      currentStatus == EventStatus.active
                          ? 'Evento Activo'
                          : 'Evento Inactivo',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: currentStatus == EventStatus.active
                          ? AppColors.primary
                          : Colors.grey[600],
                      minimumSize: const Size(double.infinity, 44),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar',
              style: AppTheme.filterButtonLabel.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ),

          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final dateTime = DateTime(
                  selectedDate.year,
                  selectedDate.month,
                  selectedDate.day,
                  selectedTime.hour,
                  selectedTime.minute,
                );

                widget.eventService.updateEvent(
                  event.id,
                  title: titleController.text,
                  description: descriptionController.text,
                  dateTime: dateTime,
                  location: locationController.text,
                  maxAttendees: int.parse(maxAttendeesController.text),
                );
                if (currentStatus == EventStatus.active) {
                  widget.eventService.activateEvent(event.id);
                } else if (currentStatus == EventStatus.inactive) {
                  widget.eventService.deactivateEvent(event.id);
                }

                Navigator.pop(context);
                _showSnackBar('Evento actualizado exitosamente');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Actualizar'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(Event event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppColors.surface
            : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          '¿Cancelar evento?',
          style: AppTheme.eventTitle.copyWith(color: AppColors.error),
        ),
        content: Text(
          'Esta acción no se puede deshacer. ¿Deseas cancelar el evento "${event.title}"?',
          style: AppTheme.eventDescription,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'No',
              style: AppTheme.filterButtonLabel.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              widget.eventService.cancelEvent(event.id);

              Navigator.pop(context);
              _showSnackBar('Evento cancelado');
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Sí, Cancelar'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
