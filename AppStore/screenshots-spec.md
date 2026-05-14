# Screenshot requirements (App Store Connect)

## Required sizes

| Device class | Resolution | Required |
|---|---|---|
| iPhone 6.7" (Pro Max / Plus) | 1290 × 2796 | yes |
| iPhone 6.1" (Pro / standard) | 1179 × 2556 | yes |
| iPad 12.9" (3rd gen+) | 2048 × 2732 | yes |
| iPad 11" | 1668 × 2388 | optional |

## Required screenshots (5 per size)

1. **Host list** — clean dark theme, 4 demo hosts (prod-edge-1, staging-db, home-pi, jump-box) with status indicators.
2. **Connected Mosh session** — terminal showing `htop` or `tail -f` with Live Activity in Dynamic Island visible above.
3. **mosh-server auto-install sheet** — three-option picker showing portable binary as default, with detected OS/arch.
4. **Secure Enclave keys** — Settings → key management list showing 2 keys with creation dates + biometric prompt overlay.
5. **iPad Stage Manager** — Termit window with terminal session split alongside SFTP browser.

## Subtitles overlay
- 1: "All your servers, in your pocket"
- 2: "Mosh that survives the tunnel"
- 3: "Auto-installs on any host"
- 4: "Keys in the Secure Enclave"
- 5: "iPad Stage Manager native"

## Pipeline
Screenshots generated automatically via `fastlane snapshot` against simulator. Stored in `fastlane/screenshots/<lang>/`.
