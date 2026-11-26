# 06 — Spec Completo y Hoja de Ruta (`Power Habits`)

**Repositorio GitHub:** `https://github.com/danibits9920/power-habits`  
**Diseño aprobado (Stitch v2 — Soft Glass Minimal):** https://stitch.withgoogle.com/projects/2943801740701979031  
**Sistema de diseño:** [DESIGN.md](./DESIGN.md) y [MASTER.md](../design-system/mis-habitos/MASTER.md)

---

## 1. Propuesta de nombre
- **Elegido:** **Power Habits** (`power-habits`, package `com.daltex.power_habits`) — claro, memorable y coherente con el contraste minimalista + energía del verde fosforescente.
- **Alternativas registradas** *(por si decides cambiar nombre comercial más adelante)*:
  1. **Pulso** — minimalista en español, evoca ritmo diario constante.
  2. **Cadencia** — transmite disciplina sostenida sin presión punitiva.

---

## 2. Alcance definitivo implementado en v0.1.0 (Beta 1 + Beta 2 completas + Auto-Update)

| Código | Capacidad | Detalle de aceptación |
| :--- | :--- | :--- |
| **Core** | **Vista Hoy unificada** | Selector `[ Todo | Personal | Laboral ]`, tira semanal de días, barra de progreso del día en verde fosforescente `#6BFF3B`, bloques *Mañana / Tarde / Noche / Sin hora*, tarjetas glass de máx. 2 líneas. |
| **A** | **Rutinas con frecuencias flexibles** | Ilimitadas; soporta `Diaria`, `Interdiaria (cada 2 días desde anchor_date)` y `Días específicos (L–D)`. Si hoy no toca, no aparece en Hoy. |
| **B** | **Múltiples recordatorios locales** | Varias horas por rutina/tarea (`flutter_local_notifications` + `timezone`), con acciones rápidas en Android (*Marcar hecho* / *Posponer 30 min*). |
| **C** | **Historial visual mensual** | Selector por rutina + cuadrícula mensual de 7 columnas distinguiendo días cumplidos (`#6BFF3B`), pendientes y días que no tocaban. |
| **D** | **Estadísticas Personal vs. Laboral** | Porcentaje real semanal/mensual separado entre **Personal** y **Laboral** calculado sobre días programados (sin penalizar días de descanso). |
| **E** | **Metas por unidades y línea de progreso** | Curso de N clases (`14/30`), línea horizontal con hitos `0/25/50/75/100 %`, botón rápido `+1` y pasos/clases nombrados opcionales. |
| **F** | **Notas rápidas al completar** | Nota breve de 1 línea opcional por día/rutina visible en la tarjeta y en el historial. |
| **G** | **Widget Android 4×2** | Widget nativo Soft Glass con progreso del día, lista rápida de rutinas pendientes y acceso directo a la app. |
| **Logros** | **Línea de tiempo de logros** | Combina hitos automáticos (25/50/75/100 % de metas, 7 días constantes en una rutina) + logros manuales creados por el usuario. |
| **OTA** | **Auto-actualización desde `main`** | Revisa `danibits9920/power-habits` Releases al iniciar y desde Ajustes, descarga el APK `arm64` con progreso y lanza el instalador Android vía `FileProvider` + `MethodChannel` + CI/CD en GitHub Actions. |
| **Backup** | **Respaldo local JSON** | Exportar e importar toda la base local en 1 toque antes de Fase 3 (Supabase). |

---

## 3. Hoja de ruta y distribución en paralelo (4 Agentes + 1 Orquestador Juez)

### Fase 0 — Fundación (Coordinador)
- Crear repo público `danibits9920/power-habits` y subir documentación + `DESIGN.md` + `MASTER.md`.
- Inicializar proyecto Flutter `app/` (`com.daltex.power_habits`), empaquetar fuentes `Outfit` y `Work Sans`, configurar Drift SQLite Supabase-ready (`lib/data/db.dart` + `db.g.dart`), repositorios base (`lib/data/repos.dart`), tokens de diseño (`lib/design/tokens.dart`) y contratos compartidos (`lib/core/providers.dart`).
- Verificar `flutter analyze` + `flutter test` en `main` antes de abrir ramas paralelas.

