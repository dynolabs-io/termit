import Foundation

struct Snippet: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var command: String
    var tagsScope: [String]
    var requireConfirmation: Bool
    var variables: [String: String]

    init(
        id: UUID = UUID(),
        name: String,
        command: String,
        tagsScope: [String] = [],
        requireConfirmation: Bool = false,
        variables: [String: String] = [:]
    ) {
        self.id = id
        self.name = name
        self.command = command
        self.tagsScope = tagsScope
        self.requireConfirmation = requireConfirmation
        self.variables = variables
    }

    func renderedCommand(for host: Host) -> String {
        var out = command
        let env: [String: String] = [
            "HOST": host.hostname,
            "USER": host.username,
            "ALIAS": host.alias,
            "PORT": String(host.port),
        ].merging(variables) { _, custom in custom }
        for (k, v) in env {
            out = out.replacingOccurrences(of: "${\(k)}", with: v)
            out = out.replacingOccurrences(of: "$\(k)", with: v)
        }
        return out
    }

    func appliesTo(host: Host) -> Bool {
        guard !tagsScope.isEmpty else { return true }
        return !Set(tagsScope).isDisjoint(with: Set(host.tags))
    }
}

@MainActor
final class SnippetStore: ObservableObject {
    @Published private(set) var snippets: [Snippet] = []
    private let storageURL: URL

    init() {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        self.storageURL = dir.appendingPathComponent("snippets.json")
        load()
    }

    func add(_ snippet: Snippet) {
        snippets.append(snippet)
        persist()
    }

    func update(_ snippet: Snippet) {
        guard let idx = snippets.firstIndex(where: { $0.id == snippet.id }) else { return }
        snippets[idx] = snippet
        persist()
    }

    func delete(_ snippet: Snippet) {
        snippets.removeAll { $0.id == snippet.id }
        persist()
    }

    private func load() {
        guard let data = try? Data(contentsOf: storageURL),
              let decoded = try? JSONDecoder().decode([Snippet].self, from: data) else { return }
        snippets = decoded
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(snippets) else { return }
        try? data.write(to: storageURL, options: [.atomic, .completeFileProtection])
    }
}
