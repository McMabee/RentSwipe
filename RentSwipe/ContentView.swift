//
//  ContentView.swift
//  RentSwipe
//
//  Created by Codex CLI.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var sessionStore: PrototypeSessionStore
    @State private var selectedRole: AccountRole = .tenant
    @State private var tenantEmail: String = ""
    @State private var tenantPassword: String = ""
    @State private var landlordEmail: String = ""
    @State private var landlordPassword: String = ""
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @FocusState private var focusedField: Field?

    private enum Field {
        case email
        case password
    }

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 28) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("RentSwipe")
                            .font(.largeTitle.weight(.bold))

                        Text("Find student housing or list your property with a swipe.")
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 24)

                    Picker("Account Type", selection: $selectedRole) {
                        ForEach(AccountRole.allCases) { role in
                            Text(role.displayLabel).tag(role)
                        }
                    }
                    .pickerStyle(.segmented)

                    VStack(alignment: .leading, spacing: 16) {
                        Text(selectedRole.title)
                            .font(.title2.weight(.semibold))

                        Text(selectedRole.message)
                            .foregroundStyle(.secondary)
                    }

                    VStack(spacing: 18) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.subheadline.weight(.medium))

                            TextField("name@example.com", text: emailBinding)
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .disableAutocorrection(true)
                                .focused($focusedField, equals: .email)
                                .textContentType(.username)
                                .padding(14)
                                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.subheadline.weight(.medium))

                            SecureField("Enter your password", text: passwordBinding)
                                .textContentType(.password)
                                .focused($focusedField, equals: .password)
                                .padding(14)
                                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                    }

                    Button {
                        attemptLogin()
                    } label: {
                        Text(selectedRole.primaryActionLabel)
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .foregroundStyle(.white)
                    }
                    .padding(.top, 8)

                    Button("Forgot Password?") {
                        alertMessage = "Password recovery is not available in this preview."
                        showAlert = true
                    }
                    .font(.subheadline.weight(.semibold))
                    .tint(.secondary)

                    Spacer(minLength: 24)
                }
                .padding(24)
            }
            .navigationTitle("Login")
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        focusedField = nil
                    }
                }
            }
            .alert("Action Required", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }

    private var emailBinding: Binding<String> {
        switch selectedRole {
        case .tenant:
            return $tenantEmail
        case .landlord:
            return $landlordEmail
        }
    }

    private var passwordBinding: Binding<String> {
        switch selectedRole {
        case .tenant:
            return $tenantPassword
        case .landlord:
            return $landlordPassword
        }
    }

    private func attemptLogin() {
        focusedField = nil
        showAlert = false

        let email = emailBinding.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines)
        let password = passwordBinding.wrappedValue

        guard !email.isEmpty else {
            alertMessage = "Please enter your email address."
            showAlert = true
            return
        }

        guard email.contains("@"), email.contains(".") else {
            alertMessage = "Enter a valid email address."
            showAlert = true
            return
        }

        guard password.count >= 6 else {
            alertMessage = "Passwords must be at least 6 characters long."
            showAlert = true
            return
        }

        do {
            try sessionStore.login(email: email, password: password, role: selectedRole)
            passwordBinding.wrappedValue = ""
        } catch let authError as AuthenticationError {
            alertMessage = authError.localizedDescription
            showAlert = true
        } catch {
            alertMessage = "Something went wrong. Please try again."
            showAlert = true
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(PrototypeSessionStore())
}
