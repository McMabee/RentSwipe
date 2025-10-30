import SwiftUI

// MARK: - Card wrapper / identity
struct SwipeCardModel: Identifiable, Equatable {
    let id = UUID()
    let listing: RentalListing

    static func == (lhs: SwipeCardModel, rhs: SwipeCardModel) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Direction marker
enum SwipeDirection {
    case left, right
}

// MARK: - Top-level swipe deck
@available(iOS 16.4, *)
struct SwipeDiscoveryView: View {
    @EnvironmentObject private var favourites: FavouritesStore
    // deck of cards (front is index 0)
    @State private var cards: [SwipeCardModel]

    // drag state for the TOP card
    @GestureState private var dragOffset: CGSize = .zero
    @State private var settledOffset: CGSize = .zero
    @State private var dragProgress: Double = 0
    
    // current horizontal drag
    private var currentDragX: CGFloat {
        dragOffset.width + settledOffset.width
    }

    // "liked" popup
    @State private var likedCard: SwipeCardModel?

    private let swipeDistanceTrigger: CGFloat = 0.25 // % of width

    init(listings: [RentalListing]) {
        _cards = State(initialValue: listings.map { SwipeCardModel(listing: $0) })
    }

    var body: some View {
        GeometryReader { geo in
            mainDeckView(in: geo)
        }
        .background(Color.black.ignoresSafeArea())
        .fullScreenCover(item: $likedCard) { liked in
            VStack(spacing: 16) {
                Text("Saved to favourites:")
                    .font(.headline)
                Text(liked.listing.title)
                    .font(.title.bold())
                Button("Close") {
                    likedCard = nil
                }
                .padding(.top, 24)
            }
            .padding()
            .presentationBackground(.ultraThinMaterial)
        }
    }

    // MARK: - deck rendering extracted to help the compiler
    @ViewBuilder
    private func mainDeckView(in geo: GeometryProxy) -> some View {
        ZStack {
            ForEach(Array(cards.enumerated().reversed()), id: \.element.id) { index, card in
                cardView(for: card, atStackIndex: index, geo: geo)
            }
        }
        .frame(width: geo.size.width, height: geo.size.height)
    }

    // one card layer in the stack (top card vs background cards)
    @ViewBuilder
    private func cardView(for card: SwipeCardModel,
                          atStackIndex index: Int,
                          geo: GeometryProxy) -> some View {

        if index == 0 {
            topCard(card, geo: geo)
        } else if (1...3).contains(index) {
            backgroundCard(card, index: index)
        } else {
            EmptyView()
        }
    }

    // MARK: - Top (draggable) card view
    private func topCard(_ card: SwipeCardModel, geo: GeometryProxy) -> some View {
        ZStack {
            CardDetailView(
                listing: card.listing,
                width: geo.size.width,
                height: geo.size.height
            )
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            
            swipeAffordanceOverlay(width: geo.size.width)
        }
        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 8)
        .offset(x: dragOffset.width + settledOffset.width,
                y: dragOffset.height + settledOffset.height)
        .rotationEffect(.degrees(
            Double((dragOffset.width + settledOffset.width) / 20.0)
        ))
        
        .animation(.spring(response: 0.25, dampingFraction: 0.8),
                   value: dragOffset)
        
