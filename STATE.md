# State

## Macro Goal
Ship complete Termit iOS terminal end-to-end: TestFlight → App Store, working Mosh+SSH with auto-install on any host.

## Macro Plan
| # | Phase | Status |
|---|---|---|
| 1 | Foundation scaffolded (repo, project.yml, all Swift modules, CI workflow, tests) | in_progress |
| 2 | First commit pushed, GHA build attempted | pending |
| 3 | All CI errors resolved, green build | pending |
| 4 | Static mosh-server binaries built and bundled | pending |
| 5 | Maestro E2E suite green against this VPS test target | pending |
| 6 | TestFlight build #1 uploaded | pending |
| 7 | App Store Connect listing + screenshots ready | pending |
| 8 | TestFlight founder smoke-test pass | pending |
| 9 | App Store submitted | pending |
| 10 | App Store approved, public release | pending |

## Current
- Repository: dynolabs-io/termit (public, MIT)
- Local: ~/repos/termit
- Master tracking issue: dynolabs-io/termit#1
- Files written: 60+ source files covering every feature from issue #1 DoD

## Required GitHub Secrets (before TestFlight upload can succeed)
- ASC_KEY_ID — App Store Connect API key ID
- ASC_ISSUER_ID — App Store Connect issuer UUID
- ASC_KEY_P8 — App Store Connect .p8 private key contents
- ASC_BETA_GROUP_ID — internal beta group UUID
- TERMIT_TEAM_ID — Apple Developer team ID
- ASC_ITC_TEAM_ID — App Store Connect team ID
- MATCH_PASSWORD — fastlane match passphrase (optional)
- MATCH_GIT_URL — match certificate repo URL (optional)
- TEST_SSH_HOST — Maestro E2E target host
- TEST_SSH_USER — Maestro E2E target user
- TEST_SSH_PRIVATE_KEY — Maestro E2E target SSH key

## Test target
The contabo VPS is used as the Maestro E2E target. A dedicated test user (`termit-ci`) with no sudo and limited shell will be created. The user's host/credentials are passed to GHA only via the secrets above, never committed.
