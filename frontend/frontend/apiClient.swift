import Foundation

class apiClient {

    static let shared = apiClient()
    
    private let baseUrl = Bundle.main.infoDictionary?["BASE_URL"] as! String

    private init() {}

    private var jwtToken: String? {
        return KeychainManager.instance.getToken(forKey: "jwt_token") // or whatever key you use
    }

    func sendRequest(endpoint: String = "/", 
                    method: String = "GET", 
                    body: Data? = nil, 
                    completion: @escaping (Data?, URLResponse?, Error?) -> Void) {
                    
        guard let url = URL(string: "https://\(baseUrl)\(endpoint)") else {
            print("Invalid URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = body
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = jwtToken { // if there is a token, add it to the header
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        URLSession.shared.dataTask(with: request, completionHandler: completion).resume()

    }
    


}
