import Foundation

final class Preferences {
    static let shared = Preferences()
    private let defaults = UserDefaults(suiteName: "group.io.dynolabs.termit") ?? .standard

    var iCloudSyncEnabled: Bool {
        get { defaults.bool(forKey: "iCloudSyncEnabled") }
        set { defaults.set(newValue, forKey: "iCloudSyncEnabled") }
    }

    var biometricRequiredEverySession: Bool {
        get { defaults.object(forKey: "biometricEverySession") as? Bool ?? true }
        set { defaults.set(newValue, forKey: "biometricEverySession") }
    }

    var themeID: String {
        get { defaults.string(forKey: "themeID") ?? "solarized-dark" }
        set { defaults.set(newValue, forKey: "themeID") }
    }

    var preferredFont: String {
        get { defaults.string(forKey: "fontFamily") ?? "JetBrainsMono-Regular" }
        set { defaults.set(newValue, forKey: "fontFamily") }
    }

    var fontSize: Double {
        get {
            let stored = defaults.double(forKey: "fontSize")
            return stored == 0 ? 13 : stored
        }
        set { defaults.set(newValue, forKey: "fontSize") }
    }

    var cursorStyle: String {
        get { defaults.string(forKey: "cursorStyle") ?? "block" }
        set { defaults.set(newValue, forKey: "cursorStyle") }
    }

    var lastUsedHostID: String? {
        get { defaults.string(forKey: "lastUsedHostID") }
        set { defaults.set(newValue, forKey: "lastUsedHostID") }
    }
}
