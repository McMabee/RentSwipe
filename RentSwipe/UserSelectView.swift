//
//  UserSelectView.swift
//  RentSwipe
//
//  Created by Ty Mabee on 2025-10-28.
//

import SwiftUI

struct UserSelectView: View {
    @Binding var selectedRole: AccountRole?

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 12) {
                Text("RentSwipe")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                Text("Who are you logging in as?")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 18) {
                ForEach(AccountRole.allCases) { role in
                    RoleChoiceButton(role: role) {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            selectedRole = role
                        }
                    }
                }
            }
            .padding(.horizontal)

            VStack(spacing: 8) {
                Label("Prototype build for concept review", systemImage: "wand.and.stars")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Text("Use the seeded credentials after selecting a role.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Spacer()
        }
        .padding(.vertical, 40)
        .padding(.horizontal, 24)
        .toolbar(.hidden, for: .navigationBar)
    }
}

private struct RoleChoiceButton: View {
    let role: AccountRole
    let action: () -> Void

    @State private var isPressed: Bool = false

    var body: some View {
        Button {
            action()
        } label: {
            HStack(alignment: .center, spacing: 16) {
                ZStack {
                    Circle()
                        .fill(role.accentColor.opacity(0.12))
                        .frame(width: 52, height: 52)

                    Image(systemName: iconName)
                        .font(.title2)
                        .foregroundColor(role.accentColor)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(role.displayLabel)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(role.message)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.headline)
                    .foregroundStyle(.tertiary)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(isPressed ? 0.05 : 0.12), radius: isPressed ? 2 : 8, y: isPressed ? 1 : 4)
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed { isPressed = true }
                }
                .onEnded { _ in
                    isPressed = false
                }
        )
    }

    private var iconName: String {
        switch role {
        case .tenant:
            return "person.2.fill"
        case .landlord:
            return "building.2.fill"
        case .admin:
            return "checkmark.seal.fill"
        }
    }
}

#Preview {
    NavigationStack {
        UserSelectView(selectedRole: .constant(nil))
    }
}
