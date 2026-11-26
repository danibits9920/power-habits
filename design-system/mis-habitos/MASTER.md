# Design System Master File — Mis Hábitos (v2 Soft Glass Minimal)

> Generado con **UI/UX Pro Max** (`minimalism-and-swiss-style` + `glassmorphism` + `Geometric Modern` Outfit/Work Sans + Flutter Stack Guidelines) y personalizado con la paleta elegida por Jesús.

## 1. Dirección estética (Anti-patrones de IA)
- **Estilo:** Minimalismo práctico + **glassmorfismo diurno sutil** (tarjetas de vidrio esmerilado blanco translúcido sobre fondo gris/blanco con un velo muy suave rosado pastel).
- **Qué evitamos explícitamente:** Fondos oscuros neón recargados, brillos tipo sci-fi, tarjetas saturadas de métricas inventadas, emojis usados como íconos, bordes laterales decorativos y texto verde fosforescente sobre blanco (ilegible).

## 2. Paleta y contraste (WCAG AA >= 4.5:1)
| Rol | Token | Valor | Uso exacto |
| :--- | :--- | :--- | :--- |
| Fondo principal | `--bg-canvas` | `#F3F4F6` → `#FFFFFF` | Base limpia gris claro / blanco con halo difuso muy suave `#FDECF3` |
| Superficie Glass | `--surface-glass` | `rgba(255, 255, 255, 0.72)` + `blur(16px)` | Tarjetas, barra de navegación flotante, hojas inferiores |
| Borde Glass | `--border-glass` | `rgba(255, 255, 255, 0.90)` / `#E5E7EB` | Definición nítida de cada superficie sin sombras pesadas |
| Rosado pastel | `--accent-pink` | `#F8C8DC` / soft `#FDECF3` | Atmósfera sutil del fondo, contexto **Personal** (texto `#5C2840`), acentos cálidos |
| Verde fosforescente | `--accent-neon` | `#6BFF3B` | **Solo** donde hay acción o progreso: barras de avance, checks completados, días logrados y CTA principal (siempre con texto/ícono `#141517`) |
| Contexto Laboral | `--work-neutral` | `#E8EAEE` / texto `#2C2F33` | Separación limpia y sobria sin introducir un cuarto color |
| Tinta principal | `--ink-primary` | `#141517` | Títulos, texto principal, íconos y texto sobre verde fosforescente |
| Tinta secundaria | `--ink-muted` | `#6B7280` | Horarios, frecuencias y etiquetas secundarias |

## 3. Tipografía (`ui-ux-pro-max` — Geometric Modern)
- **Headings & Números tabulares:** `Outfit` (600–700)
- **Body & Labels:** `Work Sans` (400–600, base 15–16px, line-height 1.45)

## 4. Reglas móviles Flutter (`pro-rules.md` + `stacks/flutter.csv`)
- **Íconos:** Solo vectoriales minimalistas (ej. Lucide / Phosphor, trazo uniforme `1.75px`), **cero emojis** estructurales.
- **Áreas táctiles:** Mínimo `48x48dp` en Android, ritmo de espaciado `8dp` (`8 / 16 / 24`).
- **Theming Flutter:** Todo centralizado en `ThemeData` + `ThemeExtension` (`Theme.of(context)`), soporte `light` y `dark`, rutas declarativas con `go_router`.
- **Simplicidad práctica:** Máximo 2 líneas por tarjeta en `Hoy`, navegación flotante de 3 pestañas (`Hoy`, `Metas`, `Progreso`) + botón `+`.
