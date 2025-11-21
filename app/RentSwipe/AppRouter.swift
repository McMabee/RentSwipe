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

    @Published var pendingListingID: UUID? = nil

    func openChat(threadID: UUID, fromListing id: UUID?) {
        if let id {
            chatLaunchSource = .listing(listingID: id)
        } else {
            chatLaunchSource = .none
        }
        pendingChatID = threadID
        selectedTab = .chats
    }

    func clearChatDeepLink() {
        pendingChatID = nil
        chatLaunchSource = .none
    }

    // NEW: called when user taps Back in a chat thread
    func handleChatBack() {
        switch chatLaunchSource {
        case .none:
            // Normal chat navigation; chat screen can just dismiss.
            clearChatDeepLink()

        case .listing(let listingID):
            // We came here from a listing.
            clearChatDeepLink()
            // Tell the app we want to show that listing on the Home tab.
            pendingListingID = listingID
            selectedTab = .home
        }
    }
}
