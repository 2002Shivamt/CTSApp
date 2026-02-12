import Foundation
internal import Combine

@MainActor
final class AuthFlowViewModel: ObservableObject {
    enum Screen: Hashable {
        case signup
        case login
        case twoFactor(method: TwoFactorMethod)
        case twoFactorCode(method: TwoFactorMethod)
    }

    @Published var path: [Screen] = []
    @Published var current: Screen = .signup

    func showSignup() { current = .signup; path = [] }
    func showLogin() { current = .login; path = [] }

    func pushTwoFactorMethodPicker() {
        path.append(.twoFactor(method: .email))
    }

    func pushTwoFactorCode(method: TwoFactorMethod) {
        // Replace the picker node with "selected method" and then code entry.
        if let idx = path.lastIndex(where: {
            if case .twoFactor = $0 { true } else { false }
        }) {
            path[idx] = .twoFactor(method: method)
        } else {
            path.append(.twoFactor(method: method))
        }
        path.append(.twoFactorCode(method: method))
    }

    func popToRoot() { path = [] }
}

@MainActor
final class LoginViewModel: ObservableObject {
    @Published var username: String
    @Published var password: String = ""
    @Published var rememberMe: Bool = false

    @Published var isSubmitting: Bool = false
    @Published var errorMessage: String?

    private let auth: AuthServicing
    private let analytics: AnalyticsTracking
    private var preferences: PreferencesStoring

    init(auth: AuthServicing, analytics: AnalyticsTracking, preferences: PreferencesStoring) {
        self.auth = auth
        self.analytics = analytics
        self.preferences = preferences
        self.username = preferences.rememberedUsername ?? ""
        self.rememberMe = preferences.rememberedUsername != nil
    }

    func toggleRememberMe() {
        rememberMe.toggle()
        analytics.track(AuthAnalytics.loginRememberCheck)
        if !rememberMe {
            preferences.rememberedUsername = nil
        }
    }

    func submit() async throws {
        errorMessage = nil
        guard ValidationRules.isValidEmail(username) else {
            throw AuthUIError.generic("Enter a valid email address.")
        }
        isSubmitting = true
        defer { isSubmitting = false }

        analytics.track(AuthAnalytics.loginSubmit)
        try await auth.login(username: username, password: password)
        if rememberMe {
            preferences.rememberedUsername = username
        }
    }

    func loginWithApple() async throws {
        errorMessage = nil
        isSubmitting = true
        defer { isSubmitting = false }

        analytics.track(AuthAnalytics.loginApple)
        try await auth.login(with: .apple)
    }

    func loginWithGoogle() async throws {
        errorMessage = nil
        isSubmitting = true
        defer { isSubmitting = false }

        analytics.track(AuthAnalytics.loginGoogle)
        try await auth.login(with: .google)
    }
}

@MainActor
final class SignupViewModel: ObservableObject {
    @Published var firstName: String = ""
    @Published var lastName: String = ""
    @Published var selectedCountryCode: CountryCodeOption = .india
    @Published var mobileNumber: String = ""

    @Published var username: String = ""
    @Published var password: String = ""

    @Published var isSubmitting: Bool = false
    @Published var errorMessage: String?
    @Published var shouldRedirectToLogin: Bool = false

    private let auth: AuthServicing

    init(auth: AuthServicing) {
        self.auth = auth
    }

    var isEmailValid: Bool {
        ValidationRules.isValidEmail(username)
    }

    var passwordRequirements: [PasswordRequirement] {
        [
            PasswordRequirement(
                title: "At least 8 characters",
                isSatisfied: password.count >= 8
            ),
            PasswordRequirement(
                title: "One uppercase letter",
                isSatisfied: ValidationRules.containsUppercase(password)
            ),
            PasswordRequirement(
                title: "One lowercase letter",
                isSatisfied: ValidationRules.containsLowercase(password)
            ),
            PasswordRequirement(
                title: "One digit",
                isSatisfied: ValidationRules.containsDigit(password)
            ),
            PasswordRequirement(
                title: "One special character",
                isSatisfied: ValidationRules.containsSpecialCharacter(password)
            )
        ]
    }

