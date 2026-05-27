import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:RockMeet/config/Theme/constants/colors.dart';
import 'package:RockMeet/core/services/notification_service.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;

  @override
  void dispose() {
    final uid = _uid;
    if (uid != null) {
      NotificationService.instance.markAllRead(uid);
    }
    super.dispose();
  }

  Future<void> _confirmDeleteAll() async {
    final uid = _uid;
    if (uid == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Borrar notificaciones',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        content: Text('¿Eliminar todas las notificaciones?',
            style: GoogleFonts.outfit()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar', style: GoogleFonts.outfit()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Eliminar',
                style: GoogleFonts.outfit(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await NotificationService.instance.deleteAllForUser(uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = _uid;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Notificaciones',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        elevation: 0,
        actions: [
          if (uid != null)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'Borrar todas',
              onPressed: _confirmDeleteAll,
            ),
        ],
      ),
      body: uid == null
          ? const Center(child: Text('No autenticado'))
          : StreamBuilder<List<Map<String, dynamic>>>(
              stream: NotificationService.instance.streamForUser(uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Error al cargar notificaciones:\n${snapshot.error}',
                        textAlign: TextAlign.center,
                        style:
                            GoogleFonts.outfit(fontSize: 13, color: Colors.red),
                      ),
                    ),
                  );
                }

                final notifications = snapshot.data ?? [];
                if (notifications.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.notifications_none,
                            size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'No tienes notificaciones',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: notifications.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final n = notifications[index];
                    final docId = n['id'] as String? ?? '';
                    return Dismissible(
                      key: ValueKey(docId),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: Colors.red.shade400,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.delete_outline,
                            color: Colors.white, size: 26),
                      ),
                      onDismissed: (_) {
                        if (docId.isNotEmpty) {
                          NotificationService.instance
                              .deleteNotification(docId);
                        }
                      },
                      child: _NotificationTile(data: n, isDark: isDark),
                    );
                  },
                );
              },
            ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isDark;

  const _NotificationTile({required this.data, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final type = data['type'] as String? ?? '';
    final fromName = data['fromName'] as String? ?? 'Alguien';
    final fromPhoto = data['fromPhotoUrl'] as String? ?? '';
    final preview = data['preview'] as String? ?? '';
    final read = data['read'] as bool? ?? true;
    final ts = data['createdAt'];
    final date = ts is Timestamp ? _formatDate(ts.toDate()) : '';

    final (icon, color, label) = switch (type) {
      'like' => (Icons.favorite, Colors.pink, '$fromName te ha dado like'),
      'match' => (
          Icons.favorite_border,
          AppColors.primary,
          '¡Has hecho match con $fromName!'
        ),
      'message' => (
          Icons.chat_bubble_outline,
          Colors.blue,
          '$fromName te ha enviado un mensaje'
        ),
      _ => (Icons.notifications, Colors.grey, fromName),
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: read
            ? (isDark ? AppColors.surface : Colors.white)
            : (isDark ? color.withOpacity(0.08) : color.withOpacity(0.05)),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: read ? AppColors.border : color.withOpacity(0.4),
          width: read ? 1 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.04),
            blurRadius: 6,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Stack(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage:
                    fromPhoto.isNotEmpty ? NetworkImage(fromPhoto) : null,
                backgroundColor: color.withOpacity(0.15),
                child: fromPhoto.isEmpty
                    ? Icon(icon, color: color, size: 22)
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? AppColors.surface : Colors.white,
                      width: 1.5,
                    ),
                  ),
                  child: Icon(icon, size: 10, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          // Texto
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: read ? FontWeight.w500 : FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                if (preview.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    '"$preview"',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color:
                          isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (date.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    date,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (!read)
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(top: 4),
              decoration:
                  BoxDecoration(color: color, shape: BoxShape.circle),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
