//
//  homePageView.swift
//  frontend
//
//  Created by Danny Huang on 7/28/25.
//


//MARK: Things to change:
//how recipe carousel gets recipes (API --> just db)
//delete API encoding in Meal struct
//for checking if favorited use uuid instead of name
//don't need to check if already in allRecipe before liking

import Foundation
import SwiftUI

struct homePageView: View {
    
    @StateObject private var viewModel = recipesViewModel()
    @State private var storesWithDeals: [StoreDetails] = []
    @State private var selectedRecipe: Meal?
    @State private var storeDeal: StoreDetails?
    @State private var showingStoreDeal = false
    @State private var likedRecipes: [Meal] = []
    @State private var allRecipes: [Meal] = []
    
    var body: some View {
        VStack {
            headerSection
            
            ScrollView {
                dealsSection
                recipesSection
            }
            .padding(.top, 20)
        }
        .padding(.leading, 10)
        .padding(.trailing, 10)
        .padding(.bottom, 30)
        .onAppear {
                    Task {
                        do {
                            likedRecipes = try await getFavoritedRecipes(type: 1).recipe ?? []
                        } catch {
                            print("Error loading favorites: \(error)")
                            likedRecipes = []
                        }
                        do {
                            allRecipes = try await getAllRecipes() ?? []
                        } catch {
                            print("Error getting all Recipes: \(error)")
                            allRecipes = []
                        }
                        UserDefaults.standard.store(likedRecipes.self, forKey: "likedRecipes")
                        UserDefaults.standard.store(allRecipes.self , forKey: "allRecipes")
                    }
                }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack(alignment: .top) {
            // Name
            ZStack(alignment: .leading) {
                Text("Koi")
                    .font(.system(size: 64))
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(red: 0.3, green: 0.2, blue: 0.6),
                                Color(red: 0.7, green: 0.6, blue: 0.9)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            // Stuff on the Right
            ZStack(alignment: .center) {
                NavigationLink(destination: shopView()) {
                    Image(systemName: "cart")
                        .foregroundColor(Color(red: 0.5, green: 0.4, blue: 0.8))
                    Text("Shop")
                        .foregroundColor(Color(red: 0.5, green: 0.4, blue: 0.8))
                }
            }
            .frame(maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: 60)
    }
    
    // MARK: - Deals Section
    private var dealsSection: some View {
        VStack {
            Text("Awesome Deals Near You")
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(Color(red: 0.5, green: 0.4, blue: 0.8))
            
            dealsScrollView
        }
        .frame(maxWidth: .infinity)
    }
    
    private var dealsScrollView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                ForEach(0..<storesWithDeals.count, id: \.self) { index in
                    dealCard(for: index)
                }
            }
            .frame(maxWidth: .infinity)
            .task {
                loadMockDeals()
            }
        }
        .sheet(isPresented: $showingStoreDeal) {
            if let storeDeal = storeDeal {
                dealView(store: storeDeal)
            }
        }
    }
    
    private func dealCard(for index: Int) -> some View {
        VStack {
            dealCardImage
            
            dealCardInfo(for: index)
        }
        .frame(width: 210, height: 180)
        .cornerRadius(8)
        .onTapGesture {
            storeDeal = storesWithDeals[index]
            showingStoreDeal = true
        }
    }
    
    private var dealCardImage: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(LinearGradient(
                colors: [
                    Color(red: 0.5, green: 0.4, blue: 0.8).opacity(0.3),
                    .blue.opacity(0.4)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ))
            .frame(height: 145)
            .overlay {
                Image(systemName: "fish.fill")
                    .font(.system(size: 24))
                    .foregroundColor(Color(red: 0.5, green: 0.4, blue: 0.8).opacity(0.7))
            }
    }
    
    private func dealCardInfo(for index: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(storesWithDeals[index].storeTitle)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.primary)
                .lineLimit(2)
            
            Text(storesWithDeals[index].storeAddress)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
    }
    
    // MARK: - Recipes Section
    private var recipesSection: some View {
        VStack {
            recipesHeader
            recipesScrollView
        }
    }
    
    private var recipesHeader: some View {
        HStack {
            Text("Find Recipes")
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(Color(red: 0.5, green: 0.4, blue: 0.8))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 50)
    }
    
    private var recipesScrollView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                ForEach(viewModel.recipes, id: \.name) { meal in
                    recipeCard(for: meal)
                }
            }
            .frame(maxWidth: .infinity)
            .task {
                loadRecipes()
            }
        }
        .sheet(item: $selectedRecipe) { meal in
            recipeSheet(recipe: meal, favorites: likedRecipes, allRecipes: allRecipes)
        }
    }
    
    private func recipeCard(for meal: Meal) -> some View {
        ZStack(alignment: .bottomLeading) {
            recipeCardImage(for: meal)
            recipeCardTitle(for: meal)
        }
        .cornerRadius(8)
        .onTapGesture {
            selectedRecipe = meal
        }
    }
    
    private func recipeCardImage(for meal: Meal) -> some View {
        AsyncImage(url: URL(string: meal.image ?? "")) { phase in
            if let image = phase.image {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else if phase.error != nil {
                Image(systemName: "fish.fill")
            } else {
                ProgressView()
            }
        }
        .frame(width: 210, height: 180)
        .cornerRadius(8)
        .clipped()
    }
    
    private func recipeCardTitle(for meal: Meal) -> some View {
        Text(meal.name)
            .foregroundColor(.white)
            .font(.system(size: 15, weight: .bold))
            .lineLimit(2)
            .multilineTextAlignment(.leading)
            .padding(8)
            .frame(maxWidth: 194) // 210 - 16 padding
            .background(
                Color(red: 0.3, green: 0.2, blue: 0.6)
            )
    }
    
    // MARK: - Helper Functions
    private func loadMockDeals() {
        storesWithDeals = []
        for _ in 0..<10 {
            storesWithDeals.append(createMockStoreDetails())
        }
    }
    
    private func loadRecipes() {
        viewModel.fetchMultipleRandomRecipes(count: 10) { recipes in
            viewModel.recipes = recipes
        }
    }
}