        //main drag logic
        .gesture(
            DragGesture(minimumDistance: 10)
                .updating($dragOffset) { value, state, _ in
                    state = value.translation
                }
                .onChanged { value in
                    let horizontalMag = abs(value.translation.width + settledOffset.width)
                    let prog = min(1.0, horizontalMag / 150.0)
                    // keep dragProgress in sync
                    if dragProgress != prog {
                        dragProgress = prog
                    }
                }
                .onEnded { value in
                    let totalX = value.translation.width + settledOffset.width
                    let widthThreshold = swipeDistanceTrigger * (geo.size.width * 0.9)

                    if totalX >= widthThreshold {
                        swipeAndRemove(.right, card: card, geo: geo)
                    } else if totalX <= -widthThreshold {
                        swipeAndRemove(.left, card: card, geo: geo)
                    } else {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            settledOffset = .zero
                            dragProgress = 0
                        }
                    }
                }
        )
    }

    // MARK: - Lower stacked cards (not draggable)
    private func backgroundCard(_ card: SwipeCardModel, index: Int) -> some View {
        CardDetailView(
            listing: card.listing,
            width: UIScreen.main.bounds.width,
            height: UIScreen.main.bounds.height
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 4)
        .offset(y: stackedYOffset(for: index, dragProgress: dragProgress))
        .rotationEffect(.degrees(stackedRotation(for: index, dragProgress: dragProgress)))
        .opacity(stackedOpacity(for: index, dragProgress: dragProgress))
        .scaleEffect(stackedScale(for: index, dragProgress: dragProgress))
    }

    // MARK: - Stack presentation helpers
    private func stackedYOffset(for index: Int, dragProgress: Double) -> CGFloat {
        // same math as before
        -25 * CGFloat(Double(index) - dragProgress)
    }

    private func stackedRotation(for index: Int, dragProgress: Double) -> Double {
        5.0 * (Double(index) - dragProgress)
    }

    private func stackedOpacity(for index: Int, dragProgress: Double) -> Double {
        max(0, 1 - 0.33 * (Double(index) - dragProgress))
    }

    private func stackedScale(for index: Int, dragProgress: Double) -> CGFloat {
        let shrink = 0.05 * CGFloat(index)
        return (1 - shrink) + 0.05 * CGFloat(dragProgress)
    }

    // MARK: - remove + animate offscreen
    private func swipeAndRemove(_ dir: SwipeDirection,
                                card: SwipeCardModel,
                                geo: GeometryProxy)
    {
        // fling amount
        let flingX: CGFloat = dir == .right ? geo.size.width * 1.2 : -geo.size.width * 1.2

        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
            settledOffset.width = flingX
        }

        // mutate deck immediately after fling decision
        removeCard(card, direction: dir)

        // reset state for next card
        dragProgress = 0
        settledOffset = .zero
    }

    private func removeCard(_ card: SwipeCardModel, direction: SwipeDirection) {
        guard let idx = cards.firstIndex(of: card) else { return }

        switch direction {
        case .right:
            // Favourite: remove cards from deck and show match sheet
            favourites.add(card.listing)
            likedCard = cards.remove(at: idx)
        
        case.left:
            // Soft block: take it off front, push to back
            let blocked = cards.remove(at: idx)
            cards.append(blocked)
        }
    }
    
    // TODO: Fix animation for swiping, make heart and x appear on swipe
    // MARK: swipe animation of heart vs x
    @ViewBuilder
    private func swipeAffordanceOverlay(width: CGFloat) -> some View {
        let x = currentDragX
        
        let normalized = min(1.0, abs(x) / 150.0)
        let opacity = Double(normalized)
        let scale: CGFloat = 0.8 + 0.4 * CGFloat(normalized)
        
        if x > 0 {
            //Swiping RIGHT = favourite (heart)
            VStack {
                HStack{
                    Spacer()
                    badgeView(
                        systemName: "heart.fill",
                        text: "SAVE",
                        color: .green
                    )
                    .scaleEffect(scale)
                    .opacity(opacity)
                }
                Spacer()
            }
            .padding(32)
            .transition(.opacity.combined(with: .scale))
        } else if x < 0 {
            //Swiping LEFT = delete (X)
            VStack{
                HStack{
                    badgeView(
                        systemName: "xmark.circle.fill",
                        text: "HIDE",
                        color: .red
                    )
                    .scaleEffect(scale)
                    .opacity(opacity)
                    Spacer()
                }
                Spacer()
            }
            .padding(32)
            .transition(.opacity.combined(with: .scale))
        } else {
            EmptyView()
        }
    }
    
    // TODO: Fix animation for swiping, make heart and x appear on swipe
    private func badgeView(systemName: String, text: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: systemName)
                .font(.headline.bold())
            Text(text)
                .font(.headline.bold())
        }
        .foregroundColor(.white)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(color.opacity(0.8))
                .shadow(radius: 8)
        )
    }
}

// MARK: - ONE CARD VIEW
// Scrollable card content: carousel + details.
struct CardDetailView: View {
    let listing: RentalListing
    let width: CGFloat
    let height: CGFloat

