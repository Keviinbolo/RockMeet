# Issues Resueltos - RockMeet

Este archivo registra bugs y errores que ya han sido solucionados. Sirve como referencia para evitar regresiones.

## Historial de resoluciones

### 2026-04-16

#### ✅ Tarjetas de perfil sin fallback de imagen
**Severidad**: Alto  
**Fecha reportado**: 2026-04-16  
**Fecha resuelto**: 2026-04-16  

**Problema**: Si una URL de foto era inválida o fallaba la carga, la tarjeta se rompía o mostraba espacio en blanco.

**Solución**: 
- Agregué `loadingBuilder` y `errorBuilder` en `Image.network()` para [lib/features/home/screens/home_page.dart](../../features/home/screens/home_page.dart)
- Agregué fallback de foto por defecto si todas las URLs son inválidas
- Implementé lo mismo en perfil [lib/features/profile/screens/Perfil.dart](../../features/profile/screens/Perfil.dart)

**Archivos**:
- `lib/features/home/screens/home_page.dart` (lines 1130-1150)
- `lib/features/profile/screens/Perfil.dart` (avatar, galería)

---

#### ✅ Stats de perfil mostrando "null" string
**Severidad**: Bajo  
**Fecha reportado**: 2026-04-16  
**Fecha resuelto**: 2026-04-16  

**Problema**: Likes, matches y activities mostraban "null" en la pantalla de perfil si el dato no existía en Firestore.

**Solución**: 
- Agregué helper `_safeStatValue()` que normaliza valores nulos a "0"
- Implementé en setState al mapear datos de Firestore y en widget StatCard

**Archivos**:
- `lib/features/profile/screens/Perfil.dart` (lines 117-124, 353-376)

---

#### ✅ Bio larga desbordaba tarjeta de usuario
**Severidad**: Medio  
**Fecha reportado**: 2026-04-16  
**Fecha resuelto**: 2026-04-16  

**Problema**: Si bio tenía mucho texto, se desbordaba de la tarjeta y rompía el layout.

**Solución**: 
- Agregué `maxLines: 6` y `overflow: TextOverflow.ellipsis` al widget Text de bio
- Limitó visualmente el contenido sin perder información (mostrar "...")

**Archivos**:
- `lib/features/home/screens/home_page.dart` (lines 1145-1150)

---

#### ✅ Edad inválida o fuera de rango en perfiles
**Severidad**: Medio  
**Fecha reportado**: 2026-04-16  
**Fecha resuelto**: 2026-04-16  

**Problema**: Perfiles podían mostrar edades negativas, 999, o valores no realistas si los datos en Firestore eran inválidos.

**Solución**: 
- Agregué validación en `_mapDocToProfile()` para acotar edad entre 18 y 99
- Si es inválido o no parseable, defaultea a 18
- Muestra edad segura en bio

**Archivos**:
- `lib/features/home/screens/home_page.dart` (lines 62-115)

---

#### ✅ Race condition en presionar dos veces "apuntarse a evento"
**Severidad**: Crítico  
**Fecha reportado**: 2026-04-16  
**Fecha resuelto**: 2026-04-16  

**Problema**: Si dos usuarios (o el mismo usuario presionando dos veces rápido) se apuntaban a un evento con aforo, ambos podían entrar aunque el evento tuviera cupo para solo 1.

**Solución**: 
- Convertí `markUserAsAttendee()` de operación secuencial read-check-write a **transacción Firestore atómica**
- Usa `_firestore.runTransaction()` para asegurar que la capacidad check y la escritura sean indivisibles
- Incluso si dos requests llegan casi simultáneamente, el segundo falla con "El evento está lleno"

**Archivos**:
- `lib/core/services/event_service.dart` (lines 130-165)

---

#### ✅ Validación insuficiente al crear eventos
**Severidad**: Medio  
**Fecha reportado**: 2026-04-16  
**Fecha resuelto**: 2026-04-16  

**Problema**: Usuario podía crear evento con:
- Título vacío o solo espacios
- Descripción vacía o muy corta
- Fecha en el pasado
- maxAttendees inválido, negativo, o que causaba crash

**Solución**: 
- Agregué validaciones completas en `_showCreateEventDialog()`:
  - Trim() de campos para evitar espacios en blanco aislados
  - Validación de longitud mínima (título 5+, descripción 10+)
  - Validación de que la fecha sea futura
  - Try-catch en parse de maxAttendees
  - Rango válido para maxAttendees (1-1000)
- Try-catch envolviendo la llamada a `createSuggestedEvent()`
- Feedback claro de error para cada validación fallida

**Archivos**:
- `lib/features/events/screens/event_screen.dart` (lines 320-385)

---

#### ✅ Sin feedback al crear evento sugerido
**Severidad**: Medio  
**Fecha reportado**: 2026-04-16  
**Fecha resuelto**: 2026-04-16  

**Problema**: Si `createSuggestedEvent()` fallaba, el usuario no recibía feedback de error; solo veía que el diálogo se cerraba.

**Solución**: 
- Envuelto la llamada en try-catch
- Agregué `_showSnackBar()` con mensaje de error si falla la creación
- Agregué `if (!mounted) return;` después de await antes de navegar/mostrar feedback

**Archivos**:
- `lib/features/events/screens/event_screen.dart` (lines 375-388)

---

#### ✅ Feedback genérico en apuntarse/desapuntarse de eventos
**Severidad**: Bajo  
**Fecha reportado**: 2026-04-16  
**Fecha resuelto**: 2026-04-16  

**Problema**: Cuando `_toggleAttendance()` fallaba, mostraba el stacktrace completo como error, poco user-friendly.

**Solución**: 
- Mejoré error parsing para identificar mensaje específico ("lleno", "no encontrado", etc)
- Mostrar mensaje amigable al usuario en lugar de stacktrace técnico

**Archivos**:
- `lib/features/events/screens/event_screen.dart` (lines 61-75)

---

## Estadísticas

| Período | Critical | Alto | Medio | Bajo | Total |
|---------|----------|------|-------|------|-------|
| 2026-04-16 | 1 | 2 | 4 | 1 | 8 |

---

## Impacto por área

- **Tarjetas & Perfil**: 4 issues (imagenes, stats, overflow, edad)
- **Eventos**: 3 issues (validación, race condition, feedback)
- **General**: 1 issue (arquitectura, feedback)

---

## Notas de mantenimiento

- Revisar regularmente que no haya re-introducción de estos bugs
- Si encuentra patrón similar, revisar esta lista
- Considerar agregar unit tests para evitar regresiones

---

**Última actualización**: 2026-04-16  
**Próxima revisión**: Después de cada sesión de prueba
