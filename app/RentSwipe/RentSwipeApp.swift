import SwiftUI
@MainActor
final class PrototypeSessionStore: ObservableObject {
    @Published private(set) var currentUser: PrototypeUser?
    
    private let authService: PrototypeAuthenticating
    
    init(authService: PrototypeAuthenticating = PrototypeLocalAuthService()) {
        self.authService = authService
    }
    
    func login(email: String, password: String) throws {
        currentUser = try authService.authenticate(email: email, password: password)
    }
    
    func logout() {
        currentUser = nil
    }
}


@available(iOS 16.4, *)
@main
struct RentSwipeApp: App {
    @StateObject private var sessionStore = PrototypeSessionStore()
    @StateObject private var favouritesStore = FavouritesStore()
    @StateObject private var chatStore = ChatStore()
    @StateObject private var router = AppRouter()
    
    @Namespace private var splashNamespace
    @State private var showSplash: Bool = true
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if showSplash {
                    // Only splash is visible
                    SplashView(finished: splashFinishedBinding, namespace: splashNamespace)
                        .zIndex(1)
                } else if sessionStore.currentUser == nil {
                    // Login flow (no opacity hack)
                    LoginEntryView(namespace: splashNamespace)
                        .environmentObject(sessionStore)
                        .environmentObject(router)
                } else {
                    // Logged-in experience
                    PrototypeHomeView(user: sessionStore.currentUser!)
                        .environmentObject(sessionStore)
                        .environmentObject(favouritesStore)
                        .environmentObject(chatStore)
                        .environmentObject(router)
                }
            }
        }
    }
    
    private var splashFinishedBinding: Binding<Bool> {
        Binding(
            get: { !showSplash },
            set: { newFinished in
                if newFinished {
                    withAnimation(.easeInOut(duration: 0.7)) {
                        showSplash = false
                    }
                }
            }
        )
    }
}

@available(iOS 16.4, *)
struct PrototypeHomeView: View {
    @EnvironmentObject private var sessionStore: PrototypeSessionStore
    @EnvironmentObject private var chatStore: ChatStore
    @EnvironmentObject private var router: AppRouter
    let user: PrototypeUser
    
    @State private var notifications: [AppNotification] = SampleData.notifications
    
    @available(iOS 16.4, *)
    var body: some View {
        TabView(selection: $router.selectedTab) {
            if user.role == .tenant {
                NavigationStack{
                    SwipeDiscoveryView(listings: SampleData.tenantListings)
                }
                .tabItem {
                    Label("Discover", systemImage: "magnifyingglass")
                }
                .tag(AppRouter.Tab.discover)
            }
            NavigationStack {
                if user.role == .tenant {
                    if #available(iOS 17.0, *) {
                        FavouritesListView()
                            .navigationTitle("Favourites")
                    } else {
                        // Fallback on earlier versions
                    }
                } else {
                    roleDashboard
                        .navigationTitle("Home")
                }
            }
            .tabItem {
                if user.role == .tenant {
                    Label("Favourites", systemImage: "heart")
                } else {
                    Label("Home", systemImage: "house")
                }
            }
            .tag(AppRouter.Tab.home)
            
            if user.role == .admin {
                NavigationStack {
                    AnalyticsOverviewView(metrics: SampleData.analytics, role: user.role)
                        .navigationTitle("Analytics")
                }
                .tabItem {
                    Label("Analytics", systemImage: "chart.bar.xaxis")
                }
            } else {
                // Tenants & landlords get Chats
                NavigationStack {
                    if #available(iOS 17.0, *) {
                        ChatsHomeView()
                            .navigationTitle("Chats")
                    } else {
                        // Fallback on earlier versions
                    }
                }
                .tabItem { Label("Chats", systemImage: "bubble.left.and.bubble.right") }
                .tag(AppRouter.Tab.chats)
            }
            
            NavigationStack {
                ProfileView(user: user)
                    .navigationTitle("Profile")
            }
            .tabItem {
                Label("Profile", systemImage: "person.crop.circle")
            }
            // keep using the same router case so you don't have to touch AppRouter
            .tag(AppRouter.Tab.inbox)
        }
        .onAppear {chatStore.setCurrentUser(user)}
    }
    
    private var workspaceTitle: String {
        switch user.role {
        case .tenant:
            return "Tenant Workspace"
        case .landlord:
            return "Home"
        case .admin:
            return "Admin Control"
        }
    }
    
    @ViewBuilder
    private var roleDashboard: some View {
        switch user.role {
        case .tenant:
            TenantDashboardView()
        case .landlord:
            LandlordHomeView()
        case .admin:
            AdminConsoleView()
        }
    }
}

// MARK: - Tenant Experience

struct TenantDashboardView: View {
    @State private var discoveryQueue: [RentalListing] = SampleData.tenantListings
    @State private var favorites: [RentalListing] = []
    @State private var dismissed: [RentalListing] = []
    @State private var filters: TenantPreferenceProfile = TenantPreferenceProfile()
    @State private var roommateMatches: [RoommateMatch] = SampleData.roommateMatches
    @State private var viewingRequests: [ViewingRequest] = SampleData.viewingRequests
    
