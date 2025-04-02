//
//  EmotionalState+CoreDataProperties.swift
//  BioMirrorTherapy
//
//  Created by Mykhailo Kotyk on 02.04.2025.
//
//

import Foundation
import CoreData


extension EmotionalState {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<EmotionalState> {
        return NSFetchRequest<EmotionalState>(entityName: "EmotionalState")
    }

    @NSManaged public var id: String?
    @NSManaged public var timestamp: Date?
    @NSManaged public var dominantEmotion: String?
    @NSManaged public var emotionalIntensity: Float
    @NSManaged public var arousalLevel: Float
    @NSManaged public var coherenceIndex: Float
    @NSManaged public var dissociationIndex: Float
    @NSManaged public var dataQuality: String?
    @NSManaged public var needsSync: Bool
    @NSManaged public var session: Session?

}

extension EmotionalState : Identifiable {

}
