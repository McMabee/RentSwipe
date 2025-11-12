import SwiftUI

struct MessageBubble: View {
    let message: ChatMessage
    let isMine: Bool

    var body: some View {
        HStack {
            if isMine { Spacer(minLength: 40) }
            VStack(alignment: .leading, spacing: 4) {
                Text(message.text)
                    .padding(10)
                    .background(isMine ? Color.accentColor.opacity(0.15) : Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                Text(time(message.sentAt)).font(.caption2).foregroundStyle(.secondary)
            }
            if !isMine { Spacer(minLength: 40) }
        }
    }

    private func time(_ d: Date) -> String {
        let f = DateFormatter(); f.timeStyle = .short; return f.string(from: d)
    }
}
