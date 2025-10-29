import SwiftUI

@MainActor
final class FavouritesStore: ObservableObject {
    @Published private(set) var listings: [RentalListing] = []

    func add(_ listing: RentalListing) {
        if !listings.contains(listing) {
            listings.append(listing)
        }
    }

    func remove(_ listing: RentalListing) {
        listings.removeAll { $0 == listing }
    }

    func toggle(_ listing: RentalListing) {
        if isFavorite(listing) { remove(listing) } else { add(listing) }
    }

    func isFavorite(_ listing: RentalListing) -> Bool {
        listings.contains(listing)
    }
}
