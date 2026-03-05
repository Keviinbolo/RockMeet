import 'package:flutter/material.dart';

import 'package:myapp/config/Theme/constants/colors.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeStaffPage extends StatefulWidget {
  const HomeStaffPage({Key? key}) : super(key: key);

  @override
  State<HomeStaffPage> createState() => _HomeStaffPageState();
}

class _HomeStaffPageState extends State<HomeStaffPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel Staff - RockMeet'),
        centerTitle: true,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
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
        ),
      ),
    );
  }

  // Sección de Resumen
  Widget _buildSummarySection(BuildContext context) {
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
                value: '12',
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context,
                title: 'Usuarios',
                value: '234',
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context,
                title: 'Asistentes',
                value: '1.2K',
                color: Colors.orange,
              ),
            ),
          ],
        ),
      ],
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
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 2,
        ),
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
          onTap: () => _handleCreateEvent(),
        ),
        const SizedBox(height: 12),
        _buildEventManagementButton(
          context,
          icon: Icons.edit,
          title: 'Editar Evento',
          subtitle: 'Modificar evento existente',
          onTap: () => _handleEditEvent(),
        ),
        const SizedBox(height: 12),
        _buildEventManagementButton(
          context,
          icon: Icons.delete_outline,
          title: 'Cancelar Evento',
          subtitle: 'Cancelar un evento programado',
          onTap: () => _handleCancelEvent(),
        ),
        const SizedBox(height: 12),
        _buildEventManagementButton(
          context,
          icon: Icons.list_alt,
          title: 'Ver Eventos',
          subtitle: 'Lista de todos los eventos',
          onTap: () => _handleViewEvents(),
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
          border: Border.all(
            color: AppColors.border,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.4 : 0.08),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Icon(
            icon,
            color: AppColors.primary,
            size: 28,
          ),
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
          onTap: () => _handleManageUsers(),
        ),
        const SizedBox(height: 12),
        _buildOptionButton(
          context,
          icon: Icons.bar_chart,
          title: 'Reportes',
          onTap: () => _handleReports(),
        ),
        const SizedBox(height: 12),
        _buildOptionButton(
          context,
          icon: Icons.settings,
          title: 'Configuración',
          onTap: () => _handleSettings(),
        ),
      ],
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
          border: Border.all(
            color: AppColors.border,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.4 : 0.08),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Icon(
            icon,
            color: AppColors.secondary,
            size: 26,
          ),
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Crear evento'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _handleEditEvent() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Editar evento'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _handleCancelEvent() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Cancelar evento'),
        backgroundColor: AppColors.error,
      ),
    );
  }

  void _handleViewEvents() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Ver eventos'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _handleManageUsers() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Gestionar usuarios'),
        backgroundColor: AppColors.secondary,
      ),
    );
  }

  void _handleReports() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Reportes'),
        backgroundColor: AppColors.secondary,
      ),
    );
  }

  void _handleSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Configuración'),
        backgroundColor: AppColors.secondary,
      ),
    );
  }
}