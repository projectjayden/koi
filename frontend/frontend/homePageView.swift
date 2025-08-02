//
//  homePageView.swift
//  frontend
//
//  Created by Danny Huang on 7/28/25.
//


import Foundation
import SwiftUI

struct homePageView: View {
    
    @StateObject private var viewModel = recipesViewModel()
    @State private var storesWithDeals: [StoreDetails] = []
    @State private var selectedRecipe: Meal?
    @State private var storeDeal: StoreDetails?
    @State private var showingStoreDeal = false
    
    var body: some View{
        VStack {
            //Header
            HStack(alignment: .top){
                //Name
                ZStack(alignment: .leading){
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
                //Stuff on the Right
                ZStack(alignment: .center){
                    NavigationLink(destination: shopView()) {
                        Image(systemName: "cart")
                            .foregroundColor(Color(red:0.5, green:0.4, blue:0.8))
                        Text("Shop")
                            .foregroundColor(Color(red:0.5, green:0.4, blue:0.8))
                    }
                }
                .frame(maxHeight: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: 60)
            ScrollView {
                
                //Deals on Home Page
                VStack{
                    Text("Awesome Deals Near You")
                        .frame(maxWidth:.infinity, alignment: .leading)
                        .font(.system(size:24, weight: .bold))
                        .foregroundStyle(Color(red:0.5, green:0.4, blue:0.8))
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 20) {
                            ForEach(0..<storesWithDeals.count, id: \.self) { index in
                                VStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(LinearGradient(
                                            colors: [Color(red:0.5, green:0.4, blue:0.8).opacity(0.3), .blue.opacity(0.4)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ))
                                        .frame(height: 145)
                                        .overlay {
                                            Image(systemName: "fish.fill")
                                                .font(.system(size: 24))
                                                .foregroundColor(Color(red:0.5, green:0.4, blue:0.8).opacity(0.7))
                                        }
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
                                .frame(width: 210, height: 180)
                                .cornerRadius(8)
                                .onTapGesture {
                                    storeDeal = storesWithDeals[index]
                                    showingStoreDeal = true
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .task {
                            storesWithDeals = []
                            for _ in 0..<10 {
                                storesWithDeals.append(createMockStoreDetails())
                            }
                        }
                    }
                    .sheet(isPresented: $showingStoreDeal) {
                        if let storeDeal = storeDeal {
                            dealView(store: storeDeal)
                        }
                    }
                    
                }
                .frame(maxWidth: .infinity)
                
                //Recipes on Home Page
                HStack{
                    Text("Find Recipes")
                        .frame(maxWidth:.infinity, alignment: .leading)
                        .font(.system(size:24, weight: .bold))
                        .foregroundStyle(Color(red:0.5, green:0.4, blue:0.8))

                }
                .frame(maxWidth: .infinity)
                .padding(.top, 50)
                
                ScrollView(.horizontal, showsIndicators: false) {
                     HStack(spacing: 20) {
                         ForEach(viewModel.recipes) { meal in // For Loop goes through 10 recipes
                             ZStack(alignment: .bottomLeading) {
                                 AsyncImage(url: URL(string: meal.strMealThumb)) { phase in
                                     if let image = phase.image {
                                         image
                                             .resizable()
                                             .aspectRatio(contentMode: .fill)
                                     } else if phase.error != nil {
                                         Color.red
                                     } else {
                                         ProgressView()
                                     }
                                 }
                                 .frame(width: 210, height: 180)
                                 .cornerRadius(8)
                                 .clipped()
                                 
                                 Text(meal.strMeal)
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
                             .onTapGesture {
                                 selectedRecipe = meal
                             }
                         }
                         .cornerRadius(8)
                     }
                     .frame(maxWidth: .infinity)
                     .task {
                         viewModel.fetchMultipleRandomRecipes(count: 10) { recipes in
                             viewModel.recipes = recipes
                         }
                     }
                 }
                 .sheet(item: $selectedRecipe) { meal in  //Sheet to meal
                     recipeSheet(recipe: meal)
                 }
            }
            .padding(.top, 20)
        }
        .padding(.leading, 10)
        .padding(.trailing, 10)
        .padding(.bottom, 30)
    }
}

// MARK: - Bottom Tabs
struct tabsView: View {
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
                Spacer() //profileView()
            }
                .tabItem {
                    Image(systemName: "gear")
                    Text("Profile")
                }
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
    let strMeal: String
    let strCategory: String
    let strInstructions: String
    let strMealThumb: String
    
    // Store ingredients and measures as arrays
    private let ingredientData: [String?]
    private let measureData: [String?]
    
    enum CodingKeys: String, CodingKey {
        case strMeal, strCategory, strInstructions, strMealThumb
        // No need to list all ingredient/measure keys here
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        strMeal = try container.decode(String.self, forKey: .strMeal)
        strCategory = try container.decode(String.self, forKey: .strCategory)
        strInstructions = try container.decode(String.self, forKey: .strInstructions)
        strMealThumb = try container.decode(String.self, forKey: .strMealThumb)
        
        // Dynamically decode ingredients and measures
        let allKeys = try decoder.container(keyedBy: DynamicCodingKey.self)
        var ingredients: [String?] = []
        var measures: [String?] = []
        
        for i in 1...20 {
            let ingredientKey = DynamicCodingKey(stringValue: "strIngredient\(i)")!
            let measureKey = DynamicCodingKey(stringValue: "strMeasure\(i)")!
            
            let ingredient = try? allKeys.decodeIfPresent(String.self, forKey: ingredientKey)
            let measure = try? allKeys.decodeIfPresent(String.self, forKey: measureKey)
            
            ingredients.append(ingredient)
            measures.append(measure)
        }
        
        self.ingredientData = ingredients
        self.measureData = measures
    }
    
    var ingredients: [(name: String, measure: String)] {
        return zip(ingredientData, measureData).compactMap { ingredient, measure in
            guard let ingredient = ingredient?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !ingredient.isEmpty else { return nil }
            
            let cleanMeasure = measure?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return (ingredient, cleanMeasure)
        }
    }
}

// Helper for dynamic key decoding
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
    @State private var favorites: [Meal] = []
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    
                    // Recipe Header
                    VStack(spacing: 16) {
                        Text(recipe.strMeal)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(Color(red: 0.3, green: 0.2, blue: 0.6))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        AsyncImage(url: URL(string: recipe.strMealThumb)) { phase in
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
                            Label(recipe.strCategory, systemImage: "tag.fill")
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
                        }
                        .padding(.horizontal)
                        
                        LazyVStack(alignment: .leading, spacing: 12) {
                            ForEach(recipe.ingredients, id: \.name) { ingredient in
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
                                        
                                        if !ingredient.measure.isEmpty {
                                            Text(ingredient.measure)
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
                        
                        Text(recipe.strInstructions)
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
                // MARK: add request to get favorite list
                
                isFavorited = favorites.contains(where: { $0.id == recipe.id })
            }
        }
    }
    
    private func toggleFavorite() {
        if isFavorited {
            favorites.removeAll{$0.id == recipe.id}
        } else {
            favorites.append(recipe)
        }
        isFavorited.toggle()
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
