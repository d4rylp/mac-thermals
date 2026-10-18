# Plan

Each phase follows the code integrity rules: it adds only what it uses, and only adds. It never
rewrites what earlier phases built, because the architecture was designed for all phases from the
start (see [ARCHITECTURE.md](ARCHITECTURE.md)).

## Phase 1 — Foundation and throttle status

- Repository hygiene, tooling (SwiftLint, swift-format, Makefile, pre-commit hook) and CI.
- `ThermalCore`: thermal pressure level, thermal state level, throttle evidence and assessment.
- `ThermalPlatform`: thermal pressure monitor (Darwin notify), thermal state monitor
  (`ProcessInfo`), launch at login (`SMAppService`).
- `ThermalUI` and the app: menu bar label, dropdown panel, Settings (General, About), first-launch
  window, reopen handling and app activation.

## Phase 2 — Sensors

- New in this phase:
  - sensor models (SensorCategory, SensorReading);
  - the reading filter, smoother and hysteresis;
  - °C/°F formatting and the Settings "Display" section;
  - the `thermals dump` CLI target;
  - a "Sensor dump for my Mac" issue template.
- SMC reader:
  - Open the AppleSMC service and enumerate keys via `#KEY`, reading by index.
  - Decode `flt ` (LE float32), `ioft` (48.16 fixed, 8 bytes) and legacy sp78.
  - Cache the key list per model identifier, then read only the selected keys.
- HID reader:
  - IOHIDEventSystemClient services with PrimaryUsagePage 0xff00 / PrimaryUsage 5.
  - IOHIDServiceClientCopyEvent with type 15 (temperature); value from IOHIDEventGetFloatValue with
    field 15<<16; name from the "Product" property.
  - These symbols are exported from IOKit but private: declare them in a small C shim, only inside
    ThermalPlatform.
- Curated per-chip sensor tables as JSON resources: M1, M2, M3, M4, M5, M6 (provisional), A18 Pro
  (MacBook Neo). Plus generic discovery of any `T***` key, shown as "Other sensors".
- Core tier names come from sysctl hw.perflevelN.name. Never hard-code E/P:
  - M1–M4: efficiency + performance.
  - Base M5: super + efficiency.
  - M5 Pro/Max: super + performance (no efficiency cores).
  - M6: super + performance + efficiency.
- Fans (read-only): FNum, F{i}Ac/Mn/Mx/Tg. FNum 0 or missing means fanless (all MacBook Airs,
  MacBook Neo); no fan group then.
- Filtering:
  - Reject non-finite values and anything outside 10–130 °C.
  - Exclude calibration sensors ("PMU tcal", SMC "TR0Z").
  - Mark parked-core placeholders as inactive (all per-core values identical, e.g. 40.0).
- Smoothing and display: EMA (alpha ≈ 0.4) and a 2.5 °C hysteresis band.
- Headline is the hottest CPU reading. Details show per-group max/average.
- Sampling: 3–5 s with the panel closed, 1 s with it open. Timer tolerance ≥10 %. Pause on sleep and
  screen lock.
- Contributor sensor dumps become test fixtures and table entries.

## Phase 3 — Throttling evidence

- IOReport (private libIOReport): "CPU Stats" / "CPU Core Performance States" and the GPU
  equivalents.
- Residency deltas give average MHz versus the max DVFS state, read from the IORegistry pmgr node.
- Add clock-speed evidence to ThrottleAssessment as a new input: sustained high active residency with
  clocks well below max, alongside pressure ≥ moderate.
- Opt-in notifications on throttle start/end.

## Phase 4 — History

- Storage: SQLite via GRDB in ~/Library/Application Support/io.github.d4rylp.MacThermals/, WAL mode.
- What to record:
  - Key series every 5 s: hottest CPU, CPU average, GPU max, SoC, SSD, battery, pressure level,
    CPU/GPU MHz, throttled flag, fan RPM.
  - All sensors every 60 s.
  - Events table: pressure changes, throttle start/stop, sleep/wake, app launch/quit, OS version.
- Writing and retention: buffer in memory and write in one transaction every 30–60 s. Prune hourly.
  Retention setting 24 h / 48 h / 7 d.
- Overnight reliability:
  - Wrap recording in a ProcessInfo activity that disables App Nap but allows idle sleep.
  - Optional "Keep Mac awake while recording" toggle via an IOPMAssertion.
  - Sleep periods appear as labelled gaps.
- History window:
  - Swift Charts, ranges 1/6/24/48 h, min/max/avg bucket downsampling to ≤1,500 points per series.
  - Charts: temperatures with pressure bands and throttled shading; CPU/GPU MHz; fan RPM.
  - Hover/scrub for values; drill into a full 60 s snapshot.
  - Overnight summary, e.g. "Throttled 2 h 13 m (01:12–03:40), peak 104 °C at 02:15, slept
    04:30–06:10".
  - CSV/JSON export.
- Later: record the top 3–5 CPU processes (libproc) with each 60 s snapshot.

## Phase 5 — Polish

- 10-minute sparkline in the panel. Optional menu bar temperature text. App icon (Icon Composer).

