# Contributing

Thanks for helping! Mac Thermals is a small personal project, so please open an issue to discuss
anything larger than a fix before writing code.

## Setup

```sh
brew install xcodegen swiftlint
make project   # generate MacThermals.xcodeproj
make hooks     # run the linters before every commit
```

Before opening a pull request, run:

```sh
make lint
make test
```

CI runs the same commands on a macOS runner with Xcode 27.1.

## Where things go

Read [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) first.

- `Packages/ThermalKit/Sources/ThermalCore`: domain logic. No UI and no direct system access, so
  everything is unit-testable with injected inputs.
- `Packages/ThermalKit/Sources/ThermalPlatform`: system integration.
- `Packages/ThermalKit/Sources/ThermalUI`: SwiftUI views and the app model.
- `App/`: the app target, which wires concrete sources into the model.

User-facing changes follow [docs/DESIGN.md](docs/DESIGN.md) (Apple's Human Interface Guidelines).

## Code integrity rules

These apply to every change.

**Design for the whole plan.** The full plan ([docs/PLAN.md](docs/PLAN.md)) is known, and the
architecture covers all of it. Each phase only *adds* code: new types, inputs, views and targets. It
never rewrites, restructures or replaces what an earlier phase wrote. Don't implement anything early,
and never make a choice you know a later phase would have to undo. If the architecture turns out to
be wrong, fix [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) first.

**Everything in the repository is real, used and tested.** Never write:

- stubs, placeholders, "coming soon" UI, or mock data in production code;
- TODO/FIXME/HACK comments or commented-out code (SwiftLint's `todo` rule fails the build);
- unused types, protocols, parameters, settings, targets or files;
- code for later phases, or feature flags for unbuilt features;
- temporary code of any kind;
- compatibility shims, deprecated APIs, or `#available` / `@available` branches (the deployment
  target is the current OS);
- diagnostic silencers: `@preconcurrency`, `nonisolated(unsafe)`, `@unchecked Sendable`,
  `swiftlint:disable`, loosened lint or format configuration, suppressed warnings, `try?` that
  swallows errors, force unwraps, force `try` or force casts;
- skipped or disabled tests, `continue-on-error` in CI, or retries that hide flakiness.

The only exception is a genuine invariant, such as a C API handle. Explain it in a doc comment and
call it out in the pull request description.

## Style

- Swift 6 language mode with complete concurrency checking. The app target defaults to `MainActor`
  isolation; package targets are nonisolated by default, and anything that crosses threads is
  genuinely `Sendable`.
- Formatting is swift-format (`.swift-format`); linting is SwiftLint (`.swiftlint.yml`) in strict
  mode. They are configured not to conflict. Warnings are errors.
- Public API has doc comments.
- Tests use Swift Testing, parameterised where sensible. UI tests in `AppUITests` use XCTest, because
  Swift Testing can't drive `XCUIApplication`.
- All user-facing text goes in String Catalogs; package code passes `bundle: .module`.
- Logging uses `os.Logger` with the module's subsystem, `io.github.d4rylp.MacThermals.<Module>`.
