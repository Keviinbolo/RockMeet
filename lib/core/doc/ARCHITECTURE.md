# Documentación de Arquitectura - RockMeet MVP

## Estructura Modular

RockMeet sigue una arquitectura **feature-based** con separación clara entre capas compartidas (core) y módulos funcionales (features).

```
lib/
├── core/                         # Servicios y utilidades globales
│   ├── services/
│   │   ├── auth_service.dart    # Autenticación y sesión
│   │   ├── chat_service.dart    # Mensajería en tiempo real
│   │   ├── event_service.dart   # Eventos (CRUD + transacciones)
│   │   ├── profile_service.dart # Datos de perfil
│   │   └── portal_auth.dart     # Enrutamiento por tipo (staff/user)
│   │
│   ├── widgets/
│   │   └── match_animation_widget.dart  # Componentes reutilizables
│   │
│   ├── theme/
│   │   ├── app_theme.dart       # Tema global
│   │   └── constants/
│   │       ├── colors.dart      # Paleta de colores
│   │       └── text_styles.dart # Estilos de texto
│   │
│   └── doc/                     # DOCUMENTACIÓN TÉCNICA
│       └── crashes/             # 📋 Reporte de errores
│           ├── README.md        # Instrucciones para reportar
│           ├── CRASH_LOG_TEMPLATE.md  # Plantilla de reporte
│           └── RESOLVED_ISSUES.md     # Bugs resueltos
│
├── config/
│   ├── Routes/
│   │   └── approutes.dart       # Definición de rutas
│   └── Theme/
│       └── constants/     # Constantes de diseño
│
└── features/                    # MÓDULOS DE FUNCIONALIDAD
    ├── auth/
    │   ├── screens/
    │   │   ├── login.dart
    │   │   ├── registro_page.dart
    │   │   └── pantalla_splash.dart
    │   └── services/ (si aplica)
    │
    ├── home/
    │   ├── screens/
    │   │   ├── home_page.dart   # ⭐ Matching principal
    │   │   └── home_staff_page.dart
    │   └── widgets/
    │
    ├── chat/
    │   ├── screens/
    │   │   └── chat_page.dart
    │   └── class_chat.dart
    │
    ├── profile/
    │   ├── screens/
    │   │   └── Perfil.dart      # Edición y visualización
    │   └── interest_screen.dart
    │
    ├── events/
    │   ├── screens/
    │   │   └── event_screen.dart # ⭐ Eventos públicos
    │   ├── class_event.dart
    │   └── staff_events.dart
    │
    ├── like/
    │   └── screens/
    │       └── like_page.dart
    │
    ├── settings/
    │   └── screens/
    │       └── ajustes.dart      # Settings y logout
    │
    └── stubs/  # Pantallas temporales/pendientes
```

## Flujos Principales

### 1. Matching & Likes (Home Page)

**Archivo**: `lib/features/home/screens/home_page.dart`  
**Servicios**: `ChatService`, `AuthService`, Firestore directo

**Flujo**:
1. Cargar lista de usuarios tipo `user` desde Firestore (excluye `staff`)
2. Renderizar un usuario por vez en tarjeta swipeable
3. **Swipe derecha** (like):
   - Guardar en colección `interactions` con `{fromUserId, toUserId, type: 'like'}`
   - Comprobar si existe match mutuo (¿otro usuario también me dio like?)
   - Si hay match: crear chat directo automáticamente
   - Mostrar modal de celebración
4. **Swipe izquierda** (pass):
   - Guardar en colección `interactions` con `type: 'pass'`

**Validaciones aplicadas**:
- Edad: sanitizada y acotada a 18-99
- Fotos: con fallback a imagen por defecto si URL inválida
- Bio: limitada a 6 líneas con ellipsis
- Usuarios staff: excluidos de búsqueda
- Interacciones previas: filtradas para no repetir

**Métodos clave**:
- `_mapDocToProfile()` - Mapeo seguro de Firestore a modelo Profile
- `_handleLike()` - Lógica de like y match mutuo
- `_isMutualLike()` - Comprobación de match
- `_prepareChatForMatch()` - Creación de chat

---

### 2. Eventos (Event Screen)

**Archivos**: 
- Frontend: `lib/features/events/screens/event_screen.dart`
- Backend: `lib/core/services/event_service.dart`

**Flujo de usuario normal**:
1. Crear evento sugerido → enviado a staff para aprobación
2. Ver eventos públicos activos y próximos
3. **Apuntarse a evento**:
   - Validación de aforo (dentro de transacción Firestore)
   - Agregar userId a `attendeeIds[]` (atómico)
   - Feedback de éxito/error

**Flujo de staff/monitor**:
1. Ver eventos sugeridos pendientes
2. Aprobar, rechazar o eliminar sugerencias
3. Crear evento directo (activo de inmediato)
4. Editar, activar, desactivar o cancelar eventos

**Validaciones aplicadas**:
- Título: mínimo 5 caracteres (trim)
- Descripción: mínimo 10 caracteres
- Fecha: debe ser futura
- MaxAttendees: número válido, entre 1-1000
- **Transacción atómica** en `markUserAsAttendee()`:
  - Lee estado actual
  - Comprueba aforo
  - Escribe nuevo asistente
  - Todo en una transacción Firestore (sin race condition)

**Métodos clave**:
- `createSuggestedEvent()` - Crear evento como sugerencia
- `markUserAsAttendee()` - Apuntarse (CON TRANSACCIÓN)
- `removeUserAsAttendee()` - Desapuntarse
- `_toggleAttendance()` - UI handler con feedback

---

### 3. Perfil (Perfil Page)

**Archivo**: `lib/features/profile/screens/Perfil.dart`  
**Servicio**: `ProfileService`

