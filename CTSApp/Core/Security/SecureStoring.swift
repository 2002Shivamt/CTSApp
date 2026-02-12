import Foundation

protocol SecureStoring {
    func readTokens() throws -> AuthTokens?
    func writeTokens(_ tokens: AuthTokens) throws
    func clearTokens() throws
}

enum SecureStoreError: Error {
    case notFound
    case unavailable
}

/// UI-only phase store (resets on app relaunch).
final class InMemorySecureStore: SecureStoring {
    private var tokens: AuthTokens?

    func readTokens() throws -> AuthTokens? { tokens }
    func writeTokens(_ tokens: AuthTokens) throws { self.tokens = tokens }
    func clearTokens() throws { tokens = nil }
}

