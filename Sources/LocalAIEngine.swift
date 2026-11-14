import Foundation
import Combine

struct DownloadableModel: Identifiable {
    let id: String
    let title: String
    let detail: String
    let url: URL
    let fileName: String

    static let catalog: [DownloadableModel] = [
        DownloadableModel(
            id: "qwen025",
            title: "Qwen 2.5 0.5B Instruct",
            detail: "Kleines Einsteigermodell · ca. 400 MB · GGUF Q4_K_M",
            url: URL(string: "https://huggingface.co/bartowski/Qwen2.5-0.5B-Instruct-GGUF/resolve/main/Qwen2.5-0.5B-Instruct-Q4_K_M.gguf")!,
            fileName: "Qwen2.5-0.5B-Instruct-Q4_K_M.gguf"
        ),
        DownloadableModel(
            id: "tinyllama",
            title: "TinyLlama 1.1B Chat",
            detail: "Kleines Chatmodell · ca. 700 MB · GGUF Q4_K_M",
            url: URL(string: "https://huggingface.co/bartowski/TinyLlama-1.1B-Chat-v1.0-GGUF/resolve/main/TinyLlama-1.1B-Chat-v1.0-Q4_K_M.gguf")!,
            fileName: "TinyLlama-1.1B-Chat-v1.0-Q4_K_M.gguf"
        )
    ]
}

final class LocalAIEngine: ObservableObject {
    @Published var downloadedModels: [String] = []
    @Published var selectedModelPath: String?
    @Published var status = "Engine noch nicht installiert"
    @Published var busy = false
    @Published var serverRunning = false
    @Published var serverURL = "http://127.0.0.1:8080"

    private var process: Process?
    private let fm = FileManager.default
    private let root: URL
    private var modelsFolder: URL { root.appendingPathComponent("Models", isDirectory: true) }
    private var engineFolder: URL { root.appendingPathComponent("Engine", isDirectory: true) }

    init() {
        let support = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        root = support.appendingPathComponent("WiFiAI", isDirectory: true)
        try? fm.createDirectory(at: modelsFolder, withIntermediateDirectories: true, attributes: nil)
        try? fm.createDirectory(at: engineFolder, withIntermediateDirectories: true, attributes: nil)
        refreshModels()
        if findServer() != nil { status = "KI-Engine installiert" }
    }

    func refreshModels() {
        let files = (try? fm.contentsOfDirectory(at: modelsFolder, includingPropertiesForKeys: nil)) ?? []
        downloadedModels = files.filter { $0.pathExtension.lowercased() == "gguf" }.map { $0.lastPathComponent }.sorted()
        if let selected = selectedModelPath, !fm.fileExists(atPath: selected) { selectedModelPath = nil }
        if selectedModelPath == nil, let first = files.first(where: { $0.pathExtension.lowercased() == "gguf" }) {
            selectedModelPath = first.path
        }
    }

    func modelURL(for name: String) -> URL? {
        let url = modelsFolder.appendingPathComponent(name)
        return fm.fileExists(atPath: url.path) ? url : nil
    }