    var satisfiedRequirementCount: Int {
        passwordRequirements.filter(\.isSatisfied).count
    }

    var totalRequirementCount: Int {
        passwordRequirements.count + 1 // +1 for email validity
    }

    var satisfiedTotalCount: Int {
        satisfiedRequirementCount + (isEmailValid ? 1 : 0)
    }

    var canSubmit: Bool {
        isEmailValid && passwordRequirements.allSatisfy(\.isSatisfied)
    }

    func submit() async {
        errorMessage = nil
        shouldRedirectToLogin = false
        guard canSubmit else {
            errorMessage = "Please satisfy all email and password requirements."
            return
        }
        isSubmitting = true
        defer { isSubmitting = false }

        do {
            try await auth.signup(username: username, password: password)
        } catch let e as AuthUIError where e == .accountAlreadyExists {
            errorMessage = e.localizedDescription
            shouldRedirectToLogin = true
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "Something went wrong."
        }
    }

    func signupWithApple() async throws { try await auth.signup(with: .apple) }
    func signupWithGoogle() async throws { try await auth.signup(with: .google) }
}

@MainActor
final class TwoFactorViewModel: ObservableObject {
    @Published var method: TwoFactorMethod = .email
    @Published var code: String = ""

    @Published var isSubmitting: Bool = false
    @Published var errorMessage: String?

    private let auth: AuthServicing
    private let analytics: AnalyticsTracking

    init(auth: AuthServicing, analytics: AnalyticsTracking) {
        self.auth = auth
        self.analytics = analytics
    }

    func sendCode() async throws {
        try await auth.sendTwoFactorCode(method: method)
    }

    func resend() async throws {
        analytics.track(AuthAnalytics.tfaResend)
        try await auth.sendTwoFactorCode(method: method)
    }

    func verify() async throws -> AuthTokens {
        errorMessage = nil
        isSubmitting = true
        defer { isSubmitting = false }

        analytics.track(AuthAnalytics.tfaSubmit)
        return try await auth.verifyTwoFactorCode(code)
    }
}

struct PasswordRequirement: Identifiable {
    let id = UUID()
    let title: String
    let isSatisfied: Bool
}

struct CountryCodeOption: Identifiable, Hashable {
    let id: String
    let name: String
    let dialCode: String

    var flag: String {
        id
            .unicodeScalars
            .compactMap { UnicodeScalar(127397 + $0.value) }
            .map(String.init)
            .joined()
    }

    var label: String {
        "\(flag) \(dialCode) \(name)"
    }

    static let india = CountryCodeOption(id: "IN", name: "India", dialCode: "+91")

