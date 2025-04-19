import Cocoa
import Carbon

class AppDelegate: NSObject, NSApplicationDelegate {
    private var hotKeyRef: EventHotKeyRef?

    func applicationDidFinishLaunching(_ notification: Notification) {
        registerGlobalHotKey()
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let hk = hotKeyRef {
            UnregisterEventHotKey(hk)
        }
    }

    private func registerGlobalHotKey() {
        let modifierFlags: UInt32 = UInt32(cmdKey) | UInt32(shiftKey)
        let keyCode: UInt32 = 35

        var hotKeyID = EventHotKeyID(signature: OSType(fourCharCode("HtK1")), id: UInt32(1))
        let status = RegisterEventHotKey(keyCode, modifierFlags, hotKeyID, GetEventDispatcherTarget(), 0, &hotKeyRef)
        guard status == noErr else {
            NSLog("Failed to register hot-key: \(status)")
            return
        }

        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetEventDispatcherTarget(), hotKeyHandler, 1, &eventType, nil, nil)
    }

    private let hotKeyHandler: EventHandlerUPP = { (_, eventRef, _) -> OSStatus in
        var hkID = EventHotKeyID()
        GetEventParameter(eventRef, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID), nil, MemoryLayout<EventHotKeyID>.size, nil, &hkID)
        if hkID.id == 1 {
            deliverNotification()
        }
        return noErr
    }

    private static func deliverNotification() {
        let note = NSUserNotification()
        note.title = "hello world"
        NSUserNotificationCenter.default.deliver(note)
    }

    private func fourCharCode(_ str: String) -> FourCharCode {
        var result: FourCharCode = 0
        for ch in str.utf8 {
            result = (result << 8) + FourCharCode(ch)
        }
        return result
    }
}