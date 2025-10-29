import SwiftUI

@available(iOS 17.0, *)
struct ChatsHomeView: View {
    @EnvironmentObject private var chat: ChatStore
    @EnvironmentObject private var router: AppRouter
    
    @State private var path: [UUID] = []
    
    var body: some View {
        NavigationStack(path: $path){
            List {
                if chat.threads.isEmpty {
                    ContentUnavailableView("No chats yet", systemImage: "bubble",
                                           description: Text("Start a conversation from a listing."))
                } else {
                    ForEach(chat.threads) { t in
                        NavigationLink(value: t.id) {
                            ChatRow(thread: t)
                        }
                    }
                }
            }
            .navigationTitle("Chats")
            .navigationDestination(for: UUID.self) { id in
                if let thread = chat.threads.first(where: { $0.id == id }) {
                    ChatThreadView(threadID: id, title: thread.title)
                        .environmentObject(router)     // pass router down
                } else {
                    Text("Chat not found")
                }
            }
            .onChange(of: router.pendingChatID) { _, newValue in
                if let id = newValue, chat.threads.contains(where: { $0.id == id }) {
                    path = []           // reset to ensure a clean push
                    path.append(id)     // push the thread
                }
            }
            
        }
    }
}

private struct ChatRow: View {
    let thread: ChatThread
    
    var body: some View {
        HStack(spacing: 12) {
            Circle().fill(Color(.secondarySystemBackground))
                .overlay(Image(systemName: "house").foregroundStyle(.secondary))
                .frame(width: 42, height: 42)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(thread.title).font(.headline)
                if let last = thread.lastMessage {
                    Text(last.text).font(.subheadline).foregroundStyle(.secondary).lineLimit(1)
                }
            }
            Spacer()
            if let last = thread.lastMessage {
                Text(time(last.sentAt)).font(.caption2).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func time(_ d: Date) -> String {
        let f = DateFormatter(); f.timeStyle = .short; return f.string(from: d)
    }
}
