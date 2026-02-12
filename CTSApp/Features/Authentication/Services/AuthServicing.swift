import Foundation

protocol AuthServicing {
    func login(username: String, password: String) async throws
    func signup(username: String, password: String) async throws
    func login(with provider: SocialProvider) async throws
    func signup(with provider: SocialProvider) async throws

    func sendTwoFactorCode(method: TwoFactorMethod) async throws
    func verifyTwoFactorCode(_ code: String) async throws -> AuthTokens

    /// UI-only helper for simulating "account already exists" at sign up.
    func isExistingAccount(username: String) async -> Bool
}

enum AuthUIError: LocalizedError, Equatable {
    case invalidCredentials
    case accountAlreadyExists
    case invalidTwoFactorCode
    case generic(String)

    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            "Please check your email and password and try again."
        case .accountAlreadyExists:
            "An account already exists for this email. Please log in instead."
        case .invalidTwoFactorCode:
            "That code didn’t work. Please try again."
        case let .generic(message):
            message
        }
    }
}

/// Mock implementation that powers the UI flow without any backend.
final class MockAuthService: AuthServicing {
    func isExistingAccount(username: String) async -> Bool {
        // Deterministic UI behavior:
        // - any email containing "+existing" simulates an already-registered account.
        username.lowercased().contains("+existing")
    }

    func login(username: String, password: String) async throws {
        try await Task.sleep(nanoseconds: 300_000_000)
        guard !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !password.isEmpty
        else { throw AuthUIError.invalidCredentials }
    }

    func signup(username: String, password: String) async throws {
        try await Task.sleep(nanoseconds: 300_000_000)
        if await isExistingAccount(username: username) {
            throw AuthUIError.accountAlreadyExists
        }
        guard !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              password.count >= 8
        else { throw AuthUIError.generic("Use a valid email and a password with at least 8 characters.") }
    }

    func login(with provider: SocialProvider) async throws {
        try await Task.sleep(nanoseconds: 300_000_000)
    }

    func signup(with provider: SocialProvider) async throws {
        try await Task.sleep(nanoseconds: 300_000_000)
    }

    func sendTwoFactorCode(method: TwoFactorMethod) async throws {
        try await Task.sleep(nanoseconds: 250_000_000)
    }

    func verifyTwoFactorCode(_ code: String) async throws -> AuthTokens {
        try await Task.sleep(nanoseconds: 300_000_000)
        // Accept 123456 for predictable UI testing.
        guard code == "123456" else { throw AuthUIError.invalidTwoFactorCode }
        return AuthTokens(
            accessToken: "mock-access-token",
            refreshToken: "mock-refresh-token",
            issuedAt: Date()
        )
    }
}

