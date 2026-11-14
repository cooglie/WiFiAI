import Foundation
import Combine

final class ChatStore: ObservableObject {
    @Published var backend: AIBackend = .llamaCpp
    @Published var serverURL = "http://127.0.0.1:8080"
    @Published var selectedModel = ""
    @Published var models: [String] = []
    @Published var sessions: [ChatSession] = []
    @Published var selectedID: UUID?
    @Published var busy = false
    @Published var status = "Nicht verbunden"
    @Published var error: String?

    private let defaults = UserDefaults.standard
    private let historyURL: URL

    var selectedSession: ChatSession? { sessions.first { $0.id == selectedID } }

    init() {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let folder = base.appendingPathComponent("WiFiAI", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true, attributes: nil)
        historyURL = folder.appendingPathComponent("chats.json")
        backend = AIBackend(rawValue: defaults.string(forKey: "backend") ?? "llama.cpp") ?? .ollama
        serverURL = defaults.string(forKey: "serverURL") ?? serverURL
        selectedModel = defaults.string(forKey: "model") ?? ""
        if let data = try? Data(contentsOf: historyURL),
           let saved = try? JSONDecoder().decode([ChatSession].self, from: data) {
            sessions = saved.sorted { $0.updatedAt > $1.updatedAt }
        }
        if sessions.isEmpty { sessions = [ChatSession()] }
        selectedID = sessions.first?.id
    }

    func save() {
        defaults.set(backend.rawValue, forKey: "backend")
        defaults.set(serverURL, forKey: "serverURL")
        defaults.set(selectedModel, forKey: "model")
        if let data = try? JSONEncoder().encode(sessions) { try? data.write(to: historyURL, options: .atomic) }
    }

    func newChat() {
        let chat = ChatSession()
        sessions.insert(chat, at: 0)
        selectedID = chat.id
        save()
    }

    func delete(_ chat: ChatSession) {
        sessions.removeAll { $0.id == chat.id }
        if sessions.isEmpty { newChat() }
        else if selectedID == chat.id { selectedID = sessions.first?.id }
        save()
    }

    private func baseURL() -> URL? {
        guard let url = URL(string: serverURL.trimmingCharacters(in: .whitespacesAndNewlines)),
              ["http", "https"].contains(url.scheme ?? ""), url.host != nil else { return nil }
        return url
    }

    func loadModels() {
        guard let base = baseURL() else { error = "Ungültige Server-Adresse."; return }
        busy = true
        error = nil
        let path = backend == .ollama ? "api/tags" : "v1/models"
        var req = URLRequest(url: base.appendingPathComponent(path))
        req.timeoutInterval = 15
        URLSession.shared.dataTask(with: req) { [weak self] data, response, err in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.busy = false
                if let err = err { self.status = "Offline"; self.error = err.localizedDescription; return }
                guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode), let data = data else {
                    self.status = "Serverfehler"; self.error = "Server nicht erreichbar. IP, Port und Firewall prüfen."; return
                }
                do {
                    if self.backend == .ollama {
                        self.models = try JSONDecoder().decode(OllamaTags.self, from: data).models.map { $0.name }
                    } else {
                        self.models = try JSONDecoder().decode(OpenAIModels.self, from: data).data.map { $0.id }
                    }
                    if !self.models.contains(self.selectedModel) { self.selectedModel = self.models.first ?? "" }
                    self.status = "Verbunden · \(self.models.count) Modell(e)"
                    self.save()
                } catch { self.status = "API-Fehler"; self.error = "Die Serverantwort konnte nicht gelesen werden." }
            }
        }.resume()
    }

    func send(_ raw: String) {
        let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !busy else { return }
        guard !selectedModel.isEmpty else { error = "Bitte zuerst ein Modell laden."; return }
        guard let base = baseURL() else { error = "Ungültige Server-Adresse."; return }
        guard let idx = sessions.firstIndex(where: { $0.id == selectedID }) else { return }

        sessions[idx].messages.append(ChatMessage(role: .user, content: text))
        sessions[idx].updatedAt = Date()
        if sessions[idx].title == "Neuer Chat" { sessions[idx].title = String(text.prefix(40)) }
        let messages = sessions[idx].messages.map { ["role": $0.role.rawValue, "content": $0.content] }
        save()
        busy = true
        status = "KI antwortet …"
        error = nil

        let path = backend == .ollama ? "api/chat" : "v1/chat/completions"
        var req = URLRequest(url: base.appendingPathComponent(path))
        req.httpMethod = "POST"
        req.timeoutInterval = 300
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = ["model": selectedModel, "messages": messages, "stream": false]
        do { req.httpBody = try JSONSerialization.data(withJSONObject: body) }
        catch { busy = false; self.error = "Nachricht konnte nicht kodiert werden."; return }

        URLSession.shared.dataTask(with: req) { [weak self] data, response, err in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.busy = false
                if let err = err { self.status = "Fehler"; self.error = err.localizedDescription; return }
                guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode), let data = data else {
                    self.status = "Serverfehler"; self.error = "KI-Anfrage fehlgeschlagen. Modell und Server prüfen."; return
                }
                do {
                    let answer: String
                    if self.backend == .ollama { answer = try JSONDecoder().decode(OllamaReply.self, from: data).message.content }
                    else { answer = try JSONDecoder().decode(OpenAIReply.self, from: data).choices.first?.message.content ?? "" }
                    guard let i = self.sessions.firstIndex(where: { $0.id == self.selectedID }) else { return }
                    self.sessions[i].messages.append(ChatMessage(role: .assistant, content: answer))
                    self.sessions[i].updatedAt = Date()
                    self.status = "Bereit"
                    self.save()
                } catch { self.status = "Antwortfehler"; self.error = "Antwortformat nicht erkannt." }
            }
        }.resume()
    }
}
