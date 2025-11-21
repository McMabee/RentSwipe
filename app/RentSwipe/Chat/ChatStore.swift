import SwiftUI

@MainActor
final class ChatStore: ObservableObject {
    @Published private(set) var threads: [ChatThread] = []
    @Published private(set) var me: ChatParticipant?

    func setCurrentUser(_ user: PrototypeUser) {
        // Always update "me" when a new user logs in
        me = ChatParticipant(id: user.id, displayName: user.displayName, role: user.role)
        seedThreadsForCurrentUser()
    }

    private func seedThreadsForCurrentUser() {
        guard let me else { return }

        let sampleTitle = "Modern 2BR Loft"

        // The "other" side of the conversation depends on our role
        let otherRole: AccountRole = (me.role == .landlord) ? .tenant : .landlord
        let other = ChatParticipant(
            id: UUID(),
            displayName: otherRole == .landlord ? "Sam (Landlord)" : "Alex (Tenant)",
            role: otherRole
        )

        // Who sends the first message?
        let intro: ChatMessage
        if me.role == .landlord {
            // Landlord is logged in: show this as a message *from* the landlord
            intro = ChatMessage(
                senderID: me.id,
                text: "Hi \(other.displayName)! Thanks for your interest in \(sampleTitle).",
                sentAt: Date().addingTimeInterval(-1800)
            )
        } else {
            // Tenant is logged in: show this as coming from the landlord
            intro = ChatMessage(
                senderID: other.id,
                text: "Hi \(me.displayName)! Thanks for your interest in \(sampleTitle).",
                sentAt: Date().addingTimeInterval(-1800)
            )
        }

        // Use the demoChatThreadID so the landlord's "Linked Chat" can open this thread
        threads = [
            ChatThread(
                id: SampleData.demoChatThreadID,
                listingID: nil,
                title: sampleTitle,
                participants: [me, other],
                messages: [intro]
            )
        ]
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
