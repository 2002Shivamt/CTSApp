import SwiftUI

struct AuthenticationRootView: View {
    @EnvironmentObject private var appState: AppState
    private let env: AppEnvironment

    @StateObject private var flow = AuthFlowViewModel()

    init(env: AppEnvironment) {
        self.env = env
    }

    var body: some View {
        NavigationStack(path: $flow.path) {
            Group {
                switch flow.current {
                case .signup:
                    SignupView(
                        viewModel: SignupViewModel(auth: env.authService),
                        onSignupSucceeded: {
                            flow.pushTwoFactorMethodPicker()
                        },
                        onGoToLogin: { flow.showLogin() }
                    )

                case .login:
                    LoginView(
                        viewModel: LoginViewModel(auth: env.authService, analytics: env.analytics, preferences: env.preferences),
                        onLoginSucceeded: {
                            flow.pushTwoFactorMethodPicker()
                        },
                        onGoToSignup: { flow.showSignup() }
                    )

                default:
                    EmptyView()
                }
            }
            .navigationDestination(for: AuthFlowViewModel.Screen.self) { screen in
                switch screen {
                case let .twoFactor(method):
                    TwoFactorMethodView(
                        initialMethod: method,
                        onContinue: { selectedMethod in
                            flow.pushTwoFactorCode(method: selectedMethod)
                        },
                        onBack: {
                            env.analytics.track(AuthAnalytics.tfaBack)
                            flow.popToRoot()
                        }
                    )

                case let .twoFactorCode(method):
                    TwoFactorCodeView(
                        method: method,
                        viewModel: TwoFactorViewModel(auth: env.authService, analytics: env.analytics),
                        onAuthenticated: { tokens, rememberUsername in
                            appState.completeAuthentication(tokens: tokens, rememberUsername: rememberUsername)
                        },
                        onBack: {
                            env.analytics.track(AuthAnalytics.tfaBack)
                            _ = flow.path.popLast()
                        }
                    )

                case .signup, .login:
                    EmptyView()
                }
            }
        }
    }
}

