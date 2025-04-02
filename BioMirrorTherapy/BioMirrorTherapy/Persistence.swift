//
//  Persistence.swift
//  BioMirrorTherapy
//
//  Created by Mykhailo Kotyk on 30.03.2025.
//

import CoreData
import Foundation

protocol PersistenceService {
    var viewContext: NSManagedObjectContext { get }
    
    func saveContext()
    func createBackgroundContext() -> NSManagedObjectContext
}

class CoreDataPersistenceService: PersistenceService {
     let container: NSPersistentContainer
    
    var viewContext: NSManagedObjectContext {
        return container.viewContext
    }
    
    init(container: NSPersistentContainer) {
        self.container = container
        
        // Configure context
        viewContext.automaticallyMergesChangesFromParent = true
        viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
    func saveContext() {
        if viewContext.hasChanges {
            do {
                try viewContext.save()
            } catch {
                print("Error saving context: \(error)")
            }
        }
    }
    
    func createBackgroundContext() -> NSManagedObjectContext {
        let context = container.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }
}


// CoreDataPersistenceService extension
extension CoreDataPersistenceService {
    func fetchEmotionalStates(for sessionId: String) -> [NSManagedObject] {
        let fetchRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "EmotionalState")
        fetchRequest.predicate = NSPredicate(format: "sessionId == %@", sessionId)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
        
        do {
            return try viewContext.fetch(fetchRequest)
        } catch {
            print("Error fetching emotional states: \(error)")
            return []
        }
    }
    
    func createEmotionalState(from integratedState: IntegratedEmotionalState, sessionId: String) -> NSManagedObject? {
        let entity = NSEntityDescription.entity(forEntityName: "EmotionalState", in: viewContext)!
        let emotionalState = NSManagedObject(entity: entity, insertInto: viewContext)
        
        emotionalState.setValue(UUID().uuidString, forKey: "id")
        emotionalState.setValue(integratedState.timestamp, forKey: "timestamp")
        emotionalState.setValue(integratedState.dominantEmotion.rawValue, forKey: "dominantEmotion")
        emotionalState.setValue(integratedState.emotionalIntensity, forKey: "emotionalIntensity")
        emotionalState.setValue(integratedState.arousalLevel, forKey: "arousalLevel")
        emotionalState.setValue(integratedState.coherenceIndex, forKey: "coherenceIndex")
        emotionalState.setValue(integratedState.dissociationIndex, forKey: "dissociationIndex")
        emotionalState.setValue(sessionId, forKey: "sessionId")
        emotionalState.setValue(true, forKey: "needsSync")
        
        return emotionalState
    }
    
    func createSession(id: UUID, phase: SessionPhase) -> NSManagedObject? {
        let entity = NSEntityDescription.entity(forEntityName: "Session", in: viewContext)!
        let session = NSManagedObject(entity: entity, insertInto: viewContext)
        
        session.setValue(id.uuidString, forKey: "id")
        session.setValue(Date(), forKey: "startTime")
        session.setValue(nil, forKey: "endTime")
        session.setValue(phase.rawValue, forKey: "phase")
        session.setValue("InProgress", forKey: "completionStatus")
        session.setValue(true, forKey: "needsSync")
        
        return session
    }
    
    func updateSession(_ session: NSManagedObject, endTime: Date, status: String) {
        session.setValue(endTime, forKey: "endTime")
        session.setValue(status, forKey: "completionStatus")
        session.setValue(true, forKey: "needsSync")
        
        saveContext()
    }
}
