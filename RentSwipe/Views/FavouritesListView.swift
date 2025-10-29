import SwiftUI

@available(iOS 17.0, *)
struct FavouritesListView: View {
    @EnvironmentObject private var favourites: FavouritesStore
    @State private var selected: Set<UUID> = []
    @State private var showCompare: Bool = false

    private let priceFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "CAD"
        return f
    }()

    private var selectedListings: [RentalListing] {
        favourites.listings.filter { selected.contains($0.id) }
    }

    var body: some View {
        NavigationStack {
            List(selection: $selected) {
                if favourites.listings.isEmpty {
                    Section {
                        ContentUnavailableView(
                            "No favourites yet",
                            systemImage: "heart",
                            description: Text("Swipe right on listings in Discover to save them here.")
                        )
                    }
                } else {
                    Section("Saved listings") {
                        ForEach(favourites.listings) { listing in
                            HStack(spacing: 12) {
                                // square thumb for consistency
                                Image(listing.photoNames.first ?? "house")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 56, height: 56)
                                    .clipped()
                                    .cornerRadius(10)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(listing.title).font(.headline)
                                    Text(listing.neighborhood)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Text(priceFormatter.string(from: NSNumber(value: listing.pricePerMonth)) ?? "$—")
                                    .font(.subheadline.weight(.semibold))
                            }
                            .contentShape(Rectangle())
                            .tag(listing.id)   // enable multi-select
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    favourites.remove(listing)
                                    selected.remove(listing.id)
                                } label: { Label("Remove", systemImage: "trash") }
                            }
                        }
                    }
                }
            }
            // Keep multi-select always on
            .environment(\.editMode, .constant(.active))
            .navigationTitle("Favourites")
            // Bottom action bar appears when selection has 2–3 items
            .safeAreaInset(edge: .bottom) {
                if (2...3).contains(selected.count) {
                    HStack(spacing: 12) {
                        Button("Cancel") {
                            selected.removeAll()
                        }
                        .buttonStyle(.bordered)
                        .tint(.gray)

                        Button {
                            showCompare = true
                        } label: {
                            Text("Compare (\(selected.count))")
                                .fontWeight(.semibold)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.clear)
                }
            }
            .sheet(isPresented: $showCompare) {
                ListingComparisonView(listings: selectedListings)
            }
        }
    }
}
