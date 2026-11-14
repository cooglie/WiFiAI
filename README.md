# WiFiAI

WiFiAI is an early macOS project intended to become a client for AI servers running on the same local network.

## Current status

**The current build does not yet provide a working, usable graphical user interface.** The app bundle can be compiled for Intel Macs, but a successful compile does not mean that the interface and chat workflow are complete or tested.

This is an experimental development build, not a finished chat application.

## Planned functionality

- Connect to an AI server on the local network
- Support for Ollama
- Support for llama.cpp using its OpenAI-compatible server API
- Local chat history and connection settings

These features should be considered planned or under development until they have been tested in a working app build.

## Platform

- macOS 10.15 Catalina or newer is the intended minimum
- Intel x86_64 build
- AI server and model are expected to run on another computer
- The app does not bundle AI models or an inference server

## Security

Do not expose an AI server directly to the public internet. Use only trusted networks and configure authentication and firewall rules on the server where available.

## Build

The repository contains a Swift macOS project. Building through Xcode requires Xcode; the standalone command-line build is experimental and may require additional compatibility fixes.

## Releases

See the [GitHub Releases](https://github.com/cooglie/WiFiAI/releases) page for available test builds. Release assets should be treated as experimental until the GUI and server connection have been verified.

## License

MIT
