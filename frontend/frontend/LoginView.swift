//
//  LoginView.swift
//  GroceryDeals
//
//  Login view with navigation to SignupView
//

import Foundation
import SwiftUI

// MARK: - Auth Container View (Main Entry Point for Auth)
struct AuthContainerView: View {
    @State private var showSignUp = false
    
    var body: some View {
        NavigationStack {
            Group {
                if showSignUp {
                    SignUpView(showSignUp: $showSignUp)
                } else {
                    LoginView(showSignUp: $showSignUp)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: showSignUp)
        }
    }
}

// MARK: - Login View
struct LoginView: View {
    @Binding var showSignUp: Bool
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var isLoading = false
    @State private var showPassword = false
    @State private var rememberMe = false
    @AppStorage("isAuthenticated") private var isAuthenticated = false
    
    @StateObject private var authManager = AuthenticationManager()
    private let networkService = NetworkService()
    
    // Default initializer for when called without binding
    init(showSignUp: Binding<Bool> = .constant(false)) {
        self._showSignUp = showSignUp
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Gradient background
                LinearGradient(
                    colors: [
                        Color(red: 0.4, green: 0.3, blue: 0.8),
                        Color(red: 0.6, green: 0.4, blue: 0.9)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Top section with illustration and welcome text
                        VStack(spacing: 24) {
                            Spacer(minLength: 60)
                            
                            // App icon/illustration placeholder
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.1))
                                    .frame(width: 120, height: 120)
                                
                                Image(systemName: "cart.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.white)
                            }
                            
                            VStack(spacing: 8) {
                                Text("Welcome Back!")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Text("Find the best grocery deals\nnear you")
                                    .font(.system(size: 16, weight: .regular))
                                    .foregroundColor(.white.opacity(0.8))
                                    .multilineTextAlignment(.center)
                                    .lineSpacing(2)
                            }
                        }
                        .padding(.horizontal, 32)
                        
                        Spacer(minLength: 40)
                        
                        // Login form card
                        VStack(spacing: 0) {
                            VStack(spacing: 24) {
                                // Email field
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Email")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.gray)
                                    
                                    HStack {
                                        Image(systemName: "envelope")
                                            .foregroundColor(.gray)
                                            .frame(width: 20)
                                        
                                        TextField("Enter your email", text: $email)
                                            .keyboardType(.emailAddress)
                                            .autocapitalization(.none)
                                            .autocorrectionDisabled()
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(email.isEmpty ? Color.clear : Color.blue.opacity(0.3), lineWidth: 1)
                                    )
                                }
                                
                                // Password field
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Password")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.gray)
                                    
                                    HStack {
                                        Image(systemName: "lock")
                                            .foregroundColor(.gray)
                                            .frame(width: 20)
                                        
                                        Group {
                                            if showPassword {
                                                TextField("Enter your password", text: $password)
                                            } else {
                                                SecureField("Enter your password", text: $password)
                                            }
                                        }
                                        
                                        Button(action: {
                                            showPassword.toggle()
                                        }) {
                                            Image(systemName: showPassword ? "eye.slash" : "eye")
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(password.isEmpty ? Color.clear : Color.blue.opacity(0.3), lineWidth: 1)
                                    )
                                }
                                
                                // Remember me and forgot password
                                HStack {
                                    HStack(spacing: 8) {
                                        Button(action: {
                                            rememberMe.toggle()
                                        }) {
                                            Image(systemName: rememberMe ? "checkmark.square.fill" : "square")
                                                .foregroundColor(rememberMe ? .blue : .gray)
                                        }
                                        
                                        Text("Remember me")
                                            .font(.system(size: 14))
                                            .foregroundColor(.gray)
                                    }
                                    
                                    Spacer()
                                    
                                    Button("Forgot Password?") {
                                        // Handle forgot password
                                    }
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.blue)
                                }
                                
                                // Error message
                                if !errorMessage.isEmpty {
                                    HStack {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundColor(.red)
                                        Text(errorMessage)
                                            .font(.system(size: 14))
                                            .foregroundColor(.red)
                                        Spacer()
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(Color.red.opacity(0.1))
                                    .cornerRadius(8)
                                }
                                
                                // Login button
                                Button(action: {
                                    Task {
                                        await login()
                                    }
                                }) {
                                    HStack {
                                        if isLoading {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                                .scaleEffect(0.8)
                                        } else {
                                            Text("Sign In")
                                                .font(.system(size: 16, weight: .semibold))
                                        }
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(
                                        LinearGradient(
                                            colors: [Color.blue, Color.blue.opacity(0.8)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(12)
                                    .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
                                }
                                .disabled(isLoading || email.isEmpty || password.isEmpty)
                                .opacity(isLoading || email.isEmpty || password.isEmpty ? 0.6 : 1.0)
                                
                                // Divider
                                HStack {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(height: 1)
                                    
                                    Text("or")
                                        .font(.system(size: 14))
                                        .foregroundColor(.gray)
                                        .padding(.horizontal, 16)
                                    
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(height: 1)
                                }
                                
                                // Social login buttons
                                VStack(spacing: 12) {
                                    // Google sign in
                                    Button(action: {
                                        // Handle Google sign in
                                    }) {
                                        HStack(spacing: 12) {
                                            Image(systemName: "globe")
                                                .foregroundColor(.black)
                                            
                                            Text("Continue with Google")
                                                .font(.system(size: 16, weight: .medium))
                                                .foregroundColor(.black)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(Color.white)
                                        .cornerRadius(12)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                        )
                                    }
                                    
                                    // Apple sign in
                                    Button(action: {
                                        // Handle Apple sign in
                                    }) {
                                        HStack(spacing: 12) {
                                            Image(systemName: "applelogo")
                                                .foregroundColor(.white)
                                            
                                            Text("Continue with Apple")
                                                .font(.system(size: 16, weight: .medium))
                                                .foregroundColor(.white)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(Color.black)
                                        .cornerRadius(12)
                                    }
                                }
                            }
                            .padding(.horizontal, 32)
                            .padding(.vertical, 32)
                            .background(Color.white)
                            .cornerRadius(24, corners: [.topLeft, .topRight])
                            
                            // Sign up section
                            VStack(spacing: 0) {
                                HStack(spacing: 4) {
                                    Text("Don't have an account?")
                                        .font(.system(size: 14))
                                        .foregroundColor(.gray)
                                    
                                    Button("Sign Up") {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            showSignUp = true
                                        }
                                    }
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.blue)
                                }
                                .padding(.bottom, 25)
                                .frame(maxWidth: .infinity)
                                .background(Color.white)
                            }
                            .cornerRadius(36, corners: [.bottomLeft, .bottomRight])
                        }
                    }
                }
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .onAppear {
            // Check for existing authentication on view appear
            do {
                let _ = try authManager.checkForJWTLocally()
            } catch {
                // Token not found or invalid, user needs to login
                print("No valid token found, user needs to login")
            }
        }
    }
    
