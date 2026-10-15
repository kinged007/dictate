# Dictate

[![CI](https://github.com/kinged007/dictate/actions/workflows/ci.yml/badge.svg)](https://github.com/kinged007/dictate/actions/workflows/ci.yml)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)
[![Swift](https://img.shields.io/badge/Swift-5-orange.svg)](https://swift.org)
[![macOS](https://img.shields.io/badge/macOS-10.15%2B-lightgrey.svg)](https://www.apple.com/macos/)

Hotkey dictation for older Intel Macs — press `Cmd+Shift+D`, speak, and cleaned text lands at your cursor.

## What it is

Dictate is a minimal hotkey dictation app for Intel Macs on macOS 10.15 (Catalina) and newer. It records audio, transcribes via Groq Whisper, cleans the result with an LLM, and pastes the text at your cursor via simulated Cmd+V — in any app where Cmd+V works (Terminal, browser, editor).

It is a minimal adaptation of [FreeFlow](https://github.com/zachlatta/freeflow) by Zach Latta, kept compatible with older Intel Macs that cannot run macOS 13+. FreeFlow itself requires macOS 13+; this fork strips it to the core loop — record, transcribe, LLM-clean, paste — using only 10.15-era APIs, and drops pipeline history, context/screenshot features, custom shortcut capture, and notarized releases. If you have a newer Mac, use FreeFlow directly.

**No prebuilt binaries.** CI runners ship macOS 13+ SDKs. The app targets a 10.15 deployment target and is built locally with one command.

## Requirements

- Intel Mac, macOS 10.15 or later
- Xcode Command Line Tools (`xcode-select --install` if not present)
- A Groq API key ([console.groq.com](https://console.groq.com)) — used for both transcription and cleanup by default; each stage can point at any OpenAI-compatible endpoint

## Install

```sh
git clone https://github.com/kinged007/dictate dictate
cd dictate
make install
```

`make install` does three things:

1. Builds `build/Dictate.app`
2. Copies it to `/Applications/Dictate.app`
3. Installs a LaunchAgent (`~/Library/LaunchAgents/com.dictate.plist`) so Dictate starts at login

Then grant permissions on first use (see below).

### Run without installing

```sh
make run          # builds and opens build/Dictate.app (does not copy to Applications)
```

### Launch at login

Two equivalent ways:

- The `make install` LaunchAgent, or
- In-app: menu bar icon > Settings > tick "Launch Dictate at login" > Save (writes the same LaunchAgent for wherever the app is installed).

### Uninstall

```sh
make uninstall    # removes the LaunchAgent and /Applications/Dictate.app
```

## Usage

### The loop

1. Press `Cmd+Shift+D` — recording starts (menu bar icon turns red).
2. Press `Cmd+Shift+D` again — recording stops.
3. Audio goes to Groq's Whisper endpoint for transcription.
4. The raw transcript goes to an LLM (default `openai/gpt-oss-120b` on Groq) that cleans it into smooth dictation.
5. The cleaned text is pasted at your cursor via simulated Cmd+V. Previous clipboard contents are restored afterwards.

### First-use permissions

Press `Cmd+Shift+D` once. macOS will ask for:

1. **Microphone** — to record your speech.
2. **Accessibility** — for the simulated Cmd+V paste.

If you move the app after granting them (e.g. out of `build/` into `/Applications`), re-grant both in System Preferences > Security & Privacy > Privacy — permissions are tied to the app's location.

### Configuration

Menu bar icon > Settings:

| Field | Default |
|---|---|
| Transcription base URL | `https://api.groq.com/openai/v1` |
| Transcription model | `whisper-large-v3-turbo` |
| Cleanup base URL | `https://api.groq.com/openai/v1` |
| Cleanup model | `openai/gpt-oss-120b` |
| Cleanup prompt | pre-filled dictation cleanup prompt (editable) |

API keys are stored in the macOS Keychain (one entry per stage), never in plaintext files. Other settings live in UserDefaults. Both stages accept any OpenAI-compatible endpoint — swap base URL and key per stage.

## Building from source

```sh
make            # build build/Dictate.app
make icon       # regenerate Resources/AppIcon.icns from the source PNG
make clean
```

The build targets the machine it runs on: `ARCH` defaults to `uname -m` (x86_64 on Intel, arm64 on Apple Silicon; override with `ARCH=...`). The deployment target stays at the minimum supported macOS — 10.15 on Intel, 11.0 on arm64 — so builds run on old Macs too. Building on a newer macOS with a 10.15 target is intentional: the app uses only 10.15-era APIs, and a lower deployment target never reduces compatibility.

```sh
swift scripts/make-icon.swift   # regenerates Resources/AppIcon-Source.png
```

## How it is tested

CI builds the app on macOS and verifies the bundle:

```sh
make                # build check — must produce build/Dictate.app/Contents/MacOS/Dictate
```

The GitHub Actions workflow (`.github/workflows/ci.yml`) runs `make` on `macos-latest` on every push and PR to `main` and verifies the app bundle exists and is executable. SwiftLint/SwiftFormat are run when available. No unit test suite is present; manual testing covers the record → transcribe → clean → paste loop and the Settings UI.

## Project layout

```
main.swift                       App entry point
AppDelegate.swift                Menu bar item + menu
HotkeyManager.swift              Carbon global hotkey (Cmd+Shift+D)
Recorder.swift                   AVAudioRecorder to temp m4a
DictationClient.swift            OpenAI-compatible transcription + chat calls
DictationPipeline.swift          State machine: record → transcribe → clean → paste
Paster.swift                     Clipboard + simulated Cmd+V + restore
Settings.swift                   UserDefaults + Keychain config
SettingsWindowController.swift   Settings UI (incl. Launch-at-login toggle)
LoginItemManager.swift           LaunchAgent management
scripts/install-launchagent.sh   LaunchAgent install (used by make install)
scripts/uninstall-launchagent.sh LaunchAgent removal
scripts/make-icon.swift          Icon generator
```

## License

GPLv3 — see [LICENSE](LICENSE).
