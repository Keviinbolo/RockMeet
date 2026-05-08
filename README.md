# 🎓 RockMeet

RockMeet es una red social móvil para estudiantes del Instituto Roca.  
Permite conectar con compañeros, compartir contenido y colaborar en proyectos de tu ciclo formativo u otros.

## ✨ Características

- 👤 Autenticación segura (login/registro con correo del instituto)
- 💬 Chat con compañeros por ciclos *(en desarrollo)*
- 🎭 Perfiles de estudiantes
- 📌 Feed de actividades y anuncios *(en desarrollo)*
- 🔔 Theflificaciones de eventos y deadlines *(en desarrollo)*
- 📚 Compartir recursos y apuntes *(en desarrollo)*
- ⚙️ Ajustes de privacidad y preferencias *(en desarrollo)*

## 🚀 Inicio rápido

### Requisitos

- Flutter 3.x+
- Dart 3.x+
- Android SDK / Xcode

### Instalación

```bash
git clone https://github.com/Keviinbolo/rockmeet.git
cd rockmeet
flutter pub get
cp .env.example .env    # Opcional, según configuración del proyecto
flutter run
```

## 📱 Pantallas principales

| Pantalla | Descripción                      | Estado        |
| -------- | -------------------------------- | ------------- |
| Splash   | Pantalla de carga                | Implementada* |
| Login    | Acceso a la aplicación           | En desarrollo |
| Registro | Crear nueva cuenta de estudiante | En desarrollo |
| Home     | Feed de actividades y anuncios   | Diseño        |
| Chat     | Mensajería con compañeros        | Planificada   |
| Perfil   | Información del estudiante       | Diseño        |
| Ajustes  | Configuración de cuenta          | Planificada   |

## 🏗️ Arquitectura

La aplicación sigue una arquitectura basada en features, organizando el código por módulos funcionales
(por ejemplo: auth, home, chat, profile, etc.) para facilitar la escalabilidad y el mantenimiento.

Consulta docs/ARCHITECTURE.md para más detalles.

## 👥 Público objetivo

Estudiantes del Instituto Roca

Diferentes ciclos formativos (DAM, DAW, otros)

## 📞 Contacto

Para reportar bugs o sugerencias, utiliza el apartado de Issues del repositorio:
https://github.com/Keviinbolo/rockmeet/issues

## 📝 Licencia

Proyecto publicado bajo licencia MIT.
Consulta el archivo LICENSE para más información.
