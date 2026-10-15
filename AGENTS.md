# Working in dictate

## Purpose

Minimal hotkey dictation app for Intel Macs (macOS 10.15+) — press a hotkey, speak, cleaned text lands at the cursor. Swift/macOS menu bar app. Based on FreeFlow, trimmed to 10.15-era APIs.

## Stack

Swift 5, AppKit, Carbon hotkey, AVAudioRecorder, OpenAI-compatible HTTP (Groq Whisper + LLM). Build with `swiftc` via `Makefile`. No package manager, no external dependencies.

## How to run checks

```sh
make            # build build/Dictate.app — primary check
make clean && make   # clean build
```

CI (`.github/workflows/ci.yml`) runs `make` on `macos-latest` and verifies the bundle. No unit test suite; manual testing covers record → transcribe → clean → paste and Settings UI.

Optional lint when tools are installed:

```sh
swiftformat --lint .   # if swiftformat installed
swiftlint lint --strict  # if swiftlint installed
```

## Branch and PR workflow

- Do not push directly to `main`. Create a feature branch and open a PR.
- Keep commits signed with `kinged007 <599286+kinged007@users.noreply.github.com>`.
- CI must pass before merge.

## Agent skills

Use the repo's skills where relevant. For general polish tasks follow `docs/02-action-plan.md` and `data/repos.csv` in the profile plan workspace. Do not add abstractions until needed (KISS/YAGNI).

## Permissions and secrets

- No secrets in commits. API keys live in macOS Keychain at runtime, never in files or env.
- Do not publish anything derived from private `tenantflex` org repos (see profile plan `docs/03-tenantflex.md`). Get org owner approval first.
- Never change repo visibility to private or delete the repo without explicit user confirmation.

## Project notes

- Prebuilt binaries are not distributed — CI runners use newer SDKs. The app is built locally; a GitHub release with a built app is manual (requires the old Intel Mac, see `data/repos.csv` notes for `dictate`).
- Deployment target is 10.15 (Intel) / 11.0 (arm64); do not bump without reason.
