import SwiftUI

struct TwoFactorMethodView: View {
    @State private var selected: TwoFactorMethod
    let onContinue: (TwoFactorMethod) -> Void
    let onBack: () -> Void

    init(initialMethod: TwoFactorMethod, onContinue: @escaping (TwoFactorMethod) -> Void, onBack: @escaping () -> Void) {
        _selected = State(initialValue: initialMethod)
        self.onContinue = onContinue
        self.onBack = onBack
    }

    var body: some View {
        ThemedScreen {
            VStack(alignment: .leading, spacing: 16) {
                Text("Two-factor authentication")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(AppTheme.current.textPrimary)

                Text("Choose how you’d like to receive your verification code.")
                    .foregroundStyle(AppTheme.current.textSecondary)

                VStack(spacing: 10) {
                    ForEach(TwoFactorMethod.allCases) { method in
                        Button {
                            selected = method
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: selected == method ? "largecircle.fill.circle" : "circle")
                                    .foregroundStyle(AppTheme.current.textSecondary)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(method.title)
                                        .font(.headline)
                                        .foregroundStyle(AppTheme.current.textPrimary)
                                    Text(method.detail)
                                        .font(.footnote)
                                        .foregroundStyle(AppTheme.current.textSecondary)
                                }
                                Spacer()
                            }
                            .padding(12)
                            .background(AppTheme.current.surfacePrimary, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .strokeBorder(AppTheme.current.borderSubtle, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }

                PrimaryCTAButton(title: "Continue") {
                    onContinue(selected)
                }

                Spacer()
            }
            .padding()
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Back", action: onBack)
            }
        }
    }
}

struct TwoFactorCodeView: View {
    let method: TwoFactorMethod
    @StateObject var viewModel: TwoFactorViewModel

    let onAuthenticated: (AuthTokens, String?) -> Void
    let onBack: () -> Void

    @State private var showError = false

    var body: some View {
        ThemedScreen {
            VStack(alignment: .leading, spacing: 16) {
                Text("Enter your code")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(AppTheme.current.textPrimary)

                Text("We sent a 6-digit code. (UI-only: use 123456)")
                    .foregroundStyle(AppTheme.current.textSecondary)

                AuthTextField(title: "Verification code", text: $viewModel.code, keyboardType: .numberPad)

                PrimaryCTAButton(title: "Verify", isLoading: viewModel.isSubmitting) {
                    Task {
                        do {
                            let tokens = try await viewModel.verify()
                            // Remembered username is handled on login submit; pass nil here.
                            onAuthenticated(tokens, nil)
                        } catch {
                            viewModel.errorMessage = (error as? LocalizedError)?.errorDescription ?? "Something went wrong."
                            showError = true
                        }
                    }
                }

                Button("Resend code") {
                    Task {
                        do { try await viewModel.resend() } catch {
                            viewModel.errorMessage = (error as? LocalizedError)?.errorDescription ?? "Something went wrong."
                            showError = true
                        }
                    }
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.current.brandSecondary)

                Spacer()
            }
            .padding()
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Back", action: onBack)
            }
        }
        .task {
            viewModel.method = method
            try? await viewModel.sendCode()
        }
        .alert("Can’t verify", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "Something went wrong.")
        }
    }
}

