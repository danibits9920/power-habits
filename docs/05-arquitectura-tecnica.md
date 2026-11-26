# 05 — Arquitectura técnica (`Power Habits`)

> Documento técnico oficial para **Power Habits** (`com.daltex.power_habits`), alineado con el stack probado de *Mis Finanzas* en Flutter 3.50 / Dart 3.14 y listo para evolucionar de Local-First a Supabase.

## Stack confirmado (verificado en entorno local)

- **Framework:** Flutter 3.50.0 / Dart 3.14.0 (Android primero, `arm64-v8a`).
- **Estado y DI:** `flutter_riverpod` (`^3.4.3`).
- **Navegación:** `go_router` (`^18.1.2`) con shell persistente de 3 pestañas (`Hoy`, `Metas`, `Progreso`) + ruta `/ajustes`.
- **Base de datos Local-First (Beta):** `drift` (`^2.35.3`) + `drift_flutter` (`^0.3.1`) sobre SQLite local.
- **Íconos y Tipografía:** `lucide_icons_flutter` (`^4.0.1`, trazo uniforme, cero emojis estructurales) + fuentes **Outfit** y **Work Sans** empaquetadas localmente en `assets/fonts/` *(evitamos `google_fonts` por incompatibilidad conocida con Flutter 3.47+).*
- **Recordatorios locales (B):** `flutter_local_notifications` (`^22.3.3`) + `timezone` con programación por hora exacta y acciones rápidas (*Hecho* / *Posponer 30 min*).
- **Auto-actualización desde `main`:** `dio` (`^5.11.1`) consultando `https://api.github.com/repos/danibits9920/power-habits/releases/latest` + `MethodChannel('com.daltex.power_habits/updater')` en `MainActivity.kt` + `FileProvider` + `REQUEST_INSTALL_PACKAGES`, replicando el flujo probado de *Mis Finanzas*.
- **Widget Android 4×2 (G):** `PowerHabitsWidgetProvider.kt` (`AppWidgetProvider`) + `MethodChannel('com.daltex.power_habits/widget')` con actualización inmediata al marcar hábitos y toques directos a la app.
- **Respaldo en Beta:** Exportar e importar backup completo JSON (`file_picker` + `share_plus` + `path_provider`).
- **CI/CD en GitHub (`main`):** `.github/workflows/release.yml` corre `flutter analyze`, `flutter test`, compila APK `arm64` firmado y publica GitHub Release (`v<version>`) en cada lanzamiento a `main`.

## Esquema SQLite / Drift ("Supabase-ready" desde el día 1)

Todas las tablas usan **UUID v4** (`id TEXT PRIMARY KEY`), `created_at` (ISO-8601 UTC), `updated_at` (ISO-8601 UTC) y `deleted_at` (nullable, soft-delete):

1. **`routines`** — Rutinas recurrentes y tareas puntuales:
   - `id`, `title`, `item_type` (`routine` | `task`), `context` (`personal` | `work`), `time_slot` (`morning` | `afternoon` | `night` | `anytime`), `frequency_type` (`daily` | `alternate` | `weekdays` | `once`), `weekdays_mask` (CSV ej. `1,3,5`), `anchor_date` (`YYYY-MM-DD`, base para frecuencia interdiaria o fecha de tarea puntual), `reminder_times` (CSV ej. `06:45,17:30`), `allow_quick_note` (bool), `sort_order`, `created_at`, `updated_at`, `deleted_at`.
2. **`routine_logs`** — Registro diario de cumplimiento y notas rápidas (F):
   - `id`, `routine_id` (FK), `log_date` (`YYYY-MM-DD`), `completed` (bool), `note` (nullable text), `completed_at`, `created_at`, `updated_at`, `deleted_at`. *(Índice único lógico por `routine_id + log_date`).*
3. **`goals`** — Metas por unidades con línea de progreso (E):
   - `id`, `title`, `context` (`personal` | `work`), `unit_label` (ej. `clases`, `salidas`, `módulos`), `current_value` (int), `target_value` (int), `milestones_unlocked` (CSV ej. `25,50`), `created_at`, `updated_at`, `deleted_at`.
4. **`goal_steps`** — Pasos/clases nombrados opcionales de una meta (E):
   - `id`, `goal_id` (FK), `step_index` (int), `title`, `completed` (bool), `note`, `completed_at`, `created_at`, `updated_at`, `deleted_at`.
5. **`achievements`** — Línea de tiempo de logros (automáticos + manuales):
   - `id`, `kind` (`auto` | `manual`), `title`, `detail`, `context` (`personal` | `work`), `source_key` (nullable, evita duplicar hitos automáticos como `goal:<id>:50`), `achieved_date` (`YYYY-MM-DD`), `created_at`, `updated_at`, `deleted_at`.
6. **`app_settings`** — Preferencias locales (tema claro/oscuro, permisos pedidos, última versión vista):
   - `key TEXT PRIMARY KEY`, `value TEXT`, `updated_at`.

## Seguridad de firma APK (lección de *Mis Finanzas*)
- Para actualizar el APK instalado en Android sin desinstalar ni perder datos SQLite, **todos los builds deben firmarse con la misma clave**.
- En local se usa el `debug.keystore` persistente del equipo (`~/.config/.android/debug.keystore`) o un upload keystore propio (`~/.keystores/power-habits-upload.jks`) respaldado también en GitHub Secrets (`ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`) para que los releases de GitHub Actions mantengan exactamente la misma firma.