    func downloadModel(_ model: DownloadableModel) {
        guard !busy else { return }
        busy = true
        status = "Lade Modell: \(model.title) …"
        let destination = modelsFolder.appendingPathComponent(model.fileName)
        let task = URLSession.shared.downloadTask(with: model.url) { [weak self] temporary, response, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                defer { self.busy = false }
                if let error = error { self.status = "Download fehlgeschlagen: \(error.localizedDescription)"; return }
                guard let temporary = temporary,
                      let http = response as? HTTPURLResponse,
                      (200..<300).contains(http.statusCode) else {
                    self.status = "Download fehlgeschlagen (HTTP-Antwort prüfen)."
                    return
                }
                do {
                    if self.fm.fileExists(atPath: destination.path) { try self.fm.removeItem(at: destination) }
                    try self.fm.moveItem(at: temporary, to: destination)
                    self.selectedModelPath = destination.path
                    self.refreshModels()
                    self.status = "Modell geladen: \(model.title)"
                } catch { self.status = "Speichern fehlgeschlagen: \(error.localizedDescription)" }
            }
        }
        task.resume()
    }

    func installEngine() {
        guard !busy else { return }
        busy = true
        status = "Suche passende llama.cpp-Version für Intel-Mac …"
        let releasesURL = URL(string: "https://api.github.com/repos/ggml-org/llama.cpp/releases?per_page=15")!
        var request = URLRequest(url: releasesURL)
        request.setValue("WiFiAI macOS app", forHTTPHeaderField: "User-Agent")
        URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            guard let self = self else { return }
            if let error = error { self.finishEngineInstall("GitHub nicht erreichbar: \(error.localizedDescription)"); return }
            guard let data = data else { self.finishEngineInstall("Keine Release-Daten erhalten."); return }
            do {
                let releases = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] ?? []
                let assets = releases.flatMap { ($0["assets"] as? [[String: Any]]) ?? [] }
                let candidate = assets.first {
                    let name = ($0["name"] as? String ?? "").lowercased()
                    return name.contains("macos") && (name.contains("x64") || name.contains("intel")) && (name.hasSuffix(".zip") || name.hasSuffix(".tar.gz"))
                }
                guard let asset = candidate, let address = asset["browser_download_url"] as? String, let url = URL(string: address) else {
                    self.finishEngineInstall("GitHub lieferte kein passendes macOS-Intel-Paket. Bitte später erneut versuchen.")
                    return
                }
                DispatchQueue.main.async { self.status = "Lade llama.cpp-Engine …" }
                let download = URLSession.shared.downloadTask(with: url) { temporary, _, downloadError in
                    if let downloadError = downloadError { self.finishEngineInstall("Engine-Download fehlgeschlagen: \(downloadError.localizedDescription)"); return }
                    guard let temporary = temporary else { self.finishEngineInstall("Engine-Download war leer."); return }
                    do {
                        try self.fm.createDirectory(at: self.engineFolder, withIntermediateDirectories: true, attributes: nil)
                        let archive = self.engineFolder.appendingPathComponent((asset["name"] as? String) ?? "llama-engine.zip")
                        if self.fm.fileExists(atPath: archive.path) { try self.fm.removeItem(at: archive) }
                        try self.fm.moveItem(at: temporary, to: archive)
                        let unzip = Process()
                        unzip.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
                        if archive.pathExtension == "gz" {
                            let tar = Process()
                            tar.executableURL = URL(fileURLWithPath: "/usr/bin/tar")
                            tar.arguments = ["-xzf", archive.path, "-C", self.engineFolder.path]
                            try tar.run(); tar.waitUntilExit()
                            if tar.terminationStatus != 0 { throw NSError(domain: "WiFiAI", code: 2, userInfo: [NSLocalizedDescriptionKey: "Engine-Archiv konnte nicht entpackt werden."]) }
                        } else {
                            unzip.arguments = ["-x", "-k", archive.path, self.engineFolder.path]
                            try unzip.run(); unzip.waitUntilExit()
                            if unzip.terminationStatus != 0 { throw NSError(domain: "WiFiAI", code: 3, userInfo: [NSLocalizedDescriptionKey: "Engine-ZIP konnte nicht entpackt werden."]) }
                        }
                        guard let binary = self.findServer() else { throw NSError(domain: "WiFiAI", code: 4, userInfo: [NSLocalizedDescriptionKey: "Im Paket wurde keine llama-server-Datei gefunden."]) }
                        try self.fm.setAttributes([.posixPermissions: 0o755], ofItemAtPath: binary.path)
                        self.finishEngineInstall("KI-Engine installiert.")
                    } catch { self.finishEngineInstall("Engine-Installation fehlgeschlagen: \(error.localizedDescription)") }
                }
                download.resume()
            } catch { self.finishEngineInstall("Release-Daten konnten nicht gelesen werden: \(error.localizedDescription)") }
        }.resume()
    }

    private func finishEngineInstall(_ message: String) {
        DispatchQueue.main.async { self.busy = false; self.status = message }
    }

    private func findServer() -> URL? {
        guard let enumerator = fm.enumerator(at: engineFolder, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles]) else { return nil }
        for case let url as URL in enumerator where url.lastPathComponent == "llama-server" { return url }
        return nil
    }

    func startServer() {
        guard !busy, !serverRunning else { return }
        guard let model = selectedModelPath, fm.fileExists(atPath: model) else { status = "Bitte zuerst ein GGUF-Modell herunterladen und auswählen."; return }
        guard let binary = findServer() else { status = "KI-Engine fehlt. Bitte zuerst Engine installieren."; return }
        do {
            let task = Process()
            task.executableURL = binary
            task.arguments = ["--model", model, "--host", "0.0.0.0", "--port", "8080", "--ctx-size", "2048"]
            let output = Pipe()
            task.standardOutput = output
            task.standardError = output
            task.terminationHandler = { [weak self] _ in
                DispatchQueue.main.async { self?.serverRunning = false; self?.status = "KI-Server gestoppt" }
            }
            try task.run()
            process = task
            serverRunning = true
            serverURL = "http://127.0.0.1:8080"
            status = "KI startet auf Port 8080 …"
        } catch { status = "KI konnte nicht gestartet werden: \(error.localizedDescription)" }
    }

    func stopServer() {
        process?.terminate()
        process = nil
        serverRunning = false
        status = "KI-Server gestoppt"
    }

    deinit { process?.terminate() }
}
