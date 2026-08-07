# Dictate

Minimal hotkey dictation app for Intel Macs on macOS 10.15 (Catalina) and
newer. Press a hotkey, speak, and clean text lands at your cursor — in the
Terminal, a browser, an editor, anywhere Cmd+V works.

**No prebuilt binaries.** CI runners ship macOS 13+ SDKs and build for newer
machines, so this app is built locally — it's one command.

## Credits

Dictate is a minimal adaptation of [FreeFlow](https://github.com/zachlatta/freeflow)
(by Zach Latta), created solely so the hotkey dictation workflow can run on
older Intel Macs stuck on macOS 10.15. FreeFlow itself requires macOS 13+;
this fork strips it down to the core loop — record, transcribe, LLM-clean,
paste at cursor — using only 10.15-era APIs, and drops everything else
(pipeline history, context/screenshot features, custom shortcut capture,
notarized releases). Big kudos to FreeFlow for the design, the dictation
cleanup prompt, and the proven paste-at-cursor approach this project builds
on. If you have a newer Mac, use FreeFlow directly.

## The loop

1. Press `Cmd+Shift+D` — recording starts (menu bar icon turns red).
2. Press `Cmd+Shift+D` again — recording stops.
3. Audio goes to Groq's Whisper endpoint for transcription.
4. The raw transcript goes to an LLM (default `openai/gpt-oss-120b` on Groq)
   that cleans it into smooth, coherent dictation.
5. The cleaned text is pasted at your cursor via simulated Cmd+V. Your
   previous clipboard contents are restored afterwards.

## Requirements

- Intel Mac, macOS 10.15 or later
- Xcode Command Line Tools (`xcode-select --install` if not present)
- A Groq API key (https://console.groq.com) — used for both transcription
  and cleanup by default. Each stage can point at any OpenAI-compatible
  endpoint with its own key (see Settings).

## Install

    git clone <repo-url> dictate
    cd dictate
    make install

`make install` does three things:

1. Builds `build/Dictate.app`
2. Copies it to `/Applications/Dictate.app`
3. Installs a LaunchAgent (`~/Library/LaunchAgents/com.josh.dictate.plist`)
   so Dictate starts automatically at login

Then grant permissions on first use (see below).

### Run without installing

    make run          # builds and opens build/Dictate.app (does not copy it to Applications)

### Launch at login

Two equivalent ways:

- The `make install` LaunchAgent, or
- In-app: menu bar icon > Settings > tick "Launch Dictate at login" > Save.
  (The checkbox writes the same LaunchAgent, using wherever the app is
  currently installed.)

### Uninstall

    make uninstall    # removes the LaunchAgent and /Applications/Dictate.app

## First-use permissions

Press `Cmd+Shift+D` once. macOS will ask for:

1. **Microphone** — needed to record your speech.
2. **Accessibility** — needed for the simulated Cmd+V paste.

If you move the app after granting them (e.g. out of `build/` into
`/Applications`), re-grant both in System Preferences > Security & Privacy >
Privacy — permissions are tied to the app's location.

## Configuration

Menu bar icon > Settings:

| Field | Default |
|---|---|
| Transcription base URL | `https://api.groq.com/openai/v1` |
| Transcription model | `whisper-large-v3-turbo` |
| Cleanup base URL | `https://api.groq.com/openai/v1` |
| Cleanup model | `openai/gpt-oss-120b` |
| Cleanup prompt | pre-filled dictation cleanup prompt (editable) |

API keys are stored in the macOS Keychain (one entry per stage), never in
plaintext files. Other settings live in UserDefaults.

Both stages accept any OpenAI-compatible endpoint — swap in a different base
URL and key per stage if you want a different transcription or cleanup
provider.

## Building from source

    make            # build build/Dictate.app
    make icon       # regenerate Resources/AppIcon.icns from the source PNG
    make clean

The icon source is drawn by `scripts/make-icon.swift` (an AppKit script):

    swift scripts/make-icon.swift   # regenerates Resources/AppIcon-Source.png

## Project layout

    main.swift                  App entry point
    AppDelegate.swift           Menu bar item + menu
    HotkeyManager.swift         Carbon global hotkey (Cmd+Shift+D)
    Recorder.swift              AVAudioRecorder to temp m4a
    DictationClient.swift       OpenAI-compatible transcription + chat calls
    DictationPipeline.swift     State machine: record -> transcribe -> clean -> paste
    Paster.swift                Clipboard + simulated Cmd+V + restore
    Settings.swift              UserDefaults + Keychain config
    SettingsWindowController.swift  Settings UI (incl. Launch-at-login toggle)
    LoginItemManager.swift      LaunchAgent management
    scripts/install-launchagent.sh   LaunchAgent install (used by make install)
    scripts/uninstall-launchagent.sh LaunchAgent removal
    scripts/make-icon.swift     Icon generator
