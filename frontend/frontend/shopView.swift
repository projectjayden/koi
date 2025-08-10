//
//  shopView.swift
//  frontend
//
//  Created by Danny Huang on 8/1/25.
//

import Foundation
import SwiftUI

@Observable
class CartManager {
    var cart: Cart = Cart.empty
    
    init() {
        loadCart()
    }
    
    func loadCart() {
        cart = UserDefaults.standard.object(Cart.self, forKey: "cart") ?? Cart.empty
    }
    
    func saveCart() {
        DispatchQueue.global(qos: .userInitiated).async {
            UserDefaults.standard.store(self.cart, forKey: "cart")
        }
    }
    
    func addItem(_ ingredient: String) {
        if !cart.ingredients.contains(ingredient) {
            cart.ingredients.append(ingredient)
            saveCart()
        }
    }
    
    func removeItem(_ ingredient: String) {
        cart.ingredients.removeAll { $0 == ingredient }
        saveCart()
    }
    
    func clearCart() {
        cart.ingredients.removeAll()
        saveCart()
    }
    
    func contains(_ ingredient: String) -> Bool {
        return cart.ingredients.contains(ingredient)
    }
}

// 2. Updated shopView
struct shopView: View {
    
    @State private var searchQuery: String = ""
    @State private var isSearchFocused: Bool = false
    @State private var filteredItems: [String] = []
    @State private var showResults: Bool = false
    @State private var showCart: Bool = false
    @State private var showSuggestions: Bool = false
    @State private var suggestions: [String] = []
    
    @State private var cartManager = CartManager()
    
    // Flash message states
    @State private var showFlashMessage: Bool = false
    @State private var flashMessage: String = ""
    @State private var flashMessageType: FlashMessageType = .success
    
    //TODO: replace with getting all items
    private var allItems: [String] = ["Free-Range Eggs", "Eggs", "Bacon", "Ham", "Broccoli", "Spinach", "Chicken Breast", "Ground Beef", "Salmon", "Milk", "Cheese", "Yogurt", "Bread", "Rice", "Pasta"]

    enum FlashMessageType {
        case success
        case warning
        case error
        
