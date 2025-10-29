import SwiftUI

@MainActor
final class ChatStore: ObservableObject {
    @Published private(set) var threads: [ChatThread] = []
    @Published private(set) var me: ChatParticipant?

    func setCurrentUser(_ user: PrototypeUser) {
        guard me == nil else { return }
        me = ChatParticipant(id: user.id, displayName: user.displayName, role: user.role)
        seedIfNeeded()
    }

    private func seedIfNeeded() {
        guard threads.isEmpty, let me else { return }
        let otherRole: AccountRole = (me.role == .landlord) ? .tenant : .landlord
        let other = ChatParticipant(id: UUID(),
                                    displayName: otherRole == .landlord ? "Sam (Landlord)" : "Alex (Tenant)",
                                    role: otherRole)

        let sampleTitle = "Modern 2BR Loft"
        let intro = ChatMessage(senderID: other.id,
                                text: "Hi \(me.displayName)! Thanks for your interest in \(sampleTitle).",
                                sentAt: Date().addingTimeInterval(-1800))

        threads = [ChatThread(id: UUID(),
                              listingID: nil,
                              title: sampleTitle,
                              participants: [me, other],
                              messages: [intro])]
    }

    func send(in threadID: UUID, text: String) {
        guard let me, let idx = threads.firstIndex(where: { $0.id == threadID }) else { return }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        threads[idx].messages.append(ChatMessage(senderID: me.id, text: trimmed, sentAt: Date()))

        // prototype echo bot
        Task {
            try? await Task.sleep(nanoseconds: 450_000_000)
            let otherID = threads[idx].participants.first { $0.id != me.id }?.id ?? UUID()
            threads[idx].messages.append(ChatMessage(senderID: otherID, text: "I love RentSwipe!!", sentAt: Date()))
        }
    }
}
