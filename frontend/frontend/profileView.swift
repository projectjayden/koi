//
//  profileView.swift
//  frontend
//
//  Created by Jayden Zhang on 7/29/25.
//

import SwiftUI
import MapKit

struct profileView: View {
    @State private var selectedTab = 0 // index
    @State private var isAnimating = false
    @State private var showEditProfile = false // edit button
    @State private var showSettings = false
    @State private var showTOS = false
    
// FAKE ACCOUNT //
    @State private var user = userProfile(
        username: "foodie_explorer",
        profileID: 12345,
        profilePic: "person.crop.circle.fill",
        subscribed: true,
        savedRecipes: [1, 2, 3, 4, 5],
        personalLists: [
            lists(itemsInList: []),
            lists(itemsInList: []),
            lists(itemsInList: [])
        ],
        savedReviews: [
            (4.5, "Amazing pasta!", MKMapItem()),
            (5.0, "Best coffee in town", MKMapItem()),
            (4.0, "Great ambiance", MKMapItem())
        ],
        aiGeneratedLists: [
            lists(itemsInList: []),
            lists(itemsInList: [])
        ],
        fameStats: fame(
            followers: 1247,
            following: 892,
            listOfFollowersIDs: [],
            listOfFollowingIDs: []
        )
    )
    
    var body: some View {
        ZStack {
            KoiBackgroundView()
            
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
        }
        .onAppear {
            withAnimation {
                isAnimating = true
            }
        }
        .sheet(isPresented: $showEditProfile, onDismiss: {
            showEditProfile = false
        }) { // edit profile modal
            editProfileSheet()
        }
        .sheet(isPresented: $showSettings, onDismiss: {
            showSettings = false
        }) { // settings modal
            settingsSheet()
        }
        .sheet(isPresented: $showTOS, onDismiss: {
            showTOS = false
            showSettings = true
        }) {
            showTos()
        }
    }
    
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
                    
                    Image(systemName: user.profilePic)
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
                    Text("@\(user.username)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.primary, Color.gray.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    // subscription badge
                    if user.subscribed {
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
            if user.subscribed {
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
    
    // settings button
    @ViewBuilder
    private func settingsSheet() -> some View {
        @State var tempEmail = "user@example.com"
        @State var tempCurrentPassword = ""
        @State var tempNewPassword = ""
        @State var tempConfirmPassword = ""
        @State var showDeleteConfirmation = false
        
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
                        accountSettingsSection(tempEmail: $tempEmail)
                        
                        // Security Settings Section
                        securitySettingsSection(
                            tempCurrentPassword: $tempCurrentPassword,
                            tempNewPassword: $tempNewPassword,
                            tempConfirmPassword: $tempConfirmPassword
                        )
                        
                        // App Settings Section
                        appSettingsSection()
                        
                        // About Section
                        aboutSection()
                        
                        // Danger Zone Section
                        dangerZoneSection(showDeleteConfirmation: $showDeleteConfirmation)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
            }
            .navigationBarHidden(true)
            .alert("Delete Account", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    // Handle account deletion
                }
            } message: {
                Text("Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently lost.")
            }
        }
    }

