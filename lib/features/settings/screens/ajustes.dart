import 'package:flutter/material.dart';
import 'package:myapp/config/Theme/app_theme.dart';

class Perfil extends StatelessWidget {
  const Perfil({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.lightTheme,
      child: Scaffold(
        backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
        body: const SettingsPage(),
      ),
    );
  }
}

// Página de ajustes con desplegables (sin estilos)
class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: Column(
        children: [
          // Header con botón de retroceso usando tema
          Container(
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
            color: Theme.of(context).primaryColor,
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                const SizedBox(width: 20),
                const Text('Ajustes', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          
          // Lista de desplegables + botón cerrar sesión
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Desplegable Cuenta
                CustomExpansionTile(
                  icon: Icons.person,
                  title: 'Cuenta',
                  subtitle: 'Información personal, email',
                  children: const [
                    ListTile(
                      leading: Icon(Icons.edit),
                      title: Text('Editar perfil'),
                    ),
                    ListTile(
                      leading: Icon(Icons.email),
                      title: Text('Cambiar email'),
                    ),
                    ListTile(
                      leading: Icon(Icons.lock),
                      title: Text('Cambiar contraseña'),
                    ),
                  ],
                ),
                
                // Desplegable Notificaciones
                CustomExpansionTile(
                  icon: Icons.notifications,
                  title: 'Notificaciones',
                  subtitle: 'Configura tus alertas',
                  children: [
                    _buildSwitchTile(
                      icon: Icons.push_pin,
                      title: 'Notificaciones push',
                      value: true,
                    ),
                    _buildSwitchTile(
                      icon: Icons.email,
                      title: 'Notificaciones por email',
                      value: false,
                    ),
                  ],
                ),
                
                // Desplegable Privacidad
                CustomExpansionTile(
                  icon: Icons.lock,
                  title: 'Privacidad',
                  subtitle: 'Controla tu privacidad',
                  children: [
                    _buildSwitchTile(
                      icon: Icons.visibility,
                      title: 'Perfil público',
                      value: true,
                    ),
                    _buildSwitchTile(
                      icon: Icons.location_on,
                      title: 'Compartir ubicación',
                      value: false,
                    ),
                  ],
                ),
                
                // Desplegable Ayuda
                CustomExpansionTile(
                  icon: Icons.help,
                  title: 'Ayuda',
                  subtitle: 'Soporte y preguntas frecuentes',
                  children: const [
                    ListTile(
                      leading: Icon(Icons.help_outline),
                      title: Text('Preguntas frecuentes'),
                    ),
                    ListTile(
                      leading: Icon(Icons.support_agent),
                      title: Text('Contactar soporte'),
                    ),
                  ],
                ),
                
                // Desplegable Acerca de
                CustomExpansionTile(
                  icon: Icons.info,
                  title: 'Acerca de',
                  subtitle: 'Versión 1.0.0',
                  children: const [
                    ListTile(
                      leading: Icon(Icons.info_outline),
                      title: Text('Versión de la app'),
                      subtitle: Text('1.0.0'),
                    ),
                    ListTile(
                      leading: Icon(Icons.code),
                      title: Text('Términos y condiciones'),
                    ),
                  ],
                ),
                
                const Divider(height: 40),
                
                // Botón de cerrar sesión (sin estilos)
                const LogoutButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper para crear SwitchListTile sin estilos
  static Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required bool value,
  }) {
    return SwitchListTile(
      secondary: Container(
        padding: const EdgeInsets.all(4),
        child: Icon(icon),
      ),
      title: Text(title),
      value: value,
      onChanged: (newValue) {
        // Aquí puedes manejar el cambio de estado
      },
    );
  }
}

// Widget personalizado para ExpansionTile sin estilos
class CustomExpansionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Widget> children;

  const CustomExpansionTile({
    Key? key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.children,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: Theme.of(context).primaryColor),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        children: children,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding: const EdgeInsets.only(left: 40, right: 16, bottom: 12),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
      ),
    );
  }
}

// Componente LogoutButton sin estilos
class LogoutButton extends StatelessWidget {
  const LogoutButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(vertical: 10),
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).primaryColor,
              side: BorderSide(color: Theme.of(context).primaryColor),
            ),
            onPressed: () {
              _showLogoutConfirmationDialog(context);
            },
            child: const Text('Cerrar sesión'),
          ),
        ),
        
        const Text(
          '¿Seguro que quieres salir? Puedes volver a iniciar sesión cuando quieras',
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  void _showLogoutConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cerrar sesión'),
          content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // Aquí iría la lógica para cerrar sesión
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sesión cerrada exitosamente')),
                );
              },
              child: const Text('Cerrar sesión'),
            ),
          ],
        );
      },
    );
  }
}

// Mantenemos el CreateAccountModal sin estilos
class CreateAccountModal extends StatelessWidget {
  const CreateAccountModal({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Crear Cuenta'),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const TextField(
            decoration: InputDecoration(
              labelText: 'Nombre completo',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
            ),
          ),
          const SizedBox(height: 16),
          const TextField(
            decoration: InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.email),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          const TextField(
            decoration: InputDecoration(
              labelText: 'Contraseña',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.lock),
            ),
            obscureText: true,
          ),
          const SizedBox(height: 16),
          const TextField(
            decoration: InputDecoration(
              labelText: 'Confirmar contraseña',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.lock_outline),
            ),
            obscureText: true,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cuenta creada exitosamente')),
                );
              },
              child: const Text('Crear Cuenta'),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}