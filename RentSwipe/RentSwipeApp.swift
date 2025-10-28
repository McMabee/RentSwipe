//
//  RentSwipeApp.swift
//  RentSwipe
//
//  Created by Codex CLI.
//

import SwiftUI

@MainActor
final class PrototypeSessionStore: ObservableObject {
    @Published private(set) var currentUser: PrototypeUser?

    private let authService: PrototypeAuthenticating

    init(authService: PrototypeAuthenticating = PrototypeLocalAuthService()) {
        self.authService = authService
    }

    func login(email: String, password: String, role: AccountRole) throws {
        currentUser = try authService.authenticate(email: email, password: password, role: role)
    }

    func logout() {
        currentUser = nil
    }
}

@main
struct RentSwipeApp: App {
    @StateObject private var sessionStore = PrototypeSessionStore()

    var body: some Scene {
        WindowGroup {
            if let user = sessionStore.currentUser {
                PrototypeHomeView(user: user)
                    .environmentObject(sessionStore)
            } else {
                ContentView()
                    .environmentObject(sessionStore)
            }
        }
    }
}

struct PrototypeHomeView: View {
    @EnvironmentObject private var sessionStore: PrototypeSessionStore
    let user: PrototypeUser

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(spacing: 12) {
                    Text("Welcome back, \(user.displayName)!")
                        .font(.title2.weight(.semibold))

                    Text("You're signed in as a \(user.role.displayLabel).")
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Email")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)

                    Text(user.email)
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Account Type")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)

                    Text(user.role.displayLabel)
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }

                Button(role: .destructive) {
                    sessionStore.logout()
                } label: {
                    Text("Log Out")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }

                Spacer()
            }
            .padding(24)
            .navigationTitle("Dashboard")
        }
    }
}
