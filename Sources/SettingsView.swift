import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: ChatStore
    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Verbindung").font(.title).bold()
                Spacer()
                Button("Fertig") { presentationMode.wrappedValue.dismiss() }
            }
            Form {
                Picker("KI-Software", selection: $store.backend) {
                    ForEach(AIBackend.allCases) { item in Text(item.rawValue).tag(item) }
                }
                TextField("Server-URL (z. B. http://192.168.1.50:11434)", text: $store.serverURL)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button(action: {
                    store.save()
                    store.loadModels()
                }) {
                    if store.busy { ProgressView().scaleEffect(0.7) }
                    else { Text("Verbindung testen und Modelle laden") }
                }.disabled(store.busy)
                Picker("Modell", selection: $store.selectedModel) {
                    if store.models.isEmpty { Text("Keine Modelle geladen").tag("") }
                    ForEach(store.models, id: \.self) { model in Text(model).tag(model) }
                }
                Text(store.status).font(.caption).foregroundColor(.secondary)
            }
            Text("Ollama: normalerweise Port 11434. llama.cpp: häufig Port 8080. Die KI läuft auf einem anderen Computer im WLAN.")
                .font(.caption).foregroundColor(.secondary)
            Spacer()
        }.padding(22).frame(width: 500, height: 340)
    }
}
