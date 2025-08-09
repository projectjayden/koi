//
//  MainView.swift
//  frontend
//
//  Created by Jayden Zhang on 8/7/25.
//

import SwiftUI

struct MainView: View {
    @StateObject private var authManager = AuthenticationManager()
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var showOnboarding = false
    @State private var isCheckingAuth = true
    
    var body: some View {
        ZStack {
            if isCheckingAuth {
                // Loading screen while checking authentication
                LoadingView()
            } else if showOnboarding && !hasSeenOnboarding {
                // Show onboarding for first-time users
                OnboardingView(
                    showOnboarding: $showOnboarding,
                    onComplete: {
                        hasSeenOnboarding = true
                        showOnboarding = false
                        // After onboarding, check if they need to login
                        if !authManager.isAuthenticated {
                            authManager.shouldShowLogin = true
                        }
                    }
                )
            } else if authManager.shouldShowLogin || !authManager.isAuthenticated {
                // Show login/signup flow
                LoginSignupFlow()
                    .environmentObject(authManager)
            } else {
                // User is authenticated - show main app
                tabsView() // Your existing tab view goes here
                    .environmentObject(authManager)
            }
        }
        .animation(.easeInOut(duration: 0.5), value: authManager.isAuthenticated)
        .animation(.easeInOut(duration: 0.5), value: showOnboarding)
        .onAppear {
            checkAuthenticationStatus()
        }

    }
    
    private func checkAuthenticationStatus() {
        Task {
            do {
                // Check for existing JWT token
                _ = try authManager.checkForJWTLocally()
            } catch {
                // No valid token found - user needs to see onboarding or login
                DispatchQueue.main.async {
                    if !hasSeenOnboarding {
                        showOnboarding = true
                    } else {
                        authManager.shouldShowLogin = true
                    }
                    // Move this inside the catch block to ensure state is set before stopping loading
                    isCheckingAuth = false
                }
                return // Exit early to avoid setting isCheckingAuth = false twice
            }
            
            // Only reach here if authentication check was successful
            DispatchQueue.main.async {
                isCheckingAuth = false
            }
        }
    }
}

// MARK: - Loading View
struct LoadingView: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.4, green: 0.3, blue: 0.8),
                    Color(red: 0.6, green: 0.4, blue: 0.9),
                    Color(red: 0.5, green: 0.6, blue: 1.0)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Image(systemName: "cart.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.white)
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isAnimating)
                
                Text("Koi")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.2)
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Login/Signup Navigation Flow
struct LoginSignupFlow: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var showSignup = false
    
    var body: some View {
        NavigationStack {
            if showSignup {
                SignUpView(showSignUp: $showSignup)
                    .environmentObject(authManager)
            } else {
                LoginView(showSignUp: $showSignup)
                    .environmentObject(authManager)
            }
        }
    }
}

// MARK: - Updated Onboarding View
struct OnboardingView: View {
    @Binding var showOnboarding: Bool
    let onComplete: () -> Void
    @State private var currentPage = 0
    @State private var animateContent = false
    
