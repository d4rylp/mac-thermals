# Design rules

Mac Thermals follows Apple's [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
(Menu bar → Menu bar extras, Settings, Accessibility, Color, Typography, Materials / Liquid Glass,
Writing, Onboarding, Notifications, Charts). These rules are mandatory for every change. Rules marked
**(later)** apply to features from later phases in [PLAN.md](PLAN.md); they are here so those phases
are designed consistently.

## Menu bar item

- The icon is an SF Symbol from the `thermometer.*` family, rendered as a monochrome template image
  so the system tints it for light and dark menu bars and the highlighted state.
- Status changes are shown by **switching symbol**, never by tinting with colour:

  | Status | Symbol |
  | --- | --- |
  | Not throttling | `thermometer.low` |
  | Throttling, moderate | `thermometer.medium` |
  | Throttling, heavy | `thermometer.high` |
  | Throttling, critical | `thermometer.sun.fill` |
  | Status unavailable | `thermometer.medium.slash` |

  `ThermalUITests` verifies that every symbol name exists.
- No animation, flashing or badges in the menu bar.
- The accessibility label states the current status, for example "Mac Thermals, not throttling".
- Never rely on the item being visible. macOS hides extras when space runs out, and macOS 27 has a
  menu bar overflow. So:
  - a first-launch window explains where the app lives;
  - launching the app again from Finder or Spotlight while it is running opens Settings (reopen
    handling).
- **(later)** Optional temperature text uses monospaced digits and whole degrees so the item's width
  stays stable.

## Dropdown panel

- Most important first: the throttle status is a large headline with a plain-language explanation,
  for example "Not throttling" / "Throttling" with "Your Mac is reducing performance to cool down."
  Jargon such as the raw level ("Thermal pressure: Moderate") goes in secondary rows.
- Supporting rows follow. **(later)** Sensor groups use progressive disclosure: a summary per group,
  expanded for detail.
- Standard SwiftUI controls, layouts and system materials only. Liquid Glass comes from the system:
  no custom chrome, no glass-on-glass layering, no hard-coded backgrounds. Where shapes nest inside
  the panel, use concentric corner radii.
- System text styles only (`.largeTitle`, `.title`, `.headline`, `.body`, `.callout`, `.caption`).
  No fixed point sizes, no custom fonts.
- Footer: "Settings…" (⌘,) and "Quit Mac Thermals" (⌘Q). macOS title case; an ellipsis only on items
  that open further UI.
- Fully keyboard navigable; Esc closes the panel. Width 340 pt, never horizontal scrolling.

## Colour and status

- Never convey status by colour alone. Status is always a symbol **and** text, with colour as a
  redundant third cue. Each status has its own symbol shape and its own wording, so nothing changes
  meaning when `accessibilityDifferentiateWithoutColor` is on.
- Semantic system colours only, never hard-coded RGB:

  | Status | Colour |
  | --- | --- |
  | Not throttling | `.green` |
  | Throttling, moderate | `.yellow` |
  | Throttling, heavy | `.orange` |
  | Throttling, critical | `.red` |
  | Status unavailable | `.secondary` |

  They adapt to light and dark mode and Increase Contrast.
- Honour Reduce Motion: no animated transitions when it is on. Phase 1 has no animations at all; any
  later animation must check `accessibilityReduceMotion`.
- Honour Reduce Transparency: standard materials handle it; never override them.

## Accessibility

- Every value has a VoiceOver label and value, with units spoken naturally ("CPU performance cores,
  72 degrees Celsius").
- Group related elements; section titles are accessibility headers.
- Every change is checked with VoiceOver and Full Keyboard Access (both are on the pull request
  checklist).

## Units, formatting and localisation

- **(later)** Temperatures are `Measurement<UnitTemperature>` formatted with the system formatters so
  they follow the user's °C/°F setting, with an optional System / °C / °F override in Settings.
- Dates and times use system formatters.
- All user-facing text is in String Catalogs. Pluralisation goes through catalog variations. Never
  build sentences by concatenation.

## Settings window

- The standard `Settings` scene with a `Form` using `.formStyle(.grouped)`. Sections exist only for
  settings that exist.
- Changes apply instantly: no Apply or Save buttons.
- Phase 1 sections:
  - **General**
    - Launch at login: `SMAppService.mainApp` register/unregister, off by default. The control
      reflects the actual status, including "requires approval in System Settings", with a button
      that opens Login Items settings.
    - A note on finding the menu bar icon.
  - **About**: version, GitHub link, licence.

## Onboarding

- One short first-launch window, shown once (tracked in `UserDefaults`): what the app does, where it
  lives (the menu bar, possibly behind the overflow), and an optional launch-at-login toggle.
- Skippable; a single primary button. Closing the window counts as finishing it.
- Never ask for permissions up front. Ask in context (for example, notification permission only when
  the user turns notifications on).

## Windows from an agent app

- Mac Thermals is an agent app (`LSUIElement`). When it opens Settings or the welcome window
  (**(later)** and History), it activates itself so the window comes to the front and takes key
  focus.
- Windows use standard title bars and restore their size and position.

## Notifications (later)

- Opt-in only.
- Notify only on meaningful transitions (throttling starts or ends), with hysteresis and a cooldown.

## Charts (later)

- Swift Charts with clear axis labels, units, legends and accessibility (audio graphs and
  descriptive labels).
- Pressure shown as background bands; throttling as shaded regions.

## Empty and error states

- When a data source is unavailable, say so honestly ("Sensor readings aren't available on this
  Mac"), never a blank or a 0. In phase 1, a signal macOS isn't reporting reads "Not available", and
  the headline reads "Status unavailable" with an explanation.

## App icon

- A macOS layered icon made with Icon Composer (`.icon`), added when designed. No placeholder icon
  meanwhile; the system default is fine.

## Writing

- Plain, calm, specific language.
- Title case for buttons and menu items; sentence case for descriptive text.
- Explain states rather than just naming them.

## Energy is UX

- A menu bar app must be near-invisible in Activity Monitor's Energy tab.
- Event-driven where possible (phase 1 is entirely push-based: Darwin notify and `ProcessInfo`
  notifications).
- **(later)** Coalesced timers with at least 10 % tolerance; no needless work while the panel is
  closed.
