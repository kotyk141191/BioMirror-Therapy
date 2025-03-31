//
//  SynchronizationManager.swift
//  BioMirrorTherapy
//
//  Created by Mykhailo Kotyk on 30.03.2025.
//

import Foundation
import Combine
import CoreData
import UIKit

class SynchronizationManager {
    // MARK: - Singleton
    
    static let shared = SynchronizationManager()
    
    // MARK: - Properties
    
    private let apiClient = APIClient.shared
    private let persistenceService: PersistenceService
    private var cancellables = Set<AnyCancellable>()
    
    // Sync tracking
    private let lastSyncTimeKey = "lastSyncTime"
    private let userDefaults = UserDefaults.standard
    
    // Notification names
    static let syncStartedNotification = Notification.Name("SyncStartedNotification")
    static let syncCompletedNotification = Notification.Name("SyncCompletedNotification")
    static let syncFailedNotification = Notification.Name("SyncFailedNotification")
    
    // MARK: - Initialization
    
    private init() {
        // Resolve persistence service from DI container
        self.persistenceService = ServiceLocator.shared.resolve()
    }
    
    // MARK: - Public Methods
    
    /// Synchronize data with the server
    /// - Parameter forceFullSync: Whether to force a full sync regardless of last sync time
    /// - Returns: Publisher with sync result
    func synchronize(forceFullSync: Bool = false) -> AnyPublisher<SyncResult, Error> {
        // Check if user is authenticated
        guard AuthenticationManager.shared.isAuthenticated else {
            return Fail(error: SyncError.notAuthenticated).eraseToAnyPublisher()
        }
        
        // Notify sync started
        NotificationCenter.default.post(name: Self.syncStartedNotification, object: nil)
        
        // Determine sync type
        let lastSyncTime = userDefaults.object(forKey: lastSyncTimeKey) as? Date
        let syncType: SyncType = forceFullSync || lastSyncTime == nil ? .full : .incremental
        
        // Create sync request
        let syncRequest = SyncRequest(
            syncType: syncType,
            lastSyncTime: lastSyncTime,
            deviceIdentifier: UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        )
        
        // Encode request
        guard let requestData = try? JSONEncoder().encode(syncRequest) else {
            let error = SyncError.encodingFailed
            NotificationCenter.default.post(name: Self.syncFailedNotification, object: nil, userInfo: ["error": error])
            return Fail(error: error).eraseToAnyPublisher()
        }
        
        // First push local changes to server
        return pushLocalChanges()
            .flatMap { _ -> AnyPublisher<SyncResponse, APIError> in
                // Then pull remote changes
                return self.apiClient.request(.syncData, method: .post, body: requestData)
            }
            .flatMap { [weak self] (response: SyncResponse) -> AnyPublisher<SyncResult, Error> in
                guard let self = self else {
                    return Fail(error: SyncError.unknown).eraseToAnyPublisher()
                }
                
                // Apply remote changes to local database
                return self.applyRemoteChanges(response)
            }
            .handleEvents(receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    // Notify sync failed
                    NotificationCenter.default.post(
                        name: Self.syncFailedNotification,
                        object: nil,
                        userInfo: ["error": error]
                    )
                }
            }, receiveOutput: { [weak self] result in
                // Update last sync time
                self?.userDefaults.set(Date(), forKey: self?.lastSyncTimeKey ?? "")
                
                // Notify sync completed
                NotificationCenter.default.post(
                    name: Self.syncCompletedNotification,
                    object: nil,
                    userInfo: ["result": result]
                )
            })
            .eraseToAnyPublisher()
    }
    
    /// Check if there are pending changes to sync
    /// - Returns: True if there are pending changes
    func hasPendingChanges() -> Bool {
        // In a real implementation, check for unsynchronized changes in CoreData
        
        // This is a simplified implementation.
        // In a real app, you'd query entities with a `needsSync` flag
        do {
            // Check sessions that need syncing
            let sessionFetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "Session")
            sessionFetchRequest.predicate = NSPredicate(format: "needsSync == YES")
            let sessionCount = try persistenceService.viewContext.count(for: sessionFetchRequest)
            
            // Check emotional states that need syncing
            let stateFetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "EmotionalState")
            stateFetchRequest.predicate = NSPredicate(format: "needsSync == YES")
            let stateCount = try persistenceService.viewContext.count(for: stateFetchRequest)
            
            return sessionCount > 0 || stateCount > 0
        } catch {
            print("Error checking for pending changes: \(error)")
            return false
        }
    }
    
    /// Get the date of the last synchronization
    /// - Returns: Date of last sync, or nil if never synced
    func getLastSyncDate() -> Date? {
        return userDefaults.object(forKey: lastSyncTimeKey) as? Date
    }
    
    // MARK: - Private Methods
    
    /// Push local changes to the server
    /// - Returns: Publisher with success status
    private func pushLocalChanges() -> AnyPublisher<Bool, APIError> {
        // In a real implementation, collect unsynchronized data and send to server
        
        // This is a simplified implementation
        // In a real app, you'd query entities with a `needsSync` flag, serialize them, and upload
        
        // Generate changes data structure
        let changesData = LocalChangesData(
            sessions: [],          // Add unsynchronized sessions
            emotionalStates: [],   // Add unsynchronized emotional states
            therapistNotes: []     // Add unsynchronized notes
        )
        
        // If no changes, return success immediately
        if changesData.isEmpty {
            return Just(true).setFailureType(to: APIError.self).eraseToAnyPublisher()
        }
        
        // Encode changes
        guard let encodedData = try? JSONEncoder().encode(changesData) else {
            return Fail(error: APIError.encodingError).eraseToAnyPublisher()
        }
        
        // Push changes to server
        return apiClient.upload(.syncData, data: encodedData)
            .map { (_: SyncPushResponse) -> Bool in
                // Mark entities as synchronized
                self.markEntitiesAsSynced()
                return true
            }
            .eraseToAnyPublisher()
    }
    
    /// Apply remote changes to local database
    /// - Parameter response: Sync response from server
    /// - Returns: Publisher with sync result
    private func applyRemoteChanges(_ response: SyncResponse) -> AnyPublisher<SyncResult, Error> {
        return Future<SyncResult, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(SyncError.unknown))
                return
            }
            
            // Create a background context for processing changes
            let context = self.persistenceService.createBackgroundContext()
            
            context.perform {
                do {
                    // Apply session changes
                    let sessionChanges = self.applySessionChanges(response.sessions, in: context)
                    
                    // Apply emotional state changes
                    let stateChanges = self.applyEmotionalStateChanges(response.emotionalStates, in: context)
                    
                    // Apply user changes
                    let userChanges = self.applyUserChanges(response.users, in: context)
                    
                    // Apply other changes as needed...
                    
                    // Save changes
                    try context.save()
                    
                    // Create result
                    let result = SyncResult(
                        sessionsAdded: sessionChanges.added,
                        sessionsUpdated: sessionChanges.updated,
                        sessionsDeleted: sessionChanges.deleted,
                        emotionalStatesAdded: stateChanges.added,
                        emotionalStatesUpdated: stateChanges.updated,
                        emotionalStatesDeleted: stateChanges.deleted,
                        usersAdded: userChanges.added,
                        usersUpdated: userChanges.updated,
                        usersDeleted: userChanges.deleted,
                        syncTime: Date()
                    )
                    
                    promise(.success(result))
                } catch {
                    promise(.failure(error))
                }
            }
        }.eraseToAnyPublisher()
    }
    
    /// Apply session changes from sync response
    /// - Parameters:
    ///   - sessions: Session data from server
    ///   - context: NSManagedObjectContext
    /// - Returns: Changes summary
    private func applySessionChanges(_ sessions: [SessionSyncData], in context: NSManagedObjectContext) -> ChangesSummary {
        // In a real implementation, merge sessions with local data
        
        // This is a simplified implementation
        var changes = ChangesSummary()
        
        // Process each session
        for sessionData in sessions {
            do {
                // Check if session exists
                let fetchRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "Session")
                fetchRequest.predicate = NSPredicate(format: "id == %@", sessionData.id)
                let results = try context.fetch(fetchRequest)
                
                if let existingSession = results.first {
                    // Update existing session
                    // ...
                    changes.updated += 1
                } else {
                    // Create new session
                    let newSession = NSEntityDescription.insertNewObject(forEntityName: "Session", into: context)
                    // ...
                    changes.added += 1
                }
            } catch {
                print("Error processing session: \(error)")
            }
        }
        
        return changes
    }
    
    /// Apply emotional state changes from sync response
    /// - Parameters:
    ///   - states: Emotional state data from server
    ///   - context: NSManagedObjectContext
    /// - Returns: Changes summary
    private func applyEmotionalStateChanges(_ states: [EmotionalStateSyncData], in context: NSManagedObjectContext) -> ChangesSummary {
        // In a real implementation, merge emotional states with local data
        
        // This is a simplified implementation
        var changes = ChangesSummary()
        
        // Process each emotional state
        for stateData in states {
            do {
                // Check if state exists
                let fetchRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "EmotionalState")
                fetchRequest.predicate = NSPredicate(format: "id == %@", stateData.id)
                let results = try context.fetch(fetchRequest)
                
                if let existingState = results.first {
                    // Update existing state
                    // ...
                    changes.updated += 1
                } else {
                    // Create new state
                    let newState = NSEntityDescription.insertNewObject(forEntityName: "EmotionalState", into: context)
                    // ...
                    changes.added += 1
                }
            } catch {
                print("Error processing emotional state: \(error)")
            }
        }
        
        return changes
    }
    
    /// Apply user changes from sync response
    /// - Parameters:
    ///   - users: User data from server
    ///   - context: NSManagedObjectContext
    /// - Returns: Changes summary
    private func applyUserChanges(_ users: [UserSyncData], in context: NSManagedObjectContext) -> ChangesSummary {
        // In a real implementation, merge users with local data
        
        // This is a simplified implementation
        var changes = ChangesSummary()
        
        // Process each user
        for userData in users {
            do {
                // Check if user exists
                let fetchRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "User")
                fetchRequest.predicate = NSPredicate(format: "id == %@", userData.id)
                let results = try context.fetch(fetchRequest)
                
                if let existingUser = results.first {
                    // Update existing user
                    // ...
                    changes.updated += 1
                } else {
                    // Create new user
                    let newUser = NSEntityDescription.insertNewObject(forEntityName: "User", into: context)
                    // ...
                    changes.added += 1
                }
            } catch {
                print("Error processing user: \(error)")
            }
        }
        
        return changes
    }
    
    /// Mark entities as synchronized
    private func markEntitiesAsSynced() {
        // In a real implementation, mark all pending entities as synced
        
        // This is a simplified implementation
        let context = persistenceService.viewContext
        
        do {
            // Find sessions that need syncing
            let sessionFetchRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "Session")
            sessionFetchRequest.predicate = NSPredicate(format: "needsSync == YES")
            let sessions = try context.fetch(sessionFetchRequest)
            
            // Find emotional states that need syncing
            let stateFetchRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "EmotionalState")
            stateFetchRequest.predicate = NSPredicate(format: "needsSync == YES")
            let states = try context.fetch(stateFetchRequest)
            
            // Mark all as synced
            for session in sessions {
                session.setValue(false, forKey: "needsSync")
            }
            
            for state in states {
                state.setValue(false, forKey: "needsSync")
            }
            
            // Save changes
            if context.hasChanges {
                try context.save()
            }
        } catch {
            print("Error marking entities as synced: \(error)")
        }
    }
}

