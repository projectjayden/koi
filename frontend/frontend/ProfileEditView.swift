//
//  ProfileEditView.swift
//  frontend
//
//  Created by Jayden Zhang on 7/29/25.
//

import SwiftUI

struct ProfileEditView: View {
    @Binding var user: UserInfo?
    @Binding var isSavingProfile: Bool
    @Binding var showEditProfile: Bool
    
    @State private var tempUsername = ""
    @State private var tempBio = ""
    @State private var tempAllergies: [String] = []
    @State private var tempPreferences: [String] = []
    @State private var tempPrivateAccount = false
    @State private var tempNotifications = true
    
    var body: some View {
        NavigationView {
            ZStack {
                // Same beautiful background as main profile
                LinearGradient(
                    colors: [
                        Color.purple.opacity(0.15),
                        Color.blue.opacity(0.08),
                        Color.white.opacity(0.9),
                        Color.purple.opacity(0.1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 25) {
                        // Header
                        VStack(spacing: 8) {
                            Text("Edit Profile")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color.primary, Color.gray.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                            
                            Text("Customize your KOI experience")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 20)
                        
                        // Profile Picture Section
                        profilePictureEditSection()
                        
                        // Basic Info Section (now includes allergies and preferences)
                        basicInfoSection()
                        
                        // Privacy Settings Section
                        privacySettingsSection()
                        
                        // Premium Section (if subscribed)
                        if user?.isSubscribed == true {
                            premiumSection()
                        }
                        
                        // Action Buttons Section (includes saving allergies and preferences)
                        actionButtonsSection()
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            // Initialize with current user data
            tempUsername = user?.name ?? ""
            tempBio = user?.bio ?? "Food enthusiast & recipe collector 🍜"
            tempAllergies = user?.allergies ?? []
            tempPreferences = user?.preferences ?? []
        }
    }
    
    // MARK: - Profile Picture Section
    
    // edit the profile picture
    @ViewBuilder
    private func profilePictureEditSection() -> some View {
        VStack(spacing: 16) {
            // Current profile picture with edit overlay
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.8), Color.gray.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                    .blur(radius: 0.5)
                
                Circle()
                    .stroke(Color.white.opacity(0.6), lineWidth: 2)
                    .frame(width: 120, height: 120)
                
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.purple.opacity(0.8), Color.blue.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                // Edit button overlay
                Button(action: {
                    // Photo picker action
                }) {
                    Circle()
                        .fill(Color.purple.opacity(0.9))
                        .frame(width: 36, height: 36)
                        .overlay(
                            Image(systemName: "camera.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                        )
                        .shadow(color: Color.purple.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .offset(x: 35, y: 35)
            }
            
            Text("Tap to change photo")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.35))
                .blur(radius: 0.5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.6), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 15, x: 0, y: 8)
    }
    
    // MARK: - Basic Info Section
    
    // edit the basic info
    @ViewBuilder
    private func basicInfoSection() -> some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Basic Information")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                // Username field
                editField(
                    title: "Username",
                    text: $tempUsername,
                    icon: "at",
                    placeholder: "Enter username"
                )
                
                // Bio field
                editField(
                    title: "Bio",
                    text: $tempBio,
                    icon: "text.alignleft",
                    placeholder: "Tell us about yourself"
                )
                
                // Allergies section
                allergySelectionSection()
                
                // Preferences section
                preferencesSelectionSection()
            }
        }
        .padding(20)
        .background(containerBackground())
        .overlay(containerBorder())
        .shadow(color: Color.black.opacity(0.05), radius: 15, x: 0, y: 8)
    }
    
    // Updated editField to work with non-optional strings
    @ViewBuilder
    private func editField(title: String, text: Binding<String>, icon: String, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(.purple.opacity(0.7))
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
            
            TextField(placeholder, text: text)
                .font(.body)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.7))
                        .blur(radius: 0.5)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.8), lineWidth: 1)
                )
        }
    }
    
    // MARK: - Allergies Section
    
    // New allergies selection section with Discord-style tags
    @ViewBuilder
    private func allergySelectionSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundColor(.red.opacity(0.7))
                Text("Allergies & Dietary Restrictions")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
            
            // Available allergy tags
            let commonAllergies = [
                "Nuts", "Dairy", "Eggs", "Gluten", "Soy", "Fish", "Shellfish",
                "Sesame", "Wheat", "Peanuts", "Tree Nuts", "Lactose",
                "Vegetarian", "Vegan", "Kosher", "Halal"
            ]
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                ForEach(commonAllergies, id: \.self) { allergy in
                    allergyTag(
                        allergy: allergy,
                        isSelected: tempAllergies.contains(allergy),
                        onTap: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                if tempAllergies.contains(allergy) {
                                    tempAllergies.removeAll { $0 == allergy }
                                } else {
                                    tempAllergies.append(allergy)
                                }
                            }
                        }
                    )
                }
            }
            
            // Show selected allergies count
            if !tempAllergies.isEmpty {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption2)
                        .foregroundColor(.green)
                    
                    Text("\(tempAllergies.count) restriction\(tempAllergies.count == 1 ? "" : "s") selected")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 4)
            }
        }
    }

    // Individual allergy tag component
    @ViewBuilder
    private func allergyTag(allergy: String, isSelected: Bool, onTap: @escaping () -> Void) -> some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption2)
                        .foregroundColor(.white)
                        .transition(.scale.combined(with: .opacity))
                }
                
                Text(allergy)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.red.opacity(0.8) : Color.white.opacity(0.6))
                    .animation(.easeInOut(duration: 0.2), value: isSelected)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? Color.red.opacity(0.3) : Color.gray.opacity(0.3),
                        lineWidth: 1
                    )
                    .animation(.easeInOut(duration: 0.2), value: isSelected)
            )
            .foregroundColor(isSelected ? .white : .primary)
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .shadow(color: isSelected ? Color.red.opacity(0.3) : Color.clear, radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Preferences Section
    
    // New preferences selection section with Discord-style tags
    @ViewBuilder
    private func preferencesSelectionSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "leaf.fill")
                    .font(.caption)
                    .foregroundColor(.green.opacity(0.7))
                Text("Dietary Preferences")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
            
            // Available preference tags
            let dietaryPreferences = [
                "Vegetarian", "Vegan", "Pescatarian", "Keto", "Paleo", "Mediterranean",
                "Low Carb", "High Protein", "Organic", "Raw Food", "Gluten-Free",
                "Dairy-Free", "Sugar-Free", "Low Sodium", "Whole Foods", "Plant-Based"
            ]
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                ForEach(dietaryPreferences, id: \.self) { preference in
                    preferenceTag(
                        preference: preference,
                        isSelected: tempPreferences.contains(preference),
                        onTap: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                if tempPreferences.contains(preference) {
                                    tempPreferences.removeAll { $0 == preference }
                                } else {
                                    tempPreferences.append(preference)
                                }
                            }
                        }
                    )
                }
            }
            
            // Show selected preferences count
            if !tempPreferences.isEmpty {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption2)
                        .foregroundColor(.green)
                    
                    Text("\(tempPreferences.count) preference\(tempPreferences.count == 1 ? "" : "s") selected")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 4)
            }
        }
        .padding(.top, 16)
    }

    // Individual preference tag component
    @ViewBuilder
    private func preferenceTag(preference: String, isSelected: Bool, onTap: @escaping () -> Void) -> some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption2)
                        .foregroundColor(.white)
                        .transition(.scale.combined(with: .opacity))
                }
                
                Text(preference)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.green.opacity(0.8) : Color.white.opacity(0.6))
                    .animation(.easeInOut(duration: 0.2), value: isSelected)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? Color.green.opacity(0.3) : Color.gray.opacity(0.3),
                        lineWidth: 1
                    )
                    .animation(.easeInOut(duration: 0.2), value: isSelected)
            )
            .foregroundColor(isSelected ? .white : .primary)
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .shadow(color: isSelected ? Color.green.opacity(0.3) : Color.clear, radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Privacy Settings Section
    
    // privacy settings
    @ViewBuilder
    private func privacySettingsSection() -> some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Privacy & Notifications")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                // Private account toggle
                toggleSetting(
                    title: "Private Account",
                    subtitle: "Only followers can see your recipes",
                    icon: "lock.fill",
                    isOn: $tempPrivateAccount
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.35))
                .blur(radius: 0.5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.6), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 15, x: 0, y: 8)
    }
    
    // toggle button
    @ViewBuilder
    private func toggleSetting(title: String, subtitle: String, icon: String, isOn: Binding<Bool>) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.purple.opacity(0.7))
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(.purple.opacity(0.8))
        }
    }
    
    // MARK: - Premium Section
    
    // premium section in the edit button
    @ViewBuilder
    private func premiumSection() -> some View {
        VStack(spacing: 16) {
            HStack {
                ZStack {
                    Image(systemName: "fish.fill")
                        .font(.system(size: 20))
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
                        .frame(width: 10, height: 10)
                        .offset(x: -3, y: -3)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("KOI Premium")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.orange, Color.yellow.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    Text("Unlimited recipes, AI suggestions & more")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "crown.fill")
                    .font(.title2)
                    .foregroundColor(.yellow)
            }
            
            HStack(spacing: 12) {
                premiumFeature(icon: "infinity", text: "Unlimited Saves")
                premiumFeature(icon: "brain.head.profile", text: "AI Features")
                premiumFeature(icon: "star.fill", text: "Priority Support")
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [Color.orange.opacity(0.1), Color.yellow.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .blur(radius: 0.5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        colors: [Color.orange.opacity(0.3), Color.yellow.opacity(0.2)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: 1.5
                )
        )
        .shadow(color: Color.orange.opacity(0.1), radius: 15, x: 0, y: 8)
    }
    
    // shows if you have premium
    @ViewBuilder
    private func premiumFeature(icon: String, text: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.orange)
            
            Text(text)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.orange.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.5))
        )
    }
    
    // MARK: - Action Buttons Section
    
    // button for the saving
    @ViewBuilder
    private func actionButtonsSection() -> some View {
        VStack(spacing: 12) {
            // Save button
            Button(action: {
                Task {
                    isSavingProfile = true
                    await saveUserChanges(
                        username: tempUsername,
                        bio: tempBio,
                        email: user?.email,
                        allergies: tempAllergies,
                        preferences: tempPreferences
                    )
                    isSavingProfile = false
                    
                    await MainActor.run {
                        showEditProfile = false
                    }
                }
            }) {
                HStack(spacing: 8) {
                    if isSavingProfile {
                        ProgressView()
                            .scaleEffect(0.8)
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.body)
                    }
                    
                    Text(isSavingProfile ? "Saving..." : "Save Changes")
                        .font(.body)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.purple.opacity(isSavingProfile ? 0.6 : 0.9))
                )
                .shadow(color: Color.purple.opacity(0.3), radius: 12, x: 0, y: 6)
            }
            .disabled(isSavingProfile)
            
            // Cancel button
            Button(action: {
                showEditProfile = false
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "xmark.circle")
                        .font(.body)
                    Text("Cancel")
                        .font(.body)
                        .fontWeight(.medium)
                }
                .foregroundColor(.purple.opacity(0.8))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.6))
                        .blur(radius: 0.5)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.purple.opacity(0.2), lineWidth: 1)
                )
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func containerBackground() -> some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(Color.white.opacity(0.35))
            .blur(radius: 0.5)
    }
    
    private func containerBorder() -> some View {
        RoundedRectangle(cornerRadius: 20)
            .stroke(Color.white.opacity(0.6), lineWidth: 1)
    }
    
    // MARK: - Networking Functions
    
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
}
                        
