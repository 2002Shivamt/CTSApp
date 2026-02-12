import Foundation
import LocalAuthentication

protocol BiometricAuthenticating {
    func canEvaluate() -> Bool
    func authenticate(reason: String) async -> Bool
}

final class LocalBiometricAuthenticator: BiometricAuthenticating {
    func canEvaluate() -> Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

    func authenticate(reason: String) async -> Bool {
        let context = LAContext()
        do {
            return try await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason)
        } catch {
            return false
        }
    }
}

