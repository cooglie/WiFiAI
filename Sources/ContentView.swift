import SwiftUI
import AppKit

struct ContentView: View {
    @EnvironmentObject var store: ChatStore
    @EnvironmentObject var engine: LocalAIEngine
    @State private var draft = ""
    @State private var showingSettings = false

    private var canSend: Bool {
        !store.busy && !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        HStack(spacing: 0) {
            sidebar
                .frame(width: 245)

            Divider()

            mainPanel
        }
        .frame(minWidth: 760, minHeight: 520)
        .sheet(isPresented: $showingSettings) {
            SettingsView().environmentObject(store)
        }
        .alert(item: Binding<AlertMessage?>(
            get: { store.error.map { AlertMessage(text: $0) } },
            set: { _ in store.error = nil }
        )) { item in
            Alert(
                title: Text("WiFiAI"),
                message: Text(item.text),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                Text("◉")
                    .font(.system(size: 25, weight: .bold))
                    .foregroundColor(.accentColor)
                VStack(alignment: .leading, spacing: 1) {
                    Text("WiFiAI").font(.title).bold()
                    Text("LOCAL AI CHAT").font(.system(size: 9, weight: .bold)).foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 20)

            Button(action: { store.newChat() }) {
                HStack {
                    Text("＋").font(.system(size: 18, weight: .medium))
                    Text("Neuer Chat").fontWeight(.semibold)
                    Spacer()
                }
                .padding(10)
                .background(Color.accentColor.opacity(0.13))
                .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal, 14)
            .padding(.bottom, 18)

            Text("VERLAUF")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.secondary)
                .padding(.horizontal, 18)
                .padding(.bottom, 8)

            ScrollView {
                VStack(spacing: 4) {
                    ForEach(store.sessions) { chat in
                        Button(action: { store.selectedID = chat.id }) {
                            HStack(spacing: 9) {
                                Text("▤").foregroundColor(.secondary)
                                Text(chat.title)
                                    .lineLimit(1)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                if chat.id == store.selectedID {
                                    Text("•").foregroundColor(.accentColor)
                                }
                            }
                            .font(.system(size: 13))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 9)
                            .background(chat.id == store.selectedID ? Color.accentColor.opacity(0.12) : Color.clear)
                            .cornerRadius(7)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .contextMenu {
                            Button("Chat löschen") { store.delete(chat) }
                        }
                    }
                }
                .padding(.horizontal, 10)
            }

            Divider()

            Button(action: { showingSettings = true }) {
                HStack(spacing: 10) {
                    Text("⚙").font(.system(size: 16))
                    Text("Einstellungen")
                    Spacer()
                    Text("›").foregroundColor(.secondary)
                }
                .padding(14)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())

            HStack(spacing: 7) {
                Circle()
                    .fill(store.status.contains("Verbunden") || store.status == "Bereit" ? Color.green : Color.orange)
                    .frame(width: 7, height: 7)
                Text(store.status)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 13)
        }
        .background(Color(NSColor.windowBackgroundColor))
    }

    private var mainPanel: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(store.selectedModel.isEmpty ? "Dein lokaler KI-Chat" : store.selectedModel)
                        .font(.headline)
                    Text(engine.serverRunning ? "Eigene KI läuft · Port 8080" : "Lokale KI · " + engine.status)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                Spacer()
                Button(action: { showingSettings = true }) {
                    Text("Verbindung einrichten")
                }
                .buttonStyle(BorderedButtonStyle())
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 15)

            Divider()

            if let chat = store.selectedSession, !chat.messages.isEmpty {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        ForEach(chat.messages) { message in
                            messageRow(message)
                        }
                        if store.busy {
                            HStack(spacing: 8) {
                                Text("◉").foregroundColor(.accentColor)
                                Text("Die KI antwortet …").font(.caption).foregroundColor(.secondary)
                            }
                            .padding(.leading, 8)
                        }
                    }
                    .padding(22)
                    .frame(maxWidth: 850)
                    .frame(maxWidth: .infinity)
                }
            } else {
                welcomePanel
            }

            Divider()

            VStack(spacing: 8) {
                HStack(alignment: .center, spacing: 10) {
                    TextField("Schreibe eine Nachricht …", text: $draft, onCommit: send)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .disabled(store.busy)
                    Button(action: send) {
                        Text(store.busy ? "…" : "Senden  ↑")
                            .fontWeight(.semibold)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                    }
                    .disabled(!canSend)
                }
                Text("Deine Nachrichten werden lokal von WiFiAI verarbeitet.")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 13)
            .background(Color(NSColor.windowBackgroundColor))
        }
    }

    private var welcomePanel: some View {
        VStack(spacing: 15) {
            Spacer()
            Text("◉")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(.accentColor)
            Text("Deine KI. Dein Netzwerk.")
                .font(.system(size: 25, weight: .bold))
            Text("Lade ein Modell herunter und starte deine eigene KI direkt auf diesem Mac.")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 390)
            Button(action: { showingSettings = true }) {
                Text("Modelle & KI-Server einrichten")
                    .fontWeight(.semibold)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 9)
            }
            .buttonStyle(BorderedButtonStyle())
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.textBackgroundColor))
    }

    private func messageRow(_ message: ChatMessage) -> some View {
        HStack {
            if message.role == .assistant {
                messageBubble(message)
                Spacer(minLength: 70)
            } else {
                Spacer(minLength: 70)
                messageBubble(message)
            }
        }
    }

    private func messageBubble(_ message: ChatMessage) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(message.role == .user ? "DU" : "WIFI AI")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.secondary)
            Text(message.content)
                .font(.system(size: 13))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(13)
        .background(message.role == .user ? Color.accentColor.opacity(0.13) : Color(NSColor.controlBackgroundColor))
        .cornerRadius(10)
        .frame(maxWidth: 620, alignment: .leading)
    }

    private func send() {
        let value = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return }
        draft = ""
        store.send(value)
    }
}

struct AlertMessage: Identifiable {
    let id = UUID()
    let text: String
}