    private let onboardingPages = [
        OnboardingPage(
            icon: "cart.fill",
            title: "Smart Shopping",
            subtitle: "Find the Best Deals",
            description: "Compare prices across multiple grocery stores and never overpay again"
        ),
        OnboardingPage(
            icon: "location.fill",
            title: "Near You",
            subtitle: "Local Store Finder",
            description: "Discover grocery stores around you with real-time pricing and availability"
        ),
        OnboardingPage(
            icon: "dollarsign.circle.fill",
            title: "Save More",
            subtitle: "Maximum Savings",
            description: "Get personalized recommendations and save up to 40% on your grocery bills"
        )
    ]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Gradient background
                LinearGradient(
                    colors: [
                        Color(red: 0.4, green: 0.3, blue: 0.8),
                        Color(red: 0.6, green: 0.4, blue: 0.9),
                        Color(red: 0.5, green: 0.6, blue: 1.0)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Skip button
                    HStack {
                        Spacer()
                        Button("Skip") {
                            onComplete()
                        }
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                    }
                    
                    Spacer(minLength: 40)
                    
                    // Main content
                    TabView(selection: $currentPage) {
                        ForEach(0..<onboardingPages.count, id: \.self) { index in
                            OnboardingPageView(
                                page: onboardingPages[index],
                                isActive: currentPage == index
                            )
                            .tag(index)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .frame(height: geometry.size.height * 0.65)
                    
                    Spacer(minLength: 30)
                    
                    // Bottom section
                    VStack(spacing: 24) {
                        // Page indicators
                        HStack(spacing: 8) {
                            ForEach(0..<onboardingPages.count, id: \.self) { index in
                                Circle()
                                    .fill(currentPage == index ? Color.white : Color.white.opacity(0.4))
                                    .frame(width: currentPage == index ? 12 : 8, height: currentPage == index ? 12 : 8)
                                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: currentPage)
                            }
                        }
                        
                        // Action buttons
                        VStack(spacing: 16) {
                            if currentPage == onboardingPages.count - 1 {
                                // Get Started button (final page)
                                Button(action: {
                                    onComplete()
                                }) {
                                    HStack {
                                        Text("Get Started")
                                            .font(.system(size: 18, weight: .semibold))
                                        
                                        Image(systemName: "arrow.right")
                                            .font(.system(size: 16, weight: .semibold))
                                    }
                                    .foregroundColor(Color(red: 0.4, green: 0.3, blue: 0.8))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Color.white)
                                    .cornerRadius(16)
                                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                                }
                                .scaleEffect(animateContent ? 1.0 : 0.8)
                                .opacity(animateContent ? 1.0 : 0.0)
                                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: animateContent)
                                
                            } else {
                                // Next button
                                Button(action: {
                                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                        currentPage += 1
                                    }
                                }) {
                                    HStack {
                                        Text("Next")
                                            .font(.system(size: 18, weight: .semibold))
                                        
                                        Image(systemName: "arrow.right")
                                            .font(.system(size: 16, weight: .semibold))
                                    }
                                    .foregroundColor(Color(red: 0.4, green: 0.3, blue: 0.8))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Color.white)
                                    .cornerRadius(16)
                                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                                }
                            }
                            
                            // Sign in option
                            Button(action: {
                                onComplete()
                            }) {
                                HStack(spacing: 4) {
                                    Text("Already have an account?")
                                        .font(.system(size: 16))
                                        .foregroundColor(.white.opacity(0.8))
                                    
                                    Text("Sign In")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .padding(.horizontal, 32)
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.3)) {
                animateContent = true
            }
        }
        .onChange(of: currentPage) {
            // Reset animation for new page
            animateContent = false
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                animateContent = true
            }
        }
    }
}

// MARK: - Onboarding Page Model
struct OnboardingPage {
    let icon: String
    let title: String
    let subtitle: String
    let description: String
}

// MARK: - Individual Onboarding Page View
struct OnboardingPageView: View {
    let page: OnboardingPage
    let isActive: Bool
    @State private var animateIcon = false
    @State private var animateText = false
    
    var body: some View {
        VStack(spacing: 32) {
            // Icon illustration
            ZStack {
                // Animated background circles
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 200, height: 200)
                    .scaleEffect(animateIcon ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: animateIcon)
                
                Circle()
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 240, height: 240)
                    .scaleEffect(animateIcon ? 0.9 : 1.0)
                    .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: animateIcon)
                
                // Main icon
                Image(systemName: page.icon)
                    .font(.system(size: 80, weight: .light))
                    .foregroundColor(.white)
                    .scaleEffect(animateIcon ? 1.1 : 1.0)
                    .animation(.spring(response: 0.8, dampingFraction: 0.6), value: animateIcon)
            }
            
            // Text content
            VStack(spacing: 16) {
                VStack(spacing: 8) {
                    Text(page.title)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .opacity(animateText ? 1.0 : 0.0)
                        .offset(y: animateText ? 0 : 20)
                        .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.2), value: animateText)
                    
                    Text(page.subtitle)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .opacity(animateText ? 1.0 : 0.0)
                        .offset(y: animateText ? 0 : 15)
                        .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.3), value: animateText)
                }
                
                Text(page.description)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 20)
                    .opacity(animateText ? 1.0 : 0.0)
                    .offset(y: animateText ? 0 : 10)
                    .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.4), value: animateText)
            }
        }
        .padding(.horizontal, 32)
        .onAppear {
            if isActive {
                startAnimations()
            }
        }
        .onChange(of: isActive) { _, active in
            if active {
                startAnimations()
            } else {
                resetAnimations()
            }
        }
    }
    
    private func startAnimations() {
        animateIcon = true
        withAnimation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.1)) {
            animateText = true
        }
    }
    
    private func resetAnimations() {
        animateIcon = false
        animateText = false
    }
}

// MARK: - Preview
struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
