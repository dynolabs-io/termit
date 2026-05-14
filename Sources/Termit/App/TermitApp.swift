import SwiftUI

@main
struct TermitApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var hostStore = HostStore()
    @StateObject private var snippetStore = SnippetStore()
    @StateObject private var themeStore = ThemeStore()
    @StateObject private var sessionManager = SessionManager()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(hostStore)
                .environmentObject(snippetStore)
                .environmentObject(themeStore)
                .environmentObject(sessionManager)
                .preferredColorScheme(themeStore.colorScheme)
                .onAppear {
                    Task { await BiometricGate.shared.unlockOrPrompt() }
                }
        }
        .commands {
            TerminalCommands()
        }
    }
}
