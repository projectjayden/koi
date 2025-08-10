//
//  ProfileView.swift
//  frontend
//
//  Created by Jayden Zhang on 7/29/25.
//

import SwiftUI
import MapKit

struct profileView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    
    @State private var selectedTab = 0 // index
    @State private var isAnimating = false
    @State private var showEditProfile = false // edit button
    @State private var showSettings = false
    @State private var showTOS = false
    @State private var user: UserInfo? = nil
    @State private var userReviews: [UserReview] = []
    @State private var savedRecipes: [Recipes] = []
    @State private var isSavingProfile = false
    @State private var showFollowingView = false
    @State private var followingViewStartTab = 0 // 0 for followers, 1 for following
    @State private var isChangingPassword = false
    @State private var passwordError: String?
    @State private var showSuccessMessage = false
    
    var body: some View {
        ZStack {
            KoiBackgroundView()
            
            if user != nil {
                ScrollView {
                    VStack(spacing: 0) {
                        // Vertical Stack of the Different Sections
                        profileHeaderView()
                            .padding(.top, 20)
                        statsSection()
                            .padding(.top, 20)
                        tabSelector()
                            .padding(.top, 30)
                        tabContent()
                            .padding(.top, 20)
                    }
                    .padding(.horizontal, 20)
                }
            } else {
                ProgressView("Loading profile...")
                    .task {
                        do {
                            let profile = try await extractUserProfile()
                            user = profile?.user
                            userReviews = profile?.reviews ?? []
                            savedRecipes = profile?.recipes ?? []
                        } catch {
                            print("Failed to load user profile: \(error)")
                        }
                    }
            }
        }
        .onAppear {
            withAnimation {
                isAnimating = true
            }
        }
        .sheet(isPresented: $showEditProfile, onDismiss: {
            showEditProfile = false
        }) { // edit profile modal
            ProfileEditView(
                user: $user,
                isSavingProfile: $isSavingProfile,
                showEditProfile: $showEditProfile
            )
        }
        .sheet(isPresented: $showSettings, onDismiss: {
            showSettings = false
        }) { // settings modal
            ProfileSettingsView(
                user: $user,
                showSettings: $showSettings,
                showTOS: $showTOS,
                isChangingPassword: $isChangingPassword,
                passwordError: $passwordError,
                showSuccessMessage: $showSuccessMessage
            )
            .environmentObject(authManager)
        }
        .sheet(isPresented: $showTOS, onDismiss: {
            showTOS = false
            showSettings = true
        }) {
            ProfileTOSView(showTOS: $showTOS)
        }
        .sheet(isPresented: $showFollowingView, onDismiss: {
            showFollowingView = false
        }) { // following/followers modal
            followingViewSheet()
        }
    }
    
    // MARK: - Profile Header
    
    // for the top part of the view, includes the buttons
    @ViewBuilder
    private func profileHeaderView() -> some View {
        ZStack {
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.8), Color.gray.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 140, height: 140)
                        .blur(radius: 0.5)
                    
                    Circle()
                        .stroke(Color.white.opacity(0.6), lineWidth: 2)
                        .frame(width: 140, height: 140)
                    
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.purple.opacity(0.8), Color.blue.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .scaleEffect(isAnimating ? 1.05 : 1.0)
                .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isAnimating)
                
                // username
                VStack(spacing: 8) {
                    Text("@\(user?.name ?? "")")                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.primary, Color.gray.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    // subscription badge
                    if user?.isSubscribed == true {
                        HStack(spacing: 6) {
                            // Golden Koi fish icon
                            ZStack {
                                Image(systemName: "drop.fill")
                                    .font(.system(size: 16))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [Color.orange, Color.yellow],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .rotationEffect(.degrees(-45))
                                
                                Circle()
                                    .fill(Color.orange.opacity(0.3))
                                    .frame(width: 8, height: 8)
                                    .offset(x: -2, y: -2)
                            }
                            .scaleEffect(1.2)
                            
                            Text("KOI Premium")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color.orange, Color.yellow.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.8))
                                .blur(radius: 0.5)
                        )
                        .overlay(
                            Capsule()
                                .stroke(
                                    LinearGradient(
                                        colors: [Color.orange.opacity(0.4), Color.yellow.opacity(0.3)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ),
                                    lineWidth: 1.5
                                )
                        )
                        .shadow(color: Color.orange.opacity(0.2), radius: 8, x: 0, y: 4)
                    }
                }
                
                // Edit, Share, and Settings Button
                HStack(spacing: 16) {
                    modernButton(title: "Edit", icon: "pencil", isPrimary: true) {
                        showEditProfile = true
                    }
                    ShareLink(item: URL(string: "https://www.example.com")!) {
                        modernButton(title: "Share", icon: "square.and.arrow.up", isPrimary: false) {
                        }
                    }
                    modernButton(title: "Settings", icon: "gearshape", isPrimary: false) {
                        showSettings = true
                    }
                }
            }
            .padding(25)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color.white.opacity(0.35))
                    .blur(radius: 0.5)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 25)
                    .stroke(Color.white.opacity(0.6), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 20, x: 0, y: 10)
            
            // premium floating badge on profile pic
            if user?.isSubscribed == true {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.orange, Color.yellow],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    Text("Premium")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    Capsule()
                        .fill(Color.orange.opacity(0.1))
                )
                .position(x: 170, y: 20)
            }
        }
    }
    
    // MARK: - Stats Section
    
    // shows the recipes, followers, and following
    @ViewBuilder
    private func statsSection() -> some View {
        HStack(spacing: 0) {
            // Recipes card (not clickable)
            statCard(title: "Recipes", value: "\(userReviews.count)", icon: "book.fill", isClickable: false) {
                // No action for recipes
            }
            
            Divider()
                .frame(height: 40)
                .background(Color.white.opacity(0.3))
            
            // Followers card (clickable)
            statCard(title: "Followers", value: formatNumber(user?.followers ?? 0), icon: "heart.fill", isClickable: true) {
                followingViewStartTab = 0 // Start on followers tab
                showFollowingView = true
            }
            
            Divider()
                .frame(height: 40)
                .background(Color.white.opacity(0.3))
            
            // Following card (clickable)
            statCard(title: "Following", value: formatNumber(user?.following ?? 0), icon: "person.2.fill", isClickable: true) {
                followingViewStartTab = 1 // Start on following tab
                showFollowingView = true
            }
        }
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.3))
                .blur(radius: 0.5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.5), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.03), radius: 15, x: 0, y: 8)
    }

    // Updated statCard helper function with navigation capability
    @ViewBuilder
    private func statCard(title: String, value: String, icon: String, isClickable: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.purple.opacity(0.7), Color.blue.opacity(0.5)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .scaleEffect(isClickable ? 1.0 : 1.0) // You can add subtle hover effects here if needed
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!isClickable)
    }
    
    @ViewBuilder
    private func followingViewSheet() -> some View {
        NavigationView {
            followingView(initialTab: followingViewStartTab)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Text(followingViewStartTab == 0 ? "Followers" : "Following")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            showFollowingView = false
                        }
                        .foregroundColor(.purple)
                        .fontWeight(.semibold)
                    }
                }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
    
    // MARK: - Tab Navigation
    
    // shows the 4 tabs: recipes, lists, reviews, and AI lists
    @ViewBuilder
    private func tabSelector() -> some View {
        HStack(spacing: 0) {
            ForEach(0..<4) { index in
                Button(action: {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        selectedTab = index
                    }
                }) {
                    VStack(spacing: 6) {
                        Image(systemName: tabIcon(for: index))
                            .font(.title3)
                        Text(tabTitle(for: index))
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(selectedTab == index ? .purple.opacity(0.8) : .secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(selectedTab == index ? Color.purple.opacity(0.08) : Color.clear)
                    )
                }
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.4))
                .blur(radius: 0.5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.white.opacity(0.6), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.03), radius: 12, x: 0, y: 6)
    }
    
    // helper function to switch between tabs
    @ViewBuilder
    private func tabContent() -> some View {
        VStack(spacing: 16) {
            switch selectedTab {
            case 0:
                recipesTab()
            case 1:
                listsTab()
            case 2:
                reviewsTab()
            case 3:
                aiListsTab()
            default:
                EmptyView()
            }
        }
    }
    
    // MARK: - Tab Content Views
    
    // helper function to display recipes
    @ViewBuilder
    private func recipesTab() -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
            ForEach(savedRecipes, id: \.uuid) { oneRecipe in
                recipeCard(recipe: oneRecipe)
            }
        }
    }
    
    // helper function to display lists
    // user.personalLists
    @ViewBuilder
    private func listsTab() -> some View {
        VStack(spacing: 12) {
            ForEach(0..<userReviews.count, id: \.self) { index in
                listCard(title: "My List #\(index + 1)", itemCount: Int.random(in: 3...12))
            }
        }
    }
    
    // helper function to display reviews
    @ViewBuilder
    private func reviewsTab() -> some View {
        VStack(spacing: 12) {
            ForEach(0..<userReviews.count, id: \.self) { index in
                reviewCard(review: userReviews[index])
            }
        }
    }
    
    // helper function to display aiLists
    // user.aiGeneratedLists
    @ViewBuilder
    private func aiListsTab() -> some View {
        VStack(spacing: 12) {
            ForEach(0..<userReviews.count, id: \.self) { index in
                aiListCard(title: "AI Suggestion #\(index + 1)")
            }
        }
    }
    
    // MARK: - Card Components
    
    // helper function for the recipes card
    @ViewBuilder
    private func recipeCard(recipe: Recipes) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [Color.purple.opacity(0.3), Color.purple.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 120)
                .overlay(
                    Image(systemName: "fork.knife")
                        .font(.title)
                        .foregroundColor(.white)
                )
            
            Text(recipe.name)
                .font(.headline)
                .fontWeight(.semibold)
            
            /*
             public struct Ingredient {
             let name: String
             let amount: Int
             let unit: String
             }
             
             public struct Recipes: Codable {
             let uuid: Int
             let userUuid: Int
             let name: String
             let ingredients: [Ingredient]
             let cateogory: String?
             let image: String?
             }
             fix this using this struct
             */
            
            Text("Delicious recipe description")
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.3))
                .blur(radius: 0.5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.4), lineWidth: 1)
        )
    }
    
    // helper function for the list card
    @ViewBuilder
    private func listCard(title: String, itemCount: Int) -> some View {
        HStack {
            Image(systemName: "list.bullet.rectangle")
                .font(.title2)
                .foregroundColor(.purple)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("\(itemCount) items")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.3))
                .blur(radius: 0.5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.4), lineWidth: 1)
        )
    }
    
    // helper function for the review card
    @ViewBuilder
    private func reviewCard(review: UserReview) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                ForEach(0..<5) { star in
                    Image(systemName: star < Int(review.rating) ? "star.fill" : "star")
                        .foregroundColor(.yellow)
                        .font(.caption)
                }
                
                Spacer()
                
                Text("Restaurant")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(review.description)
                .font(.body)
                .lineLimit(3)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.3))
                .blur(radius: 0.5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.4), lineWidth: 1)
        )
    }
    
    // helper function for the ai lists card
    @ViewBuilder
    private func aiListCard(title: String) -> some View {
        HStack {
            Image(systemName: "brain.head.profile")
                .font(.title2)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.purple, Color.blue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("AI Generated • Smart recommendations")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "sparkles")
                .font(.caption)
                .foregroundColor(.purple)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.4), Color.purple.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .blur(radius: 0.5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.purple.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - Helper Components
    
    // modern button design for edit, share, and settings
    @ViewBuilder
    private func modernButton(title: String, icon: String, isPrimary: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(isPrimary ? .white : .purple.opacity(0.8))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isPrimary ? Color.purple.opacity(0.9) : Color.white.opacity(0.6))
                    .blur(radius: isPrimary ? 0 : 0.5)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isPrimary ? Color.clear : Color.purple.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: isPrimary ? Color.purple.opacity(0.3) : Color.clear, radius: 8, x: 0, y: 4)
        }
    }
    
    // MARK: - Helper Functions
    
    private func tabIcon(for index: Int) -> String {
        switch index {
        case 0: return "book.fill"
        case 1: return "list.bullet"
        case 2: return "star.fill"
        case 3: return "brain.head.profile"
        default: return "questionmark"
        }
    }
    
    private func tabTitle(for index: Int) -> String {
        switch index {
        case 0: return "Recipes"
        case 1: return "Lists"
        case 2: return "Reviews"
        case 3: return "AI Lists"
        default: return "Unknown"
        }
    }
    
    private func formatNumber(_ number: Int) -> String {
        if number >= 1000 {
            return String(format: "%.1fK", Double(number) / 1000.0)
        }
        return "\(number)"
    }
    
    // MARK: - Data Loading
    
    private func extractUserProfile() async throws -> UserProfileResponse? {
        let network = NetworkService()
        
        do {
            guard KeychainManager.instance.getToken(forKey: "authToken") != nil else {
                throw AuthError.noData
            }
            
            let user: UserInfo? = getUserFromDefaults()
            
            // Handle reviews request that might fail for empty results
            var listOfUserReviews: ReviewsResponse?
            do {
                listOfUserReviews = try await network.requestEndpoint(
                    endpoint: "/user/get-reviews",
                    method: "POST",
                    body: [
                        "limit": 5,
                        "offset": 5,
                    ]
                )
            } catch {
                // Log the error but continue - user might have no reviews
                print("Failed to fetch reviews (user might have none): \(error)")
                listOfUserReviews = nil
            }
            
            guard let userUuid = user?.uuid else {
                print("User UUID is not available")
                return nil
            }

            let request = GetRecipesRequest(
                uuid: userUuid,
                type: 0,
                limit: 5,
                offset: 5
            )
            
            // Handle recipes request similarly
            var listOfUserRecipes: RecipesResponse?
            do {
                listOfUserRecipes = try await network.requestEndpoint(
                    endpoint: "/user/get-recipes",
                    method: "POST",
                    body: request
                )
            } catch {
                print("Failed to fetch recipes (user might have none): \(error)")
                listOfUserRecipes = nil
            }
            
            let response = UserProfileResponse(
                user: user,
                reviews: listOfUserReviews?.reviews ?? [],
                recipes: listOfUserRecipes?.recipes ?? []
            )
            
            return response
            
        } catch {
            print("Request failed:", error)
            throw error
        }
    }
    
    private func saveUserChanges(
        username: String? = nil,
        bio: String? = nil,
        email: String? = nil,
        allergies: [String]? = nil,
        preferences: [String]? = nil
    ) async {
        let network = NetworkService()
        
        do {
            let requestBody = UpdateProfileRequest(
                name: username,
                bio: bio,
                email: email,
                allergies: allergies,
                preferences: preferences
            )
            
            let _: EmptyResponse? = try await network.requestEndpoint(
                endpoint: "/user/update",
                method: "PATCH",
                body: requestBody
            )
            
            // If successful, update local user data
            await MainActor.run {
                if let currentUser = user {
                    let updatedUser = UserInfo(
                        uuid: currentUser.uuid,
                        name: username ?? currentUser.name,
                        bio: bio ?? currentUser.bio,
                        email: email ?? currentUser.email,
                        lastLogin: currentUser.lastLogin,
                        dateJoined: currentUser.dateJoined,
                        storeId: currentUser.storeId,
                        isSubscribed: currentUser.isSubscribed,
                        preferences: preferences ?? currentUser.preferences,
                        allergies: allergies ?? currentUser.allergies,
                        followers: currentUser.followers,
                        following: currentUser.following
                    )
                    
                    self.user = updatedUser
                    saveUserToDefaults(user: updatedUser)
                }
            }
            
            print("Profile updated successfully")
            print("Updated allergies: \(allergies ?? [])")
            print("Updated preferences: \(preferences ?? [])")
            
        } catch {
            await MainActor.run {
                print("Failed to update profile:", error)
            }
        }
    }
    
    private func clearUserData() {
        // Remove user from UserDefaults
        UserDefaults.standard.removeObject(forKey: "user")
        
        // Clear any other stored user data
        UserDefaults.standard.removeObject(forKey: "userPreferences")
        UserDefaults.standard.removeObject(forKey: "savedRecipes")
        // Add any other keys you store
        
        // Clear from Keychain
        do {
            try KeychainManager.instance.deleteToken(forKey: "authToken")
            try KeychainManager.instance.deleteToken(forKey: "refreshToken")
        } catch {
            print("error")
        }
        
        // Reset local state
        self.user = nil
        self.savedRecipes = []
        // Reset any other @State variables
    }
}

//
//#Preview {
//    profileView()
//}
