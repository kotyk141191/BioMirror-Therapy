//
//  AuthenticationManager.swift
//  BioMirrorTherapy
//
//  Created by Mykhailo Kotyk on 30.03.2025.
//

import Foundation
import Combine

class AuthenticationManager {
    // MARK: - Singleton
    
    static let shared = AuthenticationManager()
    
    // MARK: - Properties
    
    private let secureStorage = SecureStorageManager.shared
    
    private let apiClient = APIClient.shared
    
    private let accessTokenKey = "auth.accessToken"
    private let refreshTokenKey = "auth.refreshToken"
    private let userIdKey = "auth.userId"
    
    private(set) var accessToken: String?
    private(set) var refreshToken: String?
    private(set) var userId: String?
    
    var isAuthenticated: Bool {
        return accessToken != nil && refreshToken != nil
    }
    
    // MARK: - Initialization
    
    private init() {
        // Load tokens from secure storage if available
        do {
            if secureStorage.itemExists(forKey: accessTokenKey) {
                accessToken = try secureStorage.getString(forKey: accessTokenKey)
            }
            
            if secureStorage.itemExists(forKey: refreshTokenKey) {
                refreshToken = try secureStorage.getString(forKey: refreshTokenKey)
            }
            
            if secureStorage.itemExists(forKey: userIdKey) {
                userId = try secureStorage.getString(forKey: userIdKey)
            }
        } catch {
            print("Failed to load authentication data: \(error)")
            
            // Clear potentially corrupted data
            clearTokens()
        }
    }
    
    // MARK: - Public Methods
    
    /// Set authentication tokens
    /// - Parameters:
    ///   - accessToken: JWT access token
    ///   - refreshToken: Refresh token
    func setTokens(accessToken: String, refreshToken: String) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        
        // Extract user ID from token if possible
        if let userId = extractUserIdFromToken(accessToken) {
            self.userId = userId
        }
        
        // Store tokens securely
        do {
            try secureStorage.saveString(accessToken, forKey: accessTokenKey)
            try secureStorage.saveString(refreshToken, forKey: refreshTokenKey)
            
            if let userId = self.userId {
                try secureStorage.saveString(userId, forKey: userIdKey)
            }
        } catch {
            print("Failed to save authentication data: \(error)")
        }
    }
    
    /// Clear authentication tokens
    func clearTokens() {
        accessToken = nil
        refreshToken = nil
        userId = nil
        
        // Remove tokens from secure storage
        do {
            try secureStorage.deleteItem(forKey: accessTokenKey)
            try secureStorage.deleteItem(forKey: refreshTokenKey)
            try secureStorage.deleteItem(forKey: userIdKey)
        } catch {
            print("Failed to delete authentication data: \(error)")
        }
    }
    
    // MARK: - Private Methods
    
    private func extractUserIdFromToken(_ token: String) -> String? {
        // In a real app, decode the JWT token to extract user ID
        // This is a simplified implementation
        
        let parts = token.components(separatedBy: ".")
        guard parts.count >= 2 else { return nil }
        
        let payloadBase64 = parts[1]
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        
        let paddedPayload = payloadBase64.padding(toLength: ((payloadBase64.count + 3) / 4) * 4, withPad: "=", startingAt: 0)
        
        guard let payloadData = Data(base64Encoded: paddedPayload) else { return nil }
        
        do {
            if let json = try JSONSerialization.jsonObject(with: payloadData) as? [String: Any],
               let sub = json["sub"] as? String {
                return sub
            }
        } catch {
            print("Failed to parse token payload: \(error)")
        }
        
        return nil
    }
    
    
    // Add this to AuthenticationManager.swift
    func authenticateUser(username: String, password: String) -> AnyPublisher<Bool, Error> {
        // For now, use the API client to authenticate
        return apiClient.login(username: username, password: password)
            .map { result -> Bool in
                self.setTokens(accessToken: result.accessToken, refreshToken: result.refreshToken)
                return true
            }
            .eraseToAnyPublisher()
    }

    func checkAuthentication() -> Bool {
        return isAuthenticated
    }

    func getUserType() -> UserType {
        guard let userId = userId else { return .none }
        
        // In a real implementation, this would be determined from the token or API
        if userId.hasPrefix("child-") {
            return .child
        } else if userId.hasPrefix("parent-") {
            return .parent
        } else if userId.hasPrefix("therapist-") {
            return .therapist
        } else {
            return .none
        }
    }
}
