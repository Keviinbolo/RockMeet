# Arquitectura técnica — RockMeet

**Versión**: Sprint 7 (MVP)  
**Última actualización**: 2026-05-27  
**Stack**: Flutter 3 / Dart 3 · Firebase Auth + Firestore · Supabase Storage

---

## Estructura de carpetas

```
lib/
├── main.dart                          # Inicialización Firebase/Supabase, tema, rutas
│
├── config/
│   ├── Routes/
│   │   └── approutes.dart             # Definición centralizada de rutas nombradas
│   └── Theme/
│       ├── app_theme.dart             # ThemeData light + dark
│       ├── Logo/                      # Assets del logo
│       └── constants/
│           ├── colors.dart            # AppColors (primary, secondary, surface…)
│           └── text_styles.dart       # Estilos de texto reutilizables
│
├── core/
│   ├── api/
│   │   └── firebase_options.dart      # Configuración generada por FlutterFire CLI
│   │
│   ├── models/
│   │   ├── user_profile.dart          # UserProfile.fromFirestore()
│   │   ├── chat_message.dart          # Modelo de mensaje de chat
│   │   └── class_event.dart           # Modelo Event + EventStatus enum
│   │
│   ├── services/
│   │   ├── auth_service.dart          # Registro, login, logout, getUserData
│   │   ├── profile_service.dart       # CRUD perfil, incremento de contadores
│   │   ├── chat_service.dart          # Chats directos, envío de mensajes, streams
│   │   ├── event_service.dart         # CRUD eventos, asistencia atómica, aprobación
│   │   ├── notification_service.dart  # Enviar, leer, borrar notificaciones
│   │   ├── schedule_service.dart      # Horarios de clase (upload/delete/watch)
│   │   ├── supabase_service.dart      # Upload/delete imágenes en Supabase Storage
│   │   ├── interaction_service.dart   # Registro de likes/passes, detección de match
│   │   ├── presence_service.dart      # Indicador online/offline en Firestore
│   │   ├── tutor_code_service.dart    # Código de registro de 24 h para staff
│   │   ├── user_moderation_service.dart # Bloqueo de usuarios
│   │   ├── portal_auth.dart           # Widget de enrutamiento por tipo de usuario
│   │   └── firebase_service.dart      # Helpers genéricos Firebase
│   │
│   ├── widgets/
│   │   ├── event_card.dart            # Tarjeta de evento reutilizable
│   │   ├── match_animation_widget.dart # Overlay de celebración al hacer match
│   │   ├── settings_header.dart       # Cabecera de secciones en ajustes
│   │   ├── validation_text_field.dart # TextField con validación integrada
│   │   └── validation_state_widget.dart
│   │
│   └── doc/
│       ├── ARCHITECTURE.md            # ← este archivo
│       └── crashes/
│           ├── README.md
│           ├── CRASH_LOG_TEMPLATE.md
│           └── RESOLVED_ISSUES.md
│
└── features/
    ├── auth/
    │   ├── screens/
    │   │   ├── pantalla_splash.dart       # Pantalla de carga inicial
    │   │   ├── login.dart                 # Login + recuperación de contraseña
    │   │   ├── registro_page.dart         # Registro con código de acceso
    │   │   ├── profile_setup_page.dart    # Configuración inicial post-registro
    │   │   └── blocked_user_screen.dart   # Pantalla de cuenta bloqueada
    │   └── widgets/
    │       └── wave_background.dart       # Fondo animado de ondas
    │
    ├── home/
    │   ├── screens/
    │   │   ├── home_page.dart             # Matching principal (tarjetas deslizables)
    │   │   ├── home_staff_page.dart       # Panel del staff
    │   │   ├── staff_schedule_page.dart   # Gestión de horarios por ciclo
    │   │   ├── staff_user_management_page.dart
    │   │   └── staff_reports_page.dart
    │   └── widgets/
    │       └── swipeable_card.dart        # Tarjeta con flip animation (frente/reverso)
    │
    ├── chat/
    │   ├── screens/
    │   │   ├── chat_page.dart             # Chat en tiempo real
    │   │   └── peer_profile_screen.dart   # Perfil del interlocutor
    │   └── widgets/
    │       ├── chat_input_bar.dart
    │       └── message_bubble.dart
    │
    ├── profile/
    │   ├── screens/
    │   │   └── Perfil.dart               # Perfil propio + edición completa
    │   └── interest_screen.dart          # Selector de intereses con sub-intereses
    │
    ├── events/
    │   └── screens/
    │       └── event_screen.dart          # Lista de eventos, asistencia, sugerencias
    │
    ├── notifications/
    │   └── notifications_page.dart        # Bandeja de notificaciones con swipe-delete
    │
    ├── like/
    │   └── screens/
    │       └── like_page.dart             # Usuarios que te han dado like
    │
    └── settings/
        └── screens/
            ├── ajustes.dart               # Pantalla principal de ajustes
            ├── cambiar_contrasenia.dart
            ├── contactar_soporte.dart
            ├── politica_privacidad.dart
            ├── preguntas_frecuentes.dart
            └── terminos_condiciones.dart
```

