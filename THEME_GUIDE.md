# Readora Design System — Theme Reference

Complete specification for both Light and Dark themes. Use this as the single source of truth when styling any component in the application.

---

## Architecture

The app uses a **mutable static palette** (`AppColors`) that swaps values at runtime when the user toggles themes. All widgets reference `AppColors.xxx` — no hardcoded color literals.

- **Font:** Inter (all weights: 400, 500, 600, 700, 800)
- **Border Radius:** 14px standard, 20px for cards, 28px for bottom sheets
- **Elevation:** 0 everywhere (flat design, depth via shadows + borders)
- **Shadows:** Colored in dark mode (violet/purple tint), neutral black in light mode

---

## Light Theme — "Clean Violet"

A modern, minimal interface with cool-white surfaces, deep navy text, and refined violet accents. Feels professional, clean, and spacious.

### Color Palette

| Token | Hex | Usage |
|-------|-----|-------|
| `primary` | `#6C5CE7` | Buttons, active states, links, accents |
| `primaryLight` | `#EDE9FF` | Selected tab backgrounds, badge fills, light tints |
| `primaryDark` | `#4A3ABA` | Pressed button states, emphasis text |
| `background` | `#F8F9FC` | Scaffold/page background |
| `surface` | `#FFFFFF` | Cards, sheets, modals, input fields, nav bar |
| `cardBackground` | `#F5F4FA` | Secondary cards, input fill, nested surfaces |
| `ivory` | `#F0EFF5` | Subtle section dividers, alt backgrounds |
| `textDark` | `#1A1A2E` | Headlines, primary body text, titles |
| `textGrey` | `#6E6E82` | Secondary text, captions, descriptions |
| `textLight` | `#A0A0B4` | Placeholders, hints, disabled text |
| `successGreen` | `#2ECC71` | Success badges, completed states |
| `warningOrange` | `#FF9800` | Warning badges, pending states |
| `error` | `#E53935` | Error text, destructive actions, failed states |
| `accent` | `#FF6B6B` | Like buttons, hearts, attention markers |
| `gold` | `#FFD700` | Stars, ratings, premium indicators |
| `divider` | `#E8E6F0` | Borders, separators, card outlines |
| `shimmer` | `#EDE9FF` | Loading skeleton highlight |
| `gradientStart` | `#6C5CE7` | Gradient header left/top |
| `gradientEnd` | `#9D8AFF` | Gradient header right/bottom |

### Typography

| Style | Size | Weight | Color | Use For |
|-------|------|--------|-------|---------|
| Headline Large | 26px | 800 (Extra Bold) | `#1A1A2E` | Page titles, hero text |
| Headline Medium | 20px | 700 (Bold) | `#1A1A2E` | Section titles |
| Title Large | 18px | 700 (Bold) | `#1A1A2E` | App bar titles, card headers |
| Body Large | 15px | 400 (Regular) | `#1A1A2E` | Primary paragraph text |
| Body Medium | 14px | 400 (Regular) | `#1A1A2E` | Default body text |
| Body Small | 12px | 400 (Regular) | `#6E6E82` | Captions, timestamps |
| Label Small | 11px | 600 (Semi Bold) | `#6E6E82` | Chip labels, badges, categories |
| Button | 16px | 600 (Semi Bold) | `#FFFFFF` | Button text (on primary bg) |

### Component Specs

| Component | Background | Border | Shadow | Text Color |
|-----------|------------|--------|--------|------------|
| App Bar | `#FFFFFF` | none | none | `#1A1A2E` |
| Bottom Nav | `#FFFFFF` | none | `0,0,12 black@6%` | grey/primary |
| Card | `#FFFFFF` | `#E8E6F0` 0.8px | `0,2,8 black@4%` | `#1A1A2E` |
| Input Field | `#F5F4FA` fill | `#E8E6F0` 1px | none | `#1A1A2E` |
| Input Focused | `#F5F4FA` fill | `#6C5CE7` 1.5px | none | `#1A1A2E` |
| Primary Button | `#6C5CE7` | none | none (flat) | `#FFFFFF` |
| Chip (active) | `#EDE9FF` | none | none | `#6C5CE7` |
| Chip (inactive) | `#FFFFFF` | `#E8E6F0` | none | `#6E6E82` |
| Modal/Sheet | `#FFFFFF` | none | `0,-2,12 black@8%` | `#1A1A2E` |
| Gradient Header | `#6C5CE7` → `#9D8AFF` | none | none | `#FFFFFF` |

