import Carbon
import Cocoa

/// Global hotkey via the Carbon RegisterEventHotKey API (works on macOS 10.15).
final class HotkeyManager {
    static let shared = HotkeyManager()

    var onHotkey: (() -> Void)?

    private var hotKeyRef: EventHotKeyRef?
    private let hotKeyID = EventHotKeyID(signature: OSType(0x44494354), id: 1) // "DICT"
    private let keyCode: UInt32 = UInt32(kVK_ANSI_D)
    private let modifiers: UInt32 = UInt32(cmdKey | shiftKey) // Cmd+Shift+D

    private init() {}

    func install() {
        var eventSpec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, _, _ -> OSStatus in
                HotkeyManager.shared.onHotkey?()
                return noErr
            },
            1,
            &eventSpec,
            nil,
            nil
        )
        RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
    }

    deinit {
        if let hotKeyRef = hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
        }
    }
}
