import SwiftUI

struct BiometricGateView: View {
    let biometrics: BiometricAuthenticating
    let onSuccess: () -> Void
    let onFallback: () -> Void

    @State private var isAuthenticating = false

    var body: some View {
        ThemedScreen {
            VStack(spacing: 16) {
                Text("Unlock CTSApp")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(AppTheme.current.textPrimary)

                Text("Use Face ID / Touch ID to continue.")
                    .foregroundStyle(AppTheme.current.textSecondary)
                    .multilineTextAlignment(.center)

                PrimaryCTAButton(
                    title: isAuthenticating ? "Authenticating…" : "Use biometrics",
                    isLoading: isAuthenticating
                ) {
                    Task {
                        isAuthenticating = true
                        defer { isAuthenticating = false }
                        let ok = await biometrics.authenticate(reason: "Unlock CTSApp")
                        ok ? onSuccess() : onFallback()
                    }
                }
                .disabled(isAuthenticating || !biometrics.canEvaluate())

                Button("Use password instead", action: onFallback)
                    .foregroundStyle(AppTheme.current.brandSecondary)
            }
            .padding()
        }
    }
}

