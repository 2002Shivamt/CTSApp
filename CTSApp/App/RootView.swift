import SwiftUI

struct RootView: View {
    @EnvironmentObject private var appState: AppState
    private let env: AppEnvironment
    @State private var showSplash = true

    init(env: AppEnvironment) {
        self.env = env
    }

    var body: some View {
        Group {
            if showSplash {
                SplashView()
                    .transition(.opacity)
            } else {
                switch appState.authGate {
                case .authenticated:
                    MainPlaceholderView(onSignOut: { appState.signOut() })

                case .biometricRequired:
                    BiometricGateView(
                        biometrics: env.biometrics,
                        onSuccess: {
                            // In a real implementation we'd refresh/validate tokens with backend.
                            // For now, just unlock the app if tokens exist.
                            if let tokens = try? env.secureStore.readTokens() {
                                appState.completeAuthentication(tokens: tokens, rememberUsername: nil)
                            } else {
                                appState.signOut()
                            }
                        },
                        onFallback: { appState.signOut() }
                    )

                case .unauthenticated:
                    AuthenticationRootView(env: env)
                }
            }
        }
        .task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            withAnimation(.easeInOut(duration: 0.25)) {
                showSplash = false
            }
        }
    }
}

struct MainPlaceholderView: View {
    let onSignOut: () -> Void

    var body: some View {
        ThemedScreen {
            NavigationStack {
                VStack(spacing: 16) {
                    Text("Authenticated")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(AppTheme.current.textPrimary)

                    Text("Replace this with your post-login experience.")
                        .foregroundStyle(AppTheme.current.textSecondary)
                        .multilineTextAlignment(.center)

                    Button("Sign out", role: .destructive, action: onSignOut)
                }
                .padding()
                .navigationTitle("CTSApp")
            }
        }
    }
}

