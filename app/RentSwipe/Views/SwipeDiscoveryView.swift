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
            backgroundCard(card, index: index, geo: geo)
        } else {
            EmptyView()
        }
    }
    
    
    // MARK: - Top (draggable) card view
    private func topCard(_ card: SwipeCardModel, geo: GeometryProxy) -> some View {
        ZStack {
            CardDetailView(
                listing: card.listing,
                cardHeight: geo.size.height,
                cardWidth: geo.size.width
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
    private func backgroundCard(_ card: SwipeCardModel,
                                index: Int,
                                geo: GeometryProxy) -> some View {
        CardDetailView(
            listing: card.listing,
            cardHeight: geo.size.height,
            cardWidth: geo.size.width
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
        // Cards line up exactly at rest; as you drag, cards behind
        // lift slightly into view like Tinder.
        let lift: CGFloat = 14
        return -CGFloat(dragProgress) * lift * CGFloat(index)
    }
    
    private func stackedRotation(for index: Int, dragProgress: Double) -> Double {
        // No rotation at rest; very slight as the next card comes in.
        let maxRotation: Double = 4
        return maxRotation * dragProgress * Double(index)
    }
    
    private func stackedOpacity(for index: Int, dragProgress: Double) -> Double {
        // Slightly dim cards further back; brighten a touch as they move up.
        let base = 1.0 - 0.15 * Double(index)
        return max(0, base + 0.05 * dragProgress)
    }
    
    private func stackedScale(for index: Int, dragProgress: Double) -> CGFloat {
        // Full size at rest. As the top card is dragged away,
        // cards behind shrink just a bit to give depth.
        let maxShrink: CGFloat = 0.04
        let shrink = maxShrink * CGFloat(index) * CGFloat(dragProgress)
        return 1 - shrink
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


struct CardDetailView: View {
    let listing: RentalListing
    let cardHeight: CGFloat
    let cardWidth: CGFloat
    @State private var photoIndex = 0
    

    var body: some View {
        VStack(spacing: 0) {

            // --- PHOTO SECTION ---
            PhotoCarouselSection(
                photoNames: listing.photoNames,
                width: cardWidth,
                height: cardWidth * 0.75
            )

            

            // --- SCROLLABLE CONTENT SECTION ---
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {

                    TitleSection(listing: listing)
                    PriceSection(listing: listing)
                    AmenitiesSection(listing: listing)
                    AboutSection(listing: listing)

                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 40)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black)
        }
        .frame(width: cardWidth, height: cardHeight)
        .background(Color.black)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .contentShape(Rectangle())
    }
}

struct PhotoCarouselSection: View {
    let photoNames: [String]
    let width: CGFloat
    let height: CGFloat
    @State private var index = 0
    
    private var innerWidth: CGFloat { width - 32 }
    private var innerHeight: CGFloat { innerWidth * (height / width) }

    var body: some View {
        TabView(selection: $index) {
            ForEach(photoNames.indices, id: \.self) { i in
                Image(photoNames[i])
                    .resizable()
                    .scaledToFill()
                    .frame(width: innerWidth, height: innerHeight)
                    .clipped()
                    .tag(i)
            }
        }
        .tabViewStyle(PageTabViewStyle())
        .frame(width: innerWidth, height: innerHeight)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

struct TitleSection: View {
    let listing: RentalListing

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(listing.title)
                .font(.title2.bold())
            Text(listing.neighborhood)
                            .font(.subheadline)
                            .foregroundColor(.gray)
        }
    }
}

struct PriceSection: View {
    let listing: RentalListing

    var body: some View {
        HStack {
            Text("\(Int(listing.pricePerMonth)) CAD/mo")  // <- pricePerMonth
                            .font(.title3.bold())

            Spacer()

            Text("\(listing.bedrooms) bd • \(bathroomsText(for: listing.bathrooms)) ba")
                            .font(.subheadline)
                            .foregroundColor(.gray)
        }
    }
    
    private func bathroomsText(for value: Double) -> String {
        // If it's an integer (2.0), show "2"
        if value.rounded(.towardZero) == value {
            return "\(Int(value))"
        } else {
            // Otherwise show one decimal place (e.g. 1.5)
            return String(format: "%.1f", value)
        }
    }

}

struct AboutSection: View {
    let listing: RentalListing

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("About this place")
                .font(.headline)

            Text("Here is where the landlord would submit a description of this listing.")     // <- was listing.description
                            .font(.body)
                            .foregroundColor(.gray)
        }
    }
}

struct AmenitiesSection: View {
    let listing: RentalListing

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Amenities")
                .font(.headline)

            AmenityChipsView(amenities: listing.amenities)
        }
    }
}

// MARK: - Amenity chips with simple grid layout
struct AmenityChipsView: View {
    let amenities: [ListingAmenity]

    private let columns = [
        GridItem(.adaptive(minimum: 120), spacing: 8)
    ]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
            ForEach(amenities, id: \.self) { amenity in
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
        }
    }
}