### Fase 1 — Implementación paralela en ramas independientes
Cada agente trabaja en su propio workspace compartido (`git worktree` / rama `feat/*`) sobre la fundación de `main`, con propiedad exclusiva de archivos para evitar conflictos:

1. **Agente 1 (`feat/shell-design`) — Design System Glass & App Shell**
   - `lib/design/glass.dart`, `lib/design/primitives.dart`, `lib/core/router.dart`, `lib/app.dart`, `lib/main.dart`, `test/widget_smoke_test.dart`.
   - Implementa el look **Soft Glass Minimal** (`ui-ux-pro-max`), fondo atmosférico blanco/gris + velo rosado pastel, navegación flotante (`Hoy`, `Metas`, `Progreso`), tema Claro y Oscuro, y pruebas de humo.

2. **Agente 2 (`feat/hoy-rutinas`) — Vista Hoy, Rutinas (A), Tareas y Notas (F)**
   - `lib/features/today/` (`frequency_logic.dart`, `today_page.dart`, `routine_form_sheet.dart`, `task_form_sheet.dart`, `note_sheet.dart`) + `test/frequency_logic_test.dart`.
   - Implementa filtrado `Todo | Personal | Laboral`, tira de días, lógica exacta de frecuencias (`daily`, `alternate`, `weekdays`, `once`), bloques horarios, notas rápidas y desbloqueo de logro de 7 días constantes.

3. **Agente 3 (`feat/metas-progreso`) — Metas (E), Calendario (C), Estadísticas (D) y Logros**
   - `lib/features/goals/` (`goals_page.dart`, `goal_form_sheet.dart`, `goal_detail_sheet.dart`) + `lib/features/progress/` (`progress_page.dart`, `monthly_calendar_card.dart`, `context_stats_card.dart`, `achievements_timeline.dart`, `achievement_form_sheet.dart`) + `test/goals_progress_test.dart`.
   - Implementa metas por unidades, línea de hitos `0/25/50/75/100 %`, pasos nombrados opcionales, desbloqueo automático de hitos, calendario mensual interactivo, métricas Personal vs. Laboral y línea de tiempo de logros.

4. **Agente 4 (`feat/sistema-android`) — Recordatorios (B), Auto-Updater (`main`), Widget (G), Backup y CI/CD**
   - `lib/core/notifier.dart`, `lib/core/updater.dart`, `lib/core/home_widget.dart`, `lib/data/backup.dart`, `lib/features/settings/settings_page.dart`, `android/app/src/main/kotlin/com/daltex/power_habits/` (`MainActivity.kt`, `PowerHabitsWidgetProvider.kt`), `android/app/src/main/res/` (layout XML, drawables, `file_paths.xml`), `.github/workflows/release.yml`, `test/updater_backup_test.dart`.

### Fase 2 — Auditoría, Integración y Veredicto Autónomo (`Agente Orquestador / Juez`)
- El **Agente Orquestador / Juez** revisa cada rama contra:
  1. Spec funcional A–G + Logros + Auto-Updater + Backup.
  2. Reglas `ui-ux-pro-max` (WCAG ≥ 4.5:1, cero emojis estructurales, áreas táctiles 48dp, sin hex hardcodeados).
  3. Calidad de código y cobertura de tests.
- Resuelve autónomamente cualquier hallazgo (o exige/aplica correcciones), integra las 4 ramas en orden a `main`, conecta los puntos de integración (router final, sync del widget al cambiar DB, arranque del updater y permisos de notificación), corre `flutter analyze`, `flutter test` y compila el APK release (`arm64`) para verificar compilación real.
- Emite un acta final de aprobación en `docs/07-veredicto-orquestador.md`.

### Fase 3 — Publicación final en GitHub
- Push de la versión aprobada a `main`, creación de tag/release `v0.1.0` con el APK `arm64` adjunto en GitHub Releases para que el auto-updater quede operativo desde el primer lanzamiento.

### Fase 4 (Futuro) — Evolución a Supabase
- Añadir `SupabaseSyncService` sobre los repositorios y esquema UUID ya implementado, sin reescribir la UI.