// MARK: - Bottom Tabs
struct tabsView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    
    var body: some View{
        TabView {
            NavigationStack {
                homePageView()
            }
                .tabItem {
                    Image(systemName: "house")
                    Text("Home")
                }
            NavigationStack {
                MapView()
            }
                .tabItem{
                    Image(systemName: "map")
                    Text("Map")
                }
            NavigationStack {
                profileView()
            }
                .tabItem {
                    Image(systemName: "gear")
                    Text("Profile")
                }
                .environmentObject(authManager)
        }
        .accentColor(Color(red: 0.4, green: 0.3, blue: 0.7))
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(Color.white)
            
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}


// MARK: - Recipe Stuff
struct mealResponse: Codable {
    let meals: [Meal]
}

struct Meal: Codable, Identifiable {
    let id = UUID()
    var uuid: String?
    let user_uuid: String?
    let created_at: Int?
    let last_updated: Int?
    let name: String
    let ingredients: [(name: String, amount: Double, unit: String)]
    let category: String?
    let image: String?
    
    let instructions: String
    
    // Store raw ingredient and measure data for parsing (only used for external API decoding)
    private let ingredientData: [String?]?
    private let measureData: [String?]?
    
    // Helper struct for encoding/decoding ingredients
    private struct IngredientCodable: Codable {
        let name: String
        let amount: Double
        let unit: String
        
        init(from tuple: (name: String, amount: Double, unit: String)) {
            self.name = tuple.name
            self.amount = tuple.amount
            self.unit = tuple.unit
        }
        
        func toTuple() -> (name: String, amount: Double, unit: String) {
            return (name: name, amount: amount, unit: unit)
        }
    }
    
    // MARK: - Manual Creation Initializer
    init(
        uuid: String? = "",
        user_uuid: String? = "",
        created_at: Int? = nil,
        last_updated: Int? = nil,
        name: String,
        ingredients: [(name: String, amount: Double, unit: String)],
        category: String? = nil,
        image: String? = nil,
        instructions: String
    ) {
        self.uuid = uuid
        self.user_uuid = user_uuid
        self.created_at = created_at
        self.last_updated = last_updated
        self.name = name
        self.ingredients = ingredients
        self.category = category
        self.image = image
        self.instructions = instructions
        
        self.ingredientData = nil
        self.measureData = nil
    }
    
    // MARK: - Coding Keys for both internal and external APIs
    enum CodingKeys: String, CodingKey {
        // External API keys (TheMealDB)
        case strMeal, strCategory, strInstructions, strMealThumb
        // Internal API keys
        case uuid, user_uuid, created_at, last_updated, name, ingredients, category, image, instructions
    }
    
