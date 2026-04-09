import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myapp/config/Theme/constants/colors.dart';
import 'package:myapp/core/services/auth_service.dart';
import 'package:myapp/core/services/profile_service.dart';

class InformacionCuentaScreen extends StatefulWidget {
  const InformacionCuentaScreen({Key? key}) : super(key: key);

  @override
  State<InformacionCuentaScreen> createState() => _InformacionCuentaScreenState();
}

class _InformacionCuentaScreenState extends State<InformacionCuentaScreen> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      final user = AuthService().currentUser;
      final profile = await ProfileService.instance.getCurrentUserProfile();
      setState(() {
        _userData = {
          'displayName': user?.displayName ?? profile?['displayName'] ?? 'Usuario',
          'email': user?.email ?? profile?['email'] ?? 'No disponible',
          'photoURL': user?.photoURL ?? profile?['photoURL'] ?? '',
          'createdAt': profile?['createdAt'] ?? DateTime.now(),
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _userData = {
        'displayName': 'Usuario',
        'email': 'no-disponible@ejemplo.com',
        'photoURL': '',
        'createdAt': DateTime.now(),
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Información de la cuenta',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: _userData!['photoURL'] != null && _userData!['photoURL'].isNotEmpty
                        ? NetworkImage(_userData!['photoURL'])
                        : null,
                    child: _userData!['photoURL'] == null || _userData!['photoURL'].isEmpty
                        ? Icon(Icons.person, size: 50, color: Colors.grey.shade400)
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _userData!['displayName'],
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                 
                  const SizedBox(height: 24),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _infoRow(
                            icon: Icons.person,
                            label: 'Nombre de usuario',
                            value: _userData!['displayName'],
                          ),
                          _divider(),
                          _infoRow(
                            icon: Icons.email,
                            label: 'Correo electrónico',
                            value: _userData!['email'],
                          ),
                          _divider(),
                          _infoRow(
                            icon: Icons.calendar_today,
                            label: 'Fecha de registro',
                            value: _formatDate(_userData!['createdAt']),
                          ),
                        
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
    bool copyable = false,
    String? fullValue,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: AppColors.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          if (copyable && fullValue != null && fullValue.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.copy, size: 18),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: fullValue));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('ID de usuario copiado al portapapeles'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              tooltip: 'Copiar ID',
            ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: Colors.grey.shade300,
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'No disponible';
    try {
      DateTime dt;
      if (date is DateTime) {
        dt = date;
      } else if (date is String) {
        dt = DateTime.parse(date);
      } else {
        return 'No disponible';
      }
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (e) {
      return 'No disponible';
    }
  }
}