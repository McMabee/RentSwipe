import SwiftUI

struct LoginEntryView: View {
    @EnvironmentObject private var sessionStore: PrototypeSessionStore
    @EnvironmentObject private var router: AppRouter

    enum Step {
        case choice
        case login
        case signup
    }

    private enum AuthMode {
        case login
        case signup
    }

    @State private var step: Step = .choice
    @State private var mode: AuthMode = .login

    // Login fields
    @State private var email: String = ""
    @State private var password: String = ""

    // Signup fields
    @State private var signupName: String = ""
    @State private var signupEmail: String = ""
    @State private var signupPassword: String = ""
    @State private var signupRole: AccountRole = .tenant   // tenant / landlord only

    @State private var isLoading: Bool = false
    @State private var errorMessage: String?

    let namespace: Namespace.ID

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()

                VStack(spacing: 28) {
                    Spacer(minLength: 24)

                    // Shared brand header (target for splash animation)
                    Text("RentSwipe")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .matchedGeometryEffect(id: "rentswipe-logo", in: namespace)

                    Group {
                        switch step {
                        case .choice:
                            choiceContent
                        case .login:
                            loginForm
                        case .signup:
                            signupForm
                        }
                    }
                    .animation(.easeInOut(duration: 0.3), value: step)

                    Spacer()

                    footer
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    // MARK: - Sections

    private var choiceContent: some View {
        VStack(spacing: 16) {
            Button {
                withAnimation {
                    mode = .login
                    step = .login
                    errorMessage = nil
                }
            } label: {
                Text("Log In")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .foregroundColor(.white)
            }

            Button {
                withAnimation {
                    mode = .signup
                    step = .signup
                    errorMessage = nil
                }
            } label: {
                Text("Sign Up")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.accentColor, lineWidth: 1.5)
                    )
            }
        }
    }

    private var loginForm: some View {
        VStack(alignment: .leading, spacing: 20) {
            backButton(title: "Log In")

            VStack(spacing: 14) {
                TextField("Email", text: $email)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color(.secondarySystemBackground))
                    )

                SecureField("Password", text: $password)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color(.secondarySystemBackground))
                    )

                Button(action: handleLogin) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(.circular)
                        } else {
                            Text("Continue")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .foregroundColor(.white)
                }
                .disabled(isLoading || !canSubmitLogin)

                // Quick demo logins
                VStack(spacing: 6) {
                    Text("Prototype shortcuts")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    HStack(spacing: 12) {
                        Button {
                            applyTenantDemoCredentials()
                        } label: {
                            Text("Tenant login")
                                .font(.caption)
                                .underline()
                        }

                        Button {
                            applyLandlordDemoCredentials()
                        } label: {
                            Text("Landlord login")
                                .font(.caption)
                                .underline()
                        }
                    }
                    .foregroundStyle(Color.accentColor)
                }
                .padding(.top, 4)

                if let error = errorMessage {
                    Text(error)
                        .font(.footnote)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                }
            }
        }
    }

    private var signupForm: some View {
        VStack(alignment: .leading, spacing: 20) {
            backButton(title: "Sign Up")

            // Role selection (radio-style) for signup
            VStack(alignment: .leading, spacing: 8) {
                Text("Sign up as")
                    .font(.subheadline.weight(.semibold))

                HStack(spacing: 8) {
                    signupRolePill(.tenant)
                    signupRolePill(.landlord)
                }
            }

            VStack(spacing: 14) {
                TextField("Full name", text: $signupName)
                    .textInputAutocapitalization(.words)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color(.secondarySystemBackground))
                    )

                TextField("Email", text: $signupEmail)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color(.secondarySystemBackground))
                    )

                SecureField("Password", text: $signupPassword)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color(.secondarySystemBackground))
                    )

                Button {
                    // Prototype: explain signup is not wired
                    errorMessage = "Sign up isn’t wired up in this prototype. Use one of the demo logins to explore the app."
                } label: {
                    Text("Create Account")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .foregroundColor(.white)
                }

                if let error = errorMessage {
                    Text(error)
                        .font(.footnote)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                }
            }
        }
    }

    private var footer: some View {
        VStack(spacing: 4) {
            Text("Prototype build for concept review.")
                .font(.caption)
                .foregroundStyle(.secondary)

            if step == .login || step == .choice {
                Text("Use the seeded demo accounts to jump into different roles.")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .multilineTextAlignment(.center)
    }

    // MARK: - Helpers

    private func backButton(title: String) -> some View {
        HStack {
            Button {
                withAnimation {
                    step = .choice
                    errorMessage = nil
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                    Text("Back")
                }
            }
            .buttonStyle(.plain)

            Spacer()

            Text(title)
                .font(.headline)
        }
    }

    private func signupRolePill(_ role: AccountRole) -> some View {
        // Only allow tenant or landlord in this UI
        let isSelected = signupRole == role
        return Button {
            signupRole = role
        } label: {
            HStack(spacing: 6) {
                Circle()
                    .fill(role.accentColor.opacity(isSelected ? 0.7 : 0.25))
                    .frame(width: 10, height: 10)
                Text(role.displayLabel)
                    .font(.footnote.weight(.semibold))
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                Capsule()
                    .fill(isSelected ? role.accentColor.opacity(0.18) : Color(.secondarySystemBackground))
            )
            .foregroundColor(isSelected ? role.accentColor : .primary)
        }
        .buttonStyle(.plain)
    }

    private var canSubmitLogin: Bool {
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !password.isEmpty
    }

    private func handleLogin() {
        errorMessage = nil
        isLoading = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            do {
                try sessionStore.login(email: email, password: password)

                // After a successful login, choose the starting tab
                if let user = sessionStore.currentUser {
                    switch user.role {
                    case .tenant:
                        router.selectedTab = .discover   // tenant → Discover
                    case .landlord:
                        router.selectedTab = .home       // landlord → Home
                    case .admin:
                        // keep whatever default the router already has
                        break
                    }
                }
            } catch {
                errorMessage = (error as? LocalizedError)?.errorDescription
                    ?? "Something went wrong. Please try again."
            }
            isLoading = false
        }
    }

    // Quick-fill helpers

    private func applyTenantDemoCredentials() {
        errorMessage = nil
        email = "jessica.lee@rentswipe.mock"
        password = "swiftui123"
    }

    private func applyLandlordDemoCredentials() {
        errorMessage = nil
        email = "david.roberts@rentswipe.mock"
        password = "landlord!"
    }
}