    @State private var photoIndex: Int = 0

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {

                // IMAGE CAROUSEL
                TabView(selection: $photoIndex) {
                    ForEach(listing.photoNames.indices, id: \.self) { idx in
                        Image(listing.photoNames[idx])
                            .resizable()
                            .scaledToFill()
                            .frame(width: width, height: width * 0.75)
                            .clipped()
                            .tag(idx)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
                .frame(width: width, height: width * 0.75)
                .background(Color.black)

                // DETAILS
                listingDetailsSection(listing: listing)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .padding(.top, 16)
                    .padding(.horizontal, 16)

                Spacer(minLength: 40)
            }
            .frame(width: width)
            .background(Color(.systemBackground))
        }
        .frame(width: width, height: height)
        .background(Color.black)
    }

    @ViewBuilder
    private func listingDetailsSection(listing: RentalListing) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title / area
            Text(listing.title)
                .font(.title2.weight(.bold))
                .foregroundColor(.primary)

            Text(listing.neighborhood)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Divider()

            // Price / beds / baths row
            HStack(alignment: .firstTextBaseline) {
                Text("\(Int(listing.pricePerMonth)) CAD/mo")
                    .font(.headline)
                Spacer()
                Text("\(listing.bedrooms) bd • \(listing.bathrooms, specifier: "%.1f") ba")
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }

            Text("~\(listing.walkTimeToCampusMinutes) min walk to campus")
                .font(.footnote)
                .foregroundColor(.secondary)

            Divider()

            Text("Amenities")
                .font(.headline)
                .foregroundColor(.primary)

            AmenityChipsView(amenities: listing.amenities)

            Divider()

            HStack(spacing: 8) {
                Text("Rating: \(listing.rating, specifier: "%.1f") / 5")
                    .foregroundColor(.primary)
                    .font(.subheadline)

                if listing.isVerified {
                    Label("Verified listing", systemImage: "checkmark.seal.fill")
                        .font(.footnote.bold())
                        .foregroundColor(.green)
                } else {
                    Label("Not verified", systemImage: "exclamationmark.triangle.fill")
                        .font(.footnote.bold())
                        .foregroundColor(.orange)
                }
            }

            Text("About this place")
                .font(.headline)
                .padding(.top, 12)

            Text("""
Spacious, bright, and student-friendly. Landlord is responsive, utilities included, and there's a quiet study lounge with decent Wi-Fi. Pets allowed on approval.
""")
            .font(.body)
            .foregroundColor(.primary)

            Spacer(minLength: 24)
        }
        .padding(16)
    }
}

// MARK: - Amenity chips with simple line wrapping
struct AmenityChipsView: View {
    let amenities: [ListingAmenity]

    var body: some View {
        // We'll wrap manually into rows so we don't need custom Layout.
        let chipViews = amenities.map { amenityChip($0) }

        // Break into lines of ~3-4 chips depending on length
        VStack(alignment: .leading, spacing: 8) {
            ForEach(lines(for: chipViews), id: \.self.indices) { line in
                HStack(spacing: 8) {
                    ForEach(line.indices, id: \.self) { idx in
                        line[idx]
                    }
                }
            }
        }
    }

    // make a chip view for an amenity
    private func amenityChip(_ amenity: ListingAmenity) -> some View {
        Label(amenity.label, systemImage: amenity.icon)
            .font(.caption)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .foregroundColor(.primary)
            .background(
                Capsule()
                    .fill(Color(.systemGray6))
            )
    }

    // very simple greedy line breaker by width guess:
    // for now we'll just chunk every 3 chips which is reliable and fast.
    // you can get fancier later by measuring text.
    private func lines(for chips: [AnyView]) -> [[AnyView]] {
        // chunk size of 3 to avoid layout protocol complexity
        let chunkSize = 3
        var result: [[AnyView]] = []
        var idx = 0
        while idx < chips.count {
            let end = min(idx + chunkSize, chips.count)
            result.append(Array(chips[idx..<end]))
            idx = end
        }
        return result
    }

    // Helper to make type-erased views for storage
    private func amenityChip(_ amenity: ListingAmenity) -> AnyView {
        AnyView(
            Label(amenity.label, systemImage: amenity.icon)
                .font(.caption)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .foregroundColor(.primary)
                .background(
                    Capsule()
                        .fill(Color(.systemGray6))
                )
        )
    }
}
