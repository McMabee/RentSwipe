//
//  PrototypeAuthentication.swift
//  RentSwipe
//
//  Created by Codex CLI.
//

import Foundation

enum AccountRole: String, CaseIterable, Identifiable {
    case tenant
    case landlord

    var id: Self { self }

    var title: String {
        switch self {
        case .tenant:
            return "Tenant Login"
        case .landlord:
            return "Landlord Login"
        }
    }

    var message: String {
        switch self {
        case .tenant:
            return "Access personalized listings, save favorites, and connect with landlords."
        case .landlord:
            return "List properties, review applicants, and manage tenant communications."
        }
    }

    var primaryActionLabel: String {
        switch self {
        case .tenant:
            return "Continue as Tenant"
        case .landlord:
            return "Continue as Landlord"
        }
    }

    var displayLabel: String {
        rawValue.capitalized
    }
}

struct PrototypeUser: Identifiable, Equatable {
    let id = UUID()
    let email: String
    let displayName: String
    let role: AccountRole
}

enum AuthenticationError: LocalizedError {
    case accountNotFound
    case invalidCredentials

    var errorDescription: String? {
        switch self {
        case .accountNotFound:
            return "We couldn't find an account that matches your email and role."
        case .invalidCredentials:
            return "The password you entered is incorrect. Please try again."
        }
    }
}

protocol PrototypeAuthenticating {
    func authenticate(email: String, password: String, role: AccountRole) throws -> PrototypeUser
}

struct PrototypeLocalAuthService: PrototypeAuthenticating {
    private let accountsByRole: [AccountRole: [String: PrototypeAccount]] = {
        let tenantAccounts: [PrototypeAccount] = [
            PrototypeAccount(email: "jessica.lee@rentswipe.mock", password: "swiftui123", displayName: "Jessica Lee"),
            PrototypeAccount(email: "michael.chen@rentswipe.mock", password: "swiftrocks", displayName: "Michael Chen")
        ]

        let landlordAccounts: [PrototypeAccount] = [
            PrototypeAccount(email: "david.roberts@rentswipe.mock", password: "landlord!", displayName: "David Roberts"),
            PrototypeAccount(email: "rachel.green@rentswipe.mock", password: "rentals22", displayName: "Rachel Green")
        ]

        func makeLookup(_ accounts: [PrototypeAccount]) -> [String: PrototypeAccount] {
            Dictionary(uniqueKeysWithValues: accounts.map { ($0.email.lowercased(), $0) })
        }

        return [
            .tenant: makeLookup(tenantAccounts),
            .landlord: makeLookup(landlordAccounts)
        ]
    }()

    func authenticate(email: String, password: String, role: AccountRole) throws -> PrototypeUser {
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        guard let account = accountsByRole[role]?[normalizedEmail] else {
            throw AuthenticationError.accountNotFound
        }

        guard password == account.password else {
            throw AuthenticationError.invalidCredentials
        }

        return PrototypeUser(email: account.email, displayName: account.displayName, role: role)
    }
}

private struct PrototypeAccount {
    let email: String
    let password: String
    let displayName: String
}
