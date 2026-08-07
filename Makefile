APP_NAME = Dictate
BUNDLE_ID = com.josh.dictate
BUILD_DIR = build
APP_BUNDLE = $(BUILD_DIR)/$(APP_NAME).app
CONTENTS = $(APP_BUNDLE)/Contents
MACOS_DIR = $(CONTENTS)/MacOS
RESOURCES = $(CONTENTS)/Resources
SOURCES = main.swift AppDelegate.swift HotkeyManager.swift Recorder.swift DictationClient.swift Paster.swift Settings.swift SettingsWindowController.swift DictationPipeline.swift LoginItemManager.swift
ICON_SOURCE = Resources/AppIcon-Source.png
ICON_ICNS = Resources/AppIcon.icns

.PHONY: all clean run icon install uninstall

all: $(MACOS_DIR)/$(APP_NAME)

$(MACOS_DIR)/$(APP_NAME): $(SOURCES) Info.plist $(ICON_ICNS)
	@mkdir -p "$(MACOS_DIR)" "$(RESOURCES)"
	swiftc \
		-o "$(MACOS_DIR)/$(APP_NAME)" \
		-sdk $(shell xcrun --show-sdk-path) \
		-target x86_64-apple-macosx10.15 \
		$(SOURCES)
	@cp Info.plist "$(CONTENTS)/"
	@cp $(ICON_ICNS) "$(RESOURCES)/AppIcon.icns"
	@plutil -replace CFBundleIconFile -string "AppIcon" "$(CONTENTS)/Info.plist"
	@codesign --force --sign - "$(APP_BUNDLE)"
	@echo "Built $(APP_BUNDLE)"

icon: $(ICON_ICNS)

$(ICON_ICNS): $(ICON_SOURCE)
	@mkdir -p $(BUILD_DIR)/AppIcon.iconset
	@sips -z 16 16 $< --out $(BUILD_DIR)/AppIcon.iconset/icon_16x16.png > /dev/null
	@sips -z 32 32 $< --out $(BUILD_DIR)/AppIcon.iconset/icon_16x16@2x.png > /dev/null
	@sips -z 32 32 $< --out $(BUILD_DIR)/AppIcon.iconset/icon_32x32.png > /dev/null
	@sips -z 64 64 $< --out $(BUILD_DIR)/AppIcon.iconset/icon_32x32@2x.png > /dev/null
	@sips -z 128 128 $< --out $(BUILD_DIR)/AppIcon.iconset/icon_128x128.png > /dev/null
	@sips -z 256 256 $< --out $(BUILD_DIR)/AppIcon.iconset/icon_128x128@2x.png > /dev/null
	@sips -z 256 256 $< --out $(BUILD_DIR)/AppIcon.iconset/icon_256x256.png > /dev/null
	@sips -z 512 512 $< --out $(BUILD_DIR)/AppIcon.iconset/icon_256x256@2x.png > /dev/null
	@sips -z 512 512 $< --out $(BUILD_DIR)/AppIcon.iconset/icon_512x512.png > /dev/null
	@sips -z 1024 1024 $< --out $(BUILD_DIR)/AppIcon.iconset/icon_512x512@2x.png > /dev/null
	@iconutil -c icns -o $@ $(BUILD_DIR)/AppIcon.iconset
	@rm -rf $(BUILD_DIR)/AppIcon.iconset
	@echo "Generated $@"

# Installs the app into /Applications and registers a LaunchAgent so it
# starts automatically at login. Builds locally because the source targets
# macOS 10.15 APIs that CI runners (macOS 13+) can't produce as a
# 10.15-compatible binary without extra configuration.
install: all
	@echo "Installing $(APP_NAME) to /Applications..."
	@rm -rf "/Applications/$(APP_NAME).app"
	@cp -R "$(APP_BUNDLE)" "/Applications/"
	@bash scripts/install-launchagent.sh
	@echo ""
	@echo "Installed. On first hotkey press, grant Microphone and"
	@echo "Accessibility permissions when prompted."

uninstall:
	@bash scripts/uninstall-launchagent.sh
	@rm -rf "/Applications/$(APP_NAME).app"
	@echo "Removed $(APP_NAME) from /Applications."

clean:
	rm -rf $(BUILD_DIR) $(ICON_ICNS)

run: all
	open "$(APP_BUNDLE)"
