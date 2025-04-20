 # HelloHotKey

 A macOS menu bar application that reformats selected text using custom prompts and the OpenAI API.

 ## Features
 - Choose between three custom prompts (Prompt A, Prompt B, Prompt C).
 - Global hotkey (Shift+Command+P) to reform text in any application.
 - Settings UI to define/edit prompts and your OpenAI API key.
 - Persistent storage of prompts and API key between sessions.

 ## Dependencies
 - macOS (latest version).
 - Xcode Command Line Tools.

 ## Installation & Building
 1. Clone this repository.
 2. Install Xcode Command Line Tools if needed:
    ```bash
    xcode-select --install
    ```
 3. Build the app:
    ```bash
    ./build.sh
    ```
    This produces `HelloHotKey.app`.

 ## Configuration
 1. Launch `HelloHotKey.app`; a 🔔 icon appears in the menu bar.
 2. Click the icon and select **Settings**.
 3. Enter your OpenAI API key under **API Key:**.
 4. Define custom prompt templates for **Prompt A**, **Prompt B**, and **Prompt C**.
 5. Click **Save**.

 ## Usage
 1. Select text in any application.
 2. Press **Shift+Command+P** (the global hotkey).
 3. The app sends your selected text and chosen prompt to OpenAI.
 4. The original text is automatically replaced with the AI-generated result.

 ## Packaging for Distribution
 After building, you can code-sign and notarize the `.app` for distribution:
 ```bash
 codesign --deep --force --verify --verbose \
   --sign "Developer ID Application: Your Name (TEAMID)" HelloHotKey.app
 ```
 Notarization steps vary per Apple documentation.