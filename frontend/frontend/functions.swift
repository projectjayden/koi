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

func saveToKeychain(key: String, value: String) -> Bool {
    guard let data = value.data(using: .utf8) else {
        return false
    }

    // Delete existing item if it exists
    let query: [String: Any] = [
        kSecClass as String       : kSecClassGenericPassword,
        kSecAttrAccount as String : key
    ]
    SecItemDelete(query as CFDictionary)

    // Add new item
    let addQuery: [String: Any] = [
        kSecClass as String       : kSecClassGenericPassword,
        kSecAttrAccount as String : key,
        kSecValueData as String   : data
    ]

    let status = SecItemAdd(addQuery as CFDictionary, nil)
    return status == errSecSuccess
}

func getFromKeychain(key: String) -> String? {
    let query: [String: Any] = [
        kSecClass as String       : kSecClassGenericPassword,
        kSecAttrAccount as String : key,
        kSecReturnData as String  : true,
        kSecMatchLimit as String  : kSecMatchLimitOne
    ]

    var item: AnyObject?
    let status = SecItemCopyMatching(query as CFDictionary, &item)

    guard status == errSecSuccess,
          let data = item as? Data,
          let value = String(data: data, encoding: .utf8) else {
        return nil
    }

    return value
}

func deleteFromKeychain(key: String) -> Bool {
    let query: [String: Any] = [
        kSecClass as String       : kSecClassGenericPassword,
        kSecAttrAccount as String : key
    ]
    let status = SecItemDelete(query as CFDictionary)
    return status == errSecSuccess
}
