import Cocoa

class SettingsWindowController: NSWindowController {
    private let promptATextField = NSTextField()
    private let promptBTextField = NSTextField()
    private let promptCTextField = NSTextField()
    private let apiKeyTextField = NSTextField()

    init() {
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 400, height: 260),
                              styleMask: [.titled, .closable],
                              backing: .buffered,
                              defer: false)
        super.init(window: window)
        window.title = "Settings"
        setupUI()
        loadValues()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        guard let content = window?.contentView else { return }
        let labels = ["Prompt A:", "Prompt B:", "Prompt C:", "API Key:"]
        let textFields = [promptATextField, promptBTextField, promptCTextField, apiKeyTextField]
        for i in 0..<labels.count {
            let label = NSTextField(labelWithString: labels[i])
            label.frame = NSRect(x: 20, y: 200 - i * 40, width: 80, height: 24)
            content.addSubview(label)
            let tf = textFields[i]
            tf.frame = NSRect(x: 110, y: 200 - i * 40, width: 260, height: 24)
            tf.isEditable = true
            content.addSubview(tf)
        }
        let saveButton = NSButton(title: "Save", target: self, action: #selector(save(_:)))
        saveButton.frame = NSRect(x: 220, y: 20, width: 80, height: 30)
        content.addSubview(saveButton)
        let cancelButton = NSButton(title: "Cancel", target: self, action: #selector(cancel(_:)))
        cancelButton.frame = NSRect(x: 310, y: 20, width: 80, height: 30)
        content.addSubview(cancelButton)
    }

    private func loadValues() {
        let defaults = UserDefaults.standard
        promptATextField.stringValue = defaults.string(forKey: "promptA") ?? ""
        promptBTextField.stringValue = defaults.string(forKey: "promptB") ?? ""
        promptCTextField.stringValue = defaults.string(forKey: "promptC") ?? ""
        apiKeyTextField.stringValue = defaults.string(forKey: "openai_api_key") ?? ""
    }

    @objc private func save(_ sender: Any) {
        let defaults = UserDefaults.standard
        defaults.set(promptATextField.stringValue, forKey: "promptA")
        defaults.set(promptBTextField.stringValue, forKey: "promptB")
        defaults.set(promptCTextField.stringValue, forKey: "promptC")
        defaults.set(apiKeyTextField.stringValue, forKey: "openai_api_key")
        window?.close()
    }

    @objc private func cancel(_ sender: Any) {
        window?.close()
    }
}