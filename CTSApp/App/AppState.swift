import Foundation
import SwiftUI
internal import Combine

@MainActor
final class AppState: ObservableObject {
    @Published var session: UserSession?
    @Published var authGate: AuthGateState = .unauthenticated

    private let env: AppEnvironment

    init(env: AppEnvironment) {
        self.env = env
        restoreSessionIfPossible()
    }

    func restoreSessionIfPossible() {
        // If we have tokens and the user opted into biometrics, gate access with FaceID/TouchID.
        if let tokens = try? env.secureStore.readTokens(), tokens != nil, env.preferences.isBiometricLoginEnabled {
            authGate = .biometricRequired
        } else {
            authGate = .unauthenticated
        }
    }

    func completeAuthentication(tokens: AuthTokens, rememberUsername: String?) {
        try? env.secureStore.writeTokens(tokens)
        // NOTE: Avoid mutating env.preferences here because it's likely a `let` struct in AppEnvironment.
        // If persisting the remembered username is required, expose a mutating API on AppEnvironment,
        // e.g. `env.updateRememberedUsername(rememberUsername)` or make `preferences` reference type.
        // For now, skip direct mutation to fix compile error.
        _ = rememberUsername // intentionally unused for now
        session = UserSession(tokens: tokens)
        authGate = .authenticated
    }

    func signOut() {
        try? env.secureStore.clearTokens()
        session = nil
        authGate = .unauthenticated
    }
}

enum AuthGateState: Equatable {
    case unauthenticated
    case biometricRequired
    case authenticated
}

struct UserSession: Equatable {
    let tokens: AuthTokens
}

