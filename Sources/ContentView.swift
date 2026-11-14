import SwiftUI
import AppKit

struct ContentView: View {
    @EnvironmentObject var store: ChatStore
    @State private var draft = ""
    @State private var settings = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                HStack {
                    Text("WiFiAI").font(.title).bold()
                    Spacer()
                    Button(action: { store.newChat() }) { Image(systemName: "square.and.pencil") }
                }.padding()
                List {
                    ForEach(store.sessions) { chat in
                        Button(action: { store.selectedID = chat.id }) {
                            HStack {
                                Text(chat.title).lineLimit(1)
                                Spacer()
                                if chat.id == store.selectedID { Image(systemName: "checkmark").foregroundColor(.accentColor) }
                            }
                        }.contextMenu { Button("Chat löschen") { store.delete(chat) } }
                    }
                }
                Divider()
                Button(action: { settings = true }) { Label("Einstellungen", systemImage: "gear") }.padding()
                Text(store.status).font(.caption).foregroundColor(.secondary).padding(.bottom, 8)
            }.frame(minWidth: 190, idealWidth: 220, maxWidth: 250)

            VStack(spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(store.selectedModel.isEmpty ? "Kein Modell" : store.selectedModel).font(.headline)
                        Text(store.backend.rawValue + " · " + store.status).font(.caption).foregroundColor(.secondary)
                    }
                    Spacer()
                    Button(action: { settings = true }) { Image(systemName: "slider.horizontal.3") }
                }.padding()
                Divider()
                if let chat = store.selectedSession, !chat.messages.isEmpty {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 14) {
                            ForEach(chat.messages) { message in
                                HStack {
                                    if message.role == .assistant {
                                        bubble(message)
                                        Spacer(minLength: 55)
                                    } else {
                                        Spacer(minLength: 55)
                                        bubble(message)
                                    }
                                }
                            }
                        }.padding()
                    }
                } else {
                    Spacer()
                    VStack(spacing: 10) {
                        Image(systemName: "bubble.left.and.bubble.right").font(.system(size: 42)).foregroundColor(.secondary)
                        Text("Chatte mit deiner lokalen KI").font(.title2).bold()
                        Text("Verbinde dich über Einstellungen mit einem KI-Server im WLAN.").foregroundColor(.secondary)
                    }
                    Spacer()
                }
                Divider()
                HStack(spacing: 10) {
                    TextField("Nachricht schreiben …", text: $draft).textFieldStyle(RoundedBorderTextFieldStyle()).onCommit(send)
                    Button(action: send) { Image(systemName: "arrow.up.circle.fill").font(.system(size: 28)) }
                        .disabled(store.busy || draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }.padding()
            }
        }
        .navigationViewStyle(DoubleColumnNavigationViewStyle())
        .sheet(isPresented: $settings) { SettingsView().environmentObject(store) }
        .alert(item: Binding<AlertMessage?>(
            get: { store.error.map { AlertMessage(text: $0) } },
            set: { _ in store.error = nil }
        )) { item in Alert(title: Text("WiFiAI"), message: Text(item.text), dismissButton: .default(Text("OK"))) }
    }

    private func bubble(_ message: ChatMessage) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(message.role == .user ? "Du" : "KI").font(.caption).bold().foregroundColor(.secondary)
            Text(message.content)
        }.padding(12)
            .background(message.role == .user ? Color.accentColor.opacity(0.14) : Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)
    }

    private func send() {
        let value = draft
        draft = ""
        store.send(value)
    }
}

struct AlertMessage: Identifiable {
    let id = UUID()
    let text: String
}
