# Documentación de Crashes y Errores - RockMeet

## Propósito

Esta carpeta contiene registros de errores, crashes y incidencias encontradas durante la presentación, pruebas y desarrollo de la aplicación RockMeet. Sirve como historial para:

- Documentar bugs reportados
- Rastrear problemas resueltos
- Identificar patrones de fallos
- Mejorar la estabilidad de versiones futuras

## Estructura

```
lib/core/doc/crashes/
├── README.md                          # Este archivo
├── CRASH_LOG_TEMPLATE.md              # Plantilla para reportar nuevos crashes
├── CRASH_LOG_<FECHA>.md               # Registros de crashes por sesión/fecha
└── RESOLVED_ISSUES.md                 # Problemas resueltos
```

## Cómo reportar un crash o error

### 1. Rápido (en presentación/demo)

Si encuentras un error durante la presentación:

1. Toma nota mental del:
   - Pantalla donde ocurrió
   - Acción que lo disparó
   - Mensaje de error (si lo hay)
   - Dispositivo/plataforma (web, Android, iOS)

2. Después de la presentación, abre `CRASH_LOG_<HOY>.md` y añade una entrada con:
   - Timestamp
   - Descripción del bug
   - Pasos para reproducir
   - Impacto (crítico, alto, medio, bajo)

### 2. Completo (durante desarrollo)

Si encuentras un crash:

1. Copia el contenido de `CRASH_LOG_TEMPLATE.md`
2. Crea un archivo nuevo en formato `CRASH_LOG_YYYY-MM-DD.md` (si no existe)
3. Rellena toda la información:
   - Fecha y hora exacta
   - Stacktrace (si puedes copiar from console/logcat)
   - Pasos para reproducir
   - Archivos implicados
   - Posible causa
   - Estado (open, in-progress, resolved)
   - Fix aplicado (si ya está resuelto)

## Ejemplo de entrada rápida

```markdown
## 🔴 CRÍTICO - Home: Crash al cargar perfiles

**Fecha**: 2026-04-16 14:32  
**Plataforma**: Web (Chrome)  
**Pantalla**: HomePage  
**Acción**: Scrollar para cargar más perfiles  
**Error**: `RangeError: Index out of bounds`  
**Resolución**: Agregué validación de fotos vacías en _mapDocToProfile

**Estado**: ✅ Resuelto
```

## Niveles de severidad

| Nivel | Descripción | Ejemplo |
|-------|-------------|---------|
| 🔴 CRÍTICO | Aplicación se cuelga o es imposible continuar | Crash en login, pantalla negra, pérdida de datos |
| 🟠 ALTO | Funcionalidad principal no funciona | Match fallido, chat no carga, evento no se crea |
| 🟡 MEDIO | Funcionalidad secundaria o UX afectada | Detalle visual roto, feedback tardío |
| 🔵 BAJO | Cosmético o issue menor | Tipografía, espaciado, animación lenta |

## Archivos relacionados

- **CRASH_LOG_TEMPLATE.md**: Plantilla detallada para reportar crashes
- **RESOLVED_ISSUES.md**: Seguimiento de bugs ya solucionados
- **../architecture/**: Documentación de módulos y servicios
- **firestore.rules**: Reglas de seguridad de Firestore (afectan permisos)

## Checklist de presentación

Antes de una presentación/demo, revisa:

- [ ] No hay crashes conocidos en CRASH_LOG_<HOY>.md sin resolver
- [ ] Todos los validaciones están en lugar (eventos, fotos, datos)
- [ ] Feedback visual (SnackBars) funciona en web
- [ ] Match, chat y perfil cargan correctamente
- [ ] Transacciones de eventos son seguras (no doble-inscripción)

## Contacto

Si encuentras un crash que no sabes cómo reportar, añade un entry con lo que tengas. Es mejor documentar parcialmente que no documentar.

---

**Última actualización**: 2026-04-16  
**Mantenedor**: Equipo RockMeet
