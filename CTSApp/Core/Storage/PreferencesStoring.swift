import Foundation

protocol PreferencesStoring {
    var rememberedUsername: String? { get set }
    var isBiometricLoginEnabled: Bool { get set }
}

final class InMemoryPreferencesStore: PreferencesStoring {
    var rememberedUsername: String?
    var isBiometricLoginEnabled: Bool = false
}

final class UserDefaultsPreferencesStore: PreferencesStoring {
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    private enum Keys {
        static let rememberedUsername = "preferences.rememberedUsername"
        static let isBiometricLoginEnabled = "preferences.isBiometricLoginEnabled"
    }

    var rememberedUsername: String? {
        get { defaults.string(forKey: Keys.rememberedUsername) }
        set { defaults.set(newValue, forKey: Keys.rememberedUsername) }
    }

    var isBiometricLoginEnabled: Bool {
        get { defaults.bool(forKey: Keys.isBiometricLoginEnabled) }
        set { defaults.set(newValue, forKey: Keys.isBiometricLoginEnabled) }
    }
}

