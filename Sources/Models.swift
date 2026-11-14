import Foundation

enum AIBackend: String, CaseIterable, Identifiable {
    case ollama = "Ollama"
    case llamaCpp = "llama.cpp"
    var id: String { rawValue }
}

struct ChatMessage: Codable, Identifiable {
    enum Role: String, Codable { case user, assistant }
    let id: UUID
    let role: Role
    let content: String
    let date: Date
    init(role: Role, content: String) {
        self.id = UUID()
        self.role = role
        self.content = content
        self.date = Date()
    }
}

struct ChatSession: Codable, Identifiable {
    let id: UUID
    var title: String
    var messages: [ChatMessage]
    var updatedAt: Date
    init() {
        id = UUID()
        title = "Neuer Chat"
        messages = []
        updatedAt = Date()
    }
}

struct OllamaTags: Decodable {
    struct Model: Decodable { let name: String }
    let models: [Model]
}
struct OpenAIModels: Decodable {
    struct Model: Decodable { let id: String }
    let data: [Model]
}
struct OllamaReply: Decodable {
    struct Message: Decodable { let content: String }
    let message: Message
}
struct OpenAIReply: Decodable {
    struct Choice: Decodable {
        struct Message: Decodable { let content: String }
        let message: Message
    }
    let choices: [Choice]
}