    // MARK: - Custom Decoder (handles both formats)
    init(from decoder: Decoder) throws {
        // Try to decode as internal format first
        if let container = try? decoder.container(keyedBy: CodingKeys.self),
           container.contains(.name) {
            // Internal format decoding
            uuid = try container.decodeIfPresent(String.self, forKey: .uuid)
            user_uuid = try container.decodeIfPresent(String.self, forKey: .user_uuid)
            created_at = try container.decodeIfPresent(Int.self, forKey: .created_at)
            last_updated = try container.decodeIfPresent(Int.self, forKey: .last_updated)
            name = try container.decode(String.self, forKey: .name)
            category = try container.decodeIfPresent(String.self, forKey: .category)
            image = try container.decodeIfPresent(String.self, forKey: .image)
            instructions = try container.decode(String.self, forKey: .instructions)
            
            // Decode ingredients from array of objects
            let ingredientsCodable = try container.decode([IngredientCodable].self, forKey: .ingredients)
            ingredients = ingredientsCodable.map { $0.toTuple() }
            
            ingredientData = nil
            measureData = nil
        } else {
            // External API format decoding (TheMealDB)
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            uuid = nil
            user_uuid = nil
            created_at = nil
            last_updated = nil
            name = try container.decode(String.self, forKey: .strMeal)
            category = try container.decodeIfPresent(String.self, forKey: .strCategory)
            image = try container.decodeIfPresent(String.self, forKey: .strMealThumb)
            instructions = try container.decode(String.self, forKey: .strInstructions)
            
            // Dynamically decode ingredients and measures from external API
            let allKeys = try decoder.container(keyedBy: DynamicCodingKey.self)
            var rawIngredients: [String?] = []
            var rawMeasures: [String?] = []
            
            for i in 1...20 {
                let ingredientKey = DynamicCodingKey(stringValue: "strIngredient\(i)")!
                let measureKey = DynamicCodingKey(stringValue: "strMeasure\(i)")!
                
                let ingredient = try? allKeys.decodeIfPresent(String.self, forKey: ingredientKey)
                let measure = try? allKeys.decodeIfPresent(String.self, forKey: measureKey)
                
                rawIngredients.append(ingredient)
                rawMeasures.append(measure)
            }
            
            ingredientData = rawIngredients
            measureData = rawMeasures
            
            // Parse ingredients into the new tuple format
            ingredients = zip(rawIngredients, rawMeasures).compactMap { ingredient, measure in
                guard let ingredientName = ingredient?.trimmingCharacters(in: .whitespacesAndNewlines),
                      !ingredientName.isEmpty else { return nil }
                
                let cleanMeasure = measure?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                let parsedMeasure = Self.parseMeasure(cleanMeasure)
                
                return (name: ingredientName, amount: parsedMeasure.amount, unit: parsedMeasure.unit)
            }
        }
    }
    
    // MARK: - Custom Encoder (encodes in internal format)
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        // Encode in internal format
        try container.encodeIfPresent(uuid, forKey: .uuid)
        try container.encodeIfPresent(user_uuid, forKey: .user_uuid)
        try container.encodeIfPresent(created_at, forKey: .created_at)
        try container.encodeIfPresent(last_updated, forKey: .last_updated)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(category, forKey: .category)
        try container.encodeIfPresent(image, forKey: .image)
        try container.encode(instructions, forKey: .instructions)
        
