# 08 — Identidad de Marca Completa: Power Habits

> **Concepto rector:** *Calm Voltage (Energía Serena)* — La disciplina diaria no necesita gritar ni disfrazarse de videojuego militar; debe sentirse clara en reposo y eléctrica en el instante exacto en que cumples.

---

## 1. ADN y Posicionamiento de Marca

| Dimensión | Definición oficial |
| :--- | :--- |
| **Nombre de marca** | **Power Habits** |
| **Esencia** | Claridad mental diaria + impulso visible de progreso |
| **Arquetipo** | **El Atleta Sereno** (80 % precisión tranquila · 20 % descarga de energía al completar) |
| **Tagline principal** | **"Pequeños impulsos. Progreso real."** |
| **Taglines alternativos** | *"Tu día en foco, tu avance a la vista."* · *"Constancia con energía propia."* |
| **Promesa funcional** | Separar tu vida **Personal** y **Laboral** sin fricción, viendo cómo cada rutina o clase suma hacia metas reales. |
| **Personalidad** | **Táctil, nítida, luminosa y honesta.** Ni infantil, ni corporativa aburrida, ni agresiva estilo gimnasio extremo. |

---

## 2. Voz, Tono y Léxico Oficial

### Principios de comunicación
1. **Cero culpa, 100 % tracción:** Si un día queda incompleto, la interfaz nunca regaña ni usa rojo de alerta ("fallaste tu racha"); muestra con calma qué toca hoy.
2. **Lenguaje real, nunca jerga gamer:** Inspiración en la satisfacción visual de progreso, pero hablando como un adulto organizado.
3. **Brevedad accionable:** Microcopy de máximo 4–6 palabras en botones, estados vacíos y notificaciones.

| Usar siempre (Oficial) | Nunca usar (Descartado) |
| :--- | :--- |
| **Rutinas**, **Tareas**, **Metas**, **Logros** | *Misiones, Quests, XP, Nivel, Castigo* |
| *"Progreso de hoy · 75 %"* | *"¡Sigue así campeón! 🔥💪"* |
| *"Meta al 50 %: Curso de Inglés"* | *"¡Has desbloqueado un trofeo épico!"* |
| **Personal** · **Laboral** | *Vida / Chamba / Modo Bestia* |

---

## 3. Sistema de Logo: El Símbolo *"Volt-Check"*

Referencia visual maestra: [power-habits-logo-propuesta.png](./power-habits-logo-propuesta.png)

### Construcción conceptual
El isotipo fusiona dos gestos en una sola pieza geométrica equilibrada:
- **Trazo superior — El Rayo (*Power*):** Asta diagonal descendente en tinta **Carbon Ink (`#141517`)** con remates redondeados uniformes; representa la chispa de intención para arrancar.
- **Trazo inferior — El Check Ascendente (*Habits*):** Brazo ascendente relleno en **Volt Lime (`#6BFF3B`)** perfilado con borde **Carbon Ink (`#141517`)**; representa el hábito cumplido que impulsa hacia arriba.

### Variantes oficiales del sistema gráfico
1. **App Icon Diurno (*Porcelain Glass* — Principal):** Squircle blanco porcelana (`#F7F7FA`) con borde especular fino y halo radial **Blush Mist (`#F8C8DC`)** contenido estrictamente en la esquina superior derecha.
2. **App Icon Nocturno (*Carbon Slate*):** Squircle carbón profundo (`#141517`), rayo en blanco porcelana (`#F7F7FA`) y check sólido en **Volt Lime (`#6BFF3B`)** sin reborde blanco.
3. **Lockup Horizontal (*Wordmark*):** Isotipo *Volt-Check* a la izquierda + logotipo **"Power Habits"** en caja mixta (*Title Case*), tracking ajustado (`-0.03em`), alineado ópticamente al centro del símbolo.
4. **Área de reserva y tamaño mínimo:** Margen libre mínimo equivalente a `0.25×` el ancho del squircle; tamaño mínimo digital `24px` (solo isotipo sin wordmark por debajo de `32px`).

