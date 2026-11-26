# 04 — Bitácora de hallazgos, preguntas y respuestas

Registro vivo de todo lo que vamos conversando, descubriendo y decidiendo durante la definición del proyecto.

---

## Sesión 1 — 2026-11-25

### Contexto inicial aportado por Jesús
- **Objetivo del proyecto:** Crear una herramienta personal para mejorar sus hábitos del día a día.
- **Necesidades iniciales expresadas:** Recordar ejercicios, tareas pendientes, metas del día, línea de progreso por meta y logros realizados.
- **Forma de trabajo deseada:** Documentar el proceso en `docs/`, trabajar con **definición y contraste**, apoyarse en skills útiles e ir anotando cada hallazgo, pregunta y respuesta.

---

### Ronda 1 de Preguntas y Respuestas
- **Dolor real:** Dificultad para coordinar metas de ejercicio y estudio; sensación de falta de control sobre el día por no sentir el progreso acumulado. Busca construir disciplina poco a poco.
- **Referencia:** Probó *"Seguimiento de hábitos"*; le gustó su forma, pero quiere algo personalizado y una base propia para evolucionar.
- **Casos de uso reales:** Ejercicios, salidas a caminar, skincare (diario o interdiario), recordatorios, estudios por unidades (curso de 30 clases marcando cada clase), y tareas pendientes con sensación satisfactoria de progreso.

---

### Ronda 2 de Preguntas y Respuestas
- **Motivo de reemplazo de la app probada:** La mayoría de funciones útiles en *"Seguimiento de hábitos"* eran premium. Quiere **separar rutinas y tareas en Personal vs. Laboral**.
- **Corrección de tono/lenguaje:** La referencia a GTA/videojuegos es solo **inspiración para la sensación de progreso**, NO para usar jerga de juego ("misiones"). Terminología oficial: **Rutinas**, **Tareas**, **Metas** y **Logros**.
- **Plataforma inicial:** **Aplicación móvil primero**.

---

### Ronda 3 de Preguntas y Respuestas
- **Stack móvil elegido:** **Flutter (Dart)** por comodidad y rendimiento nativo.
- **Estrategia de datos:** **Local-First (SQLite)** para las fases **Beta**, luego migrar/sincronizar a **Supabase**.
- **Contraste técnico aplicado:** Diseñar tablas *Supabase-ready* desde el día 1 (UUID v4, `created_at`/`updated_at`, `deleted_at`, capa de Repositorios desacoplada y backup JSON en Beta).

---

### Ronda 4 de Preguntas y Respuestas

#### P8. Organización del día: selector `[ Todo | Personal | Laboral ]` + bloques Mañana / Tarde / Noche
- **Respuesta de Jesús:** **Sí.**

#### P9. Selección de funciones (A–G) + solicitud de tutorial interactivo
- **Respuesta de Jesús:** Quiere **incluir todas las funciones (A–G)** y pide un **tutorial interactivo** que le permita ver y probar el flujo explicado de cada función.
- **Hallazgo y contraste aplicado:**
  - Incluir todas las funciones A–G en el diseño completo garantiza coherencia desde el inicio (ninguna pieza queda como "parche").
  - **Contraste de ejecución:** Para no caer en la trampa de tardar semanas antes de usar la app, se propone dividir la construcción en **Beta 1** (Hoy + A + B + E + F + Logros básicos = usable en el teléfono en pocos días) y **Beta 2** (C historial/calendario + D estadísticas + G widget nativo de Android).
  - Se utilizó la skill `claude-design` para construir [prototipo-tutorial-interactivo.html](./prototipo-tutorial-interactivo.html): un simulador móvil interactivo + guía paso a paso de los 8 flujos (Hoy/Contextos, A, B, E, F, C+D, Logros y G Widget).

#### P10. Logros (automáticos vs. manuales)
- **Respuesta de Jesús:** **Ambos** (hitos automáticos + logros manuales en una sola línea de tiempo).
- **Estado:** Decisión cerrada y ya reflejada en el Paso 7 de `prototipo-tutorial-interactivo.html`.

---