    @MainActor
    func login() async {
        guard !email.isEmpty && !password.isEmpty else {
            errorMessage = "Please enter both email and password"
            return
        }
        
        errorMessage = ""
        isLoading = true
        
        do {
            let loginResponse: LoginResponse? = try await networkService.requestEndpoint(
                endpoint: "/auth/login",
                method: "POST",
                body: ["email": email, "password": password]
            )

            guard let response = loginResponse else {
                errorMessage = "No response received from server"
                isLoading = false
                return
            }

            // Save token to keychain
            try KeychainManager.instance.saveToken(response.token, forKey: "authToken")
            print("Token saved successfully")

            // Save user data to UserDefaults
            saveUserToDefaults(user: response.user)

            // Update authentication state
            isAuthenticated = true
            authManager.isAuthenticated = true
            authManager.shouldShowLogin = false
            
            // Clear form
            email = ""
            password = ""
            
        } catch let requestError as RequestError {
            switch requestError {
            case .invalidURL:
                errorMessage = "Invalid server URL"
            case .requestFailed(let message):
                errorMessage = message
            case .emptyResponse:
                errorMessage = "Empty response from server"
            }
        } catch {
            errorMessage = "Login failed. Please try again."
            print("Login error:", error)
        }
        
        isLoading = false
    }
}

// MARK: - Extensions
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Preview
struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        AuthContainerView()
    }
}
