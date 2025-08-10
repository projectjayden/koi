//
//  structs.swift
//  frontend
//
//  Created by Jayden Zhang on 8/1/25.
//

import Foundation
import MapKit

// BELOW HAS STRUCTS AND ENUMS FOR THE DIFF ERRORS //

public struct LoginRequest: Codable {
    let email: String
    let password: String
}

struct SignUpRequest: Codable {
    let email: String
    let password: String
    let name: String
    let bio: String?
    
    init(email: String, password: String, name: String, bio: String?) {
        self.email = email
        self.password = password
        self.name = name
        self.bio = bio?.isEmpty == true ? nil : bio
    }
}

public enum AuthError: Error, LocalizedError {
    case invalidURL
    case noData
    case invalidCredentials
    case emailAlreadyExists
    case passwordTooWeak
    case serverError
    case networkError(Error)
    case decodingError
    
    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid server URL"
        case .noData:
            return "No data received from server"
        case .invalidCredentials:
            return "Invalid email or password"
        case .emailAlreadyExists:
            return "An account with this email already exists"
        case .passwordTooWeak:
            return "Password is too weak. Please choose a stronger password"
        case .serverError:
            return "Server error occurred"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError:
            return "Failed to process server response"
        }
    }
}

public struct LoginResponse: Codable {
    let token: String
    let user: UserInfo
    
    // Custom initializer to handle the array format [token, {User: userInfo}]
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        
        // First element is the token string
        token = try container.decode(String.self)
        
        // Second element is an object with a "User" key
        let userContainer = try container.decode([String: UserInfo].self)
        guard let userInfo = userContainer["User"] else {
            throw DecodingError.keyNotFound(
                CodingKeys.user,
                DecodingError.Context(codingPath: container.codingPath, debugDescription: "User key not found")
            )
        }
        user = userInfo
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(token)
        try container.encode(["User": user])
    }
    
    private enum CodingKeys: String, CodingKey {
        case token, user
    }
}

struct SignUpResponse: Codable {
    let token: String
}

// BELOW HAS STRUCTS AND ENUMS FOR THE DIFF DATA TYPES //

public struct SelectedStore {
    var mapItem: MKMapItem
    var details: StoreDetails
}

public struct storeItem: Codable {
    var name: String
    var brand: String
    var price: Double
    var quantity: Int
}

public enum DealType: Codable {
    case percentageOff(Int)
    case buyXGetYPercentOff(Int, Int)
    case buyXGetY(Int, Int)
}

public struct Deals: Codable {
    var type: DealType
    var category: String
    var itemsAppliedTo: [storeItem]
    var description: String
}

public struct StoreDetails: Codable {
    var storeTitle: String
    var storeDescription: String
    var storeRating: Double
    var storeAddress: String
    var storeImages: [String] // Changed to String URLs for mock data
    var storeDeals: [Deals] // Changed to array for multiple deals
    var itemList: [storeItem]
    var storeHours: String
    var phoneNumber: String
}

// Updated data structures
public struct lists: Codable {
    var itemsInList: [storeItems] = []
}

public struct storeItems: Codable {
    // Add your store items structure here
}

struct UserFameInfo: Codable {
    let uuid: String
    let name: String
    let bio: String?
    let isSubscribed: Bool
    let followers: Int
    let following: Int
    
    enum CodingKeys: String, CodingKey {
        case uuid
        case name
        case bio
        case isSubscribed = "is_subscribed"
        case followers
        case following
    }
}

public struct UserProfileResponse {
    let user: UserInfo?
    let reviews: [UserReview]
    let recipes: [Recipes]
    
    init(user: UserInfo?, reviews: [UserReview]?, recipes: [Recipes]?) {
        self.user = user
        self.reviews = reviews ?? []
        self.recipes = recipes ?? []
    }
}

struct Cart: Codable {
    var ingredients: [String]
    
    static let empty = Cart(ingredients: [])
}

public struct RecipesResponse: Codable {
    let totalRecipes: Int
    let recipes: [Recipes]
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        totalRecipes = try container.decode(Int.self)
        recipes = try container.decode([Recipes].self)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(totalRecipes)
        try container.encode(recipes)
    }
}

struct RecipeResponse: Codable {
    let total: Int
    let recipe: [Meal]
    
    public init (from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        total = try container.decode(Int.self)
        recipe = try container.decode([Meal].self)
    }
}
        
public struct UserInfo: Codable {
    let uuid: String
    let name: String
    let bio: String
    let email: String
    let lastLogin: Int
    let dateJoined: Int
    let storeId: Int?
    let isSubscribed: Bool
    let preferences: [String]
    let allergies: [String]
    let followers: Int
    let following: Int
    
    enum CodingKeys: String, CodingKey {
        case uuid
        case name
        case bio
        case email
        case lastLogin = "last_login"
        case dateJoined = "date_joined"
        case storeId = "store_id"
        case isSubscribed = "is_subscribed"
        case preferences
        case allergies
        case followers
        case following
    }
}

public struct UserReview: Codable {
    let userUuid: String
    let storeUuid: String
    let rating: Double
    let description: String
    
    enum CodingKeys: String, CodingKey {
        case userUuid = "user_uuid"
        case storeUuid = "store_uuid"
        case rating
        case description
    }
}

public struct Ingredient: Codable {
    let name: String
    let amount: Int
    let unit: String
}