        // Convert ingredients tuples to codable format
        let ingredientsCodable = ingredients.map { IngredientCodable(from: $0) }
        try container.encode(ingredientsCodable, forKey: .ingredients)
    }
    
    // Parse measure string into amount and unit
    private static func parseMeasure(_ measureString: String) -> (amount: Double, unit: String) {
        if measureString.isEmpty {
            return (amount: 0.0, unit: "")
        }
        
        // Common patterns to match
        let patterns = [
            // Fractions: "1/2 cup", "3/4 tsp"
            #"^(\d+)/(\d+)\s*(.*)$"#,
            // Mixed fractions: "1 1/2 cups", "2 3/4 tbsp"
            #"^(\d+)\s+(\d+)/(\d+)\s*(.*)$"#,
            // Decimal numbers: "1.5 cups", "0.25 tsp"
            #"^(\d*\.?\d+)\s*(.*)$"#,
            // Whole numbers: "2 cups", "1 tbsp"
            #"^(\d+)\s*(.*)$"#
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []),
               let match = regex.firstMatch(in: measureString, options: [], range: NSRange(location: 0, length: measureString.count)) {
                
                switch pattern {
                case patterns[0]: // Simple fraction
                    let numerator = Double(String(measureString[Range(match.range(at: 1), in: measureString)!])) ?? 0
                    let denominator = Double(String(measureString[Range(match.range(at: 2), in: measureString)!])) ?? 1
                    let unit = String(measureString[Range(match.range(at: 3), in: measureString)!]).trimmingCharacters(in: .whitespaces)
                    return (amount: numerator / denominator, unit: unit)
                    
                case patterns[1]: // Mixed fraction
                    let whole = Double(String(measureString[Range(match.range(at: 1), in: measureString)!])) ?? 0
                    let numerator = Double(String(measureString[Range(match.range(at: 2), in: measureString)!])) ?? 0
                    let denominator = Double(String(measureString[Range(match.range(at: 3), in: measureString)!])) ?? 1
                    let unit = String(measureString[Range(match.range(at: 4), in: measureString)!]).trimmingCharacters(in: .whitespaces)
                    return (amount: whole + (numerator / denominator), unit: unit)
                    
                case patterns[2], patterns[3]: // Decimal or whole number
                    let amount = Double(String(measureString[Range(match.range(at: 1), in: measureString)!])) ?? 0
                    let unit = String(measureString[Range(match.range(at: 2), in: measureString)!]).trimmingCharacters(in: .whitespaces)
                    return (amount: amount, unit: unit)
                    
                default:
                    break
                }
            }
        }
        
        // If no pattern matches, treat as unit only with amount 0
        return (amount: 0.0, unit: measureString.trimmingCharacters(in: .whitespaces))
    }
    
    mutating func setID(ID: String){
        self.uuid = ID
    }
}

// Helper for dynamic key decoding (unchanged)
struct DynamicCodingKey: CodingKey {
    var stringValue: String
    var intValue: Int?
    
    init?(stringValue: String) {
        self.stringValue = stringValue
    }
    
    init?(intValue: Int) {
        return nil
    }
}

class recipesViewModel: ObservableObject {
    @Published var recipes: [Meal] = []
    
    func fetchMultipleRandomRecipes(count: Int, completion: @escaping ([Meal]) -> Void) {
        var results: [Meal] = []
        
        func fetchNext() {
            guard results.count < count else {
                DispatchQueue.main.async {
                    completion(results)
                }
                return
            }
            
            guard let url = URL(string: "https://www.themealdb.com/api/json/v1/1/random.php") else {
                fetchNext()
                return
            }
            
            URLSession.shared.dataTask(with: url) { data, _, _ in
                if let data = data,
                   let decoded = try? JSONDecoder().decode(mealResponse.self, from: data),
                   let meal = decoded.meals.first {
                    results.append(meal)
                }
                fetchNext() // fetch the next one
            }.resume()
        }
        
        fetchNext()
    }
}

struct recipeSheet: View {
    let recipe: Meal
    @State private var isFavorited = false
    @State var favorites: [Meal]
    @State var allRecipes: [Meal] 
    @State private var cartManager = CartManager()
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    
                    // Recipe Header
                    VStack(spacing: 16) {
                        Text(recipe.name) // Updated to use new property
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(Color(red: 0.3, green: 0.2, blue: 0.6))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        AsyncImage(url: URL(string: recipe.image ?? "")) { phase in // Updated to use new property
                            if let image = phase.image {
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(height: 280)
                                    .frame(maxWidth: .infinity)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                            } else if phase.error != nil {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(height: 280)
                                    .overlay(
                                        Image(systemName: "photo")
                                            .font(.system(size: 40))
                                            .foregroundColor(.gray)
                                    )
                            } else {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.gray.opacity(0.1))
                                    .frame(height: 280)
                                    .overlay(
                                        ProgressView()
                                            .scaleEffect(1.2)
                                    )
                            }
                        }
                        .padding(.horizontal)
                        
                        // Category Badge and Favorite Button
                        HStack {
                            if let category = recipe.category { // Updated to handle optional category
                                Label(category, systemImage: "tag.fill")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        Capsule()
                                            .fill(LinearGradient(
                                                colors: [
                                                    Color(red: 0.3, green: 0.2, blue: 0.6),
                                                    Color(red: 0.7, green: 0.6, blue: 0.9)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ))
                                    )
                            }
                            
                            Spacer()
                            
                            // Favorite Button
                            Button(action: toggleFavorite) {
                                Image(systemName: isFavorited ? "heart.fill" : "heart")
                                    .font(.title2)
                                    .foregroundColor(isFavorited ? .red : .gray)
                                    .animation(.easeInOut(duration: 0.2), value: isFavorited)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                        }
                        .padding(.horizontal)
                    }
                    
