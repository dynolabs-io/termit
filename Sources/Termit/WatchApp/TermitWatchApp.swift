import SwiftUI
import WatchKit
import WatchConnectivity

@main
struct TermitWatchApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    @StateObject private var session = WatchSessionRelay()

    var body: some View {
        List {
            Section("Recent") {
                ForEach(session.recentHosts, id: \.self) { alias in
                    Button {
                        session.reconnect(alias: alias)
                    } label: {
                        Label(alias, systemImage: "terminal")
                    }
                }
                if session.recentHosts.isEmpty {
                    Text("No recent hosts").font(.caption).foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Termit")
    }
}

final class WatchSessionRelay: NSObject, ObservableObject, WCSessionDelegate {
    @Published var recentHosts: [String] = []

    override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    func reconnect(alias: String) {
        try? WCSession.default.updateApplicationContext(["reconnectAlias": alias])
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        DispatchQueue.main.async {
            if let recent = applicationContext["recentHosts"] as? [String] {
                self.recentHosts = recent
            }
        }
    }
}
