import SwiftUI

struct ChatThreadView: View {
    @EnvironmentObject private var chat: ChatStore
    let threadID: UUID
    let title: String

    @State private var draft = ""
    @FocusState private var focused: Bool

    private var messages: [ChatMessage] {
        chat.threads.first(where: { $0.id == threadID })?.messages ?? []
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(messages) { m in
                            MessageBubble(
                                message: m,
                                isMine: m.senderID == chat.me?.id
                            )
                            .id(m.id)
                            .padding(.horizontal, 12)
                        }
                    }.padding(.vertical, 10)
                }
                .onChange(of: messages.count) { _ in
                    if let last = messages.last { withAnimation { proxy.scrollTo(last.id, anchor: .bottom) } }
                }
                .onAppear {
                    if let last = messages.last { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }

            HStack(spacing: 8) {
                TextField("Message…", text: $draft, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .focused($focused)

                Button {
                    let text = draft; draft = ""
                    chat.send(in: threadID, text: text)
                } label: { Image(systemName: "paperplane.fill") }
                .buttonStyle(.borderedProminent)
                .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(.systemBackground))
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