                    Divider()
                        .padding(.horizontal)
                    
                    // Ingredients Section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "list.bullet.circle.fill")
                                .font(.title2)
                                .foregroundColor(Color(red: 0.3, green: 0.2, blue: 0.6))
                            Text("Ingredients")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Button {
                                addToCart()
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "cart.fill")
                                        .font(.system(size: 16, weight: .semibold))
                                    Text("Add to cart")
                                        .font(.system(size: 17, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: 150)
                                .frame(height: 50)
                                .background {
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(LinearGradient(
                                            colors: [
                                                Color(red: 0.3, green: 0.2, blue: 0.6),
                                                Color(red: 0.5, green: 0.4, blue: 0.8)
                                            ],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        ))
                                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        LazyVStack(alignment: .leading, spacing: 12) {
                            ForEach(recipe.ingredients, id: \.name) { ingredient in // Updated to use new structure
                                HStack(alignment: .top, spacing: 12) {
                                    Circle()
                                        .fill(.blue.opacity(0.2))
                                        .frame(width: 8, height: 8)
                                        .padding(.top, 6)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(ingredient.name)
                                            .font(.body)
                                            .fontWeight(.medium)
                                            .foregroundColor(.primary)
                                        
                                        // Display amount and unit if available
                                        if ingredient.amount > 0 || !ingredient.unit.isEmpty {
                                            let measureText = ingredient.amount > 0 ?
                                                (ingredient.amount.truncatingRemainder(dividingBy: 1) == 0 ?
                                                    "\(Int(ingredient.amount)) \(ingredient.unit)" :
                                                    "\(ingredient.amount) \(ingredient.unit)") :
                                                ingredient.unit
                                            
                                            Text(measureText.trimmingCharacters(in: .whitespaces))
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    
                                    Spacer()
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(UIColor.secondarySystemGroupedBackground))
                        )
                        .padding(.horizontal)
                    }
                    
                    // Instructions Section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "doc.text.fill")
                                .font(.title2)
                                .foregroundColor(Color(red: 0.3, green: 0.2, blue: 0.6))
                            Text("Instructions")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                        }
                        .padding(.horizontal)
                        
                        Text(recipe.instructions)
                            .font(.body)
                            .lineSpacing(4)
                            .foregroundColor(.primary)
                            .padding(.horizontal)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(UIColor.secondarySystemGroupedBackground))
                            )
                            .padding(.horizontal)
                    }
                }
                .padding(.vertical, 24)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.blue)
                }
            }
            .onAppear {
                favorites = UserDefaults.standard.object([Meal].self, forKey:"likedRecipes") ?? []
                allRecipes = UserDefaults.standard.object([Meal].self, forKey:"AllRecipes") ?? []
                isFavorited = favorites.contains(where: { $0.name == recipe.name })
            }
        }
    }
    @State private var isTogglingFavorite = false
    
    private func toggleFavorite() {
        // Prevent multiple simultaneous calls
        guard !isTogglingFavorite else { return }
        
        Task {
            await MainActor.run {
                isTogglingFavorite = true
            }
            
            do {
                if isFavorited {
                    favorites.removeAll { $0.name == recipe.name }
                    UserDefaults.standard.store(favorites.self, forKey: "likedRecipes")
                    if let uuid = recipe.uuid {
                        //try await unlikeRecipe(uuid: uuid)
                    }
                } else {
                    favorites.append(recipe)
                    UserDefaults.standard.store(favorites.self, forKey: "likedRecipes")
                    if !allRecipes.contains(where: { $0.name == recipe.name }) {
                        allRecipes.append(recipe)
                        UserDefaults.standard.store(allRecipes.self , forKey: "allRecipes")
                        //try await createRecipe(recipe: recipe)
                    }
                    if let uuid = recipe.uuid {
                        //try await likeRecipe(uuid: uuid)
                    }
                }
                
                // Update UI on main thread
                await MainActor.run {
                    isFavorited.toggle()
                    isTogglingFavorite = false
                }
            } catch {
                print("Error toggling favorite: \(error)")
                // Reset loading state on error
                await MainActor.run {
                    isTogglingFavorite = false
                }
            }
        }
    }
    
    private func addToCart() {
        cartManager.loadCart()
        recipe.ingredients.forEach { ingredient in
            if !cartManager.contains(ingredient.name) {
                cartManager.cart.ingredients.append(ingredient.name)
            }
        }
        
        cartManager.saveCart()
    }
}