**Flujo**:
1. Cargar perfil actual desde Firestore
2. Mostrar datos: nombre, bio, avatar, galería (3 fotos), intereses, stats
3. En modo edición:
   - Cambiar avatar (selector predefinio de imágenes)
   - Editar nombre, bio, redes sociales (twitter, instagram, tiktok)
   - Seleccionar intereses
   - Cambiar galería (subir/cambiar up a 3 fotos)
4. Guardar cambios en tiempo real a Firestore

**Validaciones aplicadas**:
- Nombre: fallback a "Usuario" si vacío
- Bio: fallback a texto guía si vacío
- Stats (likes, matches, activities): normalizadas a "0" si nulas
- Imágenes: con loadingBuilder y errorBuilder (muestra ícono si falla)
- Solo acceso de lectura/escritura al propio perfil

**Métodos/Helpers clave**:
- `_safeStatValue()` - Normalizar stats nulos a "0"
- `_textOrFallback()` - Texto seguro con fallback
- `_loadProfileFromFirestore()` - Hidratación desde Firestore

---

## Services (Capa de Lógica)

### AuthService
**Ubicación**: `lib/core/services/auth_service.dart`

Responsabilidades:
- Registro y login con email/password
- Gestión de sesión actual (Firebase Auth)
- Lectura de tipo de usuario (`staff` o `user`)
- Logout

Métodos públicos:
- `register(email, password, displayName)`
- `login(email, password)`
- `logout()`
- `getUserTypeById(uid)` - Retorna tipo para enrutamiento
- `getUserDataById(uid)`

---

### ChatService
**Ubicación**: `lib/core/services/chat_service.dart`

Responsabilidades:
- Crear/obtener chats directos entre usuarios
- Guardar mensajes
- Streams en tiempo real para conversaciones

Métodos públicos:
- `ensureDirectChat(currentUserId, peerUid, peerName, peerAvatarUrl)`
- `sendMessage(chatId, message)`
- Getters para streams de chats

---

### EventService
**Ubicación**: `lib/core/services/event_service.dart`

Responsabilidades:
- CRUD de eventos
- Gestión de asistentes (con transacciones)
- Flujo de aprobación staff

Métodos públicos:
- `createEvent()` - Crear evento (staff)
- `createSuggestedEvent()` - Crear como sugerencia (usuario)
- `markUserAsAttendee()` - **Con transacción** para evitar race conditions
- `removeUserAsAttendee()`
- `approveEvent()`, `rejectEvent()`
- `activateEvent()`, `deactivateEvent()`
- Streams para listar eventos (públicos, pendientes, por staff)

---

### ProfileService
**Ubicación**: `lib/core/services/profile_service.dart`

Responsabilidades:
- CRUD del perfil actual
- Lectura de datos públicos
- Actualización en tiempo real

Métodos públicos:
- `getCurrentUserProfile()`
- `getUserProfileById(uid)`
- `updateCurrentUserProfile()`

---

## Rutas y Navegación

**Archivo**: `lib/config/Routes/approutes.dart`

| Ruta | Pantalla | Tipo de usuario |
|------|----------|-----------------|
| `/splash` | Pantalla de carga | Todos |
| `/login` | Login/Registro | No autenticado |
| `/home` | Home con matching | Usuario normal |
| `/homestaff` | Panel de staff | Staff |
| `/chat` | Chat | Autenticado |
| `/perfil` | Perfil | Autenticado |
| `/eventos` | Listado de eventos | Todos |
| `/ajustes` | Configuración | Autenticado |

**Enrutamiento por tipo de usuario**:
- `PortalAuth` en `main.dart` comprueba sesión y tipo
- Staff → `/homestaff`
- Usuario normal → `/home`
- Sin sesión → `/login`

---

## Colecciones Firestore

| Colección | Documentos | Propósito |
|-----------|-----------|----------|
| `users` | {uid: {...}} | Perfiles, datos públicos |
| `interactions` | {id: {fromUserId, toUserId, type}} | Likes y passes (matching) |
| `chats` | {chatId: {...}} | Conversaciones directas |
| `messages` | {messages: {msgId: {...}}} | Mensajes dentro de chats |
| `events` | {eventId: {...}} | Eventos públicos y sugerencias |

---

## Mejoras Aplicadas para MVP

### Blindagem de datos y UX
1. **Imágenes robustas**: loadingBuilder + errorBuilder en todos los Image.network()
2. **Datos normalizados**: Edad validada, stats seguros, texto con fallbacks
3. **Bio limitada**: maxLines con ellipsis para evitar desbordes

### Eventos robustos
1. **Validaciones completas**: título, descripción, fecha, maxAttendees
2. **Transacciones atómicas**: Aforo seguro sin race conditions
3. **Feedback claro**: SnackBars específicos para cada error

### Documentación de errores
1. **Carpeta `lib/core/doc/crashes/`**:
   - `README.md`: Guía de reporte
   - `CRASH_LOG_TEMPLATE.md`: Plantilla para nuevos crashes
   - `RESOLVED_ISSUES.md`: Historial de bugs solucionados
2. **Fácilmente extensible**: Añadir nueva entrada sin cambiar código

---

## Cómo Reportar Bugs o Crashes

Ver `lib/core/doc/crashes/README.md` para instrucciones completas.

**Resumen rápido**:
1. Nota mental del bug (pantalla, acción, error)
2. Abre `lib/core/doc/crashes/CRASH_LOG_TEMPLATE.md`
3. Rellena los campos (o alguien lo hace después)
4. Guarda como `CRASH_LOG_<FECHA>.md`
5. Si está resuelto, añade a `RESOLVED_ISSUES.md`

---

**Última actualización**: 2026-04-16  
**Versión**: MVP  
**Status**: Listo para presentación web
