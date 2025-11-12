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
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    handleBack()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                }
            }
        }
    }

    private func handleBack() {
        switch router.chatLaunchSource {
        case .listing:
            router.selectedTab = .home
            router.clearChatDeepLink()
        case .none:
            // default behavior: just pop
            // the system back button will handle this, but we keep symmetry
            router.clearChatDeepLink()
        }
    }
}