// MARK: - Supporting Types

enum SyncType: String, Codable {
    case full
    case incremental
}

enum SyncError: Error {
    case notAuthenticated
    case encodingFailed
    case decodingFailed
    case serverError
    case networkError
    case unknown
}

struct SyncRequest: Codable {
    let syncType: SyncType
    let lastSyncTime: Date?
    let deviceIdentifier: String
}

struct SyncResponse: Codable {
    let sessions: [SessionSyncData]
    let emotionalStates: [EmotionalStateSyncData]
    let users: [UserSyncData]
    // Add other data types as needed
}

struct SessionSyncData: Codable {
    let id: String
    let startTime: Date
    let endTime: Date?
    let phase: Int
    let completionStatus: String
    let metrics: [String: AnyCodable]
    let notes: String?
    let userId: String
    let deleted: Bool
    let lastModified: Date
}

struct EmotionalStateSyncData: Codable {
    let id: String
    let timestamp: Date
    let dominantEmotion: String
    let emotionalIntensity: Float
    let arousalLevel: Float
    let coherenceIndex: Float
    let dissociationIndex: Float
    let dataQuality: String
    let sessionId: String
    let deleted: Bool
    let lastModified: Date
}

struct UserSyncData: Codable {
    let id: String
    let type: String
    let name: String
    let dateOfBirth: Date?
    let deleted: Bool
    let lastModified: Date
}

