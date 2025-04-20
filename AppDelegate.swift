import Cocoa
import Carbon
import CoreGraphics

class AppDelegate: NSObject, NSApplicationDelegate {
    private enum Mode {
        case promptA
        case promptB
        case promptC
    }
    private var hotKeyRef: EventHotKeyRef?
    private var statusItem: NSStatusItem?
    private var settingsWindowController: SettingsWindowController?
    private static var currentMode: Mode = .promptA

    func applicationDidFinishLaunching(_ notification: Notification) {
        registerGlobalHotKey()
        setupStatusBar()
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
        handlePromptMode()
    }

    private func fourCharCode(_ str: String) -> FourCharCode {
        var result: FourCharCode = 0
        for ch in str.utf8 {
            result = (result << 8) + FourCharCode(ch)
        }
        return result
    }
    
    // MARK: - Prompt handling
    private static func handlePromptMode() {
        let pb = NSPasteboard.general
        let original = pb.string(forType: .string) ?? ""
        // Copy selected text
        simulateCmdKey(8) // 'c'
        usleep(200_000)
        let selected = pb.string(forType: .string) ?? ""
        guard !selected.isEmpty else {
            showNotification(title: "No text selected", subtitle: "Please select text and try again")
            return
        }
        showNotification(title: "debug", subtitle: selected)
        // Retrieve prompt template
        let defaults = UserDefaults.standard
        let promptKey: String
        switch currentMode {
        case .promptA: promptKey = "promptA"
        case .promptB: promptKey = "promptB"
        case .promptC: promptKey = "promptC"
        }
        let template = defaults.string(forKey: promptKey) ?? ""
        guard !template.isEmpty else {
            showNotification(title: "Prompt not set", subtitle: "Define your prompts in Settings")
            restoreClipboard(original)
            return
        }
        // Retrieve API key
        let apiKey = defaults.string(forKey: "openai_api_key") ?? ""
        guard !apiKey.isEmpty else {
            showNotification(title: "API Key not set", subtitle: "Set your OpenAI API key in Settings")
            restoreClipboard(original)
            return
        }
        // Prepare and send request
        let fullPrompt = "\(template)\n\n\(selected)"

        do {
            let result = try sendOpenAIRequest(apiKey: apiKey, prompt: fullPrompt)
            // Replace selection with AI response
            pb.clearContents()
            pb.setString(result, forType: .string)
            simulateCmdKey(9) // 'v'
            usleep(200_000)
        } catch {
            showNotification(title: "OpenAI Error", subtitle: error.localizedDescription)
            restoreClipboard(original)
            return
        }
        // Restore original clipboard
        restoreClipboard(original)
    }
    
    // Post a command+key event
    private static func simulateCmdKey(_ keyCode: CGKeyCode) {
        let src = CGEventSource(stateID: .combinedSessionState)
        let flags: CGEventFlags = .maskCommand
        let keyDown = CGEvent(keyboardEventSource: src, virtualKey: keyCode, keyDown: true)
        keyDown?.flags = flags
        keyDown?.post(tap: .cghidEventTap)
        let keyUp = CGEvent(keyboardEventSource: src, virtualKey: keyCode, keyDown: false)
        keyUp?.flags = flags
        keyUp?.post(tap: .cghidEventTap)
    }
    
