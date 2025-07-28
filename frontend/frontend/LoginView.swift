//
//  LoginView.swift
//  GroceryDeals
//
//  Login view with navigation to SignupView
//

import Foundation
import SwiftUI

// MARK: - Auth Models
struct LoginRequest: Codable {
    let email: String
    let password: String
}

struct SignUpRequest: Codable {
    let email: String
    let password: String
}

enum AuthError: Error, LocalizedError {
    case invalidURL
    case noData
    case invalidCredentials
    case emailAlreadyExists
    case passwordTooWeak
    case serverError
    case networkError(Error)
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid server URL"
        case .noData:
            return "No data received from server"
        case .invalidCredentials:
            return "Invalid email or password"
        case .emailAlreadyExists:
            return "An account with this email already exists"
        case .passwordTooWeak:
            return "Password is too weak. Please choose a stronger password"
        case .serverError:
            return "Server error occurred"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError:
            return "Failed to process server response"
        }
    }
}

// MARK: - Network Manager
@MainActor
class NetworkManager: ObservableObject {
    static let shared = NetworkManager()
    
    // Replace with your actual server URL
    private let baseURL = Bundle.main.infoDictionary?["BASE_URL"] as! String
    private let session: URLSession
    
    private init() {
        let config = URLSessionConfiguration.default
        config.httpCookieStorage = HTTPCookieStorage.shared
        config.httpShouldSetCookies = true
        config.timeoutIntervalForRequest = 30.0
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - Login Function
    func login(email: String, password: String) async throws {
        guard let url = URL(string: "\(baseURL)/auth/login") else {
            throw AuthError.invalidURL
        }
        
        let loginRequest = LoginRequest(email: email, password: password)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONEncoder().encode(loginRequest)
        } catch {
            throw AuthError.networkError(error)
        }
        
        do {
            let (_, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AuthError.serverError
            }
            
            switch httpResponse.statusCode {
            case 200:
                return
            case 401:
                throw AuthError.invalidCredentials
            default:
                throw AuthError.serverError
            }
            
        } catch {
            if error is AuthError {
                throw error
            } else {
                throw AuthError.networkError(error)
            }
        }
        
    }
    
    // MARK: - Sign Up Function
    func signUp(email: String, password: String) async throws {
        guard let url = URL(string: "\(baseURL)/auth/signup") else {
            throw AuthError.invalidURL
        }
        
        let signUpRequest = SignUpRequest(email: email, password: password)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONEncoder().encode(signUpRequest)
        } catch {
            throw AuthError.networkError(error)
        }
        
        do {
            let (_, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AuthError.serverError
            }
            
            switch httpResponse.statusCode {
            case 200, 201:
                return
            case 400:
                throw AuthError.passwordTooWeak
            case 401:
                throw AuthError.emailAlreadyExists
            default:
                throw AuthError.serverError
            }
            
        } catch {
            if error is AuthError {
                throw error
            } else {
                throw AuthError.networkError(error)
            }
        }
    }
    
    // MARK: - Check Authentication Status
    func checkAuthStatus() -> Bool {
        guard let cookies = HTTPCookieStorage.shared.cookies else {
            return false
        }
        
        return cookies.contains { cookie in
            cookie.name == "auth_token" && !cookie.value.isEmpty
        }
    }
}

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
    
    @StateObject private var networkManager = NetworkManager.shared
    
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
            if networkManager.checkAuthStatus() {
                isAuthenticated = true
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
            try await networkManager.login(email: email, password: password)
            isAuthenticated = true
            email = ""
            password = ""
        } catch let authError as AuthError {
            errorMessage = authError.localizedDescription
        } catch {
            errorMessage = "An unexpected error occurred"
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
