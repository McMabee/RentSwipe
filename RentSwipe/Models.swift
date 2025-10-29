import Foundation
import SwiftUI

// High-level account roles supported in the prototype experience.
enum AccountRole: String, CaseIterable, Identifiable {
    case tenant
    case landlord
    case admin

    var id: String { rawValue }

    var title: String {
        switch self {
        case .tenant:
            return "Tenant Login"
        case .landlord:
            return "Landlord Login"
        case .admin:
            return "Admin Console"
        }
    }

    var message: String {
        switch self {
        case .tenant:
            return "Access personalized listings, save favorites, and connect with landlords."
        case .landlord:
            return "List properties, review applicants, and manage tenant communications."
        case .admin:
            return "Verify listings, moderate reports, and manage feature rollouts."
        }
    }

    var primaryActionLabel: String {
        switch self {
        case .tenant:
            return "Continue as Tenant"
        case .landlord:
            return "Continue as Landlord"
        case .admin:
            return "Continue to Admin"
        }
    }

    var displayLabel: String {
        switch self {
        case .tenant:
            return "Tenant"
        case .landlord:
            return "Landlord"
        case .admin:
            return "Admin"
        }
    }

    var accentColor: Color {
        switch self {
        case .tenant:
            return .indigo
        case .landlord:
            return .teal
        case .admin:
            return .orange
        }
    }
}

struct PrototypeUser: Identifiable, Equatable {
    let id = UUID()
    let email: String
    let displayName: String
    let role: AccountRole
}

// MARK: - Tenant domain models

struct RentalListing: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let neighborhood: String
    let pricePerMonth: Double
    let bedrooms: Int
    let bathrooms: Double
    let walkTimeToCampusMinutes: Int
    let amenities: [ListingAmenity]
    let rating: Double
    let isVerified: Bool
    
    let photoNames: [String]
}

enum ListingAmenity: String, CaseIterable, Identifiable, Hashable{
    case furnished
    case utilitiesIncluded
    case laundryInUnit
    case petsAllowed
    case parking
    case gym
    case studyLounge

    var id: String { rawValue }

    var label: String {
        switch self {
        case .furnished:
            return "Furnished"
        case .utilitiesIncluded:
            return "Utilities"
        case .laundryInUnit:
            return "Laundry"
        case .petsAllowed:
            return "Pets"
        case .parking:
            return "Parking"
        case .gym:
            return "Gym"
        case .studyLounge:
            return "Study Lounge"
        }
    }

    var icon: String {
        switch self {
        case .furnished:
            return "bed.double.fill"
        case .utilitiesIncluded:
            return "bolt.fill"
        case .laundryInUnit:
            return "washer"
        case .petsAllowed:
            return "pawprint.fill"
        case .parking:
            return "car.fill"
        case .gym:
            return "figure.strengthtraining.traditional"
        case .studyLounge:
            return "books.vertical.fill"
        }
    }
}

struct TenantPreferenceProfile {
    var maxPrice: Int = 2200
    var minBedrooms: Int = 1
    var commutePriority: CommutePriority = .walk
    var mustHaveAmenities: Set<ListingAmenity> = [.laundryInUnit, .utilitiesIncluded]
    var allowPets: Bool = true

    enum CommutePriority: String, CaseIterable, Identifiable {
        case walk
        case transit
        case parking

        var id: String { rawValue }

        var description: String {
            switch self {
            case .walk:
                return "Prefer walking distance"
            case .transit:
                return "Near transit stops"
            case .parking:
                return "Require parking availability"
            }
        }
    }
}

struct RoommateMatch: Identifiable {
    let id = UUID()
    let name: String
    let major: String
    let matchScore: Int
    let interests: [String]
}

struct ViewingRequest: Identifiable {
    enum Status: String {
        case pendingConfirmation = "Pending Confirmation"
        case confirmed = "Confirmed"
        case rescheduleSuggested = "Reschedule Suggested"
    }

    let id = UUID()
    let propertyTitle: String
    let landlordName: String
    let scheduledFor: Date
    var status: Status
    let communicationChannel: String
}

// MARK: - Landlord domain models

struct LandlordProperty: Identifiable {
    enum Status: String {
        case draft = "Draft"
        case pending = "Pending Review"
        case live = "Live"
        case needsAttention = "Needs Attention"
    }

    let id = UUID()
    let title: String
    let address: String
    let rent: Int
    let beds: Int
    let baths: Double
    var status: Status
    var inquiriesThisWeek: Int
    var favorites: Int
    var verificationProgress: Double
}

struct TenantLead: Identifiable {
    enum Stage: String {
        case new = "New"
        case preQualified = "Pre-qualified"
        case scheduledTour = "Tour Scheduled"
        case sentApplication = "Application Sent"
    }

