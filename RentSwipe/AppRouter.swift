import SwiftUI

final class AppRouter: ObservableObject {
    enum Tab: Hashable { case home, chats, inbox, discover, favourites, analytics }
    enum ChatLaunchSource: Equatable {
        case none
        case listing(listingID: UUID)
    }

    @Published var selectedTab: Tab = .home

    // Deep link target
    @Published var pendingChatID: UUID? = nil
    @Published var chatLaunchSource: ChatLaunchSource = .none

    func openChat(threadID: UUID, fromListing id: UUID?) {
        if let id { chatLaunchSource = .listing(listingID: id) } else { chatLaunchSource = .none }
        pendingChatID = threadID
        selectedTab = .chats
    }

    func clearChatDeepLink() {
        pendingChatID = nil
        chatLaunchSource = .none
    }
}
