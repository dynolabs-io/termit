# Termit

**Native iOS Mosh + SSH terminal.** Peer-to-peer, Secure Enclave keys, auto-installs `mosh-server` on any host — even without sudo.

```
┌─────────┐                                  ┌──────────┐
│ iPhone  │ ──── Mosh (UDP, roaming) ──────► │   your   │
│ Termit  │                                  │   host   │
└─────────┘                                  └──────────┘
     ↑                                            ↑
     │ Secure Enclave SSH keys                    │ mosh-server
     │ Biometric per session                      │ auto-installed
     │ No account required                        │ (sudo OR portable)
```

## What makes Termit different

| Feature | Termit | Termius | Blink | Prompt |
|---|---|---|---|---|
| Mosh-server **auto-install** (sudo) | ✅ | ❌ | ❌ | ❌ |
| Mosh-server **portable** install (no sudo) | ✅ | ❌ | ❌ | ❌ |
| Secure Enclave SSH keys | ✅ | partial | ❌ | partial |
| No mandatory account | ✅ | ❌ (forces signup) | ✅ | ✅ |
| Live Activities | ✅ | ❌ | ❌ | ❌ |
| Lock Screen / StandBy widgets | ✅ | ❌ | ❌ | ❌ |
| Apple Watch companion | ✅ | ❌ | ❌ | ❌ |
| Magic Keyboard full chords | ✅ | partial | ✅ | partial |
| Stage Manager / multi-window | ✅ | partial | partial | ❌ |
| SFTP + port forwarding + snippets | ✅ | ✅ | partial | ✅ |
| Open source | ✅ | ❌ | partial | ❌ |

## Auto-install: the killer feature

You connect Termit to a host. We SSH in, check for `mosh-server`. If it's missing, you pick:

1. **Use SSH for this session** — works now, no install. Session breaks on network change.
2. **Install via package manager** — we detect distro, run `sudo apt-get install -y mosh` (or yum/dnf/zypper/apk/brew/pacman). Permanent system install.
3. **Drop portable binary** ⭐ — we detect arch (`uname -m -s`), SFTP-upload a bundled static `mosh-server` to `~/.local/bin/mosh-server`, chmod +x, and use it. **No sudo required.** Works on locked-down shared hosting, jump boxes, customer servers where you can't install packages.

Per-host preference remembered.

## Architecture

- **iOS app**: Swift 5.9, SwiftUI primary, UIKit/Metal for terminal renderer
- **Min iOS**: 17 (full ActivityKit + WidgetKit + AppIntents support)
- **SSH**: [SwiftNIO SSH](https://github.com/apple/swift-nio-ssh) (Apple official)
- **Mosh**: [mobile-shell/mosh](https://github.com/mobile-shell/mosh) vendored as submodule (GPL v3), Swift glue forked from [Blink Shell](https://github.com/blinksh/blink) (BSD-2-Clause)
- **Connection**: peer-to-peer, no relay, no telemetry, no OpenOva server in the path
- **Distribution**: App Store + open source

## License

Termit Swift code: **MIT** (see [LICENSE](LICENSE))

Vendored third-party:
- Mosh (GPL v3) — source available via `git submodule` from upstream
- Blink Shell Mosh-iOS glue (BSD-2-Clause)

See [THIRD_PARTY_LICENSES.md](THIRD_PARTY_LICENSES.md).

## Build

```bash
# Generate Xcode project from project.yml
brew install xcodegen
xcodegen generate

# Build static mosh-server binaries (Linux + macOS, 4 arches)
./Tools/StaticBuilds/build-mosh-static.sh

# Open in Xcode
open Termit.xcworkspace
```

## CI / TestFlight

Push to `main` → GitHub Actions macOS runner builds + uploads to TestFlight.

Required secrets:
- `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_P8` — App Store Connect API key
- `MATCH_PASSWORD`, `MATCH_GIT_BRANCH` — fastlane Match cert/profile sync (optional, if using Match)

## Sponsor

Built by [Dynolabs](https://github.com/dynolabs-io). See also [OpenOva](https://openova.io).