    let id = UUID()
    let name: String
    let email: String
    let moveInDate: Date
    var stage: Stage
    let notes: String
    let listingTitle: String
}

// MARK: - Admin domain models

struct VerificationTask: Identifiable {
    enum TaskType: String {
        case documentReview = "Document Review"
        case listingAudit = "Listing Audit"
        case appeal = "Appeal"
    }

    enum Status: String {
        case queued = "Queued"
        case inProgress = "In Progress"
        case blocked = "Blocked"
        case complete = "Complete"
    }

    let id = UUID()
    let propertyTitle: String
    let ownerName: String
    let submittedAt: Date
    var status: Status
    let taskType: TaskType
    let notes: String
}

struct ModerationReport: Identifiable {
    enum Severity: String {
        case low
        case medium
        case high
        case critical
    }

    let id = UUID()
    let reportedBy: String
    let reason: String
    let submittedAt: Date
    var severity: Severity
    var resolved: Bool
}

struct FeatureFlag: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    var isEnabled: Bool
}

// MARK: - Shared models

struct AnalyticsMetric: Identifiable {
    let id = UUID()
    let title: String
    let value: Double
    let delta: Double
    let unit: String
}

enum NotificationCategory: String {
    case swipe
    case system
    case alert
}

struct AppNotification: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let category: NotificationCategory
    let timestamp: Date
    var isCritical: Bool
    var isRead: Bool
}

// MARK: - Sample data used across prototype views

enum SampleData {
    static let roommateMatches: [RoommateMatch] = [
        RoommateMatch(name: "Amina Patel", major: "Computer Science", matchScore: 92, interests: ["Hackathons", "Farmers markets"]),
        RoommateMatch(name: "Leo Martinez", major: "Architecture", matchScore: 88, interests: ["Cycling", "Photography"]),
        RoommateMatch(name: "Sasha Kim", major: "Biology", matchScore: 86, interests: ["Climbing", "Board games"])
    ]

    static let tenantListings: [RentalListing] = [
        RentalListing(
            title: "Modern 2BR Loft",
            neighborhood: "Downtown",
            pricePerMonth: 2150,
            bedrooms: 2,
            bathrooms: 1.5,
            walkTimeToCampusMinutes: 8,
            amenities: [.furnished, .laundryInUnit, .utilitiesIncluded, .studyLounge],
            rating: 4.8,
            
            isVerified: true,
            
            photoNames: ["jacob-1", "jacob-2", "jacob-3"]
        ),
        RentalListing(
            title: "Sunny Studio",
            neighborhood: "East Lake",
            pricePerMonth: 1650,
            bedrooms: 1,
            bathrooms: 1,
            walkTimeToCampusMinutes: 12,
            amenities: [.furnished, .utilitiesIncluded, .gym],
            rating: 4.5,
            isVerified: true,
            
            photoNames: ["loft-1", "loft-2", "loft-3"]
        ),
        RentalListing(
            title: "3BR Townhome",
            neighborhood: "North Campus",
            pricePerMonth: 2450,
            bedrooms: 3,
            bathrooms: 2,
            walkTimeToCampusMinutes: 5,
            amenities: [.parking, .laundryInUnit, .petsAllowed],
            rating: 4.9,
            isVerified: false,
            
            photoNames: ["town-1", "town-2", "town-3"]
        )
    ]

    static let landlordProperties: [LandlordProperty] = [
        LandlordProperty(
            title: "Maple Street Flats",
            address: "1845 Maple Street",
            rent: 2300,
            beds: 2,
            baths: 1.5,
            status: .live,
            inquiriesThisWeek: 12,
            favorites: 58,
            verificationProgress: 1.0
        ),
        LandlordProperty(
            title: "Lakeview Apartments",
            address: "902 Lakeview Ave",
            rent: 1950,
            beds: 1,
            baths: 1,
            status: .pending,
            inquiriesThisWeek: 5,
            favorites: 23,
            verificationProgress: 0.65
        ),
        LandlordProperty(
            title: "Campus Row Homes",
            address: "77 Campus Row",
            rent: 2850,
            beds: 3,
            baths: 2,
            status: .needsAttention,
            inquiriesThisWeek: 2,
            favorites: 14,
            verificationProgress: 0.3
        )
    ]

    static let viewingRequests: [ViewingRequest] = [
        ViewingRequest(
            propertyTitle: "Maple Street Flats",
            landlordName: "David Roberts",
            scheduledFor: Calendar.current.date(byAdding: .day, value: 2, to: Date()) ?? Date(),
            status: .confirmed,
            communicationChannel: "In-app chat"
        ),
        ViewingRequest(
            propertyTitle: "Lakeview Apartments",
            landlordName: "Rachel Green",
            scheduledFor: Calendar.current.date(byAdding: .day, value: 4, to: Date()) ?? Date(),
            status: .pendingConfirmation,
            communicationChannel: "Email"
        )
    ]

    static let tenantLeads: [TenantLead] = [
        TenantLead(
            name: "Jessie Lee",
            email: "jessie.lee@mockmail.com",
            moveInDate: Calendar.current.date(byAdding: .day, value: 18, to: Date()) ?? Date(),
            stage: .preQualified,
            notes: "Shared proof of funds. Prefers weekday evening tours.",
            listingTitle: "Maple Street Flats"
        ),
        TenantLead(
            name: "Marcus Grant",
            email: "marcus.grant@mockmail.com",
            moveInDate: Calendar.current.date(byAdding: .day, value: 35, to: Date()) ?? Date(),
            stage: .scheduledTour,
            notes: "Tour booked for next Tuesday at 5pm.",
            listingTitle: "Lakeview Apartments"
        ),
        TenantLead(
            name: "Emily Carter",
            email: "emily.carter@mockmail.com",
            moveInDate: Calendar.current.date(byAdding: .day, value: 60, to: Date()) ?? Date(),
            stage: .new,
            notes: "Interested in Maple Street Flats. Asked about pet policy.",
            listingTitle: "Maple Street Flats"
        )
    ]

    static let verificationQueue: [VerificationTask] = [
        VerificationTask(
            propertyTitle: "Lakeview Apartments",
            ownerName: "Rachel Green",
            submittedAt: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
            status: .queued,
            taskType: .documentReview,
            notes: "Need to confirm updated utility bills."
        ),
        VerificationTask(
            propertyTitle: "Campus Row Homes",
            ownerName: "David Roberts",
            submittedAt: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date(),
            status: .inProgress,
            taskType: .listingAudit,
            notes: "Photos flagged for low lighting, request replacements."
        ),
        VerificationTask(
            propertyTitle: "Hilltop Studios",
            ownerName: "Angela Moss",
            submittedAt: Calendar.current.date(byAdding: .day, value: -5, to: Date()) ?? Date(),
            status: .blocked,
            taskType: .appeal,
            notes: "Awaiting landlord response to documentation request."
        )
    ]

    static let moderationReports: [ModerationReport] = [
        ModerationReport(
            reportedBy: "tenant_482",
            reason: "Listing showed incorrect pricing",
            submittedAt: Calendar.current.date(byAdding: .hour, value: -6, to: Date()) ?? Date(),
            severity: .medium,
            resolved: false
        ),
        ModerationReport(
            reportedBy: "tenant_903",
            reason: "Potential scam: landlord requesting cash deposit",
            submittedAt: Calendar.current.date(byAdding: .hour, value: -30, to: Date()) ?? Date(),
            severity: .high,
            resolved: false
        ),
        ModerationReport(
            reportedBy: "tenant_102",
            reason: "Photo misrepresentation",
            submittedAt: Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date(),
            severity: .low,
            resolved: true
        )
    ]

    static let featureFlags: [FeatureFlag] = [
        FeatureFlag(name: "Roommate Match v2", description: "Improved compatibility scoring & messaging.", isEnabled: true),
        FeatureFlag(name: "Chexy Payments", description: "3rd-party rent collection integration.", isEnabled: false),
        FeatureFlag(name: "AI Listing Insights", description: "LLMs summarize listing pros/cons for tenants.", isEnabled: true)
    ]

    static let analytics: [AnalyticsMetric] = [
        AnalyticsMetric(title: "Daily Active Tenants", value: 1240, delta: 0.12, unit: "users"),
        AnalyticsMetric(title: "Verified Listings", value: 312, delta: 0.08, unit: "listings"),
        AnalyticsMetric(title: "Match-to-Tour Conversion", value: 0.42, delta: -0.03, unit: "rate"),
        AnalyticsMetric(title: "Avg. Response Time", value: 2.4, delta: -0.15, unit: "hours")
    ]

    static let notifications: [AppNotification] = [
        AppNotification(title: "New favorite added", message: "Jessie favorited Maple Street Flats.", category: .swipe, timestamp: Calendar.current.date(byAdding: .minute, value: -22, to: Date()) ?? Date(), isCritical: false, isRead: false),
        AppNotification(title: "Verification needed", message: "Review updated utility docs for Lakeview Apartments.", category: .alert, timestamp: Calendar.current.date(byAdding: .hour, value: -2, to: Date()) ?? Date(), isCritical: true, isRead: false),
        AppNotification(title: "System update", message: "Analytics dashboard will refresh nightly at 2am.", category: .system, timestamp: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(), isCritical: false, isRead: true)
    ]
}
