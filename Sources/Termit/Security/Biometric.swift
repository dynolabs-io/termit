import Foundation
import LocalAuthentication

@MainActor
final class BiometricGate {
    static let shared = BiometricGate()
    private(set) var isUnlocked = false

    func unlockOrPrompt(reason: String = "Unlock Termit") async {
        guard !isUnlocked else { return }
        let ctx = LAContext()
        var err: NSError?
        guard ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &err) else {
            isUnlocked = true
            return
        }
        do {
            let ok = try await ctx.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason)
            isUnlocked = ok
        } catch {
            isUnlocked = false
        }
    }

    func requireForSession(host: Host) async -> Bool {
        guard Preferences.shared.biometricRequiredEverySession else { return true }
        let ctx = LAContext()
        var err: NSError?
        guard ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &err) else { return true }
        return (try? await ctx.evaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            localizedReason: "Authenticate to connect to \(host.alias)"
        )) ?? false
    }
}
