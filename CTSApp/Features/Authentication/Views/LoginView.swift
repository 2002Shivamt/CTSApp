import SwiftUI

struct LoginView: View {
    @Environment(\.openURL) private var openURL
    @StateObject var viewModel: LoginViewModel

    let onLoginSucceeded: () -> Void
    let onGoToSignup: () -> Void

    @State private var showError = false

    var body: some View {
        ThemedScreen {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header

                    VStack(spacing: 14) {
                        AuthTextField(
                            title: "Email",
                            text: $viewModel.username,
                            keyboardType: .emailAddress
                        )

                        AuthTextField(
                            title: "Password",
                            text: $viewModel.password,
                            isSecure: true
                        )
                    }

                    HStack {
                        Button {
                            viewModel.toggleRememberMe()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: viewModel.rememberMe ? "checkmark.square.fill" : "square")
                                Text("Remember me")
                            }
                        }
                        .buttonStyle(.plain)

                        Spacer()

                        Button("Forgot password?") {
                            openURL(AppConfig.passwordResetURL)
                        }
                        .font(.subheadline)
                    }
                    .foregroundStyle(AppTheme.current.textSecondary)

                    PrimaryCTAButton(title: "Log in", isLoading: viewModel.isSubmitting) {
                        Task {
                            do {
                                try await viewModel.submit()
                                onLoginSucceeded()
                            } catch {
                                viewModel.errorMessage = (error as? LocalizedError)?.errorDescription ?? "Something went wrong."
                                showError = true
                            }
                        }
                    }

                    divider

                    VStack(spacing: 10) {
                        SocialAuthButton(provider: .apple) {
                            Task {
                                do {
                                    try await viewModel.loginWithApple()
                                    onLoginSucceeded()
                                } catch {
                                    viewModel.errorMessage = (error as? LocalizedError)?.errorDescription ?? "Something went wrong."
                                    showError = true
                                }
                            }
                        }

                        SocialAuthButton(provider: .google) {
                            Task {
                                do {
                                    try await viewModel.loginWithGoogle()
                                    onLoginSucceeded()
                                } catch {
                                    viewModel.errorMessage = (error as? LocalizedError)?.errorDescription ?? "Something went wrong."
                                    showError = true
                                }
                            }
                        }
                    }

                    footer
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
        }
        .navigationTitle("")
        .navigationBarHidden(true)
        .alert("Can’t log in", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "Something went wrong.")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Welcome back")
                .font(.largeTitle.weight(.semibold))
                .foregroundStyle(AppTheme.current.textPrimary)

            Text("Log in to continue.")
                .foregroundStyle(AppTheme.current.textSecondary)
        }
        .padding(.top, 8)
    }

    private var divider: some View {
        HStack(spacing: 12) {
            Rectangle().frame(height: 1).foregroundStyle(AppTheme.current.borderSubtle)
            Text("or").font(.footnote).foregroundStyle(AppTheme.current.textMuted)
            Rectangle().frame(height: 1).foregroundStyle(AppTheme.current.borderSubtle)
        }
        .padding(.vertical, 6)
    }

    private var footer: some View {
        HStack(spacing: 6) {
            Text("New here?")
                .foregroundStyle(AppTheme.current.textSecondary)
            Button("Create an account") { onGoToSignup() }
                .fontWeight(.semibold)
                .foregroundStyle(AppTheme.current.brandSecondary)
        }
        .font(.subheadline)
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.top, 8)
    }
}

