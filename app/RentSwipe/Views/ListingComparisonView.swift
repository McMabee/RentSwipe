import SwiftUI

struct ListingComparisonView: View {
    let listings: [RentalListing]   // 2–3 recommended

    // Square preview size for photos
    private let square: CGFloat = 140
    private let columnWidth: CGFloat = 170
    private let labelColumnWidth: CGFloat = 120

    var body: some View {
        NavigationStack {
            // Allow both vertical and horizontal scrolling
            ScrollView([.vertical, .horizontal], showsIndicators: true) {
                // Use Grid for rock-solid column alignment
                Grid(alignment: .topLeading, horizontalSpacing: 12, verticalSpacing: 12) {
                    // Header Row: Photos (cropped to same square)
                    GridRow {
                        labelCell("Photo")
                            .frame(width: labelColumnWidth, alignment: .leading)

                        ForEach(listings) { l in
                            valueCell(
                                Image(l.photoNames.first ?? "house")
                                    .resizable()
                                    .scaledToFill()                // crop to fill
                                    .frame(width: square, height: square)
                                    .clipped()
                                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            )
                            .frame(width: columnWidth, alignment: .leading)
                        }
                    }

                    dividerRow()

                    row("Title") { Text($0.title).font(.headline) }
                    row("Area")  { Text($0.neighborhood) }

                    row("Monthly Cost") {
                        Text(String(format: "$%.0f CAD", $0.pricePerMonth))
                            .fontWeight(.semibold)
                    }

                    row("Bedrooms")  { Text("\($0.bedrooms)") }
                    row("Bathrooms") { Text(String(format: "%.1f", $0.bathrooms)) }

                    row("Walk to campus") { Text("\($0.walkTimeToCampusMinutes) min") }

                    row("Rating") {
                        Label(String(format: "%.1f / 5", $0.rating), systemImage: "star.fill")
                            .foregroundColor(.yellow)
                    }

                    row("Verified") { l in
                        Group {
                            if l.isVerified {
                                Label("Verified", systemImage: "checkmark.seal.fill")
                                    .foregroundColor(.green)
                            } else {
                                Label("Pending", systemImage: "clock")
                                    .foregroundColor(.orange)
                            }
                        }
                    }

                    ForEach(allAmenityLabels, id: \.self) { amenity in
                        GridRow {
                            labelCell(amenity)
                                .frame(width: labelColumnWidth, alignment: .leading)

                            ForEach(listings) { l in
                                let hasIt = listingHasAmenity(l, label: amenity)
                                valueCell(
                                    Label(hasIt ? "Yes" : "No",
                                          systemImage: hasIt ? "checkmark.circle.fill" : "xmark.circle.fill")
                                        .foregroundColor(hasIt ? .green : .red)
                                )
                                .frame(width: columnWidth, alignment: .leading)
                            }
                        }
                    }
                }
                .padding(16)
                // Give the grid natural width; horizontal ScrollView takes over when needed
            }
            .navigationTitle("Compare (\(listings.count))")
            .presentationDetents([.large, .medium])
        }
    
    }
    
    private var allAmenityLabels: [String] {
        let labels = listings.flatMap { $0.amenities.map(\.label) }
        return Array(Set(labels)).sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    private func listingHasAmenity(_ listing: RentalListing, label: String) -> Bool {
        listing.amenities.contains { $0.label == label }
    }

    // MARK: - Grid helpers

    @ViewBuilder
    private func row<Content: View>(_ label: String, @ViewBuilder _ content: @escaping (RentalListing) -> Content) -> some View {
        GridRow {
            labelCell(label)
                .frame(width: labelColumnWidth, alignment: .leading)

            ForEach(listings) { l in
                valueCell(content(l))
                    .frame(width: columnWidth, alignment: .leading)
            }
        }
    }

    @ViewBuilder
    private func labelCell(_ text: String) -> some View {
        Text(text)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.vertical, 8)
    }

    @ViewBuilder
    private func valueCell<Content: View>(_ content: Content) -> some View {
        VStack(alignment: .leading, spacing: 6) { content }
            .padding(10)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color.black.opacity(0.06))
            )
    }

    @ViewBuilder
    private func dividerRow() -> some View {
        GridRow {
            Color.clear.frame(height: 1)
            ForEach(listings) { _ in Divider() }
        }
    }
}
