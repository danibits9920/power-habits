---
version: alpha
name: Mis Habitos v2 — Soft Glass Minimal
description: Minimalist, practical Android mobile design system combining restrained daylight glassmorphism, pastel pink warmth, electric fluorescent green momentum accents, and crisp white/gray neutrality. Built with UI/UX Pro Max standards.
colors:
  primary: "#6BFF3B"
  primary-ink: "#141517"
  secondary: "#F8C8DC"
  secondary-soft: "#FDECF3"
  secondary-ink: "#5C2840"
  neutral: "#F3F4F6"
  surface: "#FFFFFF"
  glass-surface: "rgba(255, 255, 255, 0.72)"
  glass-border: "rgba(255, 255, 255, 0.88)"
  border: "#E5E7EB"
  ink: "#141517"
  ink-muted: "#6B7280"
  work-pill: "#E8EAEE"
  work-ink: "#2C2F33"
typography:
  h1:
    fontFamily: Outfit
    fontSize: 1.625rem
    fontWeight: 700
    lineHeight: 1.15
    letterSpacing: "-0.025em"
  h2:
    fontFamily: Outfit
    fontSize: 1.125rem
    fontWeight: 600
    lineHeight: 1.25
    letterSpacing: "-0.015em"
  body-md:
    fontFamily: Work Sans
    fontSize: 0.9375rem
    fontWeight: 500
    lineHeight: 1.45
  caption:
    fontFamily: Work Sans
    fontSize: 0.75rem
    fontWeight: 500
    lineHeight: 1.35
  metric:
    fontFamily: Outfit
    fontSize: 1.125rem
    fontWeight: 700
    lineHeight: 1.1
rounded:
  sm: 10px
  md: 16px
  lg: 22px
  pill: 999px
spacing:
  sm: 8px
  md: 16px
  lg: 24px
components:
  button-primary:
    backgroundColor: "{colors.primary}"
    textColor: "{colors.primary-ink}"
    rounded: "{rounded.pill}"
    padding: 14px
  badge-personal:
    backgroundColor: "{colors.secondary-soft}"
    textColor: "{colors.secondary-ink}"
    rounded: "{rounded.pill}"
    padding: 6px
  badge-laboral:
    backgroundColor: "{colors.work-pill}"
    textColor: "{colors.work-ink}"
    rounded: "{rounded.pill}"
    padding: 6px
  card-glass:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.ink}"
    rounded: "{rounded.lg}"
    padding: 16px
---

## Overview

**Mis Hábitos (v2 — Soft Glass Minimal)** is a minimalist, ultra-practical personal mobile app for Android (Flutter, Local-First). Designed under **UI/UX Pro Max** guidelines to avoid generic AI templates: generous breathing room, crisp monochrome typography, restrained daylight frosted glass over a subtle pastel-pink/cool-gray atmospheric backdrop, and high-energy fluorescent green reserved strictly for active progress and completion momentum.

## Colors

- **Neutral Canvas (`#F3F4F6` → `#FFFFFF`):** Cool porcelain gray/white studio background so the interface feels calm, airy, and readable in daylight.
- **Pastel Pink (`#F8C8DC` / soft wash `#FDECF3`):** Used softly as an organic atmospheric tint behind frosted glass surfaces and as the calm badge tint for the **Personal** context (paired with deep plum-charcoal text `#5C2840` for >7:1 WCAG AA contrast).
- **Fluorescent Green (`#6BFF3B`):** Used with strict discipline ONLY for progress fills, completed checkmarks, active day/calendar indicators, and the primary `+1` / save action — ALWAYS paired with deep charcoal ink (`#141517`, >12:1 contrast) and never as raw neon text on white.
- **Graphite Gray (`#E8EAEE` / `#2C2F33`):** Clean neutral separation for the **Laboral** (work) context without adding extra color noise.

## Typography

- **Outfit** (UI/UX Pro Max *Geometric Modern* pairing) for headings and tabular numbers (`67%`, `14/30`).
- **Work Sans** for clean, highly legible mobile body copy and routine titles (base 15–16px, line-height 1.45).

## Layout

- Practical 1-thumb mobile minimalism (`390×844` Android safe areas, minimum `48dp` tap targets, strict `8dp` spacing grid).
- Maximum 2 lines of information per routine row (title + single quiet metadata line).
- Floating frosted-glass bottom pill navigation (`Hoy`, `Metas`, `Progreso`) with crisp monochrome vector line icons (`1.75px` stroke, zero emojis).

## Elevation & Depth

- Restrained daylight glassmorphism (`rgba(255, 255, 255, 0.72)`, `backdrop-filter: blur(16px)`, `1px solid rgba(255, 255, 255, 0.9)`, subtle shadow `0 8px 24px rgba(20, 21, 23, 0.05)`) over a gentle pastel-pink and soft-gray gradient haze — clear hierarchy, never muddy.

## Shapes

- Tactile soft geometry: `22px` glass cards, `10px` rounded checkboxes, `999px` pill segmented controls and floating bottom bar.

## Components

- `card-glass`: Airy frosted white card with single-tap checkbox on the left (fills `#6BFF3B` with `#141517` check icon on completion), clean routine title, quiet frequency/time caption, and minimal context pill.
- `button-primary`: Pill CTA in `#6BFF3B` with crisp `#141517` label for instant high-contrast actionability.
- `badge-personal` / `badge-laboral`: Subtle pastel-pink vs cool-gray pills — zero visual noise.

## Do's and Don'ts

- **Do:** Keep screens calm, airy, and immediately actionable with one thumb; use vector line icons only; keep text contrast >= 4.5:1 everywhere.
- **Don't:** Use emojis as icons, put fluorescent green text directly on white, add dark cyber-neon glows, stack floating AI decorative blobs, or crowd cards with redundant stats and badges.
