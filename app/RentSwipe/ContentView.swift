import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var sessionStore: PrototypeSessionStore
    @State private var selectedRole: AccountRole?

    var body: some View {
        NavigationStack {
            Group {
                if let role = selectedRole {
                    LoginSignupView(role: role) {
                        withAnimation(.easeInOut) {
                            selectedRole = nil
                        }
                    }
                    .environmentObject(sessionStore)
                } else {
                    UserSelectView(selectedRole: $selectedRole)
                }
            }
            .animation(.easeInOut, value: selectedRole)
            .navigationTitle("")
        }
    }
}

struct LoginSignupView: View {
    @EnvironmentObject private var sessionStore: PrototypeSessionStore

    let role: AccountRole
    var onBack: () -> Void

    @State private var email: String = ""
    @State private var password: String = ""
    @State private var message: String?
    @State private var isLoading: Bool = false

    @FocusState private var focusedField: Field?

    enum Field {
        case email
        case password
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    Text(role.title)
                        .font(.largeTitle.weight(.bold))
                        .foregroundColor(.primary)

                    Text(role.message)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(spacing: 16) {
                    TextField("email@rentswipe.mock", text: $email)
                        .keyboardType(.emailAddress)
                        .textContentType(.username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .padding()
                        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .focused($focusedField, equals: .email)

                    SecureField("Password", text: $password)
                        .textContentType(.password)
                        .padding()
                        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .focused($focusedField, equals: .password)
                }

                if let msg = message {
                    Label(msg, systemImage: "exclamationmark.triangle.fill")
                        .font(.footnote)
                        .foregroundColor(.red)
                        .padding(12)
                        .background(Color.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .transition(.opacity)
                }

                Button(action: attemptLogin) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .tint(.white)
                                .scaleEffect(0.9)
                        }

                        Text(isLoading ? "Signing In" : "Sign In")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(role.accentColor, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .foregroundColor(.white)
                }
                .disabled(isLoading || email.isEmpty || password.isEmpty)

                Divider()
                    .padding(.vertical, 4)

                VStack(alignment: .leading, spacing: 12) {
                    Text("Prototype Accounts")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)

                    ForEach(sampleCredentials) { credential in
                        HStack(alignment: .top, spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(credential.email)
                                    .font(.callout)
                                    .foregroundStyle(.primary)
                                Text("Password: \(credential.password)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Button(action: {
                                email = credential.email
                                password = credential.password
                                focusedField = .password
                            }) {
                                Text("Fill")
                                    .font(.caption.weight(.semibold))
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 12)
                                    .background(Color(.systemGray5), in: Capsule())
                            }
                        }
                        .padding(12)
                        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }
            }
            .padding(.vertical, 24)
            .padding(.horizontal, 20)
        }
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: onBack) {
                    Label("Back", systemImage: "chevron.left")
                        .labelStyle(.titleAndIcon)
                }
            }
        }
        .onAppear {
            focusedField = .email
        }
    }

    private struct Credential: Identifiable {
        let id = UUID()
        let email: String
        let password: String
    }

    private var sampleCredentials: [Credential] {
        switch role {
        case .tenant:
            return [
                Credential(email: "jessica.lee@rentswipe.mock", password: "swiftui123"),
                Credential(email: "michael.chen@rentswipe.mock", password: "swiftrocks")
            ]
        case .landlord:
            return [
                Credential(email: "david.roberts@rentswipe.mock", password: "landlord!"),
                Credential(email: "rachel.green@rentswipe.mock", password: "rentals22")
            ]
        case .admin:
            return [
                Credential(email: "techlead@rentswipe.mock", password: "trust&verify"),
                Credential(email: "compliance@rentswipe.mock", password: "moderate")
            ]
        }
    }

    private func attemptLogin() {
        message = nil
        isLoading = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            defer { isLoading = false }

            do {
                try sessionStore.login(email: email, password: password, role: role)
            } catch {
                message = (error as? LocalizedError)?.errorDescription ?? "Something went wrong."
            }
        }
    }
}