public struct Recipes: Codable {
    let uuid: String
    let userUuid: String
    let name: String
    let ingredients: [Ingredient]
    let category: String?
    let image: String?
    
    enum CodingKeys: String, CodingKey {
        case uuid
        case userUuid = "user_uuid"
        case name
        case ingredients
        case category
        case image
    }
}

// RUST RESPONSES STRUCT //

public struct EmptyResponse: Codable {
    // Empty struct for 200 success responses with no body
}

public struct UpdateProfileRequest: Codable {
    let name: String?
    let bio: String?
    let email: String?
    let allergies: [String]?
    let preferences: [String]? // Add this
    
    init(name: String? = nil, bio: String? = nil, email: String? = nil, allergies: [String]? = nil, preferences: [String]? = nil, dealAlertActive: Bool? = nil, dealAlertRadius: Double? = nil) {
        self.name = name
        self.bio = bio?.isEmpty == true ? nil : bio
        self.email = email?.isEmpty == true ? nil : email
        self.allergies = allergies
        self.preferences = preferences
    }
    
    enum CodingKeys: String, CodingKey {
        case name, bio, email, allergies, preferences
    }
}

public struct GetRecipesRequest: Codable {
    let uuid: String
    let type: Int
    let limit: Int
    let offset: Int
}

public struct ReviewsResponse: Codable {
    let totalReviews: Int
    let reviews: [UserReview]
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        totalReviews = try container.decode(Int.self)
        reviews = try container.decode([UserReview].self)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(totalReviews)
        try container.encode(reviews)
    }
}

public struct FameResponse: Codable {
    let total: Int
    let users: [UserFameInfo]
    
    // Custom initializer to handle tuple-like array format
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        total = try container.decode(Int.self)
        users = try container.decode([UserFameInfo].self)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(total)
        try container.encode(users)
    }
}

struct CreateRecipeRequest: Codable {
    let name: String
    let ingredients: [IngredientRequest]
    let instructions: String?
    let category: String?
    let image: String?
    
    struct IngredientRequest: Codable {
        let name: String
        let amount: Double
        let unit: String
    }
}

// Store Side for Maps //

// Backend API request struct
public struct StoreLookupRequest: Codable {
    let geolocation: String?
    let getStoreInfo: Bool
    let getItems: Bool
    let getDeals: Bool
    let getReviews: Bool
    let reviewLimit: Int?
    let reviewOffset: Int?
    
    enum CodingKeys: String, CodingKey {
        case geolocation
        case getStoreInfo = "get_store_info"
        case getItems = "get_items"
        case getDeals = "get_deals"
        case getReviews = "get_reviews"
        case reviewLimit = "review_limit"
        case reviewOffset = "review_offset"
    }
}

// Backend API response structs
public struct BackendStoreInfo: Codable {
    let uuid: String
    let name: String
    let description: String?
    let latitude: Double
    let longitude: Double
    let phone: String?
    let email: String?
    let openHours: [[String]]?
    
    enum CodingKeys: String, CodingKey {
        case uuid, name, description, latitude, longitude, phone, email
        case openHours = "open_hours"
    }
}

public struct BackendItem: Codable {
    let uuid: String
    let name: String
    let price: Double
    let manufacturer: String?
    let inStock: Bool
    let storeUuid: String
    let dealUuid: String?
    let image: String?
    
    enum CodingKeys: String, CodingKey {
        case uuid, name, price, manufacturer, image
        case inStock = "in_stock"
        case storeUuid = "store_uuid"
        case dealUuid = "deal_uuid"
    }
}

public struct BackendDeal: Codable {
    let uuid: String
    let storeUuid: String
    let name: String
    let description: String?
    let startDate: Int
    let endDate: Int
    let type: Int
    let value1: Double
    let value2: Double?
    
    enum CodingKeys: String, CodingKey {
        case uuid, name, description, type
        case storeUuid = "store_uuid"
        case startDate = "start_date"
        case endDate = "end_date"
        case value1 = "value_1"
        case value2 = "value_2"
    }
}

public struct StoreLookupResponse: Codable {
    let store: BackendStoreInfo?
    let items: [BackendItem]?
    let deals: [BackendDeal]?
    let reviews: [UserReview]? // Using your existing UserReview struct
    let totalReviews: Int?
    
    enum CodingKeys: String, CodingKey {
        case store, items, deals, reviews
        case totalReviews = "total_reviews"
    }
}

// For the t5 Model //

struct ChatMessage: Identifiable, Codable {
    let id: UUID
    let text: String
    let isFromUser: Bool
    let timestamp: Date
    
    init(text: String, isFromUser: Bool) {
        self.id = UUID()
        self.text = text
        self.isFromUser = isFromUser
        self.timestamp = Date()
    }
    
    // Custom initializer for decoding
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.text = try container.decode(String.self, forKey: .text)
        self.isFromUser = try container.decode(Bool.self, forKey: .isFromUser)
        self.timestamp = try container.decodeIfPresent(Date.self, forKey: .timestamp) ?? Date()
    }
}

struct ChatSession {
    let sessionId: UUID
    var messages: [ChatMessage] = []
}

// MARK: - API Models
struct StartChatResponse: Codable {
    let session_id: String
}

struct ChatMessageRequest: Codable {
    let message: String
}

struct ChatMessageResponse: Codable {
    let response: String
    let session_id: String
}