### Design Principles (Light)
- Pure white surfaces against a cool off-white background create depth without shadows
- Text uses deep navy (`#1A1A2E`) — never pure black, which feels harsh
- Grey text (`#6E6E82`) has strong contrast (WCAG AA compliant)
- Violet is used sparingly as accent — never as large background areas (except gradient header)
- Inputs use a tinted fill (`#F5F4FA`) to distinguish from card backgrounds

---

## Dark Theme — "Midnight Library"

An immersive, elegant dark interface inspired by a candlelit reading room. Deep navy backgrounds, soft lavender accents, and luminous surfaces that feel like frosted glass.

### Color Palette

| Token | Hex | Usage |
|-------|-----|-------|
| `primary` | `#B8A9FF` | Buttons, active states, links, accents |
| `primaryLight` | `#2A2545` | Selected tab backgrounds, badge fills |
| `primaryDark` | `#9D8AFF` | Pressed states, emphasis text |
| `background` | `#0F0F1A` | Scaffold/page background (deepest layer) |
| `surface` | `#1A1B2E` | Cards, sheets, modals, nav bar |
| `cardBackground` | `#1E2035` | Secondary cards, input fill, nested surfaces |
| `ivory` | `#161828` | Subtle section dividers, alt backgrounds |
| `textDark` | `#F0EEF6` | Headlines, primary body text, titles |
| `textGrey` | `#9B9AB0` | Secondary text, captions, descriptions |
| `textLight` | `#5E5D73` | Placeholders, hints, disabled text |
| `successGreen` | `#50E3A0` | Success badges, completed states |
| `warningOrange` | `#FFB74D` | Warning badges, pending states |
| `error` | `#E85D5D` | Error text, destructive actions |
| `accent` | `#FF8A80` | Like buttons, hearts, attention markers |
| `gold` | `#FFD54F` | Stars, ratings, premium indicators |
| `divider` | `#2A2D45` | Borders, separators, card outlines |
| `shimmer` | `#2A2545` | Loading skeleton highlight |
| `gradientStart` | `#6C5CE7` | Gradient header left/top |
| `gradientEnd` | `#B8A9FF` | Gradient header right/bottom |

### Typography

| Style | Size | Weight | Color | Use For |
|-------|------|--------|-------|---------|
| Headline Large | 26px | 800 (Extra Bold) | `#F0EEF6` | Page titles, hero text |
| Headline Medium | 20px | 700 (Bold) | `#F0EEF6` | Section titles |
| Title Large | 18px | 700 (Bold) | `#F0EEF6` | App bar titles, card headers |
| Body Large | 15px | 400 (Regular) | `#F0EEF6` | Primary paragraph text |
| Body Medium | 14px | 400 (Regular) | `#F0EEF6` | Default body text |
| Body Small | 12px | 400 (Regular) | `#9B9AB0` | Captions, timestamps |
| Label Small | 11px | 600 (Semi Bold) | `#9B9AB0` | Chip labels, badges, categories |
| Button | 16px | 600 (Semi Bold) | `#0F0F1A` | Button text (on primary bg) |

### Component Specs

| Component | Background | Border | Shadow | Text Color |
|-----------|------------|--------|--------|------------|
| App Bar | `#1A1B2E` | none | none | `#F0EEF6` |
| Bottom Nav | `#1A1B2E` | none | `0,0,12 black@30%` | grey/primary |
| Card | `#1A1B2E` | `#2A2D45` 0.8px | `0,2,8 black@15%` | `#F0EEF6` |
| Input Field | `#1E2035` fill | `#2A2D45` 1px | none | `#F0EEF6` |
| Input Focused | `#1E2035` fill | `#B8A9FF` 1.5px | none | `#F0EEF6` |
| Primary Button | `#B8A9FF` | none | none (flat) | `#0F0F1A` |
| Chip (active) | `#2A2545` | none | none | `#B8A9FF` |
| Chip (inactive) | `#1A1B2E` | `#2A2D45` | none | `#9B9AB0` |
| Modal/Sheet | `#1A1B2E` | none | `0,-2,12 black@20%` | `#F0EEF6` |
| Gradient Header | `#6C5CE7` → `#B8A9FF` | none | none | `#FFFFFF` |

### Design Principles (Dark)
- Background uses true deep navy (`#0F0F1A`) — never pure black, which looks like a broken screen
- Surfaces layer up in brightness: `#0F0F1A` → `#1A1B2E` → `#1E2035` (creates depth)
- Primary accent is soft lavender (`#B8A9FF`) — bright enough to read, soft enough to not strain
- Card borders (`#2A2D45`) are subtle but essential for defining edges without heavy shadows
- Text is soft white (`#F0EEF6`) — never pure `#FFFFFF`, which causes eye fatigue
- Button text on the lavender primary is deep navy (`#0F0F1A`) for maximum contrast
- Status colors are slightly desaturated/lighter than light mode (easier on dark backgrounds)

