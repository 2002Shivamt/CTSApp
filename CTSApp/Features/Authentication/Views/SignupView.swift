import SwiftUI

struct SignupView: View {
    @StateObject var viewModel: SignupViewModel
    let onSignupSucceeded: () -> Void
    let onGoToLogin: () -> Void

    @State private var showAlert = false
    @State private var showRequirementsModal = false
    @State private var isPasswordVisible = false

    var body: some View {
        ThemedScreen {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header

                    VStack(spacing: 14) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Your Name")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(AppTheme.current.textSecondary)

                            HStack(alignment: .top, spacing: 12) {
                                AuthTextField(
                                    title: "First Name",
                                    text: $viewModel.firstName
                                )

                                AuthTextField(
                                    title: "Last Name",
                                    text: $viewModel.lastName
                                )
                            }
                        }

                        MobileNumberField(
                            selectedCountryCode: $viewModel.selectedCountryCode,
                            mobileNumber: $viewModel.mobileNumber
                        )

                        AuthTextField(
                            title: "Email",
                            text: $viewModel.username,
                            keyboardType: .emailAddress
                        )

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Password")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(AppTheme.current.textSecondary)

                            HStack(spacing: 10) {
                                Group {
                                    if isPasswordVisible {
                                        TextField("Password", text: $viewModel.password)
                                    } else {
                                        SecureField("Password", text: $viewModel.password)
                                    }
                                }
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .foregroundStyle(AppTheme.current.textPrimary)

                                Button {
                                    showRequirementsModal = true
                                } label: {
                                    Image(systemName: "info.circle")
                                        .imageScale(.medium)
                                        .foregroundStyle(AppTheme.current.textSecondary)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Show account requirements")

                                Button {
                                    isPasswordVisible.toggle()
                                } label: {
                                    Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                                        .imageScale(.medium)
                                        .foregroundStyle(AppTheme.current.textSecondary)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(isPasswordVisible ? "Hide password" : "Show password")
                            }
                            .padding(12)
                            .background(AppTheme.current.surfacePrimary, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .strokeBorder(AppTheme.current.borderSubtle, lineWidth: 1)
                            )
                        }
                    }

                    PrimaryCTAButton(title: "Create account", isLoading: viewModel.isSubmitting) {
                        Task {
                            await viewModel.submit()
                            if viewModel.shouldRedirectToLogin {
                                showAlert = true
                            } else if viewModel.errorMessage == nil {
                                onSignupSucceeded()
                            } else {
                                showAlert = true
                            }
                        }
                    }
                    .disabled(!viewModel.canSubmit)

                    divider

                    VStack(spacing: 10) {
                        SocialAuthButton(provider: .apple) {
                            Task {
                                do {
                                    try await viewModel.signupWithApple()
                                    onSignupSucceeded()
                                } catch {
                                    viewModel.errorMessage = (error as? LocalizedError)?.errorDescription ?? "Something went wrong."
                                    showAlert = true
                                }
                            }
                        }

                        SocialAuthButton(provider: .google) {
                            Task {
                                do {
                                    try await viewModel.signupWithGoogle()
                                    onSignupSucceeded()
                                } catch {
                                    viewModel.errorMessage = (error as? LocalizedError)?.errorDescription ?? "Something went wrong."
                                    showAlert = true
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
        .sheet(isPresented: $showRequirementsModal) {
            NavigationStack {
                ScrollView {
                    ValidationCueCard(viewModel: viewModel)
                        .padding(20)
                }
                .navigationTitle("Account requirements")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") { showRequirementsModal = false }
                    }
                }
            }
            .presentationDetents([.fraction(0.45), .medium])
        }
        .alert("Can’t create account", isPresented: $showAlert) {
            if viewModel.shouldRedirectToLogin {
                Button("Go to Log in") { onGoToLogin() }
                Button("Cancel", role: .cancel) {}
            } else {
                Button("OK", role: .cancel) {}
            }
        } message: {
            Text(viewModel.errorMessage ?? "Something went wrong.")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Create your account")
                .font(.largeTitle.weight(.semibold))
                .foregroundStyle(AppTheme.current.textPrimary)

            Text("Sign up to start.")
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
            Text("Already have an account?")
                .foregroundStyle(AppTheme.current.textSecondary)
            Button("Log in") { onGoToLogin() }
                .fontWeight(.semibold)
                .foregroundStyle(AppTheme.current.brandSecondary)
        }
        .font(.subheadline)
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.top, 8)
    }
}

private struct ValidationCueCard: View {
    @ObservedObject var viewModel: SignupViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Account requirements")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(AppTheme.current.textPrimary)
                Spacer()
                Text("\(viewModel.satisfiedTotalCount)/\(viewModel.totalRequirementCount)")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(AppTheme.current.textSecondary)
            }