### Ronda 5 — Google Stitch conectado y pantallas creadas
- **Solicitud de Jesús:** Llevar el diseño a Google Stitch con su API key.
- **Acciones realizadas:**
  - Se integró el servidor MCP de Stitch en `~/.gemini/config/mcp_config.json` (fusionado limpiamente con sus servidores de Supabase, permisos `600`).
  - Se creó [DESIGN.md](./DESIGN.md) (*Calm Tactical Discipline*) y se subió al proyecto **Mis Hábitos — App Móvil** (`projects/13088290212090283326`).
  - Se generaron y organizaron en el canvas de Stitch las **5 pantallas móviles** bajo el mismo sistema de diseño (`assets/a08200ac275a4465b6b053f69eade1e7`):
    1. **Hoy - Mis Hábitos** (Personal/Laboral + Mañana/Tarde/Noche)
    2. **Nueva Rutina** (frecuencias flexibles A + múltiples recordatorios B + nota rápida F)
    3. **Metas - Objetivos por Unidades** (curso de 30 clases + línea de progreso con hitos E)
    4. **Progreso y Logros** (calendario mensual C + estadísticas Personal/Laboral D + línea de logros automáticos y manuales)
    5. **Android Home Screen - Mis Hábitos** (Widget 4×2 G + notificación interactiva B)
  - **Enlace directo Stitch:** https://stitch.withgoogle.com/projects/13088290212090283326

### Ronda 6 — Rediseño v2 con `ui-ux-pro-max` (Glassmorfismo + Rosado Pastel + Verde Fosforescente + Blanco/Gris)
- **Feedback de Jesús:** Incorporar glassmorfismo sutil, paleta **rosado pastel + verde fosforescente + gris/blanco**, usar la skill **`ui-ux-pro-max`** y adaptarlo a un entorno sencillo, práctico, minimalista y sin patrones genéricos de IA.
- **Acciones realizadas:**
  - Instaladas vía `skillshare` las skills `ui-ux-pro-max`, `design`, `design-system` y `ui-styling`.
  - Aplicadas las guías de `ui-ux-pro-max` (`glassmorphism`, `minimalism-and-swiss-style`, emparejamiento tipográfico `Outfit` + `Work Sans`, `pro-rules.md` con contraste WCAG ≥ 4.5:1, áreas táctiles 48dp, cero emojis estructurales y guías Flutter).
  - Contraste de legibilidad aplicado: **verde fosforescente (`#6BFF3B`)** usado solo como relleno de barras, checks y botón principal **siempre con tinta carbón (`#141517`)** encima (nunca texto neón sobre blanco); **rosado pastel (`#F8C8DC` / `#FDECF3`)** como halo ambiental suave detrás de tarjetas glass blancas y contexto *Personal*; **gris neutro (`#E8EAEE` / `#2C2F33`)** para *Laboral*.
  - Creado el proyecto limpio **Stitch v2** con `DESIGN.md` + las **5 pantallas** ordenadas sin solapes:
    1. **Hoy — Control Diario** (`x=1024`)
    2. **Nueva Rutina** (`x=1480`)
    3. **Metas — Objetivos y Progreso** (`x=1936`)
    4. **Progreso — Métricas y Logros** (`x=2392`)
    5. **Pantalla de Inicio — Android Widget & Notificación** (`x=2848`)
  - **Enlace directo Stitch v2:** https://stitch.withgoogle.com/projects/2943801740701979031

### Ronda 7 — Aprobación de v2, requisito de auto-actualización y luz verde de construcción
- **Decisión de Jesús:**
  - Aprueba el diseño **v2 (Soft Glass Minimal)** y solicita apagar el servidor HTTP local (ya detenido).
  - Nombre elegido: **Power Habits** (`danibits9920/power-habits`), dejando constancia de alternativas (*Pulso*, *Cadencia*) por si en el futuro decide renombrar.
  - **Nueva función obligatoria agregada:** La app debe **actualizarse automáticamente con cada versión lanzada en `main`**, usando el mismo mecanismo probado de *Mis Finanzas* (GitHub Releases + verificador SemVer in-app + descarga con progreso + instalador nativo Android vía `FileProvider` + workflow de GitHub Actions en `main`).
  - **Modo de ejecución:** Definir la hoja de ruta completa ([06-hoja-de-ruta-y-spec.md](./06-hoja-de-ruta-y-spec.md)), crear el repo en GitHub, distribuir el trabajo en **4 agentes en paralelo** (ramas independientes) supervisados por un **Agente Orquestador / Juez Autónomo** que audita, decide hallazgos, integra, compila APK release y aprueba la versión definitiva antes de subirla a `main`.

