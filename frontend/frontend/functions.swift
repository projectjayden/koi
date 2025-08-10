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

    init(authToken: String? = nil) {
        if let providedToken = authToken {
            self.authToken = providedToken
        } else {
            // Get token from keychain (assuming it returns String?)
            let token = KeychainManager.instance.getToken(forKey: "authToken")
            self.authToken = token
            if let token = token {
                print("Auth token loaded from keychain: \(token.prefix(20))...")
            } else {
                print("No auth token found in keychain")
            }
        }
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
        print("Making request to: \(baseURL + endpoint)")
        print("HTTP Method: \(method)")  // Add this line
        print(baseURL + endpoint)
        print("AUTHTOKENNNNN:" + authToken!)
        guard let url = URL(string: baseURL + endpoint) else {
            throw RequestError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method

        // Headers
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
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


extension UserDefaults {
    
    /// Store any Codable object to UserDefaults
    /// - Parameters:
    ///   - object: The Codable object to store
    ///   - key: The key to store the object under
    /// - Returns: Bool indicating success or failure
    @discardableResult
    func store<T: Codable>(_ object: T, forKey key: String) -> Bool {
        do {
            let data = try JSONEncoder().encode(object)
            set(data, forKey: key)
            return true
        } catch {
            print("❌ Failed to encode object for key '\(key)': \(error)")
            return false
        }
    }
    
    /// Retrieve any Codable object from UserDefaults
    /// - Parameters:
    ///   - type: The type of object to retrieve
    ///   - key: The key the object is stored under
    /// - Returns: The decoded object or nil if not found/failed to decode
    func object<T: Codable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = data(forKey: key) else {
            return nil
        }
        
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            print("❌ Failed to decode object for key '\(key)': \(error)")
            return nil
        }
    }
    
    /// Store an array of Codable objects
    /// - Parameters:
    ///   - objects: Array of Codable objects
    ///   - key: The key to store the array under
    /// - Returns: Bool indicating success or failure
    @discardableResult
    func set<T: Codable>(_ objects: [T], forKey key: String) -> Bool {
        do {
            let data = try JSONEncoder().encode(objects)
            set(data, forKey: key)
            return true
        } catch {
            print("❌ Failed to encode array for key '\(key)': \(error)")
            return false
        }
    }
    
    /// Retrieve an array of Codable objects
    /// - Parameters:
    ///   - type: The type of objects in the array
    ///   - key: The key the array is stored under
    /// - Returns: Array of decoded objects or empty array if not found/failed
    func array<T: Codable>(_ type: T.Type, forKey key: String) -> [T] {
        guard let data = data(forKey: key) else {
            return []
        }
        
        do {
            return try JSONDecoder().decode([T].self, from: data)
        } catch {
            print("❌ Failed to decode array for key '\(key)': \(error)")
            return []
        }
    }
}

func getFavoritedRecipes(type: Int) async throws -> (total: Int, recipe: [Meal]) {
    let network = NetworkService()
    
    do {
        let response: RecipeResponse? = try await
        network.requestEndpoint(
            endpoint: "/user/get-recipes",
            method: "POST",
            body: ["type": type]
        )
        
        guard let response = response else {
            throw AuthError.noData
        }
        return (total: response.total, recipe: response.recipe)
    } catch {
        print("Failed to get Recipes: ", error)
        throw error
    }
}

func createRecipe(recipe: Meal) async throws -> String{
    let network = NetworkService()
    
    do {
        let request = CreateRecipeRequest(
            name: recipe.name,
            ingredients: recipe.ingredients.map {
                CreateRecipeRequest.IngredientRequest(
                    name: $0.name,
                    amount: $0.amount,
                    unit: $0.unit
                )
            },
            instructions: recipe.instructions.isEmpty ? nil : recipe.instructions,
            category: recipe.category,
            image: recipe.image
        )
        
        let response: String? = try await network.requestEndpoint(
            endpoint: "/user/recipe/create",
            method: "POST",
            body: request
        )
        
        guard response != nil else {
            throw AuthError.noData
        }
        return response ?? ""
    }
}

func getAllRecipes() async throws -> [Meal] {
    let network = NetworkService()
    
    do {
        let response: [Meal]? = try await
        network.requestEndpoint(
            endpoint: "/user/get-all-recipes",
            method: "POST"
            )
        guard let response = response else {
            throw AuthError.noData
        }
        return response
    } catch {
        print("Failed to get Recipes: ", error)
        throw error
    }
}

func likeRecipe(uuid: Int) async throws {
    let network = NetworkService()
    
    do{
        let response: Int? = try await network.requestEndpoint(
            endpoint: "/user/recipe/like/ \(uuid)",
            method: "PUT"
        )
        
        guard response != nil else {
            throw AuthError.noData
        }
    } catch {
        print("Failed to like Recipe: ", error)
        throw error
    }
}

func unlikeRecipe(uuid: Int) async throws {
    let network = NetworkService()
    
    do{
        let response: Int? = try await network.requestEndpoint(
            endpoint: "/user/recipe/unlike/ \(uuid)",
            method: "PUT"
        )
        
        guard response != nil else {
            throw AuthError.noData
        }
    } catch {
        print("Failed to unlike Recipe: ", error)
        throw error
    }
}