            ValidationItemRow(
                title: "Valid email format",
                isSatisfied: viewModel.isEmailValid
            )

            ForEach(viewModel.passwordRequirements) { requirement in
                ValidationItemRow(
                    title: requirement.title,
                    isSatisfied: requirement.isSatisfied
                )
            }
        }
        .padding(12)
        .background(AppTheme.current.surfacePrimary, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(AppTheme.current.borderSubtle, lineWidth: 1)
        )
    }
}

private struct ValidationItemRow: View {
    let title: String
    let isSatisfied: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: isSatisfied ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isSatisfied ? .green : AppTheme.current.textSecondary)
            Text(title)
                .font(.footnote)
                .foregroundStyle(AppTheme.current.textSecondary)
            Spacer()
        }
    }
}

private struct MobileNumberField: View {
    @Binding var selectedCountryCode: CountryCodeOption
    @Binding var mobileNumber: String
    @State private var showCountryPicker = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Mobile Number")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(AppTheme.current.textSecondary)

            HStack(spacing: 10) {
                Button {
                    showCountryPicker = true
                } label: {
                    HStack(spacing: 4) {
                        Text(selectedCountryCode.flag)
                        Text(selectedCountryCode.dialCode)
                            .font(.subheadline.weight(.semibold))
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundStyle(AppTheme.current.textSecondary)
                    }
                    .foregroundStyle(AppTheme.current.textPrimary)
                }

                Rectangle()
                    .fill(.quaternary)
                    .frame(width: 1, height: 22)

                TextField("Phone number", text: $mobileNumber)
                    .keyboardType(.phonePad)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .foregroundStyle(AppTheme.current.textPrimary)
            }
            .padding(12)
            .background(AppTheme.current.surfacePrimary, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(AppTheme.current.borderSubtle, lineWidth: 1)
            )
        }
        .sheet(isPresented: $showCountryPicker) {
            CountryCodePickerSheet(
                selectedCountryCode: $selectedCountryCode
            )
        }
    }
}

private struct CountryCodePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedCountryCode: CountryCodeOption
    @State private var searchText = ""

    private var filteredCountries: [CountryCodeOption] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return CountryCodeOption.all }

        return CountryCodeOption.all.filter { option in
            option.name.lowercased().contains(query)
                || option.dialCode.lowercased().contains(query)
                || option.id.lowercased().contains(query)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(AppTheme.current.textSecondary)
                    TextField("Search country or code", text: $searchText)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .foregroundStyle(AppTheme.current.textPrimary)
                }
                .padding(12)
                .background(AppTheme.current.surfacePrimary, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .padding(.horizontal, 16)
                .padding(.top, 10)

                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(filteredCountries) { option in
                            Button {
                                selectedCountryCode = option
                                dismiss()
                            } label: {
                                CountryCodeRow(
                                    option: option,
                                    isSelected: option == selectedCountryCode
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
                .scrollIndicators(.visible)
                .overlay(alignment: .trailing) {
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(AppTheme.current.textSecondary)
                        .padding(.trailing, 8)
                        .padding(.vertical, 6)
                        .background(AppTheme.current.surfacePrimary, in: Capsule())
                        .padding(.trailing, 6)
                        .allowsHitTesting(false)
                }
            }
            .navigationTitle("Select Country")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

private struct CountryCodeRow: View {
    let option: CountryCodeOption
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 10) {
            Text(option.flag)
            Text(option.name)
                .font(.body)
                .foregroundStyle(AppTheme.current.textPrimary)
            Spacer()
            Text(option.dialCode)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.current.textSecondary)
            if isSelected {
                Image(systemName: "checkmark")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.green)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(isSelected ? Color.secondary.opacity(0.12) : Color.clear)
        )
    }
}

