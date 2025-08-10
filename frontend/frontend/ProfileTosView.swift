//
//  ProfileTOSView.swift
//  frontend
//
//  Created by Jayden Zhang on 7/29/25.
//

import SwiftUI

struct ProfileTOSView: View {
    @Binding var showTOS: Bool
    
    var body: some View {
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
    
    // MARK: - Helper Components
    
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
}
                