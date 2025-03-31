//
//  SecureStorageManager.swift
//  BioMirrorTherapy
//
//  Created by Mykhailo Kotyk on 30.03.2025.
//

import Foundation
import Security

class SecureStorageManager {
    // MARK: - Singleton
    
    static let shared = SecureStorageManager()
    
    private init() {}
    
    // MARK: - Constants
    
    private enum SecureStorageError: Error {
        case dataConversionFailed
        case itemNotFound
        case unexpectedStatus(OSStatus)
        case unhandledError(status: OSStatus)
    }
    
    // Service name for the keychain
    private let serviceName = "com.biomirror.secure"
    
    // MARK: - Public Methods
    
    /// Save sensitive string data securely
    /// - Parameters:
    ///   - value: The string value to store
    ///   - key: Unique identifier for the value
    ///   - accessibility: When the data should be accessible
    /// - Throws: SecureStorageError
    func saveString(_ value: String, forKey key: String, withAccessibility accessibility: CFString = kSecAttrAccessibleWhenUnlockedThisDeviceOnly) throws {
        guard let data = value.data(using: .utf8) else {
            throw SecureStorageError.dataConversionFailed
        }
        
        try saveData(data, forKey: key, withAccessibility: accessibility)
    }
    
    /// Retrieve a securely stored string
    /// - Parameter key: The key for the string
    /// - Returns: The stored string
    /// - Throws: SecureStorageError
    func getString(forKey key: String) throws -> String {
        let data = try getData(forKey: key)
        
        guard let string = String(data: data, encoding: .utf8) else {
            throw SecureStorageError.dataConversionFailed
        }
        
        return string
    }
    
    /// Save sensitive data securely
    /// - Parameters:
    ///   - data: The data to store
    ///   - key: Unique identifier for the data
    ///   - accessibility: When the data should be accessible
    /// - Throws: SecureStorageError
    func saveData(_ data: Data, forKey key: String, withAccessibility accessibility: CFString = kSecAttrAccessibleWhenUnlockedThisDeviceOnly) throws {
        // Create query dictionary
        var query = [String: Any]()
        query[kSecClass as String] = kSecClassGenericPassword
        query[kSecAttrService as String] = serviceName
        query[kSecAttrAccount as String] = key
        
        // First check if the item already exists
        let status = SecItemCopyMatching(query as CFDictionary, nil)
        
        switch status {
        case errSecSuccess, errSecInteractionNotAllowed:
            // Item exists, update it
            var attributesToUpdate = [String: Any]()
            attributesToUpdate[kSecValueData as String] = data
            
            let updateStatus = SecItemUpdate(query as CFDictionary, attributesToUpdate as CFDictionary)
            guard updateStatus == errSecSuccess else {
                throw SecureStorageError.unexpectedStatus(updateStatus)
            }
            
        case errSecItemNotFound:
            // Item doesn't exist, create it
            query[kSecValueData as String] = data
            query[kSecAttrAccessible as String] = accessibility
            
            let addStatus = SecItemAdd(query as CFDictionary, nil)
            guard addStatus == errSecSuccess else {
                throw SecureStorageError.unexpectedStatus(addStatus)
            }
            
        default:
            throw SecureStorageError.unhandledError(status: status)
        }
    }
    
    /// Retrieve securely stored data
    /// - Parameter key: The key for the data
    /// - Returns: The stored data
    /// - Throws: SecureStorageError
    func getData(forKey key: String) throws -> Data {
        var query = [String: Any]()
        query[kSecClass as String] = kSecClassGenericPassword
        query[kSecAttrService as String] = serviceName
        query[kSecAttrAccount as String] = key
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        query[kSecReturnData as String] = kCFBooleanTrue
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status != errSecItemNotFound else {
            throw SecureStorageError.itemNotFound
        }
        
        guard status == errSecSuccess else {
            throw SecureStorageError.unexpectedStatus(status)
        }
        
        guard let data = result as? Data else {
            throw SecureStorageError.dataConversionFailed
        }
        
        return data
    }
    
    /// Delete securely stored item
    /// - Parameter key: The key for the item to delete
    /// - Throws: SecureStorageError
    func deleteItem(forKey key: String) throws {
        var query = [String: Any]()
        query[kSecClass as String] = kSecClassGenericPassword
        query[kSecAttrService as String] = serviceName
        query[kSecAttrAccount as String] = key
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw SecureStorageError.unexpectedStatus(status)
        }
    }
    
    /// Check if an item exists in secure storage
    /// - Parameter key: The key to check
    /// - Returns: True if the item exists
    func itemExists(forKey key: String) -> Bool {
        var query = [String: Any]()
        query[kSecClass as String] = kSecClassGenericPassword
        query[kSecAttrService as String] = serviceName
        query[kSecAttrAccount as String] = key
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        
        let status = SecItemCopyMatching(query as CFDictionary, nil)
        return status == errSecSuccess
    }
}

// MARK: - Convenience Extension for Coding Objects

extension SecureStorageManager {
    /// Save a Codable object securely
    /// - Parameters:
    ///   - object: The Codable object to store
    ///   - key: Unique identifier for the object
    /// - Throws: SecureStorageError or encoding errors
    func save<T: Encodable>(_ object: T, forKey key: String) throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(object)
        try saveData(data, forKey: key)
    }
    
    /// Retrieve a Codable object
    /// - Parameter key: The key for the object
    /// - Returns: The decoded object
    /// - Throws: SecureStorageError or decoding errors
    func retrieve<T: Decodable>(_ objectType: T.Type, forKey key: String) throws -> T {
        let data = try getData(forKey: key)
        let decoder = JSONDecoder()
        return try decoder.decode(objectType, from: data)
    }
}