    // settings modal
    @ViewBuilder
    private func accountSettingsSection(tempEmail: Binding<String>) -> some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 8) {
                    Image(systemName: "person.circle.fill")
                        .font(.title3)
                        .foregroundColor(.purple.opacity(0.7))
                    
                    Text("Account Settings")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
                
                // Email field
                editField(
                    title: "Email Address",
                    text: tempEmail,
                    icon: "envelope.fill",
                    placeholder: "Enter your email"
                )
                
                Button(action: {
                    // Handle password change
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
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.purple.opacity(0.9))
                    )
                    .shadow(color: Color.purple.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                
                // Account Type Display
                HStack {
                    Image(systemName: user.subscribed ? "crown.fill" : "person.fill")
                        .font(.title3)
                        .foregroundColor(user.subscribed ? .orange : .purple.opacity(0.7))
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Account Type")
                            .font(.body)
                            .fontWeight(.medium)
                        
                        Text(user.subscribed ? "KOI Premium" : "Free Account")
                            .font(.caption)
                            .foregroundColor(user.subscribed ? .orange : .secondary)
                    }
                    
                    Spacer()
                    
                    if !user.subscribed {
                        Button("Upgrade") {
                            // Handle premium upgrade
                        }
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.purple.opacity(0.9))
                        )
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(user.subscribed ? .orange.opacity(0.2) : .purple.opacity(0.2))
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

    // password changing section
    @ViewBuilder
    private func securitySettingsSection(
        tempCurrentPassword: Binding<String>,
        tempNewPassword: Binding<String>,
        tempConfirmPassword: Binding<String>
    ) -> some View {
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
                    text: tempCurrentPassword,
                    icon: "key.fill",
                    placeholder: "Enter current password"
                )
                
                // New Password
                secureField(
                    title: "New Password",
                    text: tempNewPassword,
                    icon: "lock.fill",
                    placeholder: "Enter new password"
                )
                
                // Confirm Password
                secureField(
                    title: "Confirm New Password",
                    text: tempConfirmPassword,
                    icon: "lock.fill",
                    placeholder: "Confirm new password"
                )
                
                // Change Password Button
                Button(action: {
                    // Handle password change
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.clockwise")
                            .font(.caption)
                        Text("Update Password")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.purple.opacity(0.9))
                    )
                    .shadow(color: Color.purple.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .frame(maxWidth: .infinity, alignment: .center)
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

    // delete and sign out features
    @ViewBuilder
    private func dangerZoneSection(showDeleteConfirmation: Binding<Bool>) -> some View {
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
                    // Handle sign out
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
                    showDeleteConfirmation.wrappedValue = true
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
    
    // TOS //
    
    private func showTos() -> some View {
        NavigationView {
            ZStack {
                // Beautiful gradient background matching your app theme
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
                        // Header Section
                        VStack(spacing: 12) {
                            HStack(spacing: 12) {
                                Image(systemName: "doc.text.fill")
                                    .font(.title2)
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [Color.purple.opacity(0.8), Color.blue.opacity(0.6)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                
                                Text("Terms of Service")
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
                            
                            Text("Effective Date: July 31, 2025")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(Color.white.opacity(0.6))
                                )
                        }
                        .padding(.top, 20)
                        
                        // Welcome Section
                        tosSection(
                            title: "Welcome to Koi",
                            content: "Welcome to Koi (\"the App\", \"we\", \"our\", or \"us\"). These Terms of Service (\"Terms\") govern your access to and use of the App, which helps users find the best prices and quality for grocery items at nearby supermarkets, create shopping lists, and receive AI-generated and preset recipes based on those lists.\n\nBy downloading, accessing, or using the App, you agree to be bound by these Terms. If you do not agree with these Terms, please do not use the App.",
                            icon: "hand.wave.fill",
                            accentColor: .blue
                        )
                        
                        // Eligibility Section
                        tosSection(
                            title: "1. Eligibility",
                            content: "You must be at least 13 years old (or the minimum age required in your jurisdiction) to use the App. If you are under the age of majority in your jurisdiction, you must have your parent or legal guardian's permission.",
                            icon: "person.badge.shield.checkmark.fill",
                            accentColor: .green
                        )
                        
                        // Services Section
                        tosSection(
                            title: "2. Description of Services",
                            content: "The App provides the following core features:\n• Detects your location to find nearby supermarkets\n• Helps you build a list of grocery items\n• Finds the best prices and quality options at local stores\n• Suggests AI-generated and curated recipes based on your list\n• Allows you to add ingredients from recipes directly to your list\n\nWe do not guarantee the availability, accuracy, or completeness of store pricing or inventory data.",
                            icon: "list.bullet.rectangle.fill",
                            accentColor: .purple
                        )
                        
                        // User Responsibilities Section
                        tosSection(
                            title: "3. User Responsibilities",
                            content: "You agree to use the App in compliance with all applicable laws and regulations. You agree not to:\n• Use the App for any illegal, harmful, or abusive purpose\n• Reverse-engineer, decompile, or disassemble any part of the App\n• Interfere with the App's functionality or security",
                            icon: "exclamationmark.shield.fill",
                            accentColor: .orange
                        )
                        
                        // Location Services Section
                        tosSection(
                            title: "4. Location Services",
                            content: "To provide personalized results, the App requires access to your device's location. By using the App, you consent to our use of location-based data in accordance with our Privacy Policy.",
                            icon: "location.fill",
                            accentColor: .red
                        )
                        
                        // Intellectual Property Section
                        tosSection(
                            title: "5. Intellectual Property",
                            content: "All content and features within the App (including but not limited to text, logos, designs, algorithms, recipes, and software) are the property of Koi or its licensors and are protected under intellectual property laws. You may not use this content without express permission.",
                            icon: "c.circle.fill",
                            accentColor: .indigo
                        )
                        
                        // AI Content Section
                        tosSection(
                            title: "7. AI-Generated Content",
                            content: "The App includes features that generate content using artificial intelligence. This content is provided for informational purposes only. We do not guarantee its accuracy, health or dietary suitability, or compliance with specific nutritional needs.",
                            icon: "brain.head.profile.fill",
                            accentColor: .purple
                        )
                        
                        // Contact Section
                        VStack(spacing: 16) {
                            Text("Need Help?")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            VStack(spacing: 12) {
                                HStack(spacing: 8) {
                                    Image(systemName: "envelope.fill")
                                        .foregroundColor(.purple.opacity(0.7))
                                    Text("koiSupport@gmail.com")
                                        .font(.body)
                                        .foregroundColor(.primary)
                                }
                                
                                Text("If you have questions about these Terms, please contact us at the email above.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.white.opacity(0.4))
                                .blur(radius: 0.5)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.purple.opacity(0.2), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.05), radius: 15, x: 0, y: 8)
                        
                        // Close Button
                        Button(action: {
                            showTOS = false
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.body)
                                Text("I Understand")
                                    .font(.body)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.purple.opacity(0.9))
                            )
                            .shadow(color: Color.purple.opacity(0.3), radius: 12, x: 0, y: 6)
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showTOS = false
                    }
                    .foregroundColor(.purple)
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled(false)
        .onDisappear {
            // This ensures the variable updates when modal is dismissed by swipe
            showTOS = false
        }
    }

    // Helper function for TOS sections
    @ViewBuilder
    private func tosSection(title: String, content: String, icon: String, accentColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(accentColor.opacity(0.8))
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            
            Text(content)
                .font(.body)
                .foregroundColor(.primary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
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
    
    // shows the recipes, followers, and following
    @ViewBuilder
    private func statsSection() -> some View {
        HStack(spacing: 0) {
            statCard(title: "Recipes", value: "\(user.savedRecipes.count)", icon: "book.fill")
            
            Divider()
                .frame(height: 40)
                .background(Color.white.opacity(0.3))
            
            statCard(title: "Followers", value: formatNumber(user.fameStats.followers), icon: "heart.fill")
            
            Divider()
                .frame(height: 40)
                .background(Color.white.opacity(0.3))
            
            statCard(title: "Following", value: formatNumber(user.fameStats.following), icon: "person.2.fill")
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
    
    // helper function to build the card
    @ViewBuilder
    private func statCard(title: String, value: String, icon: String) -> some View {
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
    }
    
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
    
    // helper function to display recipes
    @ViewBuilder
    private func recipesTab() -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
            ForEach(user.savedRecipes, id: \.self) { recipeId in
                recipeCard(id: recipeId)
            }
        }
    }
    
    // helper function to display lists
    @ViewBuilder
    private func listsTab() -> some View {
        VStack(spacing: 12) {
            ForEach(0..<user.personalLists.count, id: \.self) { index in
                listCard(title: "My List #\(index + 1)", itemCount: Int.random(in: 3...12))
            }
        }
    }
    
    // helper function to display reviews
    @ViewBuilder
    private func reviewsTab() -> some View {
        VStack(spacing: 12) {
            ForEach(0..<user.savedReviews.count, id: \.self) { index in
                reviewCard(review: user.savedReviews[index])
            }
        }
    }
    
    // helper function to display aiLists
    @ViewBuilder
    private func aiListsTab() -> some View {
        VStack(spacing: 12) {
            ForEach(0..<user.aiGeneratedLists.count, id: \.self) { index in
                aiListCard(title: "AI Suggestion #\(index + 1)")
            }
        }
    }
    
    // helper function for the recipes card
    @ViewBuilder
    private func recipeCard(id: Int) -> some View {
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
            
            Text("Recipe #\(id)")
                .font(.headline)
                .fontWeight(.semibold)
            
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
    private func reviewCard(review: (Double, String, MKMapItem)) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                ForEach(0..<5) { star in
                    Image(systemName: star < Int(review.0) ? "star.fill" : "star")
                        .foregroundColor(.yellow)
                        .font(.caption)
                }
                
                Spacer()
                
                Text("Restaurant")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(review.1)
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
    
// Edit Button //
    
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
    
    // the edit profile button
    @ViewBuilder
    private func editProfileSheet() -> some View {
        @State var tempUsername = user.username
        @State var tempBio = "Food enthusiast & recipe collector 🍜"
        @State var tempLocation = "San Francisco, CA"
        @State var tempPrivateAccount = false
        @State var tempNotifications = true
        
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
                        
                        // Basic Info Section
                        basicInfoSection(tempUsername: $tempUsername, tempBio: $tempBio, tempLocation: $tempLocation)
                        
                        // Privacy Settings Section
                        privacySettingsSection(tempPrivateAccount: $tempPrivateAccount, tempNotifications: $tempNotifications)
                        
                        // Premium Section (if subscribed)
                        if user.subscribed {
                            premiumSection()
                        }
                        
                        // Action Buttons
                        actionButtonsSection(
                            tempUsername: tempUsername,
                            tempBio: tempBio,
                            tempLocation: tempLocation,
                            tempPrivateAccount: tempPrivateAccount,
                            tempNotifications: tempNotifications
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
            }
            .navigationBarHidden(true)
        }
    }
    
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
                
                Image(systemName: user.profilePic)
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
    
    // edit the basic info
    @ViewBuilder
    private func basicInfoSection(tempUsername: Binding<String>, tempBio: Binding<String>, tempLocation: Binding<String>) -> some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Basic Information")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                // Username field
                editField(
                    title: "Username",
                    text: tempUsername,
                    icon: "at",
                    placeholder: "Enter username"
                )
                
                // Bio field
                editField(
                    title: "Bio",
                    text: tempBio,
                    icon: "text.alignleft",
                    placeholder: "Tell us about yourself"
                )
                
                // Location field
                editField(
                    title: "Location",
                    text: tempLocation,
                    icon: "location",
                    placeholder: "Your city"
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
    
    // edit field for the user's description
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
    
    // privacy settings
    @ViewBuilder
    private func privacySettingsSection(tempPrivateAccount: Binding<Bool>, tempNotifications: Binding<Bool>) -> some View {
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
                    isOn: tempPrivateAccount
                )
                
                // Notifications toggle
                toggleSetting(
                    title: "Push Notifications",
                    subtitle: "Get notified about new followers & recipes",
                    icon: "bell.fill",
                    isOn: tempNotifications
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
    
    // button for the saving
    @ViewBuilder
    private func actionButtonsSection(
        tempUsername: String,
        tempBio: String,
        tempLocation: String,
        tempPrivateAccount: Bool,
        tempNotifications: Bool
    ) -> some View {
        VStack(spacing: 12) {
            // Save button
            Button(action: {
                // Save all changes
                user.username = tempUsername
                // Save other changes to backend
                showEditProfile = false
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.body)
                    Text("Save Changes")
                        .font(.body)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.purple.opacity(0.9))
                )
                .shadow(color: Color.purple.opacity(0.3), radius: 12, x: 0, y: 6)
            }
            
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
    
    // helper functions
    
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
    
    private func extractUserProfile() {
        // pretend this extracts userProfile from the backend!
    }
}

#Preview {
    profileView()
}
