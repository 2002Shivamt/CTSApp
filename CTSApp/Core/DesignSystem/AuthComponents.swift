import SwiftUI

struct AuthTextField: View {
    let title: String
    let text: Binding<String>
    var keyboardType: UIKeyboardType = .default
    var isSecure: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(AppTheme.current.textSecondary)

            Group {
                if isSecure {
                    SecureField(title, text: text)
                } else {
                    TextField(title, text: text)
                }
            }
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .keyboardType(keyboardType)
            .foregroundStyle(AppTheme.current.textPrimary)
            .padding(12)
            .background(AppTheme.current.surfacePrimary, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(AppTheme.current.borderSubtle, lineWidth: 1)
            )
        }
    }
}

struct PrimaryCTAButton: View {
    let title: String
    var isLoading: Bool = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Spacer()
                if isLoading {
                    ProgressView().tint(AppTheme.current.primaryButtonText)
                } else {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(AppTheme.current.primaryButtonText)
                }
                Spacer()
            }
            .padding(.vertical, 12)
            .background(
                LinearGradient(
                    colors: [AppTheme.current.brandPrimary, AppTheme.current.brandSecondary],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(AppTheme.current.borderSubtle.opacity(0.4), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
        .opacity(isLoading ? 0.85 : 1)
    }
}

struct SocialAuthButton: View {
    let provider: SocialProvider
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                logo
                    .frame(width: 22, height: 22)

                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(titleColor)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 16)
            .background(backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: 999, style: .continuous)
                    .stroke(borderColor, lineWidth: provider == .google ? 1.25 : 0)
            )
            .clipShape(RoundedRectangle(cornerRadius: 999, style: .continuous))
        }
        .buttonStyle(.plain)
        .contentShape(RoundedRectangle(cornerRadius: 999, style: .continuous))
    }

    private var title: String {
        provider == .apple ? "Continue with Apple" : "Continue with Google"
    }

    @ViewBuilder
    private var logo: some View {
        if provider == .apple {
            Image(systemName: "apple.logo")
                .resizable()
                .scaledToFit()
                .foregroundStyle(.white)
        } else {
            Image("GoogleLogo")
                .resizable()
                .scaledToFit()
        }
    }

    private var backgroundColor: Color {
        provider == .apple ? AppTheme.current.socialAppleBackground : AppTheme.current.socialGoogleBackground
    }

    private var titleColor: Color {
        provider == .apple ? AppTheme.current.socialAppleText : AppTheme.current.socialGoogleText
    }

    private var borderColor: Color {
        AppTheme.current.socialGoogleBorder
    }
}