---

## 4. Arquitectura Cromática de Marca

Cada color tiene un **nombre propio de marca** y un **rol funcional estricto** (auditado bajo WCAG AA/AAA):

| Token de Marca | Hex (Claro / Oscuro) | Rol exclusivo en el producto | Contraste verificado |
| :--- | :--- | :--- | :--- |
| **Volt Lime** *(Acento primario)* | `#6BFF3B` | Relleno de checks completados, barras de progreso, día activo, píldora de navegación y CTA principal (`+1` / `Guardar`). **Prohibido como color de texto sobre blanco.** | **14.1 : 1** (AAA) con tinta `#141517` encima |
| **Carbon Ink** *(Tinta maestra)* | `#141517` / `#F3F4F6` | Titulares, logotipo, íconos vectoriales y texto sobre **Volt Lime**. | **16.8 : 1** (AAA) sobre `#FFFFFF` |
| **Blush Mist** *(Calidez & Personal)* | `#F8C8DC` / `#FDECF3` | Halo ambiental sutil del lienzo *Soft Glass* y etiqueta exclusiva del contexto **Personal** (con tinta ciruela oscura `#5C2840`). | **8.2 : 1** (AAA) `#5C2840` sobre `#FDECF3` |
| **Porcelain Glass** *(Superficie)* | `#F3F4F6` → `#FFFFFF` | Lienzo diurno limpio y tarjetas traslúcidas (`72 %–90 %` blanco con borde especular `1px`). | Base neutra de descanso visual |
| **Slate Work** *(Contexto Laboral)* | `#E8EAEE` / `#2C2F33` | Etiqueta exclusiva del contexto **Laboral** — sobria, neutra y separada visualmente de *Personal*. | **10.9 : 1** (AAA) `#2C2F33` sobre `#E8EAEE` |

---

## 5. Sistema Tipográfico: 3 Propuestas Llamativas + Determinación Recomendada

### Diagnóstico del estado actual (`v0.3.1`)
Actualmente la app usa `Outfit + Work Sans` cargadas como un único archivo por familia en `pubspec.yaml`. Aunque es limpia, `Outfit` es redonda y neutral: **le falta ese rasgo distintivo de marca** que hace que abras la app y sientas identidad propia desde el título `"Hoy"` o el porcentaje `"86%"`.

Aquí tienes las **3 propuestas tipográficas curadas** (100 % gratuitas en Google Fonts, soporte completo en español `áéíóúñ` y empaquetables offline en Flutter):

---

### 🏆 Propuesta 1 (DETERMINACIÓN RECOMENDADA): *"Kinetic Precision"*
- **Display / Wordmark / Titulares:** **`Bricolage Grotesque`** (`Bold 700` / `ExtraBold 800`, `letter-spacing: -0.03em`)
- **UI / Rutinas / Lectura:** **`Plus Jakarta Sans`** (`Medium 500` / `SemiBold 600`)
- **Métricas / Porcentajes / Horas:** **`JetBrains Mono`** (`SemiBold 600`, `tabular-nums`)

**Por qué es la ganadora para Power Habits:**
- **Bricolage Grotesque** tiene curvas contemporáneas y sutiles *ink traps* (cortes escultóricos en las uniones de la `P`, `w`, `r`, `H`, `a` y números como `86%`) que le dan **carácter inmediato de marca boutique** sin sacrificar legibilidad ni verse recargada.
- **Plus Jakarta Sans** aporta limpieza geométrica moderna en listas diarias de rutinas y tareas a `14–15px`.
- **JetBrains Mono** en contadores (`18/30 clases`, `07:30`, `75%`) convierte las métricas de estudio y hábitos en un tablero de precisión táctil.

---

