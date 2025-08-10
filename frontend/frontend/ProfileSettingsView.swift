//
//  ProfileSettingsView.swift
//  frontend
//
//  Created by Jayden Zhang on 7/29/25.
//

import SwiftUI

struct ProfileSettingsView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    
    @Binding var user: UserInfo?
    @Binding var showSettings: Bool
    @Binding var showTOS: Bool
    @Binding var isChangingPassword: Bool
    @Binding var passwordError: String?
    @Binding var showSuccessMessage: Bool
    
    @State private var tempEmail = ""
    @State private var tempCurrentPassword = ""
    @State private var tempNewPassword = ""
    @State private var tempConfirmPassword = ""
    @State private var showDeleteConfirmation = false
    @State private var isSavingProfile = false
    
    var body: some View {
        NavigationView {
            ZStack {
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
                            HStack(spacing: 12) {
                                Image(systemName: "gearshape.fill")
                                    .font(.title2)
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [Color.purple.opacity(0.8), Color.blue.opacity(0.6)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                
                                Text("Settings")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [Color.primary, Color.gray.opacity(0.8)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            }
                            
                            Text("Manage your account preferences")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 20)
                        
                        // Account Settings Section
                        accountSettingsSection()
                        
                        // Security Settings Section
                        securitySettingsSection()
                        
                        // App Settings Section
                        appSettingsSection()
                        
                        // About Section
                        aboutSection()
                        
                        // Danger Zone Section
                        dangerZoneSection()
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
            }
            .navigationBarHidden(true)
            .alert("Delete Account", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    Task {
                        await deleteAccount()
                    }
                }
            } message: {
                Text("Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently lost.")
            }
        }
        .onAppear {
            tempEmail = user?.email ?? ""
        }
    }
    
    // MARK: - Account Settings Section
    
    // settings modal
    @ViewBuilder
    private func accountSettingsSection() -> some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 16) {
                // Header section
                accountSettingsHeader()
                
                // Email field
                emailSection()
                
                // Update button
                updateEmailButton()
                
                // Account type section
                accountTypeSection()
            }
        }
        .padding(20)
        .background(containerBackground())
        .overlay(containerBorder())
        .shadow(color: Color.black.opacity(0.05), radius: 15, x: 0, y: 8)
    }
    
    @ViewBuilder
    private func accountSettingsHeader() -> some View {
        HStack(spacing: 8) {
            Image(systemName: "person.circle.fill")
                .font(.title3)
                .foregroundColor(.purple.opacity(0.7))
            
            Text("Account Settings")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
    }
    
    @ViewBuilder
    private func emailSection() -> some View {
        editField(
            title: "Email Address",
            text: $tempEmail,
            icon: "envelope.fill",
            placeholder: "Enter your email"
        )
    }
    
    @ViewBuilder
    private func updateEmailButton() -> some View {
        Button(action: {
            Task {
                isSavingProfile = true
                await saveUserChanges(
                    username: user?.name,
                    bio: user?.bio,
                    email: tempEmail,
                    allergies: user?.allergies
                )
                isSavingProfile = false
                
                await MainActor.run {
                    showSettings = false
                }
            }
        }) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.clockwise")
                    .font(.caption)
                Text("Update Email")
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(updateButtonBackground())
            .shadow(color: Color.purple.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
    
    @ViewBuilder
    private func accountTypeSection() -> some View {
        HStack {
            accountTypeIcon()
            accountTypeInfo()
            Spacer()
            upgradeButtonIfNeeded()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(accountTypeBackground())
    }
    
    @ViewBuilder
    private func accountTypeIcon() -> some View {
        Image(systemName: user?.isSubscribed == true ? "crown.fill" : "person.fill")
            .font(.title3)
            .foregroundColor(user?.isSubscribed == true ? .orange : .purple.opacity(0.7))
            .frame(width: 24)
    }
    
    @ViewBuilder
    private func accountTypeInfo() -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Account Type")
                .font(.body)
                .fontWeight(.medium)
            
            Text(user?.isSubscribed == true ? "KOI Premium" : "Free Account")
                .font(.caption)
                .foregroundColor(user?.isSubscribed == true ? .orange : .secondary)
        }
    }
    
    @ViewBuilder
    private func upgradeButtonIfNeeded() -> some View {
        if user?.isSubscribed != true {
            Button("Upgrade") {
                // Handle premium upgrade
            }
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(upgradeButtonBackground())
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }
    
    private func containerBackground() -> some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(Color.white.opacity(0.35))
            .blur(radius: 0.5)
    }
    
    private func containerBorder() -> some View {
        RoundedRectangle(cornerRadius: 20)
            .stroke(Color.white.opacity(0.6), lineWidth: 1)
    }
    
    private func updateButtonBackground() -> some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.purple.opacity(0.9))
    }
    
    private func upgradeButtonBackground() -> some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.purple.opacity(0.9))
    }
    
    private func accountTypeBackground() -> some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(user?.isSubscribed == true ? .orange.opacity(0.2) : .purple.opacity(0.2))
    }
    
    // MARK: - Security Settings Section
    
    // password changing section
    private func handlePasswordChange(
        current: String,
        new: String,
        confirm: String
    ) async {
        // Reset previous states
        await MainActor.run {
            passwordError = nil
            showSuccessMessage = false
            isChangingPassword = true
        }
        
        // Validate passwords using your existing validatePasswords function
        let validation = validatePasswords(current: current, new: new, confirm: confirm)
        if !validation.isValid {
            await MainActor.run {
                passwordError = validation.error
                isChangingPassword = false
            }
            return
        }
        
        // Make API call using your existing changePassword function
        do {
            try await changePassword(oldPassword: current, newPassword: new)
            
            // Success - clear fields and show success message
            await MainActor.run {
                tempCurrentPassword = ""
                tempNewPassword = ""
                tempConfirmPassword = ""
                showSuccessMessage = true
                isChangingPassword = false
            }
            
            // Hide success message after 3 seconds
            try await Task.sleep(nanoseconds: 3_000_000_000)
            await MainActor.run {
                showSuccessMessage = false
            }
            
        } catch {
            // Handle error
            await MainActor.run {
                passwordError = "Failed to update password. Please check your current password and try again."
                isChangingPassword = false
            }
        }
    }

    @ViewBuilder
    private func securitySettingsSection() -> some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 8) {
                    Image(systemName: "lock.shield.fill")
                        .font(.title3)
                        .foregroundColor(.purple.opacity(0.7))

                    Text("Security")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }

                // Current Password
                secureField(
                    title: "Current Password",
                    text: $tempCurrentPassword,
                    icon: "key.fill",
                    placeholder: "Enter current password"
                )

                // New Password
                secureField(
                    title: "New Password",
                    text: $tempNewPassword,
                    icon: "lock.fill",
                    placeholder: "Enter new password"
                )

                // Confirm Password
                secureField(
                    title: "Confirm New Password",
                    text: $tempConfirmPassword,
                    icon: "lock.fill",
                    placeholder: "Confirm new password"
                )

                Button(action: {
                    Task {
                        await handlePasswordChange(
                            current: tempCurrentPassword,
                            new: tempNewPassword,
                            confirm: tempConfirmPassword
                        )
                    }
                }) {
                    HStack(spacing: 8) {
                        if isChangingPassword {
                            ProgressView()
                                .scaleEffect(0.8)
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: "arrow.clockwise")
                                .font(.caption)
                        }
                        Text(isChangingPassword ? "Updating..." : "Update Password")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.purple.opacity(isChangingPassword ? 0.6 : 0.9))
                    )
                    .shadow(color: Color.purple.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .disabled(isChangingPassword)
                .frame(maxWidth: .infinity, alignment: .center)
                
                // Error message
                if let passwordError = passwordError {
                    Text(passwordError)
                        .font(.caption)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                
                // Success message
                if showSuccessMessage {
                    Text("Password updated successfully!")
                        .font(.caption)
                        .foregroundColor(.green)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
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
    
    // MARK: - App Settings Section
    
    // app preferences
    @ViewBuilder
    private func appSettingsSection() -> some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 8) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.title3)
                        .foregroundColor(.purple.opacity(0.7))
                    
                    Text("App Preferences")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
                
                // Language Setting
                settingsRow(
                    icon: "globe",
                    title: "Language",
                    subtitle: "English",
                    hasChevron: true
                ) {
                    // Handle language selection
                }
                
                Divider()
                    .background(Color.white.opacity(0.3))
                
                // Theme Setting
                settingsRow(
                    icon: "paintbrush.fill",
                    title: "App Theme",
                    subtitle: "System",
                    hasChevron: true
                ) {
                    // Handle theme selection
                }
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
    
    // MARK: - About Section
    
    // about and legal part
    @ViewBuilder
    private func aboutSection() -> some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .font(.title3)
                        .foregroundColor(.purple.opacity(0.7))
                    
                    Text("About & Legal")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
                
                settingsRow(
                    icon: "doc.text.fill",
                    title: "Terms of Service",
                    subtitle: "Review our terms",
                    hasChevron: true
                ) {
                    showSettings = false
                    showTOS = true
                }
                
                Divider()
                    .background(Color.white.opacity(0.3))
                
                // Privacy Policy
                settingsRow(
                    icon: "hand.raised.fill",
                    title: "Privacy Policy",
                    subtitle: "How we protect your data",
                    hasChevron: true
                ) {
                    // Handle privacy policy display
                }
                
                Divider()
                    .background(Color.white.opacity(0.3))
                
                // Help & Support
                settingsRow(
                    icon: "questionmark.circle.fill",
                    title: "Help & Support",
                    subtitle: "Get assistance",
                    hasChevron: true
                ) {
                    // Handle help section
                }
                
                Divider()
                    .background(Color.white.opacity(0.3))
                
                // App Version
                HStack {
                    Image(systemName: "app.badge.fill")
                        .font(.title3)
                        .foregroundColor(.purple.opacity(0.7))
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("App Version")
                            .font(.body)
                            .fontWeight(.medium)
                        
                        Text("KOI v2.1.0 (Build 245)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
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
    
    // MARK: - Danger Zone Section
    
    // delete and sign out features
    @ViewBuilder
    private func dangerZoneSection() -> some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.title3)
                        .foregroundColor(.red.opacity(0.8))
                    
                    Text("Danger Zone")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.red.opacity(0.8))
                }
                
                // Sign Out
                settingsRow(
                    icon: "rectangle.portrait.and.arrow.right",
                    title: "Sign Out",
                    subtitle: "Sign out of your account",
                    hasChevron: false,
                    textColor: .orange
                ) {
                    Task {
                        await logout()
                    }
                }
                
                Divider()
                    .background(Color.red.opacity(0.2))
                
                // Delete Account
                settingsRow(
                    icon: "trash.fill",
                    title: "Delete Account",
                    subtitle: "Permanently delete your account",
                    hasChevron: false,
                    textColor: .red
                ) {
                    showDeleteConfirmation = true
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.red.opacity(0.05))
                .blur(radius: 0.5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.red.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: Color.red.opacity(0.05), radius: 15, x: 0, y: 8)
    }
    
    // MARK: - Helper Components
    
    // Helper function for secure text fields
    @ViewBuilder
    private func secureField(title: String, text: Binding<String>, icon: String, placeholder: String) -> some View {
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
            
            SecureField(placeholder, text: text)
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
    
    // Helper function for regular text fields
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
    
    // Helper function for settings rows
    @ViewBuilder
    private func settingsRow(
        icon: String,
        title: String,
        subtitle: String,
        hasChevron: Bool,
        textColor: Color = .primary,
        action: @escaping () -> Void = {}
    ) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(textColor == .primary ? .purple.opacity(0.7) : textColor)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(textColor)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if hasChevron {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
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
    
    private func deleteAccount() async {
        let network = NetworkService()
        
        do {
            // Make API call to delete account
            let _: EmptyResponse? = try await network.requestEndpoint(
                endpoint: "/auth/delete-account",
                method: "GET",
                body: nil  // No body needed for GET request
            )
            
            // If successful, clear all local data
            await MainActor.run {
                clearUserData()
                // Navigate back to login/welcome screen
                // You might want to dismiss all sheets and reset navigation
            }
            
            print("Account deleted successfully")
            
        } catch {
            await MainActor.run {
                print("Failed to delete account:", error)
                // Show error alert to user
                // self.showErrorAlert = true
                // self.errorMessage = "Failed to delete account. Please try again."
            }
        }
    }
    
    private func logout() async {
        let network = NetworkService()
        
        do {
            // Call the logout endpoint
            let _: EmptyResponse? = try await network.requestEndpoint(
                endpoint: "/auth/logout",
                method: "GET",
                body: nil
            )
            
            // Clear local data regardless of API response
            await MainActor.run {
                clearUserData()
                showSettings = false
                authManager.isAuthenticated = false
                authManager.shouldShowLogin = true
            }
            
            print("Logged out successfully")
            
        } catch {
            // Even if the API call fails, clear local data
            await MainActor.run {
                clearUserData()
                print("Logout API failed, but cleared local data: \(error)")
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
        // Reset any other @State variables
    }
    
    private func changePassword(oldPassword: String, newPassword: String) async throws {
        let network = NetworkService()
        
        do {
            let requestBody = [
                "old_password": oldPassword,
                "new_password": newPassword
            ]
            
            let _: EmptyResponse? = try await network.requestEndpoint(
                endpoint: "/auth/change-password",
                method: "POST",
                body: requestBody
            )
            
            print("Password changed successfully")
            
        } catch {
            print("Failed to change password:", error)
            throw error
        }
    }
    
    private func validatePasswords(current: String, new: String, confirm: String) -> (isValid: Bool, error: String?) {
        // Check if any field is empty
        if current.isEmpty {
            return (false, "Current password is required")
        }
        
        if new.isEmpty {
            return (false, "New password is required")
        }
        
        if confirm.isEmpty {
            return (false, "Please confirm your new password")
        }
        
        if new != confirm {
            return (false, "New passwords don't match")
        }
        
        if current == new {
            return (false, "New password must be different from current password")
        }
        
        if new.count < 8 {
            return (false, "New password must be at least 8 characters long")
        }
        
        return (true, nil)
    }
}