---

## AI Chat Theme — Special Override

The AI Chat screen uses its own enhanced palette for an immersive conversational experience.

### Dark Mode (Chat)

| Element | Color | Notes |
|---------|-------|-------|
| Background | `#0F0F1A` → `#12121F` gradient | Slightly warmer at bottom |
| Owl bubble | `#1E2035` + `#2E3150` border | Glass-like appearance |
| User bubble | `#4A3ABA` → `#6C5CE7` gradient | Purple gradient, not flat |
| Accent (bold text, cursor) | `#B8A9FF` | Soft violet highlights |
| Typing dots | `#B8A9FF` with glow | Pulsing animation |
| Particles | `#B8A9FF` + `#6C5CE7` mix | Floating luminous dust |
| Input bar bg | `#161828` | Slightly lighter than page bg |
| Send button | `#4A3ABA` → `#6C5CE7` gradient | Matches user bubble identity |

### Light Mode (Chat)

| Element | Color | Notes |
|---------|-------|-------|
| Background | `#F5F4FA` → `#EEECF8` gradient | Subtle violet tint |
| Owl bubble | `#F0EDFF` + `#E0DBFF` border | Soft lavender glass |
| User bubble | `#4A3ABA` → `#6C5CE7` gradient | Same as dark (brand) |
| Accent (bold text, cursor) | `#6C5CE7` | Deeper violet for contrast on light |
| Typing dots | `#6C5CE7` | Solid, no glow needed |
| Particles | `#B8A9FF` + `#6C5CE7` at 60% opacity | Subtler than dark mode |
| Input bar bg | `#F5F4FA` | Matches page |
| Send button | `#4A3ABA` → `#6C5CE7` gradient | Same brand identity |

---

## Implementation Rules

### DO
- Always use `AppColors.xxx` — never hardcode hex values in widget files
- Use `AppColors.surface` for any card/container/sheet background
- Use `AppColors.background` for scaffold/page backgrounds
- Use `AppColors.textDark` for primary text (adapts to white in dark mode)
- Use `AppColors.textGrey` for secondary/caption text
- Use `AppColors.divider` for all borders and separators
- Use `AppColors.cardBackground` for nested/secondary surfaces (inputs, inner cards)
- Keep `Colors.white` ONLY for text/icons displayed ON TOP of gradient backgrounds (they must always be white for contrast)
- Use `Theme.of(context).brightness == Brightness.dark` when you need conditional logic

### DON'T
- Never use `Color(0xFF...)` directly in widget files
- Never use `Colors.white` as a container/card background (use `AppColors.surface`)
- Never use `Colors.black` for text (use `AppColors.textDark`)
- Never use `const` before a widget that references `AppColors.xxx` (values are not compile-time constants)
- Never use pure black (`#000000`) backgrounds — always use `#0F0F1A`
- Never use pure white (`#FFFFFF`) text in dark mode — always use `#F0EEF6`

### Gradient Backgrounds
Elements on top of the purple gradient header (Home, Library, Quotes) use:
- Text: `Colors.white` (always readable on both themes since gradient stays purple)
- Icons: `Colors.white`
- Subtle overlays: `Colors.white.withOpacity(0.15-0.25)` (decorative circles, glass effects)

These are the ONLY exception to the "no Colors.white" rule.

---

## File Reference

| File | Purpose |
|------|---------|
| `lib/core/constants/app_theme.dart` | AppColors, AppTextStyles, AppTheme (ThemeData) |
| `lib/core/theme/theme_provider.dart` | ThemeProvider (ChangeNotifier + SharedPreferences persistence) |
| `lib/main.dart` | Registers ThemeProvider, calls `AppColors.updateBrightness()` |
| `lib/features/ai_chat/presentation/widgets/chat_theme.dart` | ChatColors (context-aware methods for AI chat) |

---

## Status Badge Colors

| Status | Light | Dark |
|--------|-------|------|
| Success / Done | `#2ECC71` @ 15% bg | `#50E3A0` @ 15% bg |
| Warning / Pending | `#FF9800` @ 15% bg | `#FFB74D` @ 15% bg |
| Error / Canceled | `#E53935` @ 12% bg | `#E85D5D` @ 12% bg |
| Info / In Review | `#2196F3` @ 15% bg | `#64B5F6` @ 15% bg |

---

*Last updated: 2026-05-28*