### ⚡ Propuesta 2 (Alternativa Audaz): *"Volt Avant-Garde"*
- **Display / Wordmark / Titulares:** **`Syne`** (`Bold 700` / `ExtraBold 800`, `letter-spacing: -0.035em`)
- **UI / Rutinas / Lectura:** **`DM Sans`** (`Medium 500` / `SemiBold 600`)
- **Métricas / Porcentajes:** **`Space Mono`** (`Bold 700`)

**Cuándo elegirla:** Si quieres que los titulares (`Power Habits`, `Hoy`, `Metas`) tengan proporciones anchas, artísticas y muy disruptivas (estilo marca deportiva experimental / Nothing / Nike Lab). *Nota:* `Syne` solo debe usarse en encabezados cortos, nunca en nombres largos de rutinas.

---

### 🧭 Propuesta 3 (Alternativa Técnica): *"Swiss Instrument"*
- **Display / Titulares / Números:** **`Space Grotesk`** (`Bold 700`, `letter-spacing: -0.025em`)
- **UI / Rutinas / Lectura:** **`Manrope`** (`Medium 500` / `SemiBold 600`)
- **Métricas / Horas:** **`Space Grotesk`** (`tabular-nums`)

**Cuándo elegirla:** Si prefieres un look más ingenieril, recto y técnico-suizo donde los números grandes y los titulares comparten exactamente el mismo ADN geométrico cuadrado que el rayo del logo.

---

### Escala tipográfica oficial para la app móvil (`390dp` base)

| Rol en interfaz | Fuente (Propuesta 1) | Peso | Tamaño | Tracking | Uso exacto |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Brand Wordmark** | `Bricolage Grotesque` | `800 ExtraBold` | `24–28sp` | `-0.8` | Splash y cabecera de marca *"Power Habits"* |
| **Screen Hero (`H1`)** | `Bricolage Grotesque` | `800 ExtraBold` | `28sp` | `-0.8` | Títulos de pestaña: *"Hoy"*, *"Metas"*, *"Progreso"* |
| **Hero Metric** | `Bricolage Grotesque` | `800 ExtraBold` | `30sp` | `-1.0` | Porcentaje diario principal (`86%`) |
| **Card Title (`H2`)** | `Bricolage Grotesque` | `700 Bold` | `18sp` | `-0.3` | Títulos de metas y modales |
| **Routine Title** | `Plus Jakarta Sans` | `600 SemiBold` | `15.5sp` | `-0.1` | Nombre de rutina o tarea en tarjetas |
| **Body / Notes** | `Plus Jakarta Sans` | `500 Medium` | `14sp` | `0.0` | Notas rápidas, subtítulos y ajustes |
| **Data / Badge (`Mono`)** | `JetBrains Mono` | `600 SemiBold` | `12sp` | `+0.2` | `18/30 clases`, `07:30`, `3/4 sem`, hitos `25%–100%` |

---

## 6. Firma de Interacción, Iconografía y Ecosistema

- **Iconografía:** Trazos geométricos limpios (`Lucide`, grosor uniforme `1.75px–2px`), esquinas redondeadas coherentes con el isotipo *Volt-Check*. **Cero emojis** como iconos estructurales.
- **Geometría de superficies:** Radio `22dp` en tarjetas *Soft Glass*, `12dp` en casillas de verificación (con micro-escala táctil `0.96×` al presionar), `999dp` en píldoras de contexto y navegación flotante.
- **Firma de movimiento (*Signature Motion*):**
  - **Toque táctil:** Compresión rápida (`110ms`) + vibración háptica sutil al marcar.
  - **Deslizamiento 1:1:** La píldora **Volt Lime** acompaña el dedo entre `Hoy ↔ Metas ↔ Progreso`.
  - **Destello de hito:** Al alcanzar `25 %`, `50 %`, `75 %` o `100 %` del día/meta, destello radial limpio sin confeti infantil.
- **Coherencia fuera de la app:** Los **3 Widgets Android** (`4×3 Hoy`, `4×2 Metas`, `2×2 Mini`), el **Splash Screen** y las **Notificaciones** comparten exactamente la misma paleta *Porcelain + Blush + Volt Lime + Carbon*.
