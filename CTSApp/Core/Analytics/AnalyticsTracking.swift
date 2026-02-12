import Foundation

protocol AnalyticsTracking {
    func track(_ event: AnalyticsEvent)
}

struct AnalyticsEvent: Equatable {
    let name: String
    var properties: [String: String] = [:]
}

/// PRD-derived auth tracking tags.
enum AuthAnalytics {
    static let loginSubmit = AnalyticsEvent(name: "Authenticate:Login_Submit_Button")
    static let loginApple = AnalyticsEvent(name: "Authenticate:Login_Apple_Button")
    static let loginGoogle = AnalyticsEvent(name: "Authenticate:Login_Google_Button")
    static let loginRememberCheck = AnalyticsEvent(name: "Authenticate:Login_Remember_Check")

    static let tfaSubmit = AnalyticsEvent(name: "Authenticate:TFA_Submit_Button")
    static let tfaResend = AnalyticsEvent(name: "Authenticate:TFA_Resend_Button")
    static let tfaBack = AnalyticsEvent(name: "Authenticate:TFA_Back_Button")
}

final class DefaultAnalyticsTracker: AnalyticsTracking {
    func track(_ event: AnalyticsEvent) {
        // UI-only phase: no-op (or hook into your analytics SDK later).
        // Intentionally left blank.
    }
}