        var color: Color {
            switch self {
            case .success: return .green
            case .warning: return .orange
            case .error: return .red
            }
        }
        
        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .error: return "xmark.circle.fill"
            }
        }
    }
    
    var body: some View {
        ZStack{
            KoiBackgroundView()
            
            VStack{
                searchBarView
                
                // Show suggestions when typing (before search submission)
                if showSuggestions && !suggestions.isEmpty && !showResults {
                    suggestionsView
                }
                
                if showResults {
                    searchResultsView
                }
                else if !showSuggestions {
                    Spacer()
                    
                    
                    VStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 32))
                            .foregroundStyle( Color(red: 0.6, green: 0.5, blue: 0.9))
                        
                        Text("No items Searched")
                            .font(.headline)
                            .foregroundStyle( Color(red: 0.3, green: 0.2, blue: 0.6))
                        
                        Text("Try searching for ingredients")
                            .font(.caption)
                            .foregroundStyle( Color(red: 0.6, green: 0.5, blue: 0.9))
                    }
                }
                
                Spacer()
            }
            
            .overlay(alignment: .bottomTrailing) {
                Button {
                    showCart = true
                } label: {
                    Image(systemName: "cart")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
                .frame(width: 56, height: 56)
                .background(LinearGradient(
                    colors: [
                        Color(red: 0.3, green: 0.2, blue: 0.6),
                        Color(red: 0.7, green: 0.6, blue: 0.9)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                .scaleEffect(1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: true)
                .padding(.trailing, 20)
                .padding(.bottom, 20)
            }
            
            // Flash message overlay
            if showFlashMessage {
                VStack {
                    HStack(spacing: 12) {
                        Image(systemName: flashMessageType.icon)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(flashMessageType.color)
                        
                        Text(flashMessage)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.primary)
                        
                        Spacer()
                        
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(.regularMaterial)
                            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                            .overlay {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(flashMessageType.color.opacity(0.3), lineWidth: 1)
                            }
                    }
                    .padding(.horizontal, 16)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .onTapGesture {
                        // Dismiss on tap
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showFlashMessage = false
                        }
                    }
                    
                    Spacer()
                        .contentShape(Rectangle())
                        .allowsHitTesting(false)
                }
                .allowsHitTesting(true)
            }
        }
        .onAppear {
            filteredItems = allItems
            // Remove cart loading since CartManager handles it
        }
        .sheet(isPresented: $showCart) {
            cartView(cartManager: cartManager)
        }
        .onTapGesture {
            // Hide suggestions when tapping outside
            if showSuggestions {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showSuggestions = false
                    isSearchFocused = false
                    hideKeyboard()
                }
            }
        }
    }
    
    private var searchBarView: some View {
        HStack(spacing: 12) {
            // Search Icon
            Image(systemName: "magnifyingglass")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(searchQuery.isEmpty ? .secondary : .primary)
                .animation(.easeInOut(duration: 0.2), value: searchQuery.isEmpty)
            
            // Search TextField
            TextField("Search for Ingredients...", text: $searchQuery)
                .font(.system(size: 16, weight: .regular))
                .textFieldStyle(.plain)
                .onSubmit {
                    Task {
                        await performSearch(for: searchQuery)
                        hideKeyboard()
                        showSuggestions = false
                    }
                }
                .onTapGesture {
                    isSearchFocused = true
                    updateSuggestions()
                }
                .onChange(of: searchQuery) { oldValue, newValue in
                    if newValue.isEmpty {
                        showResults = false
                        showSuggestions = false
                        filteredItems = allItems
                    } else {
                        isSearchFocused = true
                        updateSuggestions()
                    }
                }
            
            // Clear Button
            if !searchQuery.isEmpty {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        searchQuery = ""
                        isSearchFocused = false
                        showResults = false
                        showSuggestions = false
                        filteredItems = allItems
                        hideKeyboard()
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
    
    private var suggestionsView: some View {
        let limitedSuggestions = Array(suggestions.prefix(5))
        let enumeratedSuggestions = Array(limitedSuggestions.enumerated())
        
        return ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(enumeratedSuggestions, id: \.element) { index, suggestion in
                    suggestionRow(
                        suggestion: suggestion,
                        isLast: index == limitedSuggestions.count - 1
                    )
                }
            }
        }
        .frame(maxHeight: min(280, CGFloat(limitedSuggestions.count * 60)))
        .background(suggestionsBackground)
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
    
    private var suggestionsBackground: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(.ultraThinMaterial)
            .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(.white.opacity(0.15), lineWidth: 1)
            }
    }
    
    private func suggestionRow(suggestion: String, isLast: Bool) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.3)) {
                searchQuery = suggestion
                isSearchFocused = false
                showSuggestions = false
                hideKeyboard()
            }
            Task {
                await performSearch(for: suggestion)
            }
        } label: {
            HStack(spacing: 16) {
                // Item Icon
                Image(systemName: "fish.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color(red: 0.6, green: 0.5, blue: 0.9))
                    .frame(width: 20)
                
                // Text Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(suggestion)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Arrow Icon
                Image(systemName: "arrow.up.left")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.tertiary)
                    .rotationEffect(.degrees(-45))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .buttonStyle(PlainButtonStyle())
        .background {
            Rectangle()
                .fill(.clear)
                .contentShape(Rectangle())
        }
        .overlay(alignment: .bottom) {
            if !isLast {
                Rectangle()
                    .fill(.separator.opacity(0.5))
                    .frame(height: 0.5)
                    .padding(.leading, 56)
            }
        }
    }
    
    private var searchResultsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Results")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Text("\(filteredItems.count) item\(filteredItems.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            
            if filteredItems.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 32))
                        .foregroundStyle( Color(red: 0.6, green: 0.5, blue: 0.9))
                    
                    Text("No results found")
                        .font(.headline)
                        .foregroundStyle( Color(red: 0.3, green: 0.2, blue: 0.6))
                    
                    Text("Try searching for different ingredients")
                        .font(.caption)
                        .foregroundStyle( Color(red: 0.6, green: 0.5, blue: 0.9))
                    
                    Spacer()
                    
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
                .padding(.bottom, 50)
                
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(filteredItems, id: \.self) { item in
                            searchResultRow(item: item)
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
    
    private func searchResultRow(item: String) -> some View {
        HStack {
            Image(systemName: "fish.fill")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color(red: 0.6, green: 0.5, blue: 0.9))
            
            Text(item)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.primary)
            
            Spacer()
            
            Button {
                addToCart(ingredient: item)
            } label: {
                Image(systemName: cartManager.contains(item) ? "checkmark.circle.fill" : "plus.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(cartManager.contains(item) ? .green : .blue)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.regularMaterial)
        }
    }
    
    private func addToCart(ingredient: String) {
        if cartManager.contains(ingredient) {
            showFlashMessage(message: "\(ingredient) is already in your cart", type: .warning)
            return
        }
        
        cartManager.addItem(ingredient)
        showFlashMessage(message: "Added \(ingredient) to cart", type: .success)
    }
    
    private func showFlashMessage(message: String, type: FlashMessageType) {
        flashMessage = message
        flashMessageType = type
        
        withAnimation(.easeInOut(duration: 0.3)) {
            showFlashMessage = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation(.easeInOut(duration: 0.3)) {
                showFlashMessage = false
            }
        }
    }
    
    private func hideKeyboard() {
        #if os(iOS)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        #endif
    }
    
    private func updateSuggestions() {
        withAnimation(.easeInOut(duration: 0.2)) {
            if searchQuery.isEmpty {
                suggestions = allItems
                showSuggestions = isSearchFocused
                showResults = false
            } else {
                suggestions = allItems.filter { item in
                    item.lowercased().contains(searchQuery.lowercased())
                }
                showSuggestions = !suggestions.isEmpty && isSearchFocused
                showResults = false
            }
        }
    }
    
    private func performSearch(for query: String) async {
        guard !query.isEmpty else {
            showResults = false
            return
        }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            filteredItems = allItems.filter { item in
                item.lowercased().contains(query.lowercased())
            }
            showResults = true
        }
    }
}