    @State private var showFilters: Bool = false
    @State private var selectedListing: RentalListing?
    
    
    private let priceFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "CAD"
        return formatter
    }()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                discoveryHeader
                discoveryCard
                favoritesSection
                roommateSection
                viewingRequestsSection
            }
            .padding(.vertical, 24)
            .padding(.horizontal, 20)
        }
        .background(Color(.systemGroupedBackground))
        .sheet(isPresented: $showFilters) {
            TenantFilterSheet(filters: $filters)
                .presentationDetents([.medium, .large])
        }
        .sheet(item: $selectedListing) { listing in
            ListingDetailSheet(listing: listing)
        }
    }
    
    private var discoveryHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Discovery Queue")
                        .font(.title2.weight(.semibold))
                    Text("Swipe through curated listings tailored to your preferences.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Button {
                    showFilters = true
                } label: {
                    Label("Filters", systemImage: "slider.horizontal.3")
                        .font(.callout.weight(.semibold))
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color(.systemGray5), in: Capsule())
                }
            }
            
            filterSummary
            
            if !dismissed.isEmpty {
                Text("Snoozed \(dismissed.count) listings — we'll refresh once landlords update details.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }
    
    private var discoveryCard: some View {
        VStack(spacing: 16) {
            if let listing = discoveryQueue.first {
                ListingCardView(listing: listing)
                    .onTapGesture {
                        selectedListing = listing
                    }
                
                HStack(spacing: 16) {
                    Button(role: .destructive) {
                        pass(listing)
                    } label: {
                        Label("Pass", systemImage: "xmark")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    
                    Button {
                        favorite(listing)
                    } label: {
                        Label("Favorite", systemImage: "heart.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green.opacity(0.18), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 42))
                        .foregroundColor(.indigo)
                    Text("You're all caught up!")
                        .font(.headline)
                    Text("New listings will drop once landlords finish verification.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(24)
                .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            }
        }
    }
    
    private var favoritesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Favorites")
                    .font(.title3.weight(.semibold))
                Spacer()
                if !favorites.isEmpty {
                    Text("\(favorites.count) saved")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            
            if favorites.isEmpty {
                Text("Swipe right on a listing to keep it handy for tours and roommate invites.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 14) {
                    ForEach(favorites) { listing in
                        FavoriteListingRow(listing: listing, formatter: priceFormatter)
                            .onTapGesture {
                                selectedListing = listing
                            }
                    }
                }
            }
        }
    }
    
    private var roommateSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Find a Homie")
                .font(.title3.weight(.semibold))
            
            Text("High-confidence roommate matches based on lifestyle fit and shared interests.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            VStack(spacing: 12) {
                ForEach(roommateMatches) { match in
                    RoommateMatchCard(match: match)
                }
            }
        }
    }
    
    private var viewingRequestsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Viewing Requests")
                .font(.title3.weight(.semibold))
            
            if viewingRequests.isEmpty {
                Text("Tap a favorite to schedule a tour. Landlords respond in under 4 hours on average.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 12) {
                    ForEach(viewingRequests) { request in
                        ViewingRequestCard(request: request)
                    }
                }
            }
        }
    }
    
    private var filterSummary: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Up to \(priceFormatter.string(from: NSNumber(value: filters.maxPrice)) ?? "$0") • Minimum \(filters.minBedrooms) BR")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            HStack(spacing: 8) {
                Label(filters.commutePriority.description, systemImage: "figure.walk")
                    .font(.caption)
                    .padding(8)
                    .background(Color(.systemGray6), in: Capsule())
                
                if filters.allowPets {
                    Label("Pets welcome", systemImage: "pawprint.fill")
                        .font(.caption)
                        .padding(8)
                        .background(Color(.systemGray6), in: Capsule())
                }
                
                ForEach(Array(filters.mustHaveAmenities.prefix(2)), id: \.self) { amenity in
                    Label(amenity.label, systemImage: amenity.icon)
                        .font(.caption)
                        .padding(8)
                        .background(Color(.systemGray6), in: Capsule())
                }
            }
        }
    }
    
    private func pass(_ listing: RentalListing) {
        guard let index = discoveryQueue.firstIndex(of: listing) else { return }
        dismissed.append(listing)
        discoveryQueue.remove(at: index)
    }
    
    private func favorite(_ listing: RentalListing) {
        guard let index = discoveryQueue.firstIndex(of: listing) else { return }
        if !favorites.contains(listing) {
            favorites.append(listing)
        }
        discoveryQueue.remove(at: index)
    }
}

private struct ListingCardView: View {
    let listing: RentalListing
    
