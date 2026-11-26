# Power Habits — Documentación del Proyecto

**Estado actual:** Fase de implementación multi-agente (`v0.1.0`)  
**Tipo:** App móvil Flutter (Local-First → Supabase) de hábitos, tareas diarias, metas y logros  
**Repositorio GitHub:** https://github.com/danibits9920/power-habits

## Índice de documentos

- [01-idea-y-vision.md](./01-idea-y-vision.md) — Qué quieres construir, el problema real que resuelve y los pilares iniciales.
- [02-contraste-y-preguntas.md](./02-contraste-y-preguntas.md) — Análisis crítico, riesgos típicos de este tipo de apps y preguntas clave para afinar el enfoque.
- [03-decisiones-y-alcance.md](./03-decisiones-y-alcance.md) — Registro de decisiones tomadas, alcance completo (A–G + Auto-Update) y no-objetivos.
- [04-bitacora-y-qa.md](./04-bitacora-y-qa.md) — Bitácora viva con cada hallazgo, pregunta y respuesta de nuestras conversaciones.
- [05-arquitectura-tecnica.md](./05-arquitectura-tecnica.md) — Stack Flutter + Drift (Supabase-ready), Kotlin MethodChannels, Auto-Updater y CI/CD.
- [06-hoja-de-ruta-y-spec.md](./06-hoja-de-ruta-y-spec.md) — Spec completo, hoja de ruta, matriz de agentes paralelos y criterios de aprobación.
- [DESIGN.md](./DESIGN.md) — Sistema de diseño oficial **v2 (Soft Glass Minimal: rosado pastel + verde fosforescente + blanco/gris)** generado con `ui-ux-pro-max`.
- [MASTER.md](../design-system/mis-habitos/MASTER.md) — Guía maestra de tokens, contraste WCAG y reglas Flutter (`ui-ux-pro-max`).
- [prototipo-tutorial-interactivo.html](./prototipo-tutorial-interactivo.html) — Prototipo y tutorial interactivo local para probar en vivo cada flujo (A–G).
- **Google Stitch v2 (Soft Glass Minimal — actual):** https://stitch.withgoogle.com/projects/2943801740701979031
- **Google Stitch v1 (referencia inicial):** https://stitch.withgoogle.com/projects/13088290212090283326

## Mapa de skills y herramientas para cada etapa

Estas son las skills ya disponibles en tu entorno que mejor encajan según avancemos:

| Etapa | Skill / Comando | Para qué la usaríamos aquí |
| :--- | :--- | :--- |
| **1. Definición y contraste** | `/grill-me` (comando) | Entrevista estructurada para presionar cada decisión de diseño y detectar huecos antes de escribir código. |
| **1. Investigación de referencias** | `deep-research` | Comparar cómo resuelven retención, recordatorios y líneas de progreso apps como Loop, Streaks, TickTick o Habitica, y qué dice la psicología de hábitos. |
| **1. Dinámica semanal** | `weekly-review-planning` | Inspiración práctica para el cierre semanal (logros, pendientes estancados, ajuste realista de capacidad). |
| **2. Validar dudas rápido** | `spike` | Prototipos desechables para probar rápido una idea (ej. cómo se siente la línea de progreso o el flujo de recordatorios) antes de construir en serio. |
| **3. Diseño visual y UX** | `popular-web-designs`, `claude-design`, `design-md` | Explorar referencias visuales, armar un prototipo interactivo en HTML y cerrar una guía de diseño (`DESIGN.md`). |
| **3. Arquitectura** | `architecture-diagram` | Diagramar datos, sincronización y flujo de recordatorios cuando el stack esté decidido. |
| **4. Construcción** | Stack por definir (`omarchy-app`, Next.js/PWA, Flutter o Expo) + `test-driven-development` | Implementar el MVP con pruebas y disciplina de alcance. |