## Phase 6 — Release (optional, later)

- Developer ID signing, notarization and stapling in a tag-triggered GitHub Actions workflow with
  secrets in a protected environment.
- Sparkle 2 with feed URL https://github.com/d4rylp/mac-thermals/releases/latest/download/appcast.xml.
- Homebrew tap d4rylp/homebrew-tap.

## Research

### Platform facts (Oct 2026)

- macOS 27 "Golden Gate" shipped Sep 14, 2026 and supports Apple Silicon only (macOS 26 Tahoe was the
  last Intel release).
- Xcode 27.1 ships Swift 6.4. New Xcode projects still default to Swift 5 mode, so set Swift 6
  explicitly.
- macOS 27 changes that matter here:
  - Menus hide item icons by default (opt in via `.labelStyle(.titleAndIcon)` /
    NSMenuItem.preferredImageVisibility).
  - The menu bar has an overflow chevron.
  - Liquid Glass is mandatory with the 27 SDK.
  - `@State` is now a macro.
  - MenuBarExtra is unchanged.
  - NSStatusItem gains expandedInterfaceDelegate/Session (MenuBarExtra handles this).

### Throttling signals

- Use: notify "com.apple.system.thermalpressurelevel" (public header, no root, 5 levels, push via
  notify_register_dispatch) and ProcessInfo.thermalState (coarse: on an M2 Air both moderate and
  heavy pressure report as "fair").
- Don't use: `pmset -g therm`, which reports nothing on Apple Silicon. `powermetrics` needs root.
- Source: https://stanislas.blog/2025/12/macos-thermal-throttling-app/

### No public temperature API

- Apple DTS has said there is no supported API for CPU temperature; SMC/HID are private. That's why
  this app isn't on the Mac App Store.
- https://developer.apple.com/forums/thread/689556

### SMC keys by chip (from Stats Modules/Sensors/values.swift)

- M1: E Tp09/Tp0T; P Tp01/05/0D/0H/0L/0P/0X/0b; GPU Tg05/0D/0L/0T.
- M2: E Tp1h/1t/1p/1l; P Tp01/05/09/0D/0X/0b/0f/0j; GPU Tg0f/0j.
- M3: E Te05/0L/0P/0S; GPU and P-core keys disputed between Stats (Tf**) and iSMC (Tp**), so verify
  with dumps.
- M4: E Te05/0S/09/0H; P Tp01/05/09/0D/0V/0Y/0b/0e; GPU Tg0G/0H (M4), Tg1U/1k (Pro/Max); memory
  Tm0p/1p/2p. M4 Pro uses Te06/Te0T/Tp0H instead of Te09/Te0H/Tp0V (Stats issue #3270).
- M5 Pro/Max: super Tp00–Tp0K; performance Tp0O–Tp0y; GPU Tg**; memory Tm**; package TN00–TN07.
- Stable across chips: TH0x NAND, TB0T/TB1T/TB2T battery, TW0P Wi-Fi, TCHP charger, TaLP/TaRF
  airflow (fan Macs).
- Per-core keys often come in triplets (probe A, probe B, max). Ts0P is an SSD controller on Apple
  Silicon, not the palm rest.
- Sources:
  - https://raw.githubusercontent.com/exelban/stats/master/Modules/Sensors/values.swift (MIT)
  - https://raw.githubusercontent.com/dkorunic/iSMC/master/src/temp.txt (check its licence before
    reusing data)
  - https://asahilinux.org/docs/hw/soc/smc/

### HID sensor names

- "pACC MTR Temp Sensor N" / "eACC MTR Temp Sensor N" (CPU clusters), "GPU MTR", "SOC MTR",
  "ANE MTR", "ISP MTR", "PMGR SOC Die".
- "PMU tdie N" (die), "PMU tdev N" (board thermistors; may be raw sp78 if >130).
- "PMU tcal" (calibration: exclude it).
- "NAND CH0 temp", "gas gauge battery".
- Source: https://chromium.googlesource.com/chromium/src/+/main/components/power_metrics/m1_sensors_mac.mm

### Pitfalls

- Parked cores report placeholders (−4, 0, ~1.5–5, or every core exactly 40.0):
  https://github.com/exelban/stats/issues/3692
- ioft sentinel values. Non-temperature T keys (TVM*, Tf?6 static ~64 °C, TR0Z fixed 51.85 °C).
- Sanity filters used by other tools: Stats 0–110 °C; macmon 0–150 °C; Hot 0–120 °C.

### macOS 27 breakage to expect

- IOReport "Energy Model" power counters need a private entitlement: https://github.com/vladkens/macmon
- IOPMPowerSource battery Temperature no longer returned: https://developer.apple.com/forums/thread/844418
- Macs Fan Control lost sensors on 27.0, fixed Oct 13: https://github.com/crystalidea/macs-fan-control/issues/913
- Apple changes keys per SoC and OS release, so plan for ongoing table maintenance driven by
  contributor dumps.

### Prior art to read (don't copy code without respecting licences)

- exelban/stats (MIT), vladkens/macmon, dkorunic/iSMC, macmade/Hot.
