# 02 — Contraste crítico y preguntas clave

Este documento existe para **cuestionar la idea a tiempo** antes de diseñar pantallas o escribir código. La mayoría de proyectos personales de hábitos fallan no por tecnología, sino por fricción en la vida real.

---

## 1. Tensiones y trampas comunes (contraste)

### Trampa A: El "todo en uno" que se abandona en 10 días
Unir **rutinas + tareas pendientes + metas + logros + Personal/Laboral** es potente, pero si abrir la app te muestra 25 ítems desordenados y te obliga a llenar 6 campos para crear algo, la dejas de usar en tu primera semana pesada.
- **Contraste:** Mantener una **pantalla principal de "Hoy" ultralimpia** con filtro rápido (`Todo | Personal | Laboral`) y captura rápida en pocos segundos.

### Trampa B: Recordatorios que se vuelven ruido de fondo
Una notificación genérica siempre a la misma hora termina deslizándose sin leerse.
- **Contraste:** En app móvil nativa tienes ventaja real: notificaciones locales precisas (sin depender de internet), acciones rápidas desde la notificación (ej. *"Hecho"* / *"Posponer 30 min"*), y opcionalmente un **widget en la pantalla de inicio** para ver tu progreso del día sin abrir la app.

### Trampa C: Rachas punitivas vs. progreso real
Muchas apps giran en torno a "racha de N días seguidos". Si un día te enfermas o tienes una emergencia, la racha vuelve a 0 y se te quitan las ganas de seguir.
- **Contraste:** Tu enfoque de **línea de progreso por meta + logros + consistencia** es mucho más sano: un día fallado no borra lo construido.

### Trampa D: Construir la app como excusa para procrastinar el hábito
Es muy fácil pasar semanas puliendo código en vez de usar la app para entrenar y estudiar.
- **Contraste:** Definir un **MVP sólido y usable en pocos días** (local-first en el teléfono, directo a tu Redmi) y construir la arquitectura modular para ir mejorándola sobre uso real, tal como dijiste (*"tener una base para irlo mejorando"*).

### Trampa E: Inspiración de progreso vs. Gamificación recargada *(Aclarado)*
- **Decisión tomada:** La referencia a videojuegos/GTA es solo **inspiración para la sensación de progreso y cierre satisfactorio**, NO para tematizar la app como juego ni llamar "misiones" a las cosas.
- El lenguaje será real y limpio (**Rutinas**, **Tareas**, **Metas**, **Logros**), con micro-interacciones satisfactorias, barras claras de progreso e hitos/logros reales.

### Contraste F: Personal vs. Laboral — ¿cómo vivirlo sin duplicar esfuerzo?
Separar **Personal** y **Laboral** evita contaminación mental (no ver skincare en horario laboral ni pendientes del trabajo descansando).
- **Contraste de UX:**
  - *Filtro superior rápido:* `[ Todo | Personal | Laboral ]` siempre accesible con 1 toque.
  - *Organización del día:* Agrupar opcionalmente por bloque horario (**Mañana / Tarde / Noche / Sin hora**) para que el día tenga ritmo visual y sensación de control.

---

## 2. Contraste técnico (App móvil primero)

Ya decidiste empezar por **aplicación móvil primero**. Teniendo en cuenta tu experiencia real, las dos opciones fuertes son:

| Opción | Ventajas para este proyecto | Desventajas / Riesgos |
| :--- | :--- | :--- |
| **Flutter (Dart)** | Ya tienes experiencia reciente (*Mis Finanzas*, *Ñami*), rendimiento nativo muy fluido, animaciones de progreso espectaculares, notificaciones locales y SQLite/Drift muy maduros offline-first. | Builds pesados en tu laptop si no cierras emuladores (aunque probando directo en tu Redmi por USB fluye mucho mejor); si luego quieres web, Flutter Web no es tan ligero como Next.js. |
| **React Native / Expo (TS)** | Mismo lenguaje que tu stack fuerte (TypeScript/React), iteración muy rápida, excelente soporte de notificaciones locales y SQLite; fácil compartir lógica/tipos si luego haces versión web en Next.js. | Animaciones complejas y widgets nativos de Android requieren algo más de configuración/native modules que Flutter. |

### Contraste de datos: ¿Local-first (en el teléfono) o en la nube (Supabase) desde v1?
- **Local-first (SQLite en el teléfono):** Cero latencia, funciona 100 % sin internet (ej. saliendo a caminar o en el gym), sin login ni dependencia de servidor para el MVP. Luego se puede agregar sincronización con Supabase o backup/exportación JSON.
- **Supabase desde v1:** Datos respaldados en la nube desde el día 1 y listo para una futura versión web en PC, pero exige manejar estado offline/caché para que no se sienta lenta sin internet.

---

## 3. Preguntas abiertas para cerrar la definición del MVP

1. **Stack móvil:** ¿Prefieres construirla en **Flutter** o en **React Native / Expo**?
2. **Almacenamiento inicial:** Para la v1, ¿prefieres **100 % local en el teléfono** (ultrarrápida, offline, con backup exportable) o conectada a **Supabase** desde el inicio pensando en abrirla después desde la PC?
3. **Qué funciones de "Seguimiento de hábitos" te gustaron o viste en Premium que sí quieres tener:** (ej. calendario mensual/mapa de calor, estadísticas de cumplimiento, rutinas ilimitadas, múltiples recordatorios por hábito, notas rápidas, sub-pasos, temporizador, categorías/colores).
4. **Cómo quieres organizar el día y la línea de progreso:**
   - ¿Te sirve agrupar el día por **Mañana / Tarde / Noche** + filtro **Todo / Personal / Laboral**?
   - Para una meta como el **curso de 30 clases**, ¿prefieres solo contador numérico (`+1 clase`, `12/30`) o también poder nombrar/ver la lista de pasos o hitos (ej. Módulo 1, Módulo 2...)?
