import Foundation

struct AuthTokens: Equatable, Codable {
    let accessToken: String
    let refreshToken: String
    let issuedAt: Date
}

enum SocialProvider: String, Codable {
    case apple
    case google
}

enum TwoFactorMethod: String, Codable, CaseIterable, Identifiable {
    case sms
    case email

    var id: String { rawValue }

    var title: String {
        switch self {
        case .sms: "Text message"
        case .email: "Email"
        }
    }

    var detail: String {
        switch self {
        case .sms: "We’ll send a code via SMS."
        case .email: "We’ll send a code to your email."
        }
    }
}