    private let priceFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "CAD"
        return formatter
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(listing.title)
                        .font(.title3.weight(.semibold))
                    Text(listing.neighborhood)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text(priceFormatter.string(from: NSNumber(value: listing.pricePerMonth)) ?? "$0")
                        .font(.headline)
                    Text("/month")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            HStack(spacing: 12) {
                Label("\(listing.bedrooms) bd", systemImage: "bed.double.fill")
                Label(String(format: "%.1f ba", listing.bathrooms), systemImage: "shower")
                Label("\(listing.walkTimeToCampusMinutes) min walk", systemImage: "figure.walk")
            }
            .font(.caption.weight(.medium))
            .foregroundStyle(.secondary)
            
            HStack(spacing: 8) {
                ForEach(listing.amenities.prefix(4), id: \.self) { amenity in
                    Label(amenity.label, systemImage: amenity.icon)
                        .font(.caption2)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .background(Color(.systemGray6), in: Capsule())
                }
            }
            
            HStack {
                Label(String(format: "%.1f", listing.rating), systemImage: "star.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.yellow)
                
                if listing.isVerified {
                    Label("Verified", systemImage: "checkmark.seal.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.green)
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 12, y: 8)
    }
}

private struct FavoriteListingRow: View {
    let listing: RentalListing
    let formatter: NumberFormatter
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: listing.photoNames[0])
                .resizable()
                .scaledToFit()
                .frame(width: 44, height: 44)
                .padding(12)
                .background(Color(.systemGray5), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(listing.title)
                    .font(.headline)
                Text(listing.neighborhood)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(formatter.string(from: NSNumber(value: listing.pricePerMonth)) ?? "$0")
                    .font(.subheadline.weight(.semibold))
                Text("Tour slots open")
                    .font(.caption)
                    .foregroundColor(.green)
            }
        }
        .padding(16)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 4)
    }
}

private struct RoommateMatchCard: View {
    let match: RoommateMatch
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(match.name)
                        .font(.headline)
                    Text(match.major)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Label("\(match.matchScore)%", systemImage: "heart.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.pink)
            }
            
            Text("Shared interests: \(match.interests.joined(separator: ", "))")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            ProgressView(value: Double(match.matchScore) / 100.0)
                .tint(.pink)
        }
        .padding(16)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 4)
    }
}

private struct ViewingRequestCard: View {
    let request: ViewingRequest
    
    private let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(request.propertyTitle)
                    .font(.headline)
                Spacer()
                statusBadge
            }
            
            Label("Host: \(request.landlordName)", systemImage: "person.crop.circle")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Label(formatter.string(from: request.scheduledFor), systemImage: "calendar")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Label("Coordinating via \(request.communicationChannel)", systemImage: "bubble.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 4)
    }
    
    private var statusBadge: some View {
        Text(request.status.rawValue)
            .font(.caption.weight(.semibold))
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(badgeColor.opacity(0.15), in: Capsule())
            .foregroundColor(badgeColor)
    }
    
    private var badgeColor: Color {
        switch request.status {
        case .pendingConfirmation:
            return .orange
        case .confirmed:
            return .green
        case .rescheduleSuggested:
            return .purple
        }
    }
}

private struct ListingDetailSheet: View {
    let listing: RentalListing
    
    private let priceFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "CAD"
        return formatter
    }()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(listing.title)
                            .font(.title2.weight(.semibold))
                        Text(listing.neighborhood)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(priceFormatter.string(from: NSNumber(value: listing.pricePerMonth)) ?? "$0")
                            .font(.title3.weight(.bold))
                        Text("per month")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                HStack(spacing: 16) {
                    Label("\(listing.bedrooms) bedrooms", systemImage: "bed.double")
                    Label(String(format: "%.1f baths", listing.bathrooms), systemImage: "shower")
                    Label("\(listing.walkTimeToCampusMinutes) min walk", systemImage: "figure.walk")
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Amenities")
                        .font(.headline)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                        ForEach(listing.amenities, id: \.self) { amenity in
                            HStack {
                                Image(systemName: amenity.icon)
                                Text(amenity.label)
                                    .font(.subheadline)
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                    }
                }
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Verification & Ratings")
                        .font(.headline)
                    
                    HStack(spacing: 12) {
                        Label(String(format: "%.1f / 5", listing.rating), systemImage: "star.fill")
                            .foregroundColor(.yellow)
                        
                        if listing.isVerified {
                            Label("Verified by RentSwipe", systemImage: "checkmark.seal.fill")
                                .foregroundColor(.green)
                        } else {
                            Label("Pending verification", systemImage: "clock")
                                .foregroundColor(.orange)
                        }
                    }
                }
            }
            .padding(24)
        }
        .presentationDetents([.medium, .large])
    }
}

private struct TenantFilterSheet: View {
    @Binding var filters: TenantPreferenceProfile
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Budget") {
                    Stepper(value: $filters.maxPrice, in: 1000...4000, step: 50) {
                        Text("Max monthly rent: $\(filters.maxPrice)")
                    }
                }
                
                Section("Layout") {
                    Stepper(value: $filters.minBedrooms, in: 0...5) {
                        Text("Minimum bedrooms: \(filters.minBedrooms)")
                    }
                    Toggle("Pets allowed", isOn: $filters.allowPets)
                }
                
                Section("Commute priority") {
                    Picker("Commute", selection: $filters.commutePriority) {
                        ForEach(TenantPreferenceProfile.CommutePriority.allCases) { priority in
                            Text(priority.description).tag(priority)
                        }
                    }
                    .pickerStyle(.inline)
                }
                
                Section("Must-have amenities") {
                    ForEach(ListingAmenity.allCases) { amenity in
                        Toggle(isOn: Binding(
                            get: { filters.mustHaveAmenities.contains(amenity) },
                            set: { isOn in
                                if isOn {
                                    filters.mustHaveAmenities.insert(amenity)
                                } else {
                                    filters.mustHaveAmenities.remove(amenity)
                                }
                            }
                        )) {
                            Label(amenity.label, systemImage: amenity.icon)
                        }
                    }
                }
            }
            .navigationTitle("Filters")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Reset") {
                        filters = TenantPreferenceProfile()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Landlord Home

struct LandlordHomeView: View {
    @EnvironmentObject private var router: AppRouter
    
    @State private var properties: [LandlordProperty] = SampleData.landlordProperties
    @State private var leads: [TenantLead] = SampleData.tenantLeads
    
    @State private var deeplinkProperty: LandlordProperty?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Listings overview (compact)
                    SectionCard(title: "Listings") {
                        
                        ForEach(properties.prefix(3)) { p in
                            ListingChipRow(
                                title: p.title,
                                statusText: p.status.rawValue,
                                statusColor: color(for: p.status)
                            )
                        }
                        NavigationLink {
                            ListingsListView(properties: properties)
                        } label: {
                            SectionSeeAllRow()
                        }
                        
                    }
                    
                    // Tenant pipeline (max 3)
                    SectionCard(title: "Tenant Pipeline") {
                        VStack(spacing: 12) {
                            ForEach(leads.prefix(3)) { lead in
                                TenantPipelineRow(lead: lead)
                            }
                            NavigationLink {
                                TenantPipelineView(leads: leads)
                            } label: {
                                SectionSeeAllRow()
                            }
                        }
                    }
                }
                .padding(.vertical, 24)
                .padding(.horizontal, 20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Home")
            .onChange(of: router.pendingListingID) { newID in
                guard let id = newID,
                      let property = properties.first(where: { $0.id == id}) else { return }
                deeplinkProperty = property
                router.pendingListingID = nil
            }
            .background(
                NavigationLink(
                    isActive: Binding(
                        get: { deeplinkProperty != nil },
                        set: { isActive in
                            if !isActive {
                                deeplinkProperty = nil
                            }
                        }
                    ),
                    destination: {
                        if let property = deeplinkProperty {
                            ListingFocusView(property: property)
                        } else {
                            EmptyView()
                        }
                    },
                    label: {
                        EmptyView()
                    }
                )
                .hidden()
            )
        }
    }
    
    private func color(for status: LandlordProperty.Status) -> Color {
        switch status {
        case .live:           return .green
        case .pending:        return .orange
        case .needsAttention: return .red
        case .draft:          return .gray
        }
    }
}

// ---- Reusable section shell
private struct SectionCard<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title3.weight(.semibold))
            content
        }
        .padding(16)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 4)
    }
}

private struct SectionSeeAllRow: View {
    var body: some View {
        HStack {
            Spacer()
            Text("See all")
                .font(.subheadline.weight(.semibold))
            Image(systemName: "chevron.right")
                .font(.subheadline.weight(.semibold))
        }
        .foregroundStyle(.tint)
        .padding(.top, 4)
    }
}

// ---- Compact rows for the Home
private struct ListingChipRow: View {
    let title: String
    let statusText: String
    let statusColor: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "house")
                .frame(width: 36, height: 36)
                .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 10))
            Text(title).font(.headline)
            Spacer()
            Text(statusText)
                .font(.caption.weight(.semibold))
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(statusColor.opacity(0.15), in: Capsule())
                .foregroundColor(statusColor)
        }
    }
}

private struct TenantPipelineRow: View {
    let lead: TenantLead
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.circle.fill")
                .font(.title3)
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 2) {
                Text(lead.name).font(.headline)
                // Listing name under the tenant
                Text(lead.listingTitle).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Text(lead.stage.rawValue)
                .font(.caption.weight(.semibold))
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(stageColor(lead.stage).opacity(0.15), in: Capsule())
                .foregroundColor(stageColor(lead.stage))
        }
    }
    
    private func stageColor(_ s: TenantLead.Stage) -> Color {
        switch s {
        case .new:             return .gray
        case .preQualified:    return .blue
        case .scheduledTour:   return .purple
        case .sentApplication: return .green
        }
    }
}

// ---- Drill-down screens

struct ListingsListView: View {
    let properties: [LandlordProperty]
    
    var body: some View {
        List(properties) { p in
            NavigationLink {
                ListingFocusView(property: p)
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(p.title).font(.headline)
                        Text(p.address).font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(p.status.rawValue)
                        .font(.caption.weight(.semibold))
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(color(for: p.status).opacity(0.15), in: Capsule())
                        .foregroundColor(color(for: p.status))
                }
            }
        }
        .navigationTitle("Listings")
    }
    
    private func color(for status: LandlordProperty.Status) -> Color {
        switch status {
        case .live:           return .green
        case .pending:        return .orange
        case .needsAttention: return .red
        case .draft:          return .gray
        }
    }
}

struct ListingFocusView: View {
    let property: LandlordProperty
    @EnvironmentObject private var router: AppRouter
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                analytics
                if let chatID = property.analytics.chatThreadID {
                    chatPreview(chatID: chatID)
                }
                Spacer(minLength: 12)
            }
            .padding()
        }
        .navigationTitle("Listing")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(property.title).font(.title2.weight(.semibold))
            Text(property.address).font(.subheadline).foregroundStyle(.secondary)
            Text(property.status.rawValue)
                .font(.caption.weight(.semibold))
                .padding(.vertical, 4).padding(.horizontal, 8)
                .background(Color(.systemGray5), in: Capsule())
        }
    }
    
    private var analytics: some View {
        HStack(spacing: 12) {
            statChip(label: "Views", value: "\(property.analytics.views)")
            statChip(label: "Favourites", value: "\(property.analytics.favourites)")
            statChip(label: "Chats", value: property.analytics.chatThreadID == nil ? "0" : "1")
        }
    }
    
    private func statChip(label: String, value: String) -> some View {
        VStack {
            Text(value).font(.headline)
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
    }
    
    private func chatPreview(chatID: UUID) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Linked Chat")
                .font(.title3.weight(.semibold))
            
            Button {
                router.openChat(threadID: chatID, fromListing: property.id)
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Tenant Inquiry")
                            .font(.headline)
                        Text("Tap to open in Chats")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.05), radius: 6, y: 3)
            }
        }
        .padding(.top, 8)
    }
}


struct TenantPipelineView: View {
    let leads: [TenantLead]
    
    var body: some View {
        List(leads) { lead in
            NavigationLink {
                TenantFocusView(lead: lead)
            } label: {
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(lead.name).font(.headline)
                        Spacer()
                        Text(lead.stage.rawValue)
                            .font(.caption.weight(.semibold))
                            .padding(.vertical, 3)
                            .padding(.horizontal, 7)
                            .background(stageColor(lead.stage).opacity(0.15), in: Capsule())
                            .foregroundColor(stageColor(lead.stage))
                    }
                    Text(lead.listingTitle).font(.caption).foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Tenant Pipeline")
    }
    
    private func stageColor(_ s: TenantLead.Stage) -> Color {
        switch s {
        case .new:             return .gray
        case .preQualified:    return .blue
        case .scheduledTour:   return .purple
        case .sentApplication: return .green
        }
    }
}

struct TenantFocusView: View {
    @State var lead: TenantLead
    @State private var showAdvanceConfirm = false
    
    private var nextStage: TenantLead.Stage? {
        switch lead.stage {
        case .new:             return .preQualified
        case .preQualified:    return .scheduledTour
        case .scheduledTour:   return .sentApplication
        case .sentApplication: return nil
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                info
                notifications
                pipelineActions
                documents
                chatCTA
            }
            .padding()
        }
        .navigationTitle("Applicant")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(lead.name).font(.title2.weight(.semibold))
            Text(lead.listingTitle).font(.subheadline).foregroundStyle(.secondary)
            Text(lead.stage.rawValue)
                .font(.caption.weight(.semibold))
                .padding(.vertical, 4).padding(.horizontal, 8)
                .background(Color(.systemGray5), in: Capsule())
        }
    }
    
    private var info: some View {
        SectionCard(title: "Information") {
            VStack(alignment: .leading, spacing: 8) {
                row("Email", lead.email)
                row("Target Move-in", DateFormatter.localizedString(from: lead.moveInDate, dateStyle: .medium, timeStyle: .none))
                row("Notes", lead.notes)
            }
        }
    }
    
    private var notifications: some View {
        SectionCard(title: "Notifications") {
            VStack(alignment: .leading, spacing: 8) {
                Text("• New: Uploaded proof of income")
                Text("• Reminder: Tour scheduled next Tuesday at 5:00 PM")
            }
            .font(.subheadline)
        }
    }
    
    private var pipelineActions: some View {
        SectionCard(title: "Pipeline") {
            HStack {
                Text("Current Stage: ").foregroundStyle(.secondary)
                Text(lead.stage.rawValue).font(.headline)
                Spacer()
                Button("Advance") { showAdvanceConfirm = true }
                    .buttonStyle(.borderedProminent)
                    .disabled(nextStage == nil)
            }
            // Confirmation
            .confirmationDialog(
                nextStage != nil
                ? "Advance applicant to “\(nextStage!.rawValue)”?"
                : "Already at final stage",
                isPresented: $showAdvanceConfirm,
                titleVisibility: .visible
            ) {
                if let ns = nextStage {
                    Button("Advance to \(ns.rawValue)") {
                        withAnimation(.easeInOut) { lead.stage = ns }
                    }
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }
    
    
    private var documents: some View {
        SectionCard(title: "Documents") {
            VStack(alignment: .leading, spacing: 8) {
                Button("Review Application (prototype)") {}
                    .buttonStyle(.bordered)
                Button("Send Lease (prototype)") {}
                    .buttonStyle(.bordered)
            }
        }
    }
    
    private var chatCTA: some View {
        SectionCard(title: "Chat") {
            VStack(alignment: .leading, spacing: 8) {
                Button {
                    // Future: deep-link to tenant chat thread
                } label: {
                    Label("Open Tenant Chat", systemImage: "bubble.left.and.bubble.right")
                }
                .buttonStyle(.bordered)
                Text("Note: Chat button is a future quality-of-life feature in this prototype.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
    }
    
    private func row(_ k: String, _ v: String) -> some View {
        HStack {
            Text(k).foregroundStyle(.secondary)
            Spacer()
            Text(v)
        }
    }
    
    private func advanceStage() {
        switch lead.stage {
        case .new:             lead.stage = .preQualified
        case .preQualified:    lead.stage = .scheduledTour
        case .scheduledTour:   lead.stage = .sentApplication
        case .sentApplication: break
        }
    }
}



private struct LandlordPropertyCard: View {
    @Binding var property: LandlordProperty
    
    private let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "CAD"
        return formatter
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(property.title)
                        .font(.headline)
                    Text(property.address)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Menu {
                    ForEach([LandlordProperty.Status.live, .pending, .needsAttention, .draft], id: \.self) { status in
                        Button(status.rawValue) {
                            property.status = status
                        }
                    }
                } label: {
                    StatusBadge(text: property.status.rawValue, color: color(for: property.status))
                }
            }
            
            HStack(spacing: 16) {
                Label("Rent: \(formatter.string(from: NSNumber(value: property.rent)) ?? "$0")", systemImage: "dollarsign")
                Label("Beds: \(property.beds)", systemImage: "bed.double")
                Label(String(format: "%.1f baths", property.baths), systemImage: "shower")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            
            HStack {
                MetricPill(title: "Inquiries", value: "\(property.analytics.inquiriesThisWeek) /wk", color: .teal)
                MetricPill(title: "Favorites", value: "\(property.analytics.favourites)", color: .indigo)
                
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Verification progress")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 10, y: 6)
    }
    
    private func color(for status: LandlordProperty.Status) -> Color {
        switch status {
        case .live:
            return .green
        case .pending:
            return .orange
        case .needsAttention:
            return .red
        case .draft:
            return .gray
        }
    }
}

private struct TenantLeadCard: View {
    @Binding var lead: TenantLead
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(lead.name)
                        .font(.headline)
                    Text(lead.email)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                StatusBadge(text: lead.stage.rawValue, color: stageColor(lead.stage))
            }
            
            Label("Target move-in: \(dateFormatter.string(from: lead.moveInDate))", systemImage: "calendar")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Text(lead.notes)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            HStack {
                Button("Advance Stage") {
                    advanceStage()
                }
                .buttonStyle(.borderedProminent)
                
                Button("Send Follow-up") {
                    // placeholder action
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(18)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 4)
    }
    
    private func advanceStage() {
        switch lead.stage {
        case .new:
            lead.stage = .preQualified
        case .preQualified:
            lead.stage = .scheduledTour
        case .scheduledTour:
            lead.stage = .sentApplication
        case .sentApplication:
            break
        }
    }
    
    private func stageColor(_ stage: TenantLead.Stage) -> Color {
        switch stage {
        case .new:
            return .gray
        case .preQualified:
            return .blue
        case .scheduledTour:
            return .purple
        case .sentApplication:
            return .green
        }
    }
}

private struct VerificationTaskRow: View {
    @Binding var task: VerificationTask
    
    private let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.propertyTitle)
                        .font(.headline)
                    Text("Owner: \(task.ownerName)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Menu {
                    ForEach([VerificationTask.Status.queued, .inProgress, .blocked, .complete], id: \.self) { status in
                        Button(status.rawValue) {
                            task.status = status
                        }
                    }
                } label: {
                    StatusBadge(text: task.status.rawValue, color: statusColor(task.status))
                }
            }
            
            Label("Submitted \(formatter.string(from: task.submittedAt))", systemImage: "clock")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Label(task.taskType.rawValue, systemImage: "doc.text")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Text(task.notes)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 4)
    }
    
    private func statusColor(_ status: VerificationTask.Status) -> Color {
        switch status {
        case .queued:
            return .gray
        case .inProgress:
            return .blue
        case .blocked:
            return .orange
        case .complete:
            return .green
        }
    }
}

private struct StatusBadge: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .padding(.vertical, 4)
            .padding(.horizontal, 10)
            .background(color.opacity(0.15), in: Capsule())
            .foregroundColor(color)
    }
}

private struct MetricPill: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.caption2.weight(.bold))
                .foregroundColor(color)
            Text(value)
                .font(.headline)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - Admin Console

struct AdminConsoleView: View {
    @State private var verificationQueue: [VerificationTask] = SampleData.verificationQueue
    @State private var moderationReports: [ModerationReport] = SampleData.moderationReports
    @State private var featureFlags: [FeatureFlag] = SampleData.featureFlags
    @State private var roommateMatches: [RoommateMatch] = SampleData.roommateMatches
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                verificationSection
                moderationSection
                featureFlagSection
                roommateQualitySection
            }
            .padding(.vertical, 24)
            .padding(.horizontal, 20)
        }
        .background(Color(.systemGroupedBackground))
    }
    
    private var verificationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Verification Ops")
                .font(.title2.weight(.semibold))
            
            VStack(spacing: 12) {
                ForEach($verificationQueue) { $task in
                    VerificationTaskRow(task: $task)
                }
            }
        }
    }
    
    private var moderationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Trust & Safety")
                .font(.title3.weight(.semibold))
            
            VStack(spacing: 12) {
                ForEach($moderationReports) { $report in
                    ModerationReportRow(report: $report)
                }
            }
        }
    }
    
    private var featureFlagSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Feature Flags")
                .font(.title3.weight(.semibold))
            
            ForEach($featureFlags) { $flag in
                Toggle(isOn: $flag.isEnabled) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(flag.name)
                            .font(.headline)
                        Text(flag.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .toggleStyle(SwitchToggleStyle(tint: .orange))
                .padding(12)
                .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: .black.opacity(0.03), radius: 6, y: 3)
            }
        }
    }
    
    private var roommateQualitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Roommate Match QA")
                .font(.title3.weight(.semibold))
            
            Text("Spot-check top matches before enabling for new regions.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            VStack(spacing: 12) {
                ForEach(roommateMatches) { match in
                    RoommateQAResult(match: match)
                }
            }
        }
    }
}

private struct ModerationReportRow: View {
    @Binding var report: ModerationReport
    
    private let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(report.reason)
                    .font(.headline)
                Spacer()
                StatusBadge(text: report.severity.rawValue.capitalized, color: severityColor(report.severity))
            }
            
            Label("Reported by \(report.reportedBy)", systemImage: "person.fill.questionmark")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Text("Submitted \(formatter.string(from: report.submittedAt))")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Toggle("Resolved", isOn: $report.resolved)
                .toggleStyle(SwitchToggleStyle(tint: .green))
        }
        .padding(16)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 4)
    }
    
    private func severityColor(_ severity: ModerationReport.Severity) -> Color {
        switch severity {
        case .low:
            return .gray
        case .medium:
            return .orange
        case .high:
            return .red
        case .critical:
            return .purple
        }
    }
}

private struct RoommateQAResult: View {
    let match: RoommateMatch
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(match.name)
                    .font(.headline)
                Spacer()
                Text("Score: \(match.matchScore)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Text("Review shared interests: \(match.interests.joined(separator: ", "))")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            ProgressView(value: Double(match.matchScore) / 100.0) {
                Text("Confidence")
                    .font(.caption)
            }
            .tint(.orange)
        }
        .padding(16)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.03), radius: 6, y: 3)
    }
}

// MARK: - Profile View
struct ProfileView: View {
    let user: PrototypeUser
    @EnvironmentObject private var sessionStore: PrototypeSessionStore

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 12) {
                // Scrollable content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        profileHeader
                            .padding(.bottom, 4)

                        profileSection
                        accountSection
                        appSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 40) // smaller than before so the gap above Logout is tighter
                }

                // Logout pinned to bottom
                logoutButton
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
            }
        }
    }

    // MARK: - Pieces

    private var profileHeader: some View {
        HStack(alignment: .center, spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color(.secondarySystemBackground))
                    .frame(width: 60, height: 60)

                Image(systemName: "person.fill")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundColor(user.role.accentColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(user.displayName)
                    .font(.title3.weight(.semibold))

                Text(user.role.displayLabel)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)

                Text(user.email)
                    .font(.footnote)
                    .foregroundStyle(.tertiary)
            }

            Spacer()
        }
    }

    private var profileSection: some View {
        ProfileCard(title: "Profile") {
            SettingRow(
                icon: "person.crop.circle",
                title: "Personal information",
                subtitle: "Name, email and contact details"
            )

            Divider().background(Color(.separator))

            SettingRow(
                icon: "house.fill",
                title: "Rental preferences",
                subtitle: "Neighborhood, budget and commute"
            )
        }
    }

    private var accountSection: some View {
        ProfileCard(title: "Account") {
            SettingRow(
                icon: "bell.fill",
                title: "Notifications",
                subtitle: "Push, email and in-app alerts"
            )

            Divider().background(Color(.separator))

            SettingRow(
                icon: "lock.fill",
                title: "Security",
                subtitle: "Password and device sign-ins"
            )

            if user.role == .landlord {
                Divider().background(Color(.separator))

                SettingRow(
                    icon: "creditcard.fill",
                    title: "Payouts & billing",
                    subtitle: "Payout account and invoices"
                )
            }
        }
    }

    private var appSection: some View {
        ProfileCard(title: "App") {
            SettingRow(
                icon: "questionmark.circle",
                title: "Help & support",
                subtitle: "FAQ and contact support"
            )

            Divider().background(Color(.separator))

            SettingRow(
                icon: "info.circle",
                title: "About RentSwipe",
                subtitle: "Version, terms and privacy"
            )
        }
    }

    private var logoutButton: some View {
        Button {
            sessionStore.logout()
        } label: {
            Text("Log out")
                .font(.headline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color(.secondarySystemBackground))
                )
                .foregroundColor(.red)
        }
    }
}

// MARK: - Shared UI for Profile

struct ProfileCard<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)

            VStack(spacing: 0) {
                content
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
            )
        }
    }
}

struct SettingRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(.tertiarySystemBackground))
                    .frame(width: 34, height: 34)

                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.subheadline.weight(.semibold))

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 8) // row height, tweak up/down if you want
        .contentShape(Rectangle())
    }
}




// MARK: - Analytics & Notifications

struct AnalyticsOverviewView: View {
    let metrics: [AnalyticsMetric]
    let role: AccountRole
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Real-time health across swipe engagement, trust & safety, and supply.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                VStack(spacing: 16) {
                    ForEach(metrics) { metric in
                        AnalyticsMetricCard(metric: metric)
                    }
                }
                
                focusCallout
            }
            .padding(.vertical, 24)
            .padding(.horizontal, 20)
        }
        .background(Color(.systemGroupedBackground))
    }
    
    @ViewBuilder
    private var focusCallout: some View {
        switch role {
        case .tenant:
            CalloutCard(title: "Your search activity", message: "Favorites syncing across devices and roommate shares coming next.", icon: "sparkles")
        case .landlord:
            CalloutCard(title: "Lead quality", message: "We're surfacing verified students first. Expect higher tour-to-lease conversions.", icon: "person.crop.circle.badge.checkmark")
        case .admin:
            CalloutCard(title: "Trust metrics", message: "Critical alerts will surface here when scam likelihood rises in a district.", icon: "shield.lefthalf.fill")
        }
    }
}

private struct AnalyticsMetricCard: View {
    let metric: AnalyticsMetric
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(metric.title)
                    .font(.headline)
                Spacer()
                deltaBadge
            }
            
            Text(formattedValue)
                .font(.system(size: 28, weight: .bold, design: .rounded))
            
            ProgressView(value: normalizedValue)
                .tint(metric.delta >= 0 ? .green : .red)
        }
        .padding(20)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 4)
    }
    
    private var formattedValue: String {
        if metric.unit == "rate" {
            return String(format: "%.0f%%", metric.value * 100)
        } else if metric.unit == "hours" {
            return String(format: "%.1f hrs", metric.value)
        } else {
            return String(format: "%.0f", metric.value)
        }
    }
    
    private var normalizedValue: Double {
        switch metric.unit {
        case "rate":
            return min(max(metric.value, 0.0), 1.0)
        case "hours":
            return min(max(1.0 - metric.value / 24.0, 0.0), 1.0)
        default:
            return min(metric.value / 1500.0, 1.0)
        }
    }
    
    private var deltaBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: metric.delta >= 0 ? "arrow.up" : "arrow.down")
            Text(String(format: "%.0f%%", abs(metric.delta) * 100))
        }
        .font(.caption.weight(.semibold))
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background((metric.delta >= 0 ? Color.green : Color.red).opacity(0.15), in: Capsule())
        .foregroundColor(metric.delta >= 0 ? .green : .red)
    }
}

private struct CalloutCard: View {
    let title: String
    let message: String
    let icon: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.accentColor)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.headline)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(18)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.03), radius: 6, y: 3)
    }
}

struct NotificationCenterView: View {
    let role: AccountRole
    @Binding var notifications: [AppNotification]
    
    private let relativeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter
    }()
    
    var body: some View {
        List {
            Section(header: Text("\(role.displayLabel) updates")) {
                ForEach($notifications) { $notification in
                    NotificationRow(notification: $notification, formatter: relativeFormatter)
                }
            }
            
            Section("Actions") {
                Button("Mark all as read") {
                    for index in notifications.indices {
                        notifications[index].isRead = true
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .overlay(alignment: .topLeading) {
            if notifications.isEmpty {
                Text("Inbox is quiet — we'll nudge you when there's activity.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding()
            }
        }
    }
}

private struct NotificationRow: View {
    @Binding var notification: AppNotification
    let formatter: RelativeDateTimeFormatter
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(notification.isCritical ? .red : .accentColor)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(notification.title)
                        .font(.headline)
                    Spacer()
                    Text(formatter.localizedString(for: notification.timestamp, relativeTo: Date()))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Text(notification.message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                if !notification.isRead {
                    Button("Mark as read") {
                        notification.isRead = true
                    }
                    .font(.caption)
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    private var icon: String {
        switch notification.category {
        case .swipe:
            return "hand.tap.fill"
        case .system:
            return "gearshape.fill"
        case .alert:
            return "exclamationmark.triangle.fill"
        }
    }
}
