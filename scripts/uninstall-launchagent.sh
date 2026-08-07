#!/bin/bash
# Removes the Dictate LaunchAgent and stops it from running at login.
set -e

LABEL="com.dictate"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"

launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || launchctl unload "$PLIST" 2>/dev/null || true
rm -f "$PLIST"

echo "LaunchAgent removed — Dictate will no longer start at login."
