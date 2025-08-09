//
//  functions.swift
//  frontend
//
//  Created by Kenneth Ng on 8/1/25.
//

import Foundation
import Security

struct AnyEncodable: Encodable {
    private let encodeClosure: (Encoder) throws -> Void

    init<T: Encodable>(_ wrapped: T) {
        self.encodeClosure = wrapped.encode
    }

    func encode(to encoder: Encoder) throws {
        try encodeClosure(encoder)
    }
}

enum RequestError: Error {
    case invalidURL
    case requestFailed(String)
    case emptyResponse
}

class NetworkService {
    let baseURL: String = Bundle.main.infoDictionary?["BASE_URL"] as! String
    let authToken: String?

    // TODO: instead of taking as parameter get it from keychain
    init(authToken: String? = nil) {
        self.authToken = authToken
    }

    /// Makes a request to the given endpoint with the given method and body.
    /// - Parameters:
    ///   - endpoint: the endpoint to request (should start with `/`)
    ///   - method: the HTTP method to use. Defaults to "GET"
    ///   - body: the body of the request as an encodable object
    /// - Returns: A decoded response object of type `T`
    func requestEndpoint<T: Decodable>(
        endpoint: String,
        method: String = "GET",
        body: Encodable? = nil
    ) async throws -> T? {
        print(baseURL + endpoint)
        guard let url = URL(string: baseURL + endpoint) else {
            throw RequestError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method

        // Headers
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = authToken {
            request.setValue(token, forHTTPHeaderField: "Authorization")
        }

        // Body
        if let body = body {
            let jsonData = try JSONEncoder().encode(AnyEncodable(body))
            request.httpBody = jsonData
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw RequestError.requestFailed("Invalid response")
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw RequestError.requestFailed("Failed to fetch \(endpoint) (status: \(httpResponse.statusCode))")
        }

        guard let data = data.isEmpty ? nil : data else {
            return nil
        }

        return try JSONDecoder().decode(T.self, from: data)
    }
}

class AuthenticationManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var shouldShowLogin = false
    
    func checkForJWTLocally() throws -> Bool {
        guard let savedToken = KeychainManager.instance.getToken(forKey: "authToken"),
              !savedToken.isEmpty else {
            DispatchQueue.main.async {
                self.isAuthenticated = false
                self.shouldShowLogin = true
            }
            throw AuthError.noData
        }
        
        DispatchQueue.main.async {
            self.isAuthenticated = true
            self.shouldShowLogin = false
        }
        return true
    }
}

// USERDEFAULTS FUNCTIONS //

func saveUserToDefaults(user: UserInfo) {
    do {
        let encoder = JSONEncoder()
        let userData = try encoder.encode(user)
        UserDefaults.standard.set(userData, forKey: "currentUser")
        UserDefaults.standard.synchronize() // Force immediate save
        print("User data saved to UserDefaults")
    } catch {
        print("Failed to encode user data:", error)
    }
}

func getUserFromDefaults() -> UserInfo? {
    guard let userData = UserDefaults.standard.data(forKey: "currentUser") else {
        print("No user data found in UserDefaults")
        return nil
    }
    
    do {
        let decoder = JSONDecoder()
        let user = try decoder.decode(UserInfo.self, from: userData)
        return user
    } catch {
        print("Failed to decode user data:", error)
        return nil
    }
}

func clearUserFromDefaults() {
    UserDefaults.standard.removeObject(forKey: "currentUser")
    UserDefaults.standard.synchronize()
    print("User data cleared from UserDefaults")
}
