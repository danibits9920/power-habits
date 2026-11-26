# 03 — Decisiones y alcance del MVP

> Registro de decisiones cerradas durante la fase de definición y contraste.

## Decisiones tomadas

| # | Tema | Decisión | Motivo / Contraste descartado | Fecha |
| :--- | :--- | :--- | :--- | :--- |
| 1 | Plataforma principal | **Aplicación móvil primero** (Android / Redmi) | Ejercicio, caminar y skincare pasan lejos de la PC; mejores recordatorios locales y acceso inmediato en el bolsillo. | 2026-11-25 |
| 2 | Terminología y tono | **Lenguaje limpio y real:** *Rutinas*, *Tareas*, *Metas*, *Logros* | Se descartó jerga de videojuego ("misiones"). Los videojuegos son solo inspiración para la *sensación de progreso y logro*, no para la temática visual. | 2026-11-25 |
| 3 | Separación de contextos | **Separar Personal vs. Laboral** | Evita mezclar rutinas personales (skincare, ejercicio) con pendientes de trabajo y da mayor sensación de control. | 2026-11-25 |
| 4 | Frecuencias de rutinas | **Frecuencia flexible** (diaria, interdiaria, días específicos) | Necesidad real desde el día 1 (ej. skincare interdiario, ejercicio ciertos días). | 2026-11-25 |
| 5 | Metas por unidades | **Soporte de progreso por pasos/unidades** (ej. `X / 30 clases`) | Permite ver avance real en estudios/cursos, no solo checkboxes aislados. | 2026-11-25 |
| 6 | Stack móvil | **Flutter (Dart)** | Comodidad de Jesús, rendimiento nativo fluido, excelentes animaciones y experiencia previa en proyectos Flutter. | 2026-11-25 |
| 7 | Persistencia y fases | **Fase Beta: Local-First (SQLite)** → **Fase siguiente: Supabase** | Permite validar y usar la app rápido, 100 % offline y sin fricción de login; el esquema se diseña *Supabase-ready* desde el día 1. | 2026-11-25 |
| 8 | Vista de Hoy | **Selector `[ Todo | Personal | Laboral ]` + bloques Mañana / Tarde / Noche** | Da control inmediato según el momento del día y separa contextos sin cambiar de app. | 2026-11-25 |
| 9 | Alcance completo de funciones | **Incluir A–G completas** (con propuesta de entrega en Beta 1 + Beta 2) | Todas las funciones (A–G) entran en el diseño y prototipo interactivo; dividir la implementación en 2 entregas evita retrasar el uso diario real. | 2026-11-25 |
| 10 | Dinámica de Logros | **Ambos: automáticos + manuales en una sola línea de tiempo** | Combina hitos automáticos (25/50/75/100 %, constancia) con logros personales registrados a mano; ya incluido así en el prototipo. | 2026-11-25 |
| 11 | Dirección visual (v2) | **Soft Glass Minimal (`ui-ux-pro-max`)**: rosado pastel + verde fosforescente + blanco/gris con glassmorfismo diurno sutil | Sencillo, práctico y minimalista sin patrones de IA ni emojis; verde fosforescente solo en progreso/checks/CTA con texto carbón (`>12:1` contraste). | 2026-11-25 |
| 12 | Nombre del proyecto y repo | **Power Habits** (`danibits9920/power-habits`, package `com.daltex.power_habits`) | Directo, enérgico y coherente con el acento verde fosforescente. *(Alternativas anotadas si algún día rebrandea: **Pulso** o **Cadencia**).* | 2026-11-25 |
| 13 | Actualizaciones OTA / GitHub | **Auto-actualización in-app desde GitHub Releases en cada lanzamiento de `main`** (igual a *Mis Finanzas*) | La app revisa `releases/latest` en GitHub al abrir y desde Ajustes, descarga el APK `arm64` con barra de progreso y abre el instalador nativo vía `FileProvider` + `MethodChannel`. CI/CD en GitHub Actions compila y publica cada release desde `main`. | 2026-11-25 |

## Alcance funcional completo (A–G) y entrega sugerida por fases

### Beta 1 — Core diario usable rápido (Local-First)
- **Vista Hoy:** Filtro `[ Todo | Personal | Laboral ]`, barra de progreso del día y bloques **Mañana / Tarde / Noche / Sin hora**.
- **(A) Rutinas ilimitadas con frecuencias flexibles:** diaria, interdiaria (cada 2 días) y días específicos de la semana; solo aparecen los días que corresponden.
- **(B) Múltiples recordatorios por rutina/tarea:** notificaciones locales con hora exacta y acciones rápidas (*Hecho* / *Posponer*).
- **(E) Metas por unidades con línea de progreso:** barra e hitos (`25 % / 50 % / 75 % / 100 %`), avance en 1 toque (`+1`) y opción de nombrar pasos/módulos (ej. curso de 30 clases).
- **(F) Notas rápidas al completar:** nota breve opcional al marcar una rutina, tarea o clase.
- **Tareas puntuales:** pendientes con contexto Personal o Laboral.
- **Logros base + Backup JSON:** línea de tiempo con hitos automáticos + logros manuales y respaldo local exportable.

### Beta 2 — Analítica visual y acceso rápido (Local-First)
- **(C) Historial visual por rutina:** calendario mensual / cuadrícula de constancia por cada hábito.
- **(D) Estadísticas claras:** porcentaje de cumplimiento semanal y mensual desglosado por **Personal** vs. **Laboral**.
- **(G) Widget de pantalla de inicio en Android:** progreso del día y marcado en 1 toque sin abrir la app.

### Fase 3 — Nube y multiplataforma
- Sincronización bidireccional y autenticación con **Supabase** (sobre el esquema UUID + timestamps preparado desde Beta 1).
- Acceso web opcional para sesiones largas de estudio o planificación en laptop.

### Fuera de alcance (No-objetivos)
- Funciones sociales / feeds públicos.
- Gamificación recargada (tiendas, monedas, avatares o castigos por fallar un día).
