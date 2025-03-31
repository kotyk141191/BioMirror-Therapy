//
//  APIClient.swift
//  BioMirrorTherapy
//
//  Created by Mykhailo Kotyk on 30.03.2025.
//

import Foundation
import Combine

class APIClient {
    // MARK: - Singleton
    
    static let shared = APIClient()
    
    // MARK: - Properties
    
    private let baseURL: URL
    private let session: URLSession
    private let authManager: AuthenticationManager
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    private init() {
        // In a real app, this would be configurable based on environment
        baseURL = URL(string: "https://api.biomirror.com/v1")!
        
        // Configure session with caching policy and timeouts
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30.0
        configuration.timeoutIntervalForResource = 120.0
        configuration.requestCachePolicy = .reloadRevalidatingCacheData
        session = URLSession(configuration: configuration)
        
        // Initialize authentication manager
        authManager = AuthenticationManager.shared
    }
    
    // MARK: - Public Methods
    
    /// Make an authenticated API request
    /// - Parameters:
    ///   - endpoint: API endpoint to request
    ///   - method: HTTP method
    ///   - parameters: Optional query parameters
    ///   - body: Optional request body
    /// - Returns: Publisher with decoded response or error
    func request<T: Decodable>(_ endpoint: APIEndpoint,
                               method: HTTPMethod = .get,
                               parameters: [String: String]? = nil,
                               body: Data? = nil) -> AnyPublisher<T, APIError> {
        
        // Construct URL with query parameters
        var components = URLComponents(url: baseURL.appendingPathComponent(endpoint.path), resolvingAgainstBaseURL: true)
        
        if let parameters = parameters {
            components?.queryItems = parameters.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        
        guard let url = components?.url else {
            return Fail(error: APIError.invalidURL).eraseToAnyPublisher()
        }
        
        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.httpBody = body
        
        // Set common headers
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // Add authentication if available
        if let token = authManager.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Make the request
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                // Check for HTTP errors
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError.invalidResponse
                }
                
                switch httpResponse.statusCode {
                case 200...299:
                    return data
                case 401:
                    throw APIError.unauthorized
                case 403:
                    throw APIError.forbidden
                case 404:
                    throw APIError.notFound
                case 500...599:
                    throw APIError.serverError(httpResponse.statusCode)
                default:
                    throw APIError.unexpectedStatusCode(httpResponse.statusCode)
                }
            }
            .decode(type: T.self, decoder: JSONDecoder())
            .mapError { error in
                if let apiError = error as? APIError {
                    return apiError
                }
                
                if let decodingError = error as? DecodingError {
                    return APIError.decodingError(decodingError)
                }
                
                return APIError.unknown(error)
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    /// Upload data to the API
    /// - Parameters:
    ///   - endpoint: API endpoint
    ///   - data: Data to upload
    ///   - parameters: Optional query parameters
    /// - Returns: Publisher with decoded response or error
    func upload<T: Decodable>(_ endpoint: APIEndpoint,
                              data: Data,
                              parameters: [String: String]? = nil) -> AnyPublisher<T, APIError> {
        
        return request(endpoint, method: .post, parameters: parameters, body: data)
    }
    
    /// Download data from the API
    /// - Parameters:
    ///   - endpoint: API endpoint
    ///   - parameters: Optional query parameters
    /// - Returns: Publisher with downloaded data or error
    func download(_ endpoint: APIEndpoint,
                  parameters: [String: String]? = nil) -> AnyPublisher<Data, APIError> {
        
        // Construct URL with query parameters
        var components = URLComponents(url: baseURL.appendingPathComponent(endpoint.path), resolvingAgainstBaseURL: true)
        
        if let parameters = parameters {
            components?.queryItems = parameters.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        
        guard let url = components?.url else {
            return Fail(error: APIError.invalidURL).eraseToAnyPublisher()
        }
        
        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // Add authentication if available
        if let token = authManager.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Make the request
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                // Check for HTTP errors
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError.invalidResponse
                }
                
                switch httpResponse.statusCode {
                case 200...299:
                    return data
                case 401:
                    throw APIError.unauthorized
                case 403:
                    throw APIError.forbidden
                case 404:
                    throw APIError.notFound
                case 500...599:
                    throw APIError.serverError(httpResponse.statusCode)
                default:
                    throw APIError.unexpectedStatusCode(httpResponse.statusCode)
                }
            }
            .mapError { error in
                if let apiError = error as? APIError {
                    return apiError
                }
                
                return APIError.unknown(error)
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    /// Log in user with credentials
    /// - Parameters:
    ///   - username: Username/email
    ///   - password: Password
    /// - Returns: Publisher with authentication result or error
    func login(username: String, password: String) -> AnyPublisher<AuthenticationResult, APIError> {
        let loginData = LoginRequest(username: username, password: password)
        
        guard let encodedData = try? JSONEncoder().encode(loginData) else {
            return Fail(error: APIError.encodingError).eraseToAnyPublisher()
        }
        
        return request(.login, method: .post, body: encodedData)
            .handleEvents(receiveOutput: { [weak self] (result: AuthenticationResult) in
                // Store authentication tokens
                self?.authManager.setTokens(accessToken: result.accessToken, refreshToken: result.refreshToken)
            })
            .eraseToAnyPublisher()
    }
    
    /// Refresh the authentication token
    /// - Returns: Publisher with authentication result or error
    func refreshToken() -> AnyPublisher<AuthenticationResult, APIError> {
        guard let refreshToken = authManager.refreshToken else {
            return Fail(error: APIError.unauthorized).eraseToAnyPublisher()
        }
        
        let refreshData = RefreshTokenRequest(refreshToken: refreshToken)
        
        guard let encodedData = try? JSONEncoder().encode(refreshData) else {
            return Fail(error: APIError.encodingError).eraseToAnyPublisher()
        }
        
        return request(.refreshToken, method: .post, body: encodedData)
            .handleEvents(receiveOutput: { [weak self] (result: AuthenticationResult) in
                // Store new authentication tokens
                self?.authManager.setTokens(accessToken: result.accessToken, refreshToken: result.refreshToken)
            })
            .eraseToAnyPublisher()
    }
    
    /// Log out the current user
    /// - Returns: Publisher with success status or error
    func logout() -> AnyPublisher<Bool, APIError> {
        guard let refreshToken = authManager.refreshToken else {
            // Already logged out
            authManager.clearTokens()
            return Just(true).setFailureType(to: APIError.self).eraseToAnyPublisher()
        }
        
        let logoutData = LogoutRequest(refreshToken: refreshToken)
        
        guard let encodedData = try? JSONEncoder().encode(logoutData) else {
            return Fail(error: APIError.encodingError).eraseToAnyPublisher()
        }
        
        return request(.logout, method: .post, body: encodedData)
            .map { (_: EmptyResponse) -> Bool in
                // Clear stored tokens
                self.authManager.clearTokens()
                return true
            }
            .catch { error -> AnyPublisher<Bool, APIError> in
                // Even if the server request fails, clear tokens locally
                self.authManager.clearTokens()
                return Just(true).setFailureType(to: APIError.self).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - Supporting Types

enum APIEndpoint {
    case login
    case logout
    case refreshToken
    case user
    case patients
    case sessions
    case sessionDetail(id: String)
    case emotionalData
    case syncData
    case mlModels
    case mlModelVersion(name: String)
    
    var path: String {
        switch self {
        case .login:
            return "auth/login"
        case .logout:
            return "auth/logout"
        case .refreshToken:
            return "auth/refresh"
        case .user:
            return "users/me"
        case .patients:
            return "patients"
        case .sessions:
            return "sessions"
        case .sessionDetail(let id):
            return "sessions/\(id)"
        case .emotionalData:
            return "data/emotional"
        case .syncData:
            return "sync"
        case .mlModels:
            return "models"
        case .mlModelVersion(let name):
            return "models/\(name)/version"
        }
    }
}

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
}

enum APIError: Error {
    case invalidURL
    case invalidResponse
    case unauthorized
    case forbidden
    case notFound
    case serverError(Int)
    case unexpectedStatusCode(Int)
    case decodingError(DecodingError)
    case encodingError
    case unknown(Error)
}

// MARK: - Request/Response Types

struct LoginRequest: Codable {
    let username: String
    let password: String
}

struct RefreshTokenRequest: Codable {
    let refreshToken: String
}

struct LogoutRequest: Codable {
    let refreshToken: String
}

struct AuthenticationResult: Codable {
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int
    let tokenType: String
}

struct EmptyResponse: Codable {}
