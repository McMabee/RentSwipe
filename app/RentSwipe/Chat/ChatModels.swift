import Foundation
extension AccountRole: Codable{}

struct ChatParticipant: Identifiable, Hashable, Codable {
    let id: UUID
    var displayName: String
    var role: AccountRole        // reuse your existing role enum
}

struct ChatMessage: Identifiable, Hashable, Codable {
    var id: UUID = UUID()
    let senderID: UUID
    var text: String
    var sentAt: Date
}

struct ChatThread: Identifiable, Hashable, Codable {
    let id: UUID
    var listingID: UUID?
    var title: String
    var participants: [ChatParticipant]
    var messages: [ChatMessage]

    var lastMessage: ChatMessage? { messages.last }
}
