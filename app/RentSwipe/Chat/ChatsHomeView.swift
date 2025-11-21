import SwiftUI

@available(iOS 17.0, *)
struct ChatsHomeView: View {
    @EnvironmentObject private var chat: ChatStore
    @EnvironmentObject private var router: AppRouter
    
    @State private var deeplinkThread: ChatThread? = nil
    
    @State private var path: [UUID] = []
    
    var body: some View {
        ZStack{
            chatsList
            NavigationLink(
                isActive: Binding(
                    get: { deeplinkThread != nil },
                    set: { isActive in
                        if !isActive {
                            deeplinkThread = nil
                        }
                    }
                ),
                destination: {
                    if let thread = deeplinkThread {
                        ChatThreadView(threadID: thread.id, title: thread.title)
                    } else {
                        EmptyView()
                    }
                },
                label: { EmptyView() }
            )
            .hidden()
        }
        .onChange(of: router.pendingChatID) { newID in
            // When router.openChat(...) is called, this will fire
            guard
                let id = newID,
                let thread = chat.threads.first(where: { $0.id == id })
            else { return }
            
            deeplinkThread = thread
            // We *don’t* clear pendingChatID here; handleChatBack will do that.
        }
    }
    
    private var chatsList: some View {
        // Whatever you already had (list of threads, etc.)
        // For example:
        List(chat.threads) { thread in
            NavigationLink {
                ChatThreadView(threadID: thread.id, title: thread.title)
            } label: {
                Text(thread.title)
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
