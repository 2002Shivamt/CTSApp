import Foundation

/// Centralized configuration for environment-specific values.
/// Keep secrets out of here; use runtime config / secure storage instead.
enum AppConfig {
    /// Base URL for the Java (Spring Boot) backend.
    ///
    /// Replace this with your env-specific host (dev/stage/prod).
    static let apiBaseURL = URL(string: "https://api.example.com")!

    /// Password reset happens on web (per PRD).
    static let passwordResetURL = URL(string: "https://example.com/password-reset")!
}