---

### Ronda 8 — Auditoría autónoma, integración en `main` y Release `v0.1.0`
- **Resultado:** Las 4 ramas paralelas (`feat/shell-design`, `feat/hoy-rutinas`, `feat/metas-progreso`, `feat/sistema-android`) fueron auditadas e integradas en orden sobre `main`.
- **Correcciones aplicadas por el Juez Autónomo:** prevención de overflow en `PrimaryNeonButton`, resiliencia de `PhoneNotifier` en tests headless, soporte de edición de `anchorDate`, notas rápidas visibles en el historial mensual de `Progreso`, eliminación de `SoftGlassBackground` duplicado en `Ajustes`, botón `+` de `48dp` con drawables Soft Glass en el widget Android 4×2 y cableado completo en `app.dart` (`PhoneNotifier`, `syncTodayWidgetFromDb`, `/hoy?new=1`, `maybePromptForUpdate`).
- **Compuertas superadas:** `flutter analyze` (0 issues), `flutter test` (29/29 verdes) y `flutter build apk --release --target-platform android-arm64` (`24.1 MB`).
- **Acta completa:** Ver [07-veredicto-orquestador.md](./07-veredicto-orquestador.md) — Veredicto: **`APROBADO`**.

### Ronda 9 — Iteraciones post-lanzamiento (`v0.1.1`, `v0.2.0`, `v0.3.0`, `v0.3.1`) y Propuesta de Logo
- **`v0.1.1` (Modales por encima de tabs):** Todos los bottom sheets, diálogos y date/time pickers usan `useRootNavigator: true` y `SafeArea(top: false)` para no quedar detrás de la barra flotante.
- **`v0.2.0` (Widgets interactivos):** 3 widgets Android Soft Glass (`4×3 Hoy`, `4×2 Metas`, `2×2 Mini`) con acciones directas fuera de la app y sincronización bidireccional con SQLite.
- **`v0.3.0` (Interacciones, Interdiaria flexible y `X veces/sem`):** Micro-animaciones (`motion.dart`), `Interdiaria` configurable con días semanales editables (`Continua` o `2d/3d/4d/5d`) + modo flexible `X veces/sem`, y primer logo vectorizado + splash.
- **`v0.3.1` (Rendimiento 60fps + Swipe horizontal):** Eliminado el `BackdropFilter` apilado en cada `GlassCard` durante el scroll (causa principal de lag en Android), añadido `RepaintBoundary` y navegación `PageView` 1:1 entre `Hoy ↔ Metas ↔ Progreso` (`34/34` tests verdes).
- **Logo v2 (Propuesta visual en Stitch + Concept Board):** Como el logo manual de `v0.3.0` no lució tan refinado como se esperaba, se preparó una propuesta visual profesional en Google Stitch v2 (`projects/2943801740701979031`) y en [power-habits-logo-propuesta.png](./power-habits-logo-propuesta.png) para aprobarla antes de empaquetarla como ícono nativo real en `v0.3.2`.

---

### Próximos pasos tras Release `v0.3.1`
1. Aprobar el nuevo diseño del logo (Stitch v2 / concept board) e integrarlo fielmente como `ic_launcher` + splash en **`v0.3.2`**.
2. Configurar los secretos de firma (`ANDROID_KEYSTORE_BASE64`, etc.) en GitHub Actions si se desea firma fija de release distinta a la firma debug reproducible.
3. Fase 4 (futuro): añadir `SupabaseSyncService` sobre los repositorios y esquema UUID ya implementado sin reescribir la UI.