// 3. Updated cartView
struct cartView: View {
    let cartManager: CartManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack{
                KoiBackgroundView()
                VStack {
                    if cartManager.cart.ingredients.isEmpty {
                        // Empty cart state
                        VStack(spacing: 16) {
                            Spacer()
                            
                            Image(systemName: "cart")
                                .font(.system(size: 64))
                                .foregroundStyle( Color(red: 0.3, green: 0.2, blue: 0.6))
                            
                            Text("Your cart is empty")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundStyle( Color(red: 0.3, green: 0.2, blue: 0.6))
                            
                            Text("Add some ingredients to get started")
                                .font(.body)
                                .foregroundStyle( Color(red: 0.3, green: 0.2, blue: 0.6))
                            
                            Spacer()
                        }
                    } else {
                        // Action buttons when cart has items
                        HStack(spacing: 12) {
                            Button {
                                saveCart()
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "bookmark.fill")
                                        .font(.system(size: 16, weight: .semibold))
                                    Text("Save")
                                        .font(.system(size: 17, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
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
                            
                            Button {
                                goShopping()
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "bag.fill")
                                        .font(.system(size: 16, weight: .semibold))
                                    Text("Go")
                                        .font(.system(size: 17, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background {
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(LinearGradient(
                                            colors: [
                                                Color(red: 0.7, green: 0.6, blue: 0.9),
                                                Color(red: 0.5, green: 0.4, blue: 0.8)
                                            ],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        ))
                                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        
                        // Cart items list
                        List {
                            ForEach(cartManager.cart.ingredients, id: \.self) { ingredient in
                                cartItemRow(ingredient: ingredient)
                            }
                            .onDelete(perform: deleteItems)
                        }
                        .listStyle(PlainListStyle())
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                if !cartManager.cart.ingredients.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Clear All") {
                            clearCart()
                        }
                        .foregroundStyle(.red)
                    }
                }
            }
        }
        // Remove onAppear since CartManager handles loading
    }
    
    private func cartItemRow(ingredient: String) -> some View {
        HStack(spacing: 16) {
            // Item icon
            Image(systemName: "leaf.fill")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.green)
                .frame(width: 20)
            
            // Item name
            Text(ingredient)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(.primary)
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button {
                removeFromCart(ingredient: ingredient)
            } label: {
                Label("Delete", systemImage: "trash")
            }
            .tint(.red)
        }
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
    }
    
    private func removeFromCart(ingredient: String) {
        withAnimation(.easeInOut(duration: 0.3)) {
            cartManager.removeItem(ingredient)
        }
    }
    
    private func deleteItems(at offsets: IndexSet) {
        withAnimation(.easeInOut(duration: 0.3)) {
            for index in offsets {
                let ingredient = cartManager.cart.ingredients[index]
                cartManager.removeItem(ingredient)
            }
        }
    }
    
    private func clearCart() {
        withAnimation(.easeInOut(duration: 0.3)) {
            cartManager.clearCart()
        }
    }
    
    private func saveCart() {
        // Save cart functionality - could save to favorites, export, etc.
        print("Saving cart with \(cartManager.cart.ingredients.count) items")
        // Add your save logic here
    }
    
    private func goShopping() {
        // Go shopping functionality - could navigate to store locator, etc.
        print("Going shopping with cart items: \(cartManager.cart.ingredients)")
        // Add your go shopping logic here
        dismiss() // Close cart view for now
    }
}

#Preview {
    shopView()
}