// MARK: Deals

func createMockStoreDetails() -> StoreDetails {
     let sampleItems = [
         storeItem(name: "Organic Bananas", brand: "Fresh Farms", price: 2.99, quantity: 1),
         storeItem(name: "Whole Milk", brand: "Dairy Best", price: 3.49, quantity: 1),
         storeItem(name: "Sourdough Bread", brand: "Baker's Choice", price: 4.99, quantity: 1),
         storeItem(name: "Free Range Eggs", brand: "Happy Hens", price: 5.99, quantity: 12)
     ]
     
     let sampleDeals = [
         Deals(
             type: .percentageOff(20),
             category: "Organic Produce",
             itemsAppliedTo: [sampleItems[0]],
             description: "20% off all organic fruits"
         ),
         Deals(
             type: .buyXGetYPercentOff(2, 50),
             category: "Dairy",
             itemsAppliedTo: [sampleItems[1]],
             description: "Buy 2 milk products, get 50% off the second"
         )
     ]
     
     return StoreDetails(
         storeTitle: "Local Grocery Store",
         storeDescription: "Your neighborhood grocery store with fresh produce, quality meats, and everyday essentials.",
         storeRating: Double.random(in: 3.5...5.0),
         storeAddress: "Address not available",
         storeImages: ["store1", "store2", "store3"], // Mock image names
         storeDeals: sampleDeals,
         itemList: sampleItems,
         storeHours: "Mon-Sun: 7:00 AM - 10:00 PM",
         phoneNumber: "+1 (555) 123-4567"
     )
 }

struct dealView : View {
    let store: StoreDetails
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    storeHeaderView
                    
                    dealsSection
                    
                    itemsOnSaleSection
                    
                }
                .padding(.vertical, 24)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.blue)
                }
            }
        }
    }
    
    private var storeHeaderView: some View {
        ZStack(alignment: .bottom) {
            // Mock store image background
            RoundedRectangle(cornerRadius: 0)
                .fill(LinearGradient(
                    colors: [Color(red:0.5, green:0.4, blue:0.8).opacity(0.3), .blue.opacity(0.4)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(height: 200)
            
            // Store name overlay
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(store.storeTitle)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 2)
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }
    
    // store deals section
    private var dealsSection: some View {
        modernCard {
            VStack(alignment: .leading, spacing: 16) {
                sectionHeader("Current Deals", icon: "tag.fill")
                
                ForEach(store.storeDeals.indices, id: \.self) { index in
                    let deal = store.storeDeals[index]
                    dealCard(deal: deal)
                }
            }
        }
    }
    
    // Items on sale section
    private var itemsOnSaleSection: some View {
        modernCard {
            VStack(alignment: .leading, spacing: 16) {
                sectionHeader("Items On Sale", icon: "cart.fill")
                
                ForEach(store.storeDeals.indices, id: \.self) { dealIndex in
                    let deal = store.storeDeals[dealIndex]
                    
                    ForEach(0..<deal.itemsAppliedTo.count, id: \.self) { index in
                        
                        itemCard(item: deal.itemsAppliedTo[index], deal: deal)
                    }
                }
            }
        }
    }
    
    private func itemCard(item: storeItem, deal: Deals) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Mock item image
            RoundedRectangle(cornerRadius: 8)
                .fill(LinearGradient(
                    colors: [.green.opacity(0.2), .blue.opacity(0.2)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(height: 80)
                .overlay {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.green.opacity(0.7))
                }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                Text(item.brand)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                Text(deal.description)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                switch deal.type {
                case .percentageOff(let discount):
                    
                    let newPrice: Double = item.price * (1-Double(discount)/100)
                    
                    HStack{
                        Text("$\(String(format: "%.2f", item.price))")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.red)
                            .strikethrough()
                        
                        Text("$\(String(format: "%.2f", newPrice))")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.green)
                    }
                    
                default:
                    Text("$\(String(format: "%.2f", item.price))")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.green)
                }
            }
        }
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .frame(width: 300)
    }
}
        
#Preview {
    tabsView()
}