    static let all: [CountryCodeOption] = [
        CountryCodeOption(id: "AF", name: "Afghanistan", dialCode: "+93"),
        CountryCodeOption(id: "AL", name: "Albania", dialCode: "+355"),
        CountryCodeOption(id: "DZ", name: "Algeria", dialCode: "+213"),
        CountryCodeOption(id: "AS", name: "American Samoa", dialCode: "+1-684"),
        CountryCodeOption(id: "AD", name: "Andorra", dialCode: "+376"),
        CountryCodeOption(id: "AO", name: "Angola", dialCode: "+244"),
        CountryCodeOption(id: "AI", name: "Anguilla", dialCode: "+1-264"),
        CountryCodeOption(id: "AG", name: "Antigua and Barbuda", dialCode: "+1-268"),
        CountryCodeOption(id: "AR", name: "Argentina", dialCode: "+54"),
        CountryCodeOption(id: "AM", name: "Armenia", dialCode: "+374"),
        CountryCodeOption(id: "AW", name: "Aruba", dialCode: "+297"),
        CountryCodeOption(id: "AU", name: "Australia", dialCode: "+61"),
        CountryCodeOption(id: "AT", name: "Austria", dialCode: "+43"),
        CountryCodeOption(id: "AZ", name: "Azerbaijan", dialCode: "+994"),
        CountryCodeOption(id: "BS", name: "Bahamas", dialCode: "+1-242"),
        CountryCodeOption(id: "BH", name: "Bahrain", dialCode: "+973"),
        CountryCodeOption(id: "BD", name: "Bangladesh", dialCode: "+880"),
        CountryCodeOption(id: "BB", name: "Barbados", dialCode: "+1-246"),
        CountryCodeOption(id: "BY", name: "Belarus", dialCode: "+375"),
        CountryCodeOption(id: "BE", name: "Belgium", dialCode: "+32"),
        CountryCodeOption(id: "BZ", name: "Belize", dialCode: "+501"),
        CountryCodeOption(id: "BJ", name: "Benin", dialCode: "+229"),
        CountryCodeOption(id: "BM", name: "Bermuda", dialCode: "+1-441"),
        CountryCodeOption(id: "BT", name: "Bhutan", dialCode: "+975"),
        CountryCodeOption(id: "BO", name: "Bolivia", dialCode: "+591"),
        CountryCodeOption(id: "BA", name: "Bosnia and Herzegovina", dialCode: "+387"),
        CountryCodeOption(id: "BW", name: "Botswana", dialCode: "+267"),
        CountryCodeOption(id: "BR", name: "Brazil", dialCode: "+55"),
        CountryCodeOption(id: "VG", name: "British Virgin Islands", dialCode: "+1-284"),
        CountryCodeOption(id: "BN", name: "Brunei", dialCode: "+673"),
        CountryCodeOption(id: "BG", name: "Bulgaria", dialCode: "+359"),
        CountryCodeOption(id: "BF", name: "Burkina Faso", dialCode: "+226"),
        CountryCodeOption(id: "BI", name: "Burundi", dialCode: "+257"),
        CountryCodeOption(id: "KH", name: "Cambodia", dialCode: "+855"),
        CountryCodeOption(id: "CM", name: "Cameroon", dialCode: "+237"),
        CountryCodeOption(id: "CA", name: "Canada", dialCode: "+1"),
        CountryCodeOption(id: "CV", name: "Cape Verde", dialCode: "+238"),
        CountryCodeOption(id: "KY", name: "Cayman Islands", dialCode: "+1-345"),
        CountryCodeOption(id: "CF", name: "Central African Republic", dialCode: "+236"),
        CountryCodeOption(id: "TD", name: "Chad", dialCode: "+235"),
        CountryCodeOption(id: "CL", name: "Chile", dialCode: "+56"),
        CountryCodeOption(id: "CN", name: "China", dialCode: "+86"),
        CountryCodeOption(id: "CO", name: "Colombia", dialCode: "+57"),
        CountryCodeOption(id: "KM", name: "Comoros", dialCode: "+269"),
        CountryCodeOption(id: "CG", name: "Congo", dialCode: "+242"),
        CountryCodeOption(id: "CD", name: "Congo (DRC)", dialCode: "+243"),
        CountryCodeOption(id: "CK", name: "Cook Islands", dialCode: "+682"),
        CountryCodeOption(id: "CR", name: "Costa Rica", dialCode: "+506"),
        CountryCodeOption(id: "HR", name: "Croatia", dialCode: "+385"),
        CountryCodeOption(id: "CU", name: "Cuba", dialCode: "+53"),
        CountryCodeOption(id: "CY", name: "Cyprus", dialCode: "+357"),
        CountryCodeOption(id: "CZ", name: "Czech Republic", dialCode: "+420"),
        CountryCodeOption(id: "DK", name: "Denmark", dialCode: "+45"),
        CountryCodeOption(id: "DJ", name: "Djibouti", dialCode: "+253"),
        CountryCodeOption(id: "DM", name: "Dominica", dialCode: "+1-767"),
        CountryCodeOption(id: "DO", name: "Dominican Republic", dialCode: "+1-809"),
        CountryCodeOption(id: "EC", name: "Ecuador", dialCode: "+593"),
        CountryCodeOption(id: "EG", name: "Egypt", dialCode: "+20"),
        CountryCodeOption(id: "SV", name: "El Salvador", dialCode: "+503"),
        CountryCodeOption(id: "GQ", name: "Equatorial Guinea", dialCode: "+240"),
        CountryCodeOption(id: "ER", name: "Eritrea", dialCode: "+291"),
        CountryCodeOption(id: "EE", name: "Estonia", dialCode: "+372"),
        CountryCodeOption(id: "ET", name: "Ethiopia", dialCode: "+251"),
        CountryCodeOption(id: "FK", name: "Falkland Islands", dialCode: "+500"),
        CountryCodeOption(id: "FO", name: "Faroe Islands", dialCode: "+298"),
        CountryCodeOption(id: "FJ", name: "Fiji", dialCode: "+679"),
        CountryCodeOption(id: "FI", name: "Finland", dialCode: "+358"),
        CountryCodeOption(id: "FR", name: "France", dialCode: "+33"),
        CountryCodeOption(id: "GF", name: "French Guiana", dialCode: "+594"),
        CountryCodeOption(id: "PF", name: "French Polynesia", dialCode: "+689"),
        CountryCodeOption(id: "GA", name: "Gabon", dialCode: "+241"),
        CountryCodeOption(id: "GM", name: "Gambia", dialCode: "+220"),
        CountryCodeOption(id: "GE", name: "Georgia", dialCode: "+995"),
        CountryCodeOption(id: "DE", name: "Germany", dialCode: "+49"),
        CountryCodeOption(id: "GH", name: "Ghana", dialCode: "+233"),
        CountryCodeOption(id: "GI", name: "Gibraltar", dialCode: "+350"),
        CountryCodeOption(id: "GR", name: "Greece", dialCode: "+30"),
        CountryCodeOption(id: "GL", name: "Greenland", dialCode: "+299"),
        CountryCodeOption(id: "GD", name: "Grenada", dialCode: "+1-473"),
        CountryCodeOption(id: "GP", name: "Guadeloupe", dialCode: "+590"),
        CountryCodeOption(id: "GU", name: "Guam", dialCode: "+1-671"),
        CountryCodeOption(id: "GT", name: "Guatemala", dialCode: "+502"),
        CountryCodeOption(id: "GN", name: "Guinea", dialCode: "+224"),
        CountryCodeOption(id: "GW", name: "Guinea-Bissau", dialCode: "+245"),
        CountryCodeOption(id: "GY", name: "Guyana", dialCode: "+592"),
        CountryCodeOption(id: "HT", name: "Haiti", dialCode: "+509"),
        CountryCodeOption(id: "HN", name: "Honduras", dialCode: "+504"),
        CountryCodeOption(id: "HK", name: "Hong Kong", dialCode: "+852"),
        CountryCodeOption(id: "HU", name: "Hungary", dialCode: "+36"),
        CountryCodeOption(id: "IS", name: "Iceland", dialCode: "+354"),
        CountryCodeOption(id: "IN", name: "India", dialCode: "+91"),
        CountryCodeOption(id: "ID", name: "Indonesia", dialCode: "+62"),
        CountryCodeOption(id: "IR", name: "Iran", dialCode: "+98"),
        CountryCodeOption(id: "IQ", name: "Iraq", dialCode: "+964"),
        CountryCodeOption(id: "IE", name: "Ireland", dialCode: "+353"),
        CountryCodeOption(id: "IL", name: "Israel", dialCode: "+972"),
        CountryCodeOption(id: "IT", name: "Italy", dialCode: "+39"),
        CountryCodeOption(id: "CI", name: "Ivory Coast", dialCode: "+225"),
        CountryCodeOption(id: "JM", name: "Jamaica", dialCode: "+1-876"),
        CountryCodeOption(id: "JP", name: "Japan", dialCode: "+81"),
        CountryCodeOption(id: "JO", name: "Jordan", dialCode: "+962"),
        CountryCodeOption(id: "KZ", name: "Kazakhstan", dialCode: "+7"),
        CountryCodeOption(id: "KE", name: "Kenya", dialCode: "+254"),
        CountryCodeOption(id: "KI", name: "Kiribati", dialCode: "+686"),
        CountryCodeOption(id: "KW", name: "Kuwait", dialCode: "+965"),
        CountryCodeOption(id: "KG", name: "Kyrgyzstan", dialCode: "+996"),
        CountryCodeOption(id: "LA", name: "Laos", dialCode: "+856"),
        CountryCodeOption(id: "LV", name: "Latvia", dialCode: "+371"),
        CountryCodeOption(id: "LB", name: "Lebanon", dialCode: "+961"),
        CountryCodeOption(id: "LS", name: "Lesotho", dialCode: "+266"),
        CountryCodeOption(id: "LR", name: "Liberia", dialCode: "+231"),
        CountryCodeOption(id: "LY", name: "Libya", dialCode: "+218"),
        CountryCodeOption(id: "LI", name: "Liechtenstein", dialCode: "+423"),
        CountryCodeOption(id: "LT", name: "Lithuania", dialCode: "+370"),
        CountryCodeOption(id: "LU", name: "Luxembourg", dialCode: "+352"),
        CountryCodeOption(id: "MO", name: "Macau", dialCode: "+853"),
        CountryCodeOption(id: "MK", name: "North Macedonia", dialCode: "+389"),
        CountryCodeOption(id: "MG", name: "Madagascar", dialCode: "+261"),
        CountryCodeOption(id: "MW", name: "Malawi", dialCode: "+265"),
        CountryCodeOption(id: "MY", name: "Malaysia", dialCode: "+60"),
        CountryCodeOption(id: "MV", name: "Maldives", dialCode: "+960"),
        CountryCodeOption(id: "ML", name: "Mali", dialCode: "+223"),
        CountryCodeOption(id: "MT", name: "Malta", dialCode: "+356"),
        CountryCodeOption(id: "MH", name: "Marshall Islands", dialCode: "+692"),
        CountryCodeOption(id: "MQ", name: "Martinique", dialCode: "+596"),
        CountryCodeOption(id: "MR", name: "Mauritania", dialCode: "+222"),
        CountryCodeOption(id: "MU", name: "Mauritius", dialCode: "+230"),
        CountryCodeOption(id: "YT", name: "Mayotte", dialCode: "+262"),
        CountryCodeOption(id: "MX", name: "Mexico", dialCode: "+52"),
        CountryCodeOption(id: "FM", name: "Micronesia", dialCode: "+691"),
        CountryCodeOption(id: "MD", name: "Moldova", dialCode: "+373"),
        CountryCodeOption(id: "MC", name: "Monaco", dialCode: "+377"),
        CountryCodeOption(id: "MN", name: "Mongolia", dialCode: "+976"),
        CountryCodeOption(id: "ME", name: "Montenegro", dialCode: "+382"),
        CountryCodeOption(id: "MS", name: "Montserrat", dialCode: "+1-664"),
        CountryCodeOption(id: "MA", name: "Morocco", dialCode: "+212"),
        CountryCodeOption(id: "MZ", name: "Mozambique", dialCode: "+258"),
        CountryCodeOption(id: "MM", name: "Myanmar", dialCode: "+95"),
        CountryCodeOption(id: "NA", name: "Namibia", dialCode: "+264"),
        CountryCodeOption(id: "NR", name: "Nauru", dialCode: "+674"),
        CountryCodeOption(id: "NP", name: "Nepal", dialCode: "+977"),
        CountryCodeOption(id: "NL", name: "Netherlands", dialCode: "+31"),
        CountryCodeOption(id: "NC", name: "New Caledonia", dialCode: "+687"),
        CountryCodeOption(id: "NZ", name: "New Zealand", dialCode: "+64"),
        CountryCodeOption(id: "NI", name: "Nicaragua", dialCode: "+505"),
        CountryCodeOption(id: "NE", name: "Niger", dialCode: "+227"),
        CountryCodeOption(id: "NG", name: "Nigeria", dialCode: "+234"),
        CountryCodeOption(id: "NU", name: "Niue", dialCode: "+683"),
        CountryCodeOption(id: "KP", name: "North Korea", dialCode: "+850"),
        CountryCodeOption(id: "MP", name: "Northern Mariana Islands", dialCode: "+1-670"),
        CountryCodeOption(id: "NO", name: "Norway", dialCode: "+47"),
        CountryCodeOption(id: "OM", name: "Oman", dialCode: "+968"),
        CountryCodeOption(id: "PK", name: "Pakistan", dialCode: "+92"),
        CountryCodeOption(id: "PW", name: "Palau", dialCode: "+680"),
        CountryCodeOption(id: "PS", name: "Palestine", dialCode: "+970"),
        CountryCodeOption(id: "PA", name: "Panama", dialCode: "+507"),
        CountryCodeOption(id: "PG", name: "Papua New Guinea", dialCode: "+675"),
        CountryCodeOption(id: "PY", name: "Paraguay", dialCode: "+595"),
        CountryCodeOption(id: "PE", name: "Peru", dialCode: "+51"),
        CountryCodeOption(id: "PH", name: "Philippines", dialCode: "+63"),
        CountryCodeOption(id: "PL", name: "Poland", dialCode: "+48"),
        CountryCodeOption(id: "PT", name: "Portugal", dialCode: "+351"),
        CountryCodeOption(id: "PR", name: "Puerto Rico", dialCode: "+1-787"),
        CountryCodeOption(id: "QA", name: "Qatar", dialCode: "+974"),
        CountryCodeOption(id: "RE", name: "Reunion", dialCode: "+262"),
        CountryCodeOption(id: "RO", name: "Romania", dialCode: "+40"),
        CountryCodeOption(id: "RU", name: "Russia", dialCode: "+7"),
        CountryCodeOption(id: "RW", name: "Rwanda", dialCode: "+250"),
        CountryCodeOption(id: "WS", name: "Samoa", dialCode: "+685"),
        CountryCodeOption(id: "SM", name: "San Marino", dialCode: "+378"),
        CountryCodeOption(id: "ST", name: "Sao Tome and Principe", dialCode: "+239"),
        CountryCodeOption(id: "SA", name: "Saudi Arabia", dialCode: "+966"),
        CountryCodeOption(id: "SN", name: "Senegal", dialCode: "+221"),
        CountryCodeOption(id: "RS", name: "Serbia", dialCode: "+381"),
        CountryCodeOption(id: "SC", name: "Seychelles", dialCode: "+248"),
        CountryCodeOption(id: "SL", name: "Sierra Leone", dialCode: "+232"),
        CountryCodeOption(id: "SG", name: "Singapore", dialCode: "+65"),
        CountryCodeOption(id: "SK", name: "Slovakia", dialCode: "+421"),
        CountryCodeOption(id: "SI", name: "Slovenia", dialCode: "+386"),
        CountryCodeOption(id: "SB", name: "Solomon Islands", dialCode: "+677"),
        CountryCodeOption(id: "SO", name: "Somalia", dialCode: "+252"),
        CountryCodeOption(id: "ZA", name: "South Africa", dialCode: "+27"),
        CountryCodeOption(id: "KR", name: "South Korea", dialCode: "+82"),
        CountryCodeOption(id: "SS", name: "South Sudan", dialCode: "+211"),
        CountryCodeOption(id: "ES", name: "Spain", dialCode: "+34"),
        CountryCodeOption(id: "LK", name: "Sri Lanka", dialCode: "+94"),
        CountryCodeOption(id: "KN", name: "Saint Kitts and Nevis", dialCode: "+1-869"),
        CountryCodeOption(id: "LC", name: "Saint Lucia", dialCode: "+1-758"),
        CountryCodeOption(id: "VC", name: "Saint Vincent and the Grenadines", dialCode: "+1-784"),
        CountryCodeOption(id: "SD", name: "Sudan", dialCode: "+249"),
        CountryCodeOption(id: "SR", name: "Suriname", dialCode: "+597"),
        CountryCodeOption(id: "SZ", name: "Eswatini", dialCode: "+268"),
        CountryCodeOption(id: "SE", name: "Sweden", dialCode: "+46"),
        CountryCodeOption(id: "CH", name: "Switzerland", dialCode: "+41"),
        CountryCodeOption(id: "SY", name: "Syria", dialCode: "+963"),
        CountryCodeOption(id: "TW", name: "Taiwan", dialCode: "+886"),
        CountryCodeOption(id: "TJ", name: "Tajikistan", dialCode: "+992"),
        CountryCodeOption(id: "TZ", name: "Tanzania", dialCode: "+255"),
        CountryCodeOption(id: "TH", name: "Thailand", dialCode: "+66"),
        CountryCodeOption(id: "TL", name: "Timor-Leste", dialCode: "+670"),
        CountryCodeOption(id: "TG", name: "Togo", dialCode: "+228"),
        CountryCodeOption(id: "TO", name: "Tonga", dialCode: "+676"),
        CountryCodeOption(id: "TT", name: "Trinidad and Tobago", dialCode: "+1-868"),
        CountryCodeOption(id: "TN", name: "Tunisia", dialCode: "+216"),
        CountryCodeOption(id: "TR", name: "Turkey", dialCode: "+90"),
        CountryCodeOption(id: "TM", name: "Turkmenistan", dialCode: "+993"),
        CountryCodeOption(id: "TC", name: "Turks and Caicos Islands", dialCode: "+1-649"),
        CountryCodeOption(id: "TV", name: "Tuvalu", dialCode: "+688"),
        CountryCodeOption(id: "UG", name: "Uganda", dialCode: "+256"),
        CountryCodeOption(id: "UA", name: "Ukraine", dialCode: "+380"),
        CountryCodeOption(id: "AE", name: "United Arab Emirates", dialCode: "+971"),
        CountryCodeOption(id: "GB", name: "United Kingdom", dialCode: "+44"),
        CountryCodeOption(id: "US", name: "United States", dialCode: "+1"),
        CountryCodeOption(id: "UY", name: "Uruguay", dialCode: "+598"),
        CountryCodeOption(id: "UZ", name: "Uzbekistan", dialCode: "+998"),
        CountryCodeOption(id: "VU", name: "Vanuatu", dialCode: "+678"),
        CountryCodeOption(id: "VA", name: "Vatican City", dialCode: "+379"),
        CountryCodeOption(id: "VE", name: "Venezuela", dialCode: "+58"),
        CountryCodeOption(id: "VN", name: "Vietnam", dialCode: "+84"),
        CountryCodeOption(id: "VI", name: "US Virgin Islands", dialCode: "+1-340"),
        CountryCodeOption(id: "YE", name: "Yemen", dialCode: "+967"),
        CountryCodeOption(id: "ZM", name: "Zambia", dialCode: "+260"),
        CountryCodeOption(id: "ZW", name: "Zimbabwe", dialCode: "+263")
    ]
}

enum ValidationRules {
    private static let emailPattern = #"^[A-Z0-9a-z._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$"#

    static func isValidEmail(_ email: String) -> Bool {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.range(of: emailPattern, options: .regularExpression) != nil
    }

    static func containsUppercase(_ value: String) -> Bool {
        value.range(of: "[A-Z]", options: .regularExpression) != nil
    }

    static func containsLowercase(_ value: String) -> Bool {
        value.range(of: "[a-z]", options: .regularExpression) != nil
    }

    static func containsDigit(_ value: String) -> Bool {
        value.range(of: "[0-9]", options: .regularExpression) != nil
    }

    static func containsSpecialCharacter(_ value: String) -> Bool {
        value.range(of: #"[^A-Za-z0-9]"#, options: .regularExpression) != nil
    }
}