struct LocalChangesData: Codable {
    let sessions: [SessionSyncData]
    let emotionalStates: [EmotionalStateSyncData]
    let therapistNotes: [TherapistNoteSyncData]
    
    var isEmpty: Bool {
        return sessions.isEmpty && emotionalStates.isEmpty && therapistNotes.isEmpty
    }
}

struct TherapistNoteSyncData: Codable {
    let id: String
    let sessionId: String
    let notes: String
    let timestamp: Date
}

struct SyncPushResponse: Codable {
    let success: Bool
    let message: String?
    let failedItems: [String]?
}

struct SyncResult {
    let sessionsAdded: Int
    let sessionsUpdated: Int
    let sessionsDeleted: Int
    let emotionalStatesAdded: Int
    let emotionalStatesUpdated: Int
    let emotionalStatesDeleted: Int
    let usersAdded: Int
    let usersUpdated: Int
    let usersDeleted: Int
    let syncTime: Date
    
    var totalChanges: Int {
        return sessionsAdded + sessionsUpdated + sessionsDeleted +
               emotionalStatesAdded + emotionalStatesUpdated + emotionalStatesDeleted +
               usersAdded + usersUpdated + usersDeleted
    }
}

struct ChangesSummary {
    var added = 0
    var updated = 0
    var deleted = 0
}

// For encoding/decoding arbitrary values
struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if container.decodeNil() {
            value = NSNull()
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            value = dictionary.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "AnyCodable cannot decode value")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case is NSNull:
            try container.encodeNil()
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dictionary as [String: Any]:
            try container.encode(dictionary.mapValues { AnyCodable($0) })
        default:
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: container.codingPath, debugDescription: "AnyCodable cannot encode value"))
        }
    }
}
