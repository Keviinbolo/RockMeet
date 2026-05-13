import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:RockMeet/config/Theme/constants/colors.dart';
import 'package:RockMeet/core/services/user_moderation_service.dart';

class StaffUserManagementPage extends StatefulWidget {
  const StaffUserManagementPage({super.key});

  @override
  State<StaffUserManagementPage> createState() => _StaffUserManagementPageState();
}

class _StaffUserManagementPageState extends State<StaffUserManagementPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late final Stream<List<ModeratedUser>> _usersStream;

  @override
  void initState() {
    super.initState();
    _usersStream = UserModerationService.instance.watchUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final service = UserModerationService.instance;

    return Scaffold(
      appBar: AppBar(title: const Text('Gestionar usuarios')),
      body: StreamBuilder<List<ModeratedUser>>(
        stream: _usersStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'No se pudieron cargar los usuarios',
                style: GoogleFonts.outfit(fontSize: 16),
              ),
            );
          }

          final users = snapshot.data ?? <ModeratedUser>[];
          final filteredUsers = users.where((user) {
            final query = _searchQuery.trim().toLowerCase();
            if (query.isEmpty) return true;
            return user.displayName.toLowerCase().contains(query);
          }).toList();

          if (users.isEmpty) {
            return const Center(child: Text('No hay usuarios para mostrar'));
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                  },
                  decoration: InputDecoration(
                    hintText: 'Buscar por nombre de usuario',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                            icon: const Icon(Icons.close),
                          ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    filled: true,
                  ),
                ),
              ),
              Expanded(
                child: filteredUsers.isEmpty
                    ? Center(
                        child: Text(
                          'No hay coincidencias para "$_searchQuery"',
                          style: GoogleFonts.outfit(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        itemCount: filteredUsers.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final user = filteredUsers[index];
                          final isSelf = user.id == currentUserId;
                          final canModerate = !user.isStaff && !isSelf;

                          return Card(
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 26,
                                        backgroundColor:
                                            AppColors.primary.withValues(
                                          alpha: 0.12,
                                        ),
                                        backgroundImage: user.photoURL.isNotEmpty
                                            ? NetworkImage(user.photoURL)
                                            : null,
                                        child: user.photoURL.isEmpty
                                            ? Icon(
                                                Icons.person,
                                                color: AppColors.primary,
                                              )
                                            : null,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              user.displayName,
                                              style: GoogleFonts.outfit(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              user.email,
                                              style: GoogleFonts.outfit(
                                                fontSize: 13,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      _UserChip(
                                        label: user.isStaff ? 'Staff' : 'Usuario',
                                        color: user.isStaff
                                            ? Colors.blue
                                            : AppColors.primary,
                                      ),
                                      if (user.isBlocked)
                                        const _UserChip(
                                          label: 'Bloqueado',
                                          color: Colors.red,
                                        ),
                                      if (isSelf)
                                        const _UserChip(
                                          label: 'Tú',
                                          color: Colors.orange,
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: canModerate
                                              ? () => _showBlockDialog(
                                                  context,
                                                  service,
                                                  user,
                                                )
                                              : null,
                                          icon: Icon(
                                            user.isBlocked
                                                ? Icons.lock_open
                                                : Icons.block,
                                          ),
                                          label: Text(
                                            user.isBlocked
                                                ? 'Desbloquear'
                                                : 'Bloquear',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (!canModerate)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 10),
                                      child: Text(
                                        user.isStaff
                                            ? 'Los usuarios staff no se pueden bloquear.'
                                            : 'No puedes moderar tu propio usuario.',
                                        style: GoogleFonts.outfit(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showBlockDialog(
    BuildContext context,
    UserModerationService service,
    ModeratedUser user,
  ) async {
    final isBlocked = user.isBlocked;
    final actionLabel = isBlocked ? 'desbloquear' : 'bloquear';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('${isBlocked ? 'Desbloquear' : 'Bloquear'} usuario'),
        content: Text(
          '¿Seguro que quieres $actionLabel a ${user.displayName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(isBlocked ? 'Desbloquear' : 'Bloquear'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    try {
      if (isBlocked) {
        await service.unblockUser(
          userId: user.id,
          staffId: FirebaseAuth.instance.currentUser!.uid,
        );
      } else {
        await service.blockUser(
          userId: user.id,
          staffId: FirebaseAuth.instance.currentUser!.uid,
        );
      }

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isBlocked
                ? 'Usuario desbloqueado correctamente'
                : 'Usuario bloqueado correctamente',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo completar la acción: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class _UserChip extends StatelessWidget {
  const _UserChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
