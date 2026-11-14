# WiFiAI

Native standalone macOS chat client for a local AI server on your Wi-Fi.

- macOS 10.15 Catalina or newer
- Intel x86_64 build (universal/Apple Silicon can be added later)
- Ollama API and llama.cpp OpenAI-compatible API
- Chat history stored locally in Application Support
- No Python, Node.js, browser, cloud account or API key required on the Mac running this app

## Server setup

The app is a standalone **client**. The AI model and inference server run on another computer on your LAN.

### Ollama
Configure Ollama on the server to listen on your LAN interface, for example `OLLAMA_HOST=0.0.0.0:11434`, then pull a model such as `ollama pull llama3.2`. In WiFiAI use the server URL `http://SERVER-IP:11434`.

### llama.cpp
Start the server on the other computer, for example:
```bash
./llama-server -m /path/to/model.gguf --host 0.0.0.0 --port 8080
```
In WiFiAI use `http://SERVER-IP:8080`.

Allow the port through the server computer's firewall. Use only trusted LANs: this initial version does not add authentication or TLS.

## Build
Open `WiFiAI.xcodeproj` in Xcode and build the `WiFiAI` scheme. Deployment target: macOS 10.15.

## Release
Pushing to `main` runs the GitHub Actions workflow. It builds `WiFiAI.app`, packages it as `WiFiAI-macOS.zip`, and publishes the v0.1.0 GitHub Release.

The GitHub runner build is not a substitute for testing on a physical Catalina Intel Mac.

## License
MIT
