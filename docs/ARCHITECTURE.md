# Architecture

This document describes the **final** architecture of Mac Thermals: every phase in
[PLAN.md](PLAN.md), not only the one being built. It was written before any code. Each phase
implements its slice of this design exactly, and later phases plug in **purely by addition**: new
types, new members, new targets, new views and new sections. No phase rewrites, restructures or
replaces what an earlier phase wrote.

If a change seems to require reshaping existing code, the design below is wrong: fix this document
first, in its own pull request, and explain why.

## Principles

1. **Sources push, the model holds, views read.** System integration produces values as
   `AsyncStream`s. One `@Observable` app model consumes them and is the single source of truth.
   Views, the menu bar label and Settings only read the model (and call its intent methods).
2. **Domain logic is pure.** Everything that decides something (what a pressure level means, whether
   the Mac is throttling, how readings are filtered, how history is downsampled) lives in
   `ThermalCore`, takes its inputs as values and is unit-tested without touching the system.
3. **System access is isolated.** Only `ThermalPlatform` talks to Darwin notify, `ProcessInfo`
   notifications, ServiceManagement, IOKit, SMC, HID, IOReport, sysctl and power management. Private
   API declarations live in a C shim that only `ThermalPlatform` can see.
4. **Interfaces belong to the domain.** The protocols a source conforms to are declared in
   `ThermalCore`, so `ThermalUI` depends on `ThermalCore` only and its model is tested with fakes.
   The app target is the only place that knows which concrete source feeds which model member.
5. **Event-driven and cheap.** Prefer push notifications over polling. Where sampling is
   unavoidable (phase 2 onwards) it uses coalesced timers with at least 10 % tolerance, slows down
   while the panel is closed and stops during sleep and screen lock.

## Repository layout (all phases)

The phase that introduces each item is in brackets. Nothing is listed here that a phase would later
move or rename.

```
App/                                  [1] App target "Mac Thermals" (menu bar agent)
  MacThermalsApp.swift                [1] Scenes: MenuBarExtra, Settings, Welcome window; [4] History window
  AppDelegate.swift                   [1] Launch wiring of sources into the model, reopen handling
  Localizable.xcstrings               [1] Strings owned by the app target (scene titles)
  MacThermals.entitlements            [1] Sandbox off; hardened runtime is a build setting
  Icon.icon                           [5] Layered app icon from Icon Composer
  Updater.swift                       [6] Sparkle 2 updater controller (app target only)
AppTests/                             [1] Hosted app tests (bundle configuration)
AppUITests/                           [1] XCUITest: welcome window, panel, Settings, reopen
Config/
  Base.xcconfig                       [1] Signing defaults; `#include? "Local.xcconfig"`
  Local.xcconfig                      [1] Optional, gitignored: personal DEVELOPMENT_TEAM
Packages/ThermalKit/                  [1] The one local SwiftPM package
  Package.swift
  Sources/
    ThermalCore/                      [1] Domain logic, no UI, no system access
    ThermalPlatform/                  [1] System integration
    CPrivateAPI/                      [2] C declarations of private IOKit/HID [3] and IOReport symbols
    ThermalHistory/                   [4] SQLite (GRDB) storage, recorder, queries, export
    ThermalUI/                        [1] SwiftUI views and the app model
    thermals/                         [2] `thermals` command-line tool (`thermals dump`)
  Tests/
    ThermalCoreTests/                 [1]
    ThermalPlatformTests/             [1]
    ThermalUITests/                   [1]
    ThermalHistoryTests/              [4]
docs/                                 [1] ARCHITECTURE.md, DESIGN.md, PLAN.md
scripts/pre-commit                    [1] Runs `make lint`
.github/workflows/ci.yml              [1] Lint, build, test
.github/workflows/release.yml         [6] Tag-triggered sign, notarize, staple, appcast
project.yml                           [1] XcodeGen spec (the .xcodeproj is generated, not committed)
```

## Module graph

```
App target ──► ThermalUI ──────────► ThermalCore
     │             └─[4]─► ThermalHistory ──► ThermalCore, GRDB
     ├────────► ThermalPlatform ───► ThermalCore
     │             └─[2]─► CPrivateAPI (C declarations, not a product)
     ├─[4]────► ThermalHistory
     └─[6]────► Sparkle

[2] thermals CLI ──► ThermalPlatform, ThermalCore
```

Rules:

- `ThermalCore` depends only on Foundation. It has no knowledge of SwiftUI, AppKit, IOKit, notify
  or ServiceManagement.
- `ThermalPlatform` depends on `ThermalCore` (and, from phase 2, the `CPrivateAPI` C target). It
  conforms concrete monitors to `ThermalCore` protocols.
- `ThermalUI` depends on `ThermalCore` (and, from phase 4, `ThermalHistory`). It never imports
  `ThermalPlatform`; it never reads the system directly except standard app services such as
  `NSApplication` activation and `UserDefaults`-backed `@AppStorage`.
- `ThermalHistory` depends on `ThermalCore` and GRDB.
- `thermals` depends on `ThermalCore` and `ThermalPlatform`.
- The app target depends on `ThermalCore`, `ThermalPlatform` and `ThermalUI` (and, from phase 4,
  `ThermalHistory`; from phase 6, Sparkle).

Adding a target is an append to `Package.swift` and `project.yml`; existing targets keep their names,
paths and contents.

## Data flow

```
 ThermalPlatform (sources)            ThermalUI (ThermalModel, @MainActor @Observable)        Views
 ───────────────────────────          ──────────────────────────────────────────────          ─────
 ThermalPressureMonitor ──AsyncStream──► observe(_: ThermalPressureSource) ─► pressureLevel ─┐
 ThermalStateMonitor    ──AsyncStream──► observe(_: ThermalStateSource)    ─► thermalState  ─┤
 [2] SensorMonitor      ──AsyncStream──► observe(_: SensorSource)          ─► sensors       ─┤
 [3] ClockSpeedMonitor  ──AsyncStream──► observe(_: ClockSpeedSource)      ─► clockSpeeds   ─┤
                                              │                                              ├─► MenuBarLabel
                                              └─► throttleEvidence ─► throttleAssessment ─────┤   DashboardView
 LaunchAtLoginController ◄── intents ──── setLaunchAtLogin(_:) ─► launchAtLoginStatus ───────┘   SettingsView
                                                                                                  WelcomeView
 Consumers that react to the model (purely additive, via Observation's `Observations`):
   [3] ThrottleNotifier      observes throttleAssessment → opt-in notifications
   [4] HistoryRecorder       observes the model's readings → buffered SQLite writes
   [5] Sparkline buffer      observes the headline temperature → 10-minute ring buffer
```

### The app model

`ThermalModel` (in `ThermalUI`) is the single source of truth. It is `@MainActor` and `@Observable`.

- **One `observe(_:)` overload per source protocol.** Each is an `async` method that iterates the
  source's stream until it ends and writes into its own stored members. The app delegate starts one
  task per source at launch. A later phase adds a source by adding a new protocol (in
  `ThermalCore`), a new conforming monitor (in `ThermalPlatform`), a new `observe(_:)` overload and
  members (in `ThermalModel`), and one new line in the app delegate. Existing overloads are
  untouched.
- **Intent methods** (`setLaunchAtLogin(_:)`, `refreshLaunchAtLoginStatus()`,
  `openLoginItemsSettings()`) are how views change things. Later intents (sampling cadence while
  the panel is open, notification opt-in, retention) are new methods.
- **Derived values** (`throttleAssessment`) are computed from stored members, so they can never be
  stale.

Consumers that *react* to the model (notifications, history recording, the sparkline buffer) do not
change the model: they observe it with `Observations` and run in their own tasks, started by the app
delegate. This keeps every observe overload single-purpose and lets those phases add behaviour
without editing the model's existing code.

### Throttle assessment

Whether the Mac is throttling is decided from a *set of evidence*, so new kinds of evidence can be
added without changing how existing kinds are evaluated.

```
protocol ThrottleEvidence: Sendable {
    static var authority: ThrottleEvidenceAuthority { get }   // .primary or .fallback
    var throttleStatus: ThrottleStatus? { get }               // nil = no information right now
}
```

- `ThermalPressureLevel` is `.primary` evidence. `.unknown` pressure carries no information.
- `ThermalStateLevel` (from `ProcessInfo`) is `.fallback` evidence: coarse, so it only decides when
  no primary evidence is informative.
- `ThrottleEvidenceSet` keeps the latest evidence of each kind (keyed by its type), so a new reading
  replaces the previous reading of the same kind and never accumulates.
- `ThrottleAssessment(evidence:)` takes the evidence with the highest authority that has
  information and reports the most severe status among it: `.notThrottled` or
  `.throttled(ThrottleSeverity)`, or no status at all when nothing is informative. It provides
  localised `title` and `explanation` strings. The rule is order-independent and does not know any
  concrete evidence type.

**Phase 3 plugs in by addition:** a new `ClockSpeedEvidence` value type (in `ThermalCore`) conforms
to `ThrottleEvidence` with `.primary` authority. It reports throttling only for sustained high
active residency with clocks well below the maximum DVFS state *alongside* pressure of at least
moderate (it is built from the residency deltas and the current pressure level), so it can raise the
severity but never contradicts the pressure signal. `ThermalModel` gains
`observe(_: ClockSpeedSource)`, which updates `clockSpeeds` and inserts the new evidence into the
existing `throttleEvidence` set. `ThrottleAssessment` and the existing evidence types do not change.

## Modules in detail

### ThermalCore

| Type | Phase | Purpose |
| --- | --- | --- |
| `ThermalPressureLevel` | 1 | macOS notify thermal pressure (0 nominal, 1 moderate, 2 heavy, 3 trapping, 4 sleeping, `unknown(raw)`); primary evidence |
| `ThermalStateLevel` | 1 | Wraps `ProcessInfo.ThermalState`; fallback evidence |
| `ThrottleEvidence`, `ThrottleEvidenceAuthority` | 1 | Evidence abstraction |
| `ThrottleSeverity`, `ThrottleStatus` | 1 | Ordered outcomes |
| `ThrottleEvidenceSet`, `ThrottleAssessment` | 1 | Combination rule and localised wording |
| `ThermalPressureSource`, `ThermalStateSource` | 1 | Source protocols (`AsyncStream`) |
| `LaunchAtLoginService`, `LaunchAtLoginStatus` | 1 | Login item abstraction |
| `SensorCategory`, `SensorReading`, `SensorSnapshot` | 2 | Sensor model; groups and per-group max/average |
| `SensorTable`, `SensorTableEntry` | 2 | Decoded per-chip JSON tables (resources of this target) |
| `CoreTier` | 2 | Core tier names from `hw.perflevelN.name` values, never hard-coded |
| `FanReading` | 2 | Read-only fan state; absent when fanless |
| `ReadingFilter`, `ReadingSmoother` | 2 | Range/calibration/parked-core filtering, EMA and hysteresis |
| `TemperatureUnitPreference`, temperature formatting | 2 | `Measurement<UnitTemperature>` with System / °C / °F |
| `SensorSource` | 2 | Source protocol |
| `ClockSpeedEvidence`, `ClockResidency`, `ClockSpeedSource` | 3 | Residency maths and evidence |
| `ThrottleTransitionDetector`, `NotificationService` | 3 | Hysteresis and cooldown for notifications; delivery protocol |

### ThermalPlatform

| Type | Phase | Purpose |
| --- | --- | --- |
| `ThermalPressureMonitor` | 1 | Darwin notify `com.apple.system.thermalpressurelevel`; initial value via `notify_register_check` + `notify_get_state`, updates via `notify_register_dispatch` |
| `ThermalStateMonitor` | 1 | `ProcessInfo.thermalState` + `thermalStateDidChangeNotification` |
| `LaunchAtLoginController` | 1 | `SMAppService.mainApp` |
| `SMCReader` | 2 | AppleSMC connection, `#KEY` enumeration by index, `flt `/`ioft`/`sp78` decoding, per-model key cache |
| `HIDSensorReader` | 2 | IOHIDEventSystemClient temperature services |
| `HardwareInfo` | 2 | Model identifier, chip, `hw.perflevelN.name` |
| `SensorMonitor` | 2 | Samples readers on a tolerant timer; cadence from the model; pauses on sleep and screen lock |
| `IOReportReader`, `ClockSpeedMonitor` | 3 | CPU/GPU performance-state residency |
| `UserNotificationService` | 3 | `UNUserNotificationCenter`, authorisation requested in context |
| `RecordingActivity` | 4 | `ProcessInfo` activity (no App Nap, idle sleep allowed) and optional `IOPMAssertion` |
| `ProcessSampler` | 4 | Top CPU processes via libproc |

`CPrivateAPI` (phase 2) is a C target with a module map that declares the private but exported
IOKit HID and IOReport symbols. Only `ThermalPlatform` depends on it; it is not a product.

### ThermalUI

| Type | Phase | Purpose |
| --- | --- | --- |
| `ThermalModel` | 1 | The app model (see above) |
| `ThrottleStatusAppearance` | 1 | Symbol, semantic colour and accessibility wording per status |
| `MenuBarLabel` | 1 | Template SF Symbol; [5] optional monospaced whole-degree text |
| `DashboardView`, `DashboardContent` | 1 | The dropdown panel: headline, signal rows, footer; [2] sensor groups; [5] sparkline |
| `SettingsView` | 1 | General and About; [2] Display; [3] Notifications; [4] History |
| `LaunchAtLoginToggle`, `LaunchAtLoginRow` | 1 | Login item control with honest status |
| `WelcomeView` | 1 | First-launch window |
| `SensorGroupSection` | 2 | Progressive disclosure per sensor group |
| `HistoryView` and charts | 4 | Swift Charts history window |

`DashboardContent` and `LaunchAtLoginRow` take plain values so they can be previewed for every state
without fake sources; `DashboardView` and `LaunchAtLoginToggle` adapt the model to them.

### ThermalHistory (phase 4)

GRDB over SQLite in `~/Library/Application Support/io.github.d4rylp.MacThermals/` (WAL mode).
`HistoryRecorder` (an actor) buffers samples in memory and writes them in one transaction every
30–60 s; pruning runs hourly against the retention setting. Queries return bucketed min/max/avg
series (≤1,500 points per series), sleep gaps and the overnight summary; export writes CSV/JSON.

### thermals CLI (phase 2)

An executable target named `thermals` with a `dump` command that prints every SMC and HID
temperature source, the model identifier and the core tiers, in the format the "Sensor dump for my
Mac" issue template asks for. Contributor dumps become `ThermalCoreTests` fixtures and table entries.

## How each phase plugs in

| Phase | Adds | Existing code touched |
| --- | --- | --- |
| 1 | Everything listed as [1] | — |
| 2 | Sensor types and tables (Core); `CPrivateAPI`; SMC/HID readers, `HardwareInfo`, `SensorMonitor` (Platform); `ThermalModel.sensors` + `observe(_: SensorSource)` + cadence intent; `SensorGroupSection` and a Display section; `thermals` target; issue template | One `observe` task in `AppDelegate`; a new section placed in the panel and Settings bodies; new entries in `Package.swift`/`project.yml` |
| 3 | `ClockSpeedEvidence` and friends (Core); IOReport reader and monitor (Platform); `observe(_: ClockSpeedSource)`; `ThrottleNotifier`; Notifications section | One `observe` task and one notifier task in `AppDelegate`; a new Settings section |
| 4 | `ThermalHistory` target; recorder task; History window scene and views | New scene in `MacThermalsApp`; a "History…" footer item; a new Settings section |
| 5 | Sparkline view and buffer; optional menu bar text; app icon | New subviews in the panel and label |
| 6 | Release workflow; Sparkle updater; Homebrew tap | A new app-target file and a "Check for Updates…" item |

"Touched" means new lines placed into an existing body or list; no existing line changes meaning.

## Concurrency

- Swift 6 language mode with complete concurrency checking everywhere.
- App target: default actor isolation `MainActor`, approachable concurrency.
- Package targets: nonisolated by default. Everything that crosses an isolation boundary is
  genuinely `Sendable` (value types, `AsyncStream`, actors). `ThermalModel` is explicitly
  `@MainActor`.
- Sources expose `AsyncStream`s whose `onTermination` releases the underlying registration.

## Logging

`os.Logger` with one subsystem per module, `io.github.d4rylp.MacThermals.<Module>`, and a category
per type. The app target uses `io.github.d4rylp.MacThermals`.

## Localisation

All user-facing text lives in String Catalogs: one per target that owns text (`ThermalCore`,
`ThermalUI`, the app). Package code always passes `bundle: .module`. Pluralisation uses catalog
variations; sentences are never assembled by concatenation. Measurements, dates and times use system
formatters.

## Testing

- `ThermalCoreTests`: Swift Testing, parameterised over raw values and evidence combinations.
- `ThermalPlatformTests`: run against the real system on macOS; they check that monitors produce an
  initial value and release their registrations.
- `ThermalUITests`: `ThermalModel` with fake sources and a fake login item service; symbol names
  exist in SF Symbols.
- `AppTests`: hosted in the app; verify the built bundle's configuration (agent app, bundle
  identifier, deployment target).
- `AppUITests`: XCUITest (Swift Testing can't drive `XCUIApplication`) launches the built app and
  drives the welcome window, the menu bar panel (Esc, Settings…, Quit), Settings and reopen handling.
  [4] adds the History window.
- `ThermalHistoryTests` (phase 4): in-memory database.

## Build configuration

- XcodeGen generates `MacThermals.xcodeproj` from `project.yml`; one scheme runs the app tests and
  all package test targets.
- `ARCHS = arm64`, `MACOSX_DEPLOYMENT_TARGET = 27.0`, hardened runtime on, App Sandbox off.
- Warnings are errors in every configuration, for the app (`SWIFT_TREAT_WARNINGS_AS_ERRORS`,
  `GCC_TREAT_WARNINGS_AS_ERRORS`) and the package (`treatAllWarnings(as: .error)`).
- Signing defaults to "Sign to Run Locally" (`CODE_SIGN_IDENTITY = -`) from `Config/Base.xcconfig`,
  which optionally includes a gitignored `Config/Local.xcconfig`. CI builds with
  `CODE_SIGNING_ALLOWED=NO`.
