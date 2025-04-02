//
//  Session+CoreDataProperties.swift
//  BioMirrorTherapy
//
//  Created by Mykhailo Kotyk on 02.04.2025.
//
//

import Foundation
import CoreData


extension Session {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Session> {
        return NSFetchRequest<Session>(entityName: "Session")
    }

    @NSManaged public var id: String?
    @NSManaged public var startTime: Date?
    @NSManaged public var endTime: Date?
    @NSManaged public var phase: Int16
    @NSManaged public var completionStatus: String?
    @NSManaged public var needsSync: Bool
    @NSManaged public var notes: String?
    @NSManaged public var emotionalStates: EmotionalState?

}

extension Session : Identifiable {

}


