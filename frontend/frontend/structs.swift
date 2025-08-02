//
//  structs.swift
//  frontend
//
//  Created by Jayden Zhang on 8/1/25.
//

import Foundation
import MapKit

// BELOW HAS STRUCTS AND ENUMS FOR THE DIFF DATA TYPES //

public struct SelectedStore {
    var mapItem: MKMapItem
    var details: StoreDetails
}

public struct storeItem {
    var name: String
    var brand: String
    var price: Double
    var quantity: Int
}

public enum DealType {
    case percentageOff(Int)
    case buyXGetYPercentOff(Int, Int)
    case buyXGetY(Int, Int)
}

public struct Deals {
    var type: DealType
    var category: String
    var itemsAppliedTo: [storeItem]
    var description: String
}

public struct StoreDetails {
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
public struct lists {
    var itemsInList: [storeItems] = []
}

public struct storeItems {
    // Add your store items structure here
}

public struct fame {
    var followers: Int
    var following: Int
    var listOfFollowersIDs: [Int]
    var listOfFollowingIDs: [Int] // Fixed the duplicate variable name
}

public struct userProfile {
    var username: String
    var profileID: Int
    var profilePic: String
    var subscribed: Bool
    var savedRecipes: [Int] // id's of the recipes
    var personalLists: [lists]
    var savedReviews: [(Double, String, MKMapItem)] // rating, review text, location
    var aiGeneratedLists: [lists]
    var fameStats: fame
}