    // MARK: - Status Bar
    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            button.title = "🔔"
        }
        let menu = NSMenu()

        // Prompt options
        let promptAItem = NSMenuItem(title: "Prompt A", action: #selector(selectPromptA(_:)), keyEquivalent: "")
        promptAItem.target = self
        promptAItem.state = .on
        menu.addItem(promptAItem)
        let promptBItem = NSMenuItem(title: "Prompt B", action: #selector(selectPromptB(_:)), keyEquivalent: "")
        promptBItem.target = self
        menu.addItem(promptBItem)
        let promptCItem = NSMenuItem(title: "Prompt C", action: #selector(selectPromptC(_:)), keyEquivalent: "")
        promptCItem.target = self
        menu.addItem(promptCItem)
        // Settings
        let settingsItem = NSMenuItem(title: "Settings", action: #selector(openSettings(_:)), keyEquivalent: "")
        settingsItem.target = self
        menu.addItem(settingsItem)
        menu.addItem(NSMenuItem.separator())
        // Quit
        let quitItem = NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        quitItem.target = NSApp
        menu.addItem(quitItem)
        statusItem?.menu = menu
    }

    @objc private func selectPromptA(_ sender: Any?) {
        AppDelegate.currentMode = .promptA
        updateMenuCheckmarks(selectedTitle: "Prompt A")
    }

    @objc private func selectPromptB(_ sender: Any?) {
        AppDelegate.currentMode = .promptB
        updateMenuCheckmarks(selectedTitle: "Prompt B")
    }

    @objc private func selectPromptC(_ sender: Any?) {
        AppDelegate.currentMode = .promptC
        updateMenuCheckmarks(selectedTitle: "Prompt C")
    }

    @objc private func openSettings(_ sender: Any?) {
        if settingsWindowController == nil {
            settingsWindowController = SettingsWindowController()
        }
        settingsWindowController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func updateMenuCheckmarks(selectedTitle: String) {
        guard let menuItems = statusItem?.menu?.items else { return }
        for item in menuItems {
            if item.action == #selector(selectPromptA(_:)) ||
               item.action == #selector(selectPromptB(_:)) ||
               item.action == #selector(selectPromptC(_:)) {
                item.state = (item.title == selectedTitle) ? .on : .off
            }
        }
    }
    
    // MARK: - Networking and Utilities
    private enum RequestError: LocalizedError {
        case invalidURL
        case timeout
        case invalidResponse
        case httpError(code: Int)
        case noData
        case invalidJSON
        case missingChoices
        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Invalid request URL"
            case .timeout:
                return "Request timed out"
            case .invalidResponse:
                return "Invalid response from server"
            case .httpError(let code):
                return "HTTP error: \(code)"
            case .noData:
                return "No data received"
            case .invalidJSON:
                return "Failed to parse JSON"
            case .missingChoices:
                return "No choices in response"
            }
        }
    }
    
    private static func sendOpenAIRequest(apiKey: String, prompt: String) throws -> String {
        // Validate URL
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            throw RequestError.invalidURL
        }
        // Build request
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = [
            "model": "gpt-4.1",
            "messages": [
                ["role": "developer", "content": "you are a helpful assistant"],
                ["role": "user", "content": prompt]
            ]
        ]

        let httpBody = try JSONSerialization.data(withJSONObject: body)
        req.httpBody = httpBody
        // Synchronous network call
        let sem = DispatchSemaphore(value: 0)
        var responseData: Data?
        var urlResponse: URLResponse?
        var urlError: Error?
        let task = URLSession.shared.dataTask(with: req) { data, response, error in
            responseData = data
            urlResponse = response
            urlError = error
            sem.signal()
        }
        task.resume()
        if sem.wait(timeout: .now() + 60) == .timedOut {
            throw RequestError.timeout
        }
        if let error = urlError {
            throw error
        }
        guard let httpResp = urlResponse as? HTTPURLResponse else {
            throw RequestError.invalidResponse
        }
        guard (200...299).contains(httpResp.statusCode) else {
            throw RequestError.httpError(code: httpResp.statusCode)
        }
        guard let data = responseData else {
            throw RequestError.noData
        }
        let jsonObj = try JSONSerialization.jsonObject(with: data)
        guard let json = jsonObj as? [String: Any] else {
            throw RequestError.invalidJSON
        }
        
        guard let choices = json["choices"] as? [[String: Any]],
              let first = choices.first,
              let message = first["message"] as? [String: Any], // Cast explicitly here
              let text = message["content"] as? String else {
            throw RequestError.missingChoices
        }

        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private static func showNotification(title: String, subtitle: String? = nil) {
        let note = NSUserNotification()
        note.title = title
        if let sub = subtitle { note.informativeText = sub }
        NSUserNotificationCenter.default.deliver(note)
    }
    
    private static func restoreClipboard(_ content: String) {
        let pb = NSPasteboard.general
        pb.clearContents()
        if !content.isEmpty { pb.setString(content, forType: .string) }
    }
}