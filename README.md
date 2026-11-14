# WiFiAI

WiFiAI is a native macOS app that is being developed to download GGUF models, run them locally with llama.cpp, and expose the local model through an HTTP API on the Mac.

## Current development build

The project now contains:
- A model catalogue with direct GGUF downloads (Qwen 2.5 0.5B Instruct and TinyLlama 1.1B Chat).
- A first engine installer that searches official llama.cpp GitHub release assets for a macOS Intel archive.
- A local server launcher configured for port 8080 and host 0.0.0.0.
- Local model storage under ~/Library/Application Support/WiFiAI/Models.

**Important:** This is an early, unverified implementation. The engine asset discovery depends on the naming of upstream release assets, and this code has not yet been built or tested end-to-end on a Mac. A successful source commit is not a tested app release.

## How it is intended to work

1. Open WiFiAI and open “KI / Modelle”.
2. Install the llama.cpp engine.
3. Download a GGUF model.
4. Select the model and start the KI server.
5. Connect from another device on the same trusted Wi-Fi using http://MAC-IP:8080.

The server currently has no authentication. Do not expose port 8080 to the public internet or an untrusted network.

## Requirements

- Intel macOS target: macOS 10.15 or newer.
- A compatible llama.cpp macOS x64 release asset.
- Enough RAM and disk space for the selected model. Small models are recommended for older Intel Macs.

## License

MIT