---

## Flujos principales

### 1. Autenticación y enrutamiento

**Archivos clave**: `portal_auth.dart`, `login.dart`, `registro_page.dart`

```
App inicio
  └── PortalAuth
        ├── Sin sesión          → /login
        ├── type = 'user'       → /home
        └── type = 'staff'      → /homestaff
```

**Registro** (usuario):
1. Validar código de 24 h generado por staff (`TutorCodeService.validateCode()`)
2. Crear usuario en Firebase Auth (`createUserWithEmailAndPassword`)
3. Escribir documento en `users/{uid}` con campos iniciales
4. Redirigir a `/profile-setup`

**Contraseña**: mínimo 8 caracteres, al menos una letra y un número (validado en cliente con RegExp).

**Recuperación de contraseña**: `FirebaseAuth.sendPasswordResetEmail()` — disponible para todos los tipos de usuario.

---

### 2. Matching (Home Page)

**Archivo**: `lib/features/home/screens/home_page.dart`  
**Widget tarjeta**: `lib/features/home/widgets/swipeable_card.dart`  
**Servicios**: `InteractionService`, `NotificationService`, `ChatService`

```
Cargar usuarios (tipo 'user', excluye staff + interacciones previas)
  │
  ├── Swipe derecha (Like)
  │     ├── interactions/{id} {type:'like', from, to}
  │     ├── ¿Match mutuo?
  │     │     ├── Sí → crear chat + notificación 'match' a ambos
  │     │     │        + mostrar MatchAnimationWidget
  │     │     └── No → notificación 'like' al receptor
  │
  └── Swipe izquierda (Pass)
        └── interactions/{id} {type:'pass', from, to}
```

**Tarjeta deslizable** — dos caras con `AnimationController`:
- **Frente**: foto principal, nombre, edad, bio (max 6 líneas), píldoras de intereses
- **Reverso**: galería, género, ciclo formativo, links de redes sociales (abre navegador externo), botón de like/pass

---

### 3. Perfil

**Archivo**: `lib/features/profile/screens/Perfil.dart`  
**Servicio**: `ProfileService`, `ScheduleService`, `SupabaseService`

**Campos editables**: nombre, bio, avatar, galería (3 fotos), ciclo formativo, intereses (+sub-intereses), Twitter/X, Instagram, TikTok, Spotify, canción favorita, artista favorito.

**Botón de horario de clase**:
```
_scheduleKey (getter)
  ├── _course != null → extraer código ('DAM' de 'DAM - Desarrollo...')
  │     └── ¿código en availableClasses? → devuelve código
  └── _course == null → usar _clase como fallback (cuentas legacy)
        └── ¿_clase en availableClasses? → devuelve código

StreamBuilder(watchScheduleImageUrl(_scheduleKey))
  ├── scheduleUrl vacío  → SizedBox.shrink()  (sin botón)
  └── scheduleUrl lleno  → ElevatedButton 'Ver horario de clases'
```

Al guardar perfil, `_clase` se sincroniza automáticamente con el código extraído de `_course` (`derivedClase`).

---

### 4. Eventos

**Archivos**: `event_screen.dart`, `event_service.dart`  
**Modelo**: `class_event.dart` → `Event` + `EventStatus { active, inactive, pending, cancelled, completed }`

**Flujo usuario**:
1. Ver eventos activos en tiempo real
2. Apuntarse → `markUserAsAttendee()` (transacción Firestore: comprueba aforo antes de escribir)
3. Desapuntarse → `removeUserAsAttendee()`
4. Sugerir evento → estado `pending` hasta revisión staff

**Flujo staff**:
1. Crear evento directo (activo de inmediato)
2. Aprobar / rechazar sugerencias
3. Editar título, descripción, fecha, lugar, aforo, estado (activo ↔ inactivo)
4. Eliminar evento

**Transacción de aforo** — evita race conditions:
```dart
FirebaseFirestore.instance.runTransaction((tx) async {
  final doc = await tx.get(eventRef);
  final current = List<String>.from(doc['attendeeIds']);
  if (current.length >= doc['maxAttendees']) throw 'Aforo completo';
  if (current.contains(userId)) throw 'Ya apuntado';
  tx.update(eventRef, {'attendeeIds': FieldValue.arrayUnion([userId])});
});
```

---

### 5. Notificaciones

**Archivos**: `notification_service.dart`, `notifications_page.dart`

**Tipos**: `like` · `match` · `message`

```
NotificationService.send(toUserId, type, fromUserId, fromName, ...)
  └── Firestore: notifications/{docId}

NotificationsPage
  ├── StreamBuilder(streamForUser(uid))   → lista en tiempo real
  ├── Dismissible por notificación        → deleteNotification(docId)
  └── Botón delete_sweep                  → deleteAllForUser(uid) (batch)
```

Contador de no leídas: `unreadCountStream(uid)` — stream de Firestore con filtro `read == false`.

---

### 6. Horarios de clase (Staff)

**Archivos**: `schedule_service.dart`, `staff_schedule_page.dart`

**Ciclos disponibles**: DAM, DAW, ASIX, SMX, AU, IDMN, HB, MP, EDI (con nombre completo en UI)

```
Staff sube imagen
  ├── SupabaseService.uploadImage('class-schedules/{className}.jpg')
  └── Firestore: class_schedules/{className} {scheduleImageUrl, updatedAt}

Staff elimina imagen
  ├── SupabaseService.deleteImage('class-schedules/{className}.jpg')
  └── Firestore: .update({scheduleImageUrl: FieldValue.delete()})

Usuario consulta (StreamBuilder en Perfil)
  └── watchScheduleImageUrl(_scheduleKey) → URL | null
```

---

## Servicios — Referencia rápida

| Servicio | Singleton | Responsabilidad principal |
|---|---|---|
| `AuthService` | factory | Registro, login, logout, lookup de usuario |
| `ProfileService` | `.instance` | CRUD perfil, incremento de contadores (likes, amigos, actividades) |
| `ChatService` | — | Crear/obtener chats, enviar mensajes, streams |
| `EventService` | — | CRUD eventos, asistencia atómica, flujo de aprobación |
| `NotificationService` | `.instance` | Enviar, leer, marcar, borrar notificaciones |
| `ScheduleService` | `.instance` | Gestión de imágenes de horario por ciclo |
| `SupabaseService` | `.instance` | Upload/delete de imágenes en Supabase Storage |
| `InteractionService` | — | Registro likes/passes, detección de match mutuo |
| `PresenceService` | `.instance` | Presencia online/offline en Firestore |
| `TutorCodeService` | — | Generar/validar códigos de registro de 24 h |
| `UserModerationService` | — | Bloqueo/desbloqueo de cuentas |

---

## Colecciones Firestore

| Colección | Documento | Campos clave |
|---|---|---|
| `users` | `{uid}` | displayName, email, photoURL, course, clase, gender, age, type, blockedBy[], likes, friends, activities, gallery[], interests[], interestsDetail, twitter, instagram, tiktok, spotify |
| `interactions` | `{autoId}` | fromUserId, toUserId, type ('like'·'pass'), createdAt |
| `chats` | `{chatId}` | participantIds[], lastMessage, updatedAt |
| `messages` | `{chatId}/messages/{msgId}` | senderId, text, createdAt, read |
| `events` | `{eventId}` | title, description, dateTime, location, maxAttendees, attendeeIds[], status, staffOrganizerId, suggestedByUserId |
| `notifications` | `{autoId}` | toUserId, fromUserId, fromName, fromPhotoUrl, type, preview, read, createdAt |
| `class_schedules` | `{className}` | className, scheduleImageUrl, updatedAt |
| `support_messages` | `{autoId}` | fromEmail, subject, message, read, status, createdAt |
| `tutor_codes` | `config` | code, generatedAt, expiresAt, generatedBy |

---

## Rutas nombradas

| Ruta | Widget | Acceso |
|---|---|---|
| `/splash` | `PortalAuth` | Todos |
| `/login` | `LoginPage` | No autenticado |
| `/register` | `RegistroScreen` | No autenticado |
| `/profile-setup` | `ProfileSetupPage` | Recién registrado |
| `/home` | `HomePage` | `type == 'user'` |
| `/homestaff` | `HomeStaffPage` | `type == 'staff'` |
| `/settings` | `SettingsScreen` | Autenticado |
| `/like` | `LikesPage` | `type == 'user'` |

---

## Almacenamiento Supabase

| Bucket / Ruta | Contenido |
|---|---|
| `profile-photos/{uid}.jpg` | Avatar de perfil |
| `gallery/{uid}/photo_{ts}.jpg` | Fotos de galería del perfil |
| `class-schedules/{className}.jpg` | Imagen del horario de clase |

---

## Presencia online

`PresenceService` escucha `FirebaseAuth.authStateChanges()` en `main.dart`:
- Login → `init()` → escribe `{online: true, lastSeen}` en `users/{uid}`
- Logout / app close → `deactivate()` → escribe `{online: false, lastSeen: now}`

---

## Decisiones de diseño relevantes

### Campos `clase` y `course` en el perfil
- `course`: nombre completo del ciclo (ej. `'DAM - Desarrollo de Aplicaciones Multiplataforma'`). Es el campo que edita el usuario desde el dropdown.
- `clase`: código corto del ciclo (ej. `'DAM'`). Derivado automáticamente de `course` al guardar. Se usa como clave en `class_schedules`.
- Si `course` es null, se usa `clase` como fallback (compatibilidad con cuentas antiguas).

### Swipe cards y normalización de datos
- `_mapDocToProfile()` sanitiza edad, fotos y bio antes de construir la tarjeta.
- Se excluyen usuarios `staff`, bloqueados y con interacciones previas.

### Transacciones de aforo
- `markUserAsAttendee()` usa `runTransaction()` para evitar que dos usuarios se apunten simultáneamente cuando queda una plaza.

### Notificaciones
- No se usa FCM (push nativo). Las notificaciones son documentos Firestore consultados en tiempo real desde `NotificationsPage` y el badge de la barra de navegación.

---

## Cómo reportar bugs

Ver `lib/core/doc/crashes/README.md`.

Resumen:
1. Identifica pantalla, acción y error
2. Copia `CRASH_LOG_TEMPLATE.md` → renombra como `CRASH_LOG_YYYYMMDD.md`
3. Rellena los campos
4. Si ya está resuelto, añade la entrada a `RESOLVED_ISSUES.md`
