# Third-party licenses

Termit ships with these third-party components:

## Mosh — `mobile-shell/mosh`
- License: **GNU General Public License v3.0**
- Source: https://github.com/mobile-shell/mosh
- Vendored as: git submodule under `ThirdParty/mosh`
- Used by: Termit iOS client (mosh protocol implementation) and the bundled `mosh-server` binaries shipped under `Resources/MoshServer/`
- GPL obligation satisfied by:
  - Linking to upstream source from the in-app About screen
  - Distributing the submodule alongside the Termit repository
  - Building Termit Swift code under MIT, which is GPL-compatible when linked

## Blink Shell — `blinksh/blink`
- License: **BSD 2-Clause**
- Source: https://github.com/blinksh/blink
- Vendored as: git submodule under `ThirdParty/blink-mosh`
- Used by: Swift/Objective-C glue layer wrapping Mosh for iOS lifecycle handling

## SwiftNIO SSH — `apple/swift-nio-ssh`
- License: **Apache License 2.0**
- Source: https://github.com/apple/swift-nio-ssh
- Used by: SSH client implementation

## SwiftNIO — `apple/swift-nio`
- License: **Apache License 2.0**
- Source: https://github.com/apple/swift-nio

## Swift Crypto — `apple/swift-crypto`
- License: **Apache License 2.0**
- Source: https://github.com/apple/swift-crypto

## Citadel — `orlandos-nl/Citadel`
- License: **MIT**
- Source: https://github.com/orlandos-nl/Citadel
- Used by: High-level SSH/SFTP convenience built on SwiftNIO SSH

## JetBrains Mono — `JetBrains/JetBrainsMono`
- License: **SIL Open Font License 1.1**
- Source: https://github.com/JetBrains/JetBrainsMono
- Bundled under: `Resources/Fonts/`

## Berkeley Mono Variable — Berkeley Graphics
- License: paid license per device (see https://berkeleygraphics.com)
- Bundled only in distributions where a per-device license has been purchased

## Themes
- Solarized — Ethan Schoonover, MIT
- Dracula — Dracula Theme Inc, MIT
- Nord — Sven Greb / Arctic Ice Studio, MIT
- Tomorrow — Chris Kempson, MIT
- Catppuccin — Catppuccin org, MIT
