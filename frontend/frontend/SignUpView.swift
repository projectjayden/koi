//
//  SignUpView.swift
//  GroceryDeals
//
//  Signup view with navigation back to LoginView
//

import Foundation
import SwiftUI

// MARK: - Sign Up View
struct SignUpView: View {
    @Binding var showSignUp: Bool
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var name = ""
    @State private var bio = ""
    @State private var errorMessage = ""
    @State private var isLoading = false
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @State private var agreeToTerms = false
    @AppStorage("isAuthenticated") private var isAuthenticated = false
    
    @StateObject private var authManager = AuthenticationManager()
    private let networkService = NetworkService()
    
    private var passwordsMatch: Bool {
        password == confirmPassword && !confirmPassword.isEmpty
    }
    
    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty && !name.isEmpty && passwordsMatch && agreeToTerms
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
                            // Back button
                            HStack {
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        showSignUp = false
                                    }
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "chevron.left")
                                            .font(.system(size: 16, weight: .medium))
                                        Text("Back")
                                            .font(.system(size: 16, weight: .medium))
                                    }
                                    .foregroundColor(.white)
                                }
                                Spacer()
                            }
                            Spacer(minLength: 10)
                            // App icon/illustration placeholder
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.1))
                                    .frame(width: 100, height: 100)
                                
                                Image(systemName: "person.badge.plus")
                                    .font(.system(size: 40))
                                    .foregroundColor(.white)
                            }
                            
                            VStack(spacing: 8) {
                                Text("Create Account")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Text("Join us to discover amazing\ngrocery deals")
                                    .font(.system(size: 16, weight: .regular))
                                    .foregroundColor(.white.opacity(0.8))
                                    .multilineTextAlignment(.center)
                                    .lineSpacing(2)
                            }
                        }
                        .padding(.horizontal, 32)
                        
                        Spacer(minLength: 60)
                        
                        // Sign up form card
                        VStack(spacing: 0) {
                            VStack(spacing: 20) {
                                // Name field
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Full Name")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.gray)
                                    
                                    HStack {
                                        Image(systemName: "person")
                                            .foregroundColor(.gray)
                                            .frame(width: 20)
                                        
                                        TextField("Enter your full name", text: $name)
                                            .autocapitalization(.words)
                                            .autocorrectionDisabled()
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(name.isEmpty ? Color.clear : Color.blue.opacity(0.3), lineWidth: 1)
                                    )
                                }
                                
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
                                                TextField("Create a password", text: $password)
                                            } else {
                                                SecureField("Create a password", text: $password)
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
                                    
                                    // Password strength indicator
                                    if !password.isEmpty {
                                        PasswordStrengthView(password: password)
                                    }
                                }
                                
                                // Confirm Password field
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Confirm Password")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.gray)
                                    
                                    HStack {
                                        Image(systemName: "lock.fill")
                                            .foregroundColor(.gray)
                                            .frame(width: 20)
                                        
                                        Group {
                                            if showConfirmPassword {
                                                TextField("Confirm your password", text: $confirmPassword)
                                            } else {
                                                SecureField("Confirm your password", text: $confirmPassword)
                                            }
                                        }
                                        
                                        Button(action: {
                                            showConfirmPassword.toggle()
                                        }) {
                                            Image(systemName: showConfirmPassword ? "eye.slash" : "eye")
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(
                                                confirmPassword.isEmpty ? Color.clear :
                                                passwordsMatch ? Color.green.opacity(0.5) : Color.red.opacity(0.5),
                                                lineWidth: 1
                                            )
                                    )
                                    
                                    // Password match indicator
                                    if !confirmPassword.isEmpty {
                                        HStack(spacing: 6) {
                                            Image(systemName: passwordsMatch ? "checkmark.circle.fill" : "xmark.circle.fill")
                                                .foregroundColor(passwordsMatch ? .green : .red)
                                                .font(.system(size: 12))
                                            
                                            Text(passwordsMatch ? "Passwords match" : "Passwords don't match")
                                                .font(.system(size: 12))
                                                .foregroundColor(passwordsMatch ? .green : .red)
                                        }
                                    }
                                }
                                
                                // Bio field (optional)
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Bio (Optional)")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.gray)
                                    
                                    HStack {
                                        Image(systemName: "text.alignleft")
                                            .foregroundColor(.gray)
                                            .frame(width: 20)
                                        
                                        TextField("Tell us about yourself", text: $bio)
                                            .autocapitalization(.sentences)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(bio.isEmpty ? Color.clear : Color.blue.opacity(0.3), lineWidth: 1)
                                    )
                                }
                                
                                // Terms and conditions
                                HStack(spacing: 8) {
                                    Button(action: {
                                        agreeToTerms.toggle()
                                    }) {
                                        Image(systemName: agreeToTerms ? "checkmark.square.fill" : "square")
                                            .foregroundColor(agreeToTerms ? .blue : .gray)
                                    }
                                    
                                    HStack(spacing: 4) {
                                        Text("I agree to the")
                                            .font(.system(size: 14))
                                            .foregroundColor(.gray)
                                        
                                        Button("Terms & Conditions") {
                                            // Handle terms navigation
                                        }
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.blue)
                                    }
                                    
                                    Spacer()
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
                                
                                // Sign up button
                                Button(action: {
                                    Task {
                                        await signUp()
                                    }
                                }) {
                                    HStack {
                                        if isLoading {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                                .scaleEffect(0.8)
                                        } else {
                                            Text("Create Account")
                                                .font(.system(size: 16, weight: .semibold))
                                        }
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(
                                        LinearGradient(
                                            colors: [Color.green, Color.green.opacity(0.8)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(12)
                                    .shadow(color: Color.green.opacity(0.3), radius: 8, x: 0, y: 4)
                                }
                                .disabled(isLoading || !isFormValid)
                                .opacity(isLoading || !isFormValid ? 0.6 : 1.0)
                            }
                            .padding(.horizontal, 32)
                            .padding(.vertical, 32)
                            .background(Color.white)
                            .cornerRadius(24, corners: [.topLeft, .topRight])
                            
                            // Already have account section
                            VStack(spacing: 0) {
                                HStack(spacing: 4) {
                                    Text("Already have an account?")
                                        .font(.system(size: 14))
                                        .foregroundColor(.gray)
                                    
                                    Button("Sign In") {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            showSignUp = false
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
    }
    
    @MainActor
    func signUp() async {
        guard isFormValid else {
            errorMessage = "Please fill in all fields correctly"
            return
        }
        
        errorMessage = ""
        isLoading = true
        
        do {
            let requestBody: [String: String] = [
                "email": email,
                "password": password,
                "name": name,
                "bio": bio
            ]
            
            let signUpResponse: SignUpResponse? = try await networkService.requestEndpoint(
                endpoint: "/auth/signup",
                method: "POST",
                body: requestBody
            )
            
            guard let response = signUpResponse else {
                errorMessage = "No response received from server"
                isLoading = false
                return
            }
            
            // Save token to keychain
            try KeychainManager.instance.saveToken(response.token, forKey: "authToken")
            print("Token saved successfully")
            
            // Update authentication state
            isAuthenticated = true
            authManager.isAuthenticated = true
            authManager.shouldShowLogin = false
            
            // Clear form
            email = ""
            password = ""
            confirmPassword = ""
            name = ""
            bio = ""
            
        } catch let requestError as RequestError {
            switch requestError {
            case .invalidURL:
                errorMessage = "Invalid server URL"
            case .requestFailed(let message):
                // Handle specific error codes from your API
                if message.contains("400") {
                    errorMessage = "Password is too weak. Please choose a stronger password."
                } else if message.contains("401") {
                    errorMessage = "An account with this email already exists."
                } else {
                    errorMessage = message
                }
            case .emptyResponse:
                errorMessage = "Empty response from server"
            }
        } catch {
            errorMessage = "Sign up failed. Please try again."
            print("Sign up error:", error)
        }
        
        isLoading = false
    }
}

// MARK: - Password Strength Component
struct PasswordStrengthView: View {
    let password: String
    
    private var strength: Int {
        var score = 0
        
        if password.count >= 8 { score += 1 }
        if password.rangeOfCharacter(from: .lowercaseLetters) != nil { score += 1 }
        if password.rangeOfCharacter(from: .uppercaseLetters) != nil { score += 1 }
        if password.rangeOfCharacter(from: .decimalDigits) != nil { score += 1 }
        if password.rangeOfCharacter(from: CharacterSet(charactersIn: "!@#$%^&*()_+-=[]{}|;:,.<>?")) != nil { score += 1 }
        
        return score
    }
    
    private var strengthText: String {
        switch strength {
        case 0...1: return "Very Weak"
        case 2: return "Weak"
        case 3: return "Fair"
        case 4: return "Good"
        case 5: return "Strong"
        default: return "Very Weak"
        }
    }
    
    private var strengthColor: Color {
        switch strength {
        case 0...1: return .red
        case 2: return .orange
        case 3: return .yellow
        case 4: return .blue
        case 5: return .green
        default: return .red
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Password Strength: \(strengthText)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(strengthColor)
                Spacer()
            }
            
            HStack(spacing: 4) {
                ForEach(0..<5) { index in
                    Rectangle()
                        .fill(index < strength ? strengthColor : Color.gray.opacity(0.3))
                        .frame(height: 4)
                        .cornerRadius(2)
                }
            }
        }
    }
}

// MARK: - Preview
struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        SignUpView(showSignUp: .constant(true))
    }
}
