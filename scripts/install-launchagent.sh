#!/bin/bash
# Installs a LaunchAgent so Dictate starts automatically at login.
# Writes ~/Library/LaunchAgents/com.josh.dictate.plist pointing at the
# installed app, then loads it with launchctl (bootstrap on modern macOS,
# falling back to the classic load -w which still works on 10.15).
set -e

APP_PATH="/Applications/Dictate.app/Contents/MacOS/Dictate"
LABEL="com.josh.dictate"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"

mkdir -p "$HOME/Library/LaunchAgents"

cat > "$PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$LABEL</string>
    <key>ProgramArguments</key>
    <array>
        <string>$APP_PATH</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <false/>
    <key>ProcessType</key>
    <string>Interactive</string>
</dict>
</plist>
EOF

# Tear down any previous instance, then load the new plist.
launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || launchctl unload "$PLIST" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$PLIST" 2>/dev/null || launchctl load -w "$PLIST"

echo "LaunchAgent installed at $PLIST — Dictate will start at login."
