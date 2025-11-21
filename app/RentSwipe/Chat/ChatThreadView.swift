import SwiftUI

struct ChatThreadView: View {
    @EnvironmentObject private var chat: ChatStore
    @EnvironmentObject private var router: AppRouter

    let threadID: UUID
    let title: String

    @State private var draft = ""
    @FocusState private var focused: Bool

    private var messages: [ChatMessage] {
        chat.threads.first(where: { $0.id == threadID })?.messages ?? []
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { scroll in
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(messages) { m in
                            MessageBubble(message: m, isMine: chat.me?.id == m.senderID)
                                .id(m.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: messages.count) { _ in
                    if let last = messages.last {
                        withAnimation {
                            scroll.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }

            Divider()

            HStack(spacing: 12) {
                TextField("Message...", text: $draft, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .focused($focused)
                    .lineLimit(1...4)

                Button {
                    send()
                } label: {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 18, weight: .semibold))
                }
                .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(.thinMaterial)
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            // Decide what “back” should do based on how we got here
            router.handleChatBack()
        }
    }

    private func send() {
        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        chat.send(in: threadID, text: trimmed)
        draft = ""
    }
}
