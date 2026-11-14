import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: ChatStore
    @EnvironmentObject var engine: LocalAIEngine
    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("WiFiAI – Lokale KI").font(.title).bold()
                Spacer()
                Button("Fertig") { presentationMode.wrappedValue.dismiss() }
            }

            GroupBox(label: Text("1. KI-Engine")) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("WiFiAI lädt die passende llama.cpp-Engine für macOS Intel von den offiziellen GitHub-Releases.")
                        .font(.caption).foregroundColor(.secondary)
                    HStack {
                        Button(action: { engine.installEngine() }) {
                            Text(engine.busy ? "Bitte warten …" : "Engine herunterladen / installieren")
                        }.disabled(engine.busy)
                        Spacer()
                        Text(engine.status).font(.caption).foregroundColor(.secondary).lineLimit(2)
                    }
                }.padding(8)
            }

            GroupBox(label: Text("2. KI-Modelle herunterladen")) {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(DownloadableModel.catalog) { model in
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(model.title).fontWeight(.semibold)
                                Text(model.detail).font(.caption).foregroundColor(.secondary)
                            }
                            Spacer()
                            if engine.downloadedModels.contains(model.fileName) {
                                Text("Geladen").foregroundColor(.green).font(.caption)
                            } else {
                                Button("Herunterladen") { engine.downloadModel(model) }
                                    .disabled(engine.busy)
                            }
                        }
                        Divider()
                    }
                    if !engine.downloadedModels.isEmpty {
                        Picker("Aktives Modell", selection: Binding(
                            get: { engine.selectedModelPath ?? "" },
                            set: { engine.selectedModelPath = $0.isEmpty ? nil : $0 }
                        )) {
                            ForEach(engine.downloadedModels, id: \.self) { name in
                                Text(name).tag(engine.modelURL(for: name)?.path ?? "")
                            }
                        }
                    }
                }.padding(8)
            }

            GroupBox(label: Text("3. KI im WLAN starten")) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Button(action: { engine.startServer() }) { Text("KI-Server starten") }
                            .disabled(engine.serverRunning || engine.busy)
                        Button(action: { engine.stopServer() }) { Text("Stoppen") }
                            .disabled(!engine.serverRunning)
                        Spacer()
                        Text(engine.serverRunning ? "Läuft" : "Gestoppt")
                            .font(.caption).foregroundColor(engine.serverRunning ? .green : .secondary)
                    }
                    Text("Port: 8080 · LAN-Adresse: http://MAC-IP:8080")
                        .font(.system(.caption, design: .monospaced))
                    Text("Der Server bindet an alle Netzwerk-Schnittstellen. Nur in vertrauenswürdigen WLANs verwenden; aktuell ohne Passwortschutz.")
                        .font(.caption).foregroundColor(.secondary)
                }.padding(8)
            }

            Spacer()
        }
        .padding(20)
        .frame(width: 620, height: 610)
    }
}