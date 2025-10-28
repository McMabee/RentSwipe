import SwiftUI
@MainActor
final class PrototypeSessionStore: ObservableObject {
    @Published private(set) var currentUser: PrototypeUser?

    private let authService: PrototypeAuthenticating

    init(authService: PrototypeAuthenticating = PrototypeLocalAuthService()) {
        self.authService = authService
    }

    func login(email: String, password: String, role: AccountRole) throws {
        currentUser = try authService.authenticate(email: email, password: password, role: role)
    }

    func logout() {
        currentUser = nil
    }
}

@available(iOS 16.4, *)
@main
struct RentSwipeApp: App {
    @StateObject private var sessionStore = PrototypeSessionStore()

    @State private var showSplash: Bool = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                if showSplash {
                    SplashView(finished: splashFinishedBinding)
                        .transition(.opacity)
                        .zIndex(1)
                }
                else if sessionStore.currentUser == nil {
                    LoginEntryView()
                        .environmentObject(sessionStore)
                }
                else {
                    // user is logged in
                    PrototypeHomeView(user: sessionStore.currentUser!)
                        .environmentObject(sessionStore)
                }
            }
        }
    }
    
    private var splashFinishedBinding: Binding<Bool> {
        Binding(
            get: { !showSplash },
            set: { newFinished in
                if newFinished {
                    withAnimation(.easeOut(duration: 0.4)) {
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
    let user: PrototypeUser

    @State private var notifications: [AppNotification] = SampleData.notifications

    var body: some View {
        TabView {
            if user.role == .tenant {
                NavigationStack{
                    SwipeDiscoveryView(listings: SampleData.tenantListings)
                        .navigationTitle("Discover")
                        .toolbar{ logoutToolbar }
                }
            }
            NavigationStack {
                roleDashboard
                    .navigationTitle(workspaceTitle)
                    .toolbar { logoutToolbar }
            }
            .tabItem {
                Label("Workspace", systemImage: "sparkles")
            }

            NavigationStack {
                AnalyticsOverviewView(metrics: SampleData.analytics, role: user.role)
                    .navigationTitle("Analytics")
                    .toolbar { logoutToolbar }
            }
            .tabItem {
                Label("Analytics", systemImage: "chart.bar.xaxis")
            }

            NavigationStack {
                NotificationCenterView(role: user.role, notifications: $notifications)
                    .navigationTitle("Inbox")
                    .toolbar { logoutToolbar }
            }
            .tabItem {
                Label("Inbox", systemImage: notifications.contains(where: { !$0.isRead }) ? "bell.badge.fill" : "bell")
            }
        }
    }

    private var workspaceTitle: String {
        switch user.role {
        case .tenant:
            return "Tenant Workspace"
        case .landlord:
            return "Landlord Console"
        case .admin:
            return "Admin Control"
        }
    }

    @ToolbarContentBuilder
    private var logoutToolbar: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button(role: .destructive) {
                sessionStore.logout()
            } label: {
                Label("Log Out", systemImage: "rectangle.portrait.and.arrow.right")
            }
        }
    }

    @ViewBuilder
    private var roleDashboard: some View {
        switch user.role {
        case .tenant:
            TenantDashboardView()
        case .landlord:
            LandlordConsoleView()
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
        formatter.currencyCode = "USD"
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
        formatter.currencyCode = "USD"
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

// MARK: - Landlord Console

struct LandlordConsoleView: View {
    @State private var properties: [LandlordProperty] = SampleData.landlordProperties
    @State private var leads: [TenantLead] = SampleData.tenantLeads
    @State private var verificationTasks: [VerificationTask] = SampleData.verificationQueue

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                portfolioSection
                leadsSection
                complianceSection
            }
            .padding(.vertical, 24)
            .padding(.horizontal, 20)
        }
        .background(Color(.systemGroupedBackground))
    }

    private var portfolioSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Portfolio Performance")
                    .font(.title2.weight(.semibold))
                Spacer()
                Text("Avg. response time: 2.1 hrs")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 16) {
                ForEach($properties) { $property in
                    LandlordPropertyCard(property: $property)
                }
            }
        }
    }

    private var leadsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Tenant Pipeline")
                .font(.title3.weight(.semibold))

            VStack(spacing: 14) {
                ForEach($leads) { $lead in
                    TenantLeadCard(lead: $lead)
                }
            }
        }
    }

    private var complianceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Verification & Compliance")
                .font(.title3.weight(.semibold))

            Text("Track verification progress to keep listings at the top of tenant searches.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            VStack(spacing: 12) {
                ForEach($verificationTasks) { $task in
                    VerificationTaskRow(task: $task)
                }
            }
        }
    }
}

private struct LandlordPropertyCard: View {
    @Binding var property: LandlordProperty

    private let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
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
                MetricPill(title: "Inquiries", value: "\(property.inquiriesThisWeek) /wk", color: .teal)
                MetricPill(title: "Favorites", value: "\(property.favorites)", color: .indigo)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Verification progress")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                ProgressView(value: property.verificationProgress)
                    .tint(.green)
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
