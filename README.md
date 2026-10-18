# Mac Thermals

A small, open-source macOS menu bar app that tells you whether your Apple Silicon Mac is thermally
throttled right now: reducing its performance to cool down. That matters most on fanless Macs such
as the MacBook Air, which slow down under sustained load instead of spinning up a fan.

Mac Thermals currently shows:

- a menu bar icon that changes with the throttle status;
- a dropdown panel with the status in plain language, the system thermal pressure level and the
  `ProcessInfo` thermal state;
- a Settings window with launch at login.

Temperatures from every available sensor and 24–48 hours of history are planned; see
[docs/PLAN.md](docs/PLAN.md).

## Requirements

- macOS 27 "Golden Gate" or later
- An Apple Silicon Mac
- Xcode 27.1 or later (Swift 6.4)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) and [SwiftLint](https://github.com/realm/SwiftLint)

## Build from source

```sh
brew install xcodegen swiftlint
git clone https://github.com/d4rylp/mac-thermals.git
cd mac-thermals
make project            # generates MacThermals.xcodeproj from project.yml
open MacThermals.xcodeproj
```

Then choose the **MacThermals** scheme and **Run**. The app appears in the menu bar, not the Dock.

To build a Release copy and install it in `/Applications` instead:

```sh
make install
```

The build is signed with "Sign to Run Locally", so you don't need an Apple developer account. To
sign with your own team, create `Config/Local.xcconfig` (it is gitignored):

```
DEVELOPMENT_TEAM = ABCDE12345
CODE_SIGN_IDENTITY = Apple Development
```

Other commands: `make build`, `make test`, `make lint`, `make format`, `make clean`, and
`make hooks` to install a pre-commit hook that runs the linters.

## Why it isn't on the Mac App Store

macOS has no public API for CPU or GPU temperatures; Apple has said so
([Apple Developer Forums](https://developer.apple.com/forums/thread/689556)). Reading sensors means
using private SMC and IOKit HID interfaces, which the App Store doesn't allow and which require the
App Sandbox to be off. So Mac Thermals is distributed as source on GitHub, and you build it yourself.

The throttle status uses only public interfaces: the Darwin notify thermal pressure level and
`ProcessInfo.thermalState`.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). The architecture is described in
[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) and the design rules in [docs/DESIGN.md](docs/DESIGN.md).

## License

[MIT](LICENSE)
