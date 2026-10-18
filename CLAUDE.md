# CLAUDE.md

Guidance for Claude (and other agents) working in this repository.

## What this is

Mac Thermals: a native macOS 27 menu bar app (Apple Silicon only) that shows whether the Mac is
thermally throttled, and later sensor temperatures and history. Distributed as source; not on the Mac
App Store because later phases read private SMC/HID APIs.

## Read first

- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md): the final architecture for every phase. Code
  implements its slice exactly; later phases only add.
- [docs/DESIGN.md](docs/DESIGN.md): mandatory UX rules from Apple's Human Interface Guidelines.
  Follow them for every user-facing change.
- [docs/PLAN.md](docs/PLAN.md): the phased plan and research notes.
- [CONTRIBUTING.md](CONTRIBUTING.md): contributor workflow.

## Commands

```sh
make project   # xcodegen generate (MacThermals.xcodeproj is generated, never committed)
make build     # Debug build of the app
make test      # app unit + UI tests and all ThermalKit test targets via xcodebuild
make lint      # swiftlint --strict and swift format lint --strict
make format    # swift format in place
make install   # Release build copied to /Applications
make clean
make hooks     # pre-commit hook that runs make lint
```

CI (`.github/workflows/ci.yml`) runs `make lint`, `make build` and `make test` on the `xcode-27`
runner with Xcode 27.1 and `CODE_SIGNING_ALLOWED=NO`. When working from Linux, CI is the build and
test environment.

## Module rules

- `ThermalCore`: domain logic and the protocols sources conform to. Foundation only: no SwiftUI,
  AppKit, IOKit, notify or ServiceManagement. Fully unit-tested with Swift Testing.
- `ThermalPlatform`: system integration; depends on `ThermalCore`. Private API declarations (from
  phase 2) live in a C shim that only this target sees.
- `ThermalUI`: SwiftUI views and `ThermalModel`, the single `@Observable` source of truth. Depends on
  `ThermalCore`, never on `ThermalPlatform`. Views that need previews take plain values; thin
  adapters connect them to the model.
- `App/`: scenes and the app delegate, the only place that wires concrete sources into the model.
- New sources: a protocol in `ThermalCore`, a monitor in `ThermalPlatform`, an `observe(_:)` overload
  and members on `ThermalModel`, and one task in `AppDelegate`.
- New throttle evidence: a new `ThrottleEvidence` type inserted into the model's evidence set.
  `ThrottleAssessment` doesn't change.

## Conventions

- Swift 6 mode, complete concurrency checking. App target: default isolation `MainActor`,
  approachable concurrency. Package targets: nonisolated by default, cross-thread values genuinely
  `Sendable`.
- Deployment target macOS 27.0, `arm64` only. No `#available` checks.
- Warnings are errors everywhere. SwiftLint strict; swift-format strict; they agree.
- Public API has doc comments. Tests use Swift Testing; UI tests (`AppUITests`) use XCTest because
  Swift Testing can't drive `XCUIApplication`.
- All user-facing text in String Catalogs (`bundle: .module` in package code); no sentences built by
  concatenation. Long strings use multi-line literals with `\` continuations.
- `os.Logger` with subsystem `io.github.d4rylp.MacThermals.<Module>`.
- No third-party runtime dependencies until a phase in the plan adds one.

## Code integrity rules (non-negotiable)

- Design for the whole plan; each phase only adds. Never rewrite, restructure or replace earlier
  work. Never implement ahead, and never make a choice a later phase would have to undo.
- Everything in the repository is real, used and tested. Never write stubs, placeholders, "coming
  soon" UI, mock data in production code, TODO/FIXME/HACK, commented-out code, unused declarations or
  files, code for later phases, feature flags, temporary code, compatibility shims, deprecated APIs or
  `#available` branches.
- No diagnostic silencers: `@preconcurrency`, `nonisolated(unsafe)`, `@unchecked Sendable`,
  `swiftlint:disable`, loosened lint/format config, suppressed warnings, `try?` that swallows errors,
  force unwraps/try/casts. The only exception is a genuine invariant (such as a C API handle),
  explained in a doc comment and called out in the pull request.
- No skipped or disabled tests, no `continue-on-error`, no retries that hide flakiness.
- Every phase ends finished and clean: CI green, zero warnings, zero lint violations, formatted.
