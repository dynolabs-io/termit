# Termit — Architecture

## Module layout

```
Sources/Termit/
├── App/                    # @main, AppDelegate, SceneDelegate, multi-window
├── Models/                 # Host, Session, Snippet, Theme — Codable, iCloud-syncable
├── Security/               # Secure Enclave keys, Biometric, Keychain
├── Net/                    # SSHClient, MoshClient, MoshServerInstaller, SFTPClient, PortForwarder
├── Terminal/               # VT100/xterm parser, buffer, Metal renderer
├── UI/
│   ├── Hosts/              # HostList, HostEdit, HostDetail
│   ├── Terminal/           # SessionView, TabBar, InstallSheet
│   ├── SFTP/               # SFTPBrowserView
│   ├── Snippets/           # SnippetListView, SnippetEditView
│   └── Settings/           # SettingsView, ThemePicker
├── Widgets/                # Lock Screen + StandBy WidgetKit targets
├── WatchApp/               # watchOS companion
└── Intents/                # AppIntents for Shortcuts/Siri
```

## Connection lifecycle

```
HostList tap host
  │
  ▼
Biometric prompt (FaceID/TouchID)
  │
  ▼
SSH bootstrap (SwiftNIO SSH)
  │   • Authenticates user (key from Secure Enclave OR password)
  │   • Allocates PTY
  ▼
mosh-server probe: `which mosh-server || ls ~/.local/bin/mosh-server`
  │
  ├─ found ──► spawn mosh-server, get UDP port+key ──► drop SSH ──► UDP roaming session
  │
  └─ missing ──► MoshInstallSheet:
                   [a] SSH-only this session
                   [b] sudo install (auto-detect pkg manager)
                   [c] Portable binary drop (no sudo) ◄── default
                          │
                          ▼
                   detect arch via `uname -m -s`
                   SFTP-upload bundled mosh-server-<arch>
                   chmod +x ~/.local/bin/mosh-server
                   spawn it ──► UDP roaming session
```

## Security model

| Concern | Mechanism |
|---|---|
| SSH private key exfiltration | Keys generated with `kSecAttrTokenIDSecureEnclaveAttr`, non-exportable, never leave the chip |
| Per-key access control | `kSecAccessControlBiometryCurrentSet` — each use prompts FaceID/TouchID |
| Stored credentials | Keychain Services, with biometric ACL on sensitive items |
| iCloud sync of hosts/snippets | CloudKit private database, payload encrypted with symmetric key in Keychain (NOT synced); user-toggleable, off by default |
| Account/identity | None. No login. No analytics. No telemetry. |
| Network privacy | Peer-to-peer SSH/Mosh. No OpenOva/Dynolabs server in the data path. |

## Mosh-server static binary toolchain

Per-arch builds produced by `Tools/StaticBuilds/build-mosh-static.sh`:

| Target | Toolchain | Output |
|---|---|---|
| linux-x86_64 | musl-cross-make + zig cc -target x86_64-linux-musl | Resources/MoshServer/mosh-server-linux-x86_64 |
| linux-aarch64 | musl-cross-make + zig cc -target aarch64-linux-musl | Resources/MoshServer/mosh-server-linux-aarch64 |
| darwin-x86_64 | clang + macOS SDK | Resources/MoshServer/mosh-server-darwin-x86_64 |
| darwin-aarch64 | clang + macOS SDK | Resources/MoshServer/mosh-server-darwin-aarch64 |

Built in CI by `.github/workflows/static-mosh-server.yaml`. Binaries committed under `Resources/MoshServer/` and bundled into the iOS app.

## iOS-native surfaces

| Surface | Module | Notes |
|---|---|---|
| Live Activities | App/LiveActivity + ActivityKit | Compact + expanded Dynamic Island; updates on session keepalive |
| Lock Screen widget | Widgets/LockScreenWidget | accessoryCircular + accessoryRectangular; last connected host |
| StandBy widget | Widgets/StandByWidget | systemSmall scaled for night-mode StandBy |
| Apple Watch | WatchApp/ | Glance, complications, recent hosts list, reconnect via WatchConnectivity |
| Shortcuts | Intents/ | AppIntent: ConnectToHost(host), RunSnippet(snippet), DisconnectAll |
| Stage Manager | App/SceneDelegate | UISceneSession multi-window, NSUserActivity state restore |

## CI/CD

```
push to main
  │
  ▼
.github/workflows/ios-testflight.yaml on macos-14
  • xcodegen generate
  • brew install maestro
  • xcodebuild build-for-testing
  • XCUITest unit + integration on iPhone 15 Pro simulator
  • Boot simulator, install app, run Maestro E2E suite (must all pass before upload)
  • xcodebuild archive + export
  • fastlane pilot upload to TestFlight (ASC API key from secrets)
  • POST /betaGroups/.../relationships/builds to assign to "Internal" group
```

Per `feedback_asc_204_trust_and_beta_group_assignment.md`: 204 = success, do NOT re-poll.
Per `feedback_e2e_gate_must_complete_action_not_open_menu.md`: each Maestro flow drives the action to its real outcome.

## Licensing & App Store

- Termit Swift code: MIT.
- Mosh: GPL v3, vendored as submodule, source URL printed in About screen, satisfies GPL.
- Blink iOS Mosh glue (fork): BSD-2-Clause, attribution in THIRD_PARTY_LICENSES.md.
- App Store: shipped under MIT umbrella. Precedent: Blink Shell has shipped this same composition since 2018.

## Build dependency graph

```
TermitApp.swift
  └── HostListView
        ├── EnclaveKeys (Secure Enclave)
        ├── KeyStore (Keychain)
        └── HostStore (CoreData / SwiftData)
              └── CloudKitSync (optional)

SessionView
  ├── SSHClient (SwiftNIO SSH)
  ├── MoshClient (MoshGlue → MoshCore)
  ├── MoshServerInstaller (3 paths)
  └── TerminalRenderer (Metal)

Widgets target ─── reads HostStore via App Group shared container
WatchApp target ─── reads HostStore via WatchConnectivity push
Intents target ─── triggers SessionView via NSUserActivity
```
