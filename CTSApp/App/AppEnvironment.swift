import Foundation

/// App-wide dependency container.
///
/// This keeps MVVM testable (inject protocols), and gives us a clean seam for future backend integrations.
struct AppEnvironment {
    let analytics: AnalyticsTracking
    let authService: AuthServicing
    let secureStore: SecureStoring
    let preferences: PreferencesStoring
    let biometrics: BiometricAuthenticating

    /// Use for the current phase: UI-only development with mock behavior.
    static func ui() -> AppEnvironment {
        let analytics = DefaultAnalyticsTracker()
        let secureStore = InMemorySecureStore()
        let preferences = InMemoryPreferencesStore()
        let authService = MockAuthService()
        let biometrics = LocalBiometricAuthenticator()

        return AppEnvironment(
            analytics: analytics,
            authService: authService,
            secureStore: secureStore,
            preferences: preferences,
            biometrics: biometrics
        )
    }

    /// Alias for previews/tests.
    static func mock() -> AppEnvironment { ui() }
}

