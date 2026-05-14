import AppIntents
import Foundation

struct ConnectToHostIntent: AppIntent {
    static var title: LocalizedStringResource = "Connect to Host"
    static var description = IntentDescription("Open Termit and connect to a saved host.")
    static var openAppWhenRun: Bool = true

    @Parameter(title: "Host", description: "The host alias to connect to")
    var hostAlias: String

    func perform() async throws -> some IntentResult {
        let defaults = UserDefaults(suiteName: "group.io.dynolabs.termit") ?? .standard
        defaults.set(hostAlias, forKey: "intentReconnectAlias")
        return .result()
    }
}

struct RunSnippetIntent: AppIntent {
    static var title: LocalizedStringResource = "Run Snippet"
    static var description = IntentDescription("Run a saved snippet on a host.")
    static var openAppWhenRun: Bool = true

    @Parameter(title: "Snippet") var snippetName: String
    @Parameter(title: "Host") var hostAlias: String

    func perform() async throws -> some IntentResult {
        let defaults = UserDefaults(suiteName: "group.io.dynolabs.termit") ?? .standard
        defaults.set(["snippet": snippetName, "host": hostAlias], forKey: "intentRunSnippet")
        return .result()
    }
}

struct DisconnectAllIntent: AppIntent {
    static var title: LocalizedStringResource = "Disconnect All Sessions"
    static var description = IntentDescription("Disconnect every active SSH/Mosh session in Termit.")
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult {
        let defaults = UserDefaults(suiteName: "group.io.dynolabs.termit") ?? .standard
        defaults.set(Date(), forKey: "intentDisconnectAll")
        return .result()
    }
}

struct TermitShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: ConnectToHostIntent(),
            phrases: ["Connect to \(\.$hostAlias) in \(.applicationName)"],
            shortTitle: "Connect to host",
            systemImageName: "terminal"
        )
        AppShortcut(
            intent: DisconnectAllIntent(),
            phrases: ["Disconnect everything in \(.applicationName)"],
            shortTitle: "Disconnect all",
            systemImageName: "wifi.slash"
        )
    }
}
