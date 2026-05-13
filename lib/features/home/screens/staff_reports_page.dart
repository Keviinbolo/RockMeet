import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:RockMeet/config/Theme/app_theme.dart';
import 'package:RockMeet/config/Theme/constants/colors.dart';
import 'package:RockMeet/core/services/event_service.dart';
import 'package:RockMeet/core/services/user_moderation_service.dart';
import 'package:RockMeet/core/models/class_event.dart';

class StaffReportsPage extends StatelessWidget {
  const StaffReportsPage({
    super.key,
    required this.staffId,
    required this.eventService,
  });

  final String staffId;
  final EventService eventService;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reportes')),
      body: StreamBuilder<List<ModeratedUser>>(
        stream: UserModerationService.instance.watchUsers(),
        builder: (context, usersSnapshot) {
          if (usersSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = usersSnapshot.data ?? <ModeratedUser>[];
          return StreamBuilder<List<Event>>(
            stream: eventService.getEventsByStaffStream(staffId),
            builder: (context, staffEventsSnapshot) {
              if (staffEventsSnapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              return StreamBuilder<List<Event>>(
                stream: eventService.getPendingEventsStream(),
                builder: (context, pendingEventsSnapshot) {
                  if (pendingEventsSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final staffEvents = staffEventsSnapshot.data ?? <Event>[];
                  final pendingEvents = pendingEventsSnapshot.data ?? <Event>[];
                  final activeEvents = staffEvents
                      .where((event) => event.status == EventStatus.active)
                      .length;
                  final blockedUsers = users
                      .where((user) => user.isBlocked)
                      .length;
                  final staffUsers = users.where((user) => user.isStaff).length;

                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(
                        'Resumen general',
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _ReportStatGrid(
                        items: [
                          _ReportStatItem(
                            label: 'Usuarios totales',
                            value: users.length.toString(),
                            color: AppColors.primary,
                            icon: Icons.people,
                          ),
                          _ReportStatItem(
                            label: 'Usuarios staff',
                            value: staffUsers.toString(),
                            color: Colors.blue,
                            icon: Icons.badge,
                          ),
                          _ReportStatItem(
                            label: 'Usuarios bloqueados',
                            value: blockedUsers.toString(),
                            color: Colors.red,
                            icon: Icons.block,
                          ),
                          _ReportStatItem(
                            label: 'Eventos staff',
                            value: staffEvents.length.toString(),
                            color: Colors.orange,
                            icon: Icons.event,
                          ),
                          _ReportStatItem(
                            label: 'Eventos activos',
                            value: activeEvents.toString(),
                            color: Colors.green,
                            icon: Icons.check_circle,
                          ),
                          _ReportStatItem(
                            label: 'Eventos pendientes',
                            value: pendingEvents.length.toString(),
                            color: Colors.purple,
                            icon: Icons.schedule,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Indicadores rápidos',
                        style: AppTheme.eventTitle.copyWith(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _ReportNote(
                        title: 'Moderación de usuarios',
                        body:
                            'Desde "Gestionar usuarios" puedes bloquear y desbloquear cualquier usuario no staff.',
                      ),
                      const SizedBox(height: 12),
                      _ReportNote(
                        title: 'Eventos en revisión',
                        body:
                            'Los eventos pendientes siguen entrando por el flujo de aprobación del staff.',
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _ReportStatGrid extends StatelessWidget {
  const _ReportStatGrid({required this.items});

  final List<_ReportStatItem> items;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemBuilder: (context, index) => items[index],
    );
  }
}

class _ReportStatItem extends StatelessWidget {
  const _ReportStatItem({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white70
                  : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportNote extends StatelessWidget {
  const _ReportNote({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.surface
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(body, style: GoogleFonts.outfit(fontSize: 14, height: 1.4)),
        ],
      ),
    );
  }
}
