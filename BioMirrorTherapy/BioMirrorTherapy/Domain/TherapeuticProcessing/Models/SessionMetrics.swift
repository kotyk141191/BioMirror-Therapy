//
//  SessionMetrics.swift
//  BioMirrorTherapy
//
//  Created by Mykhailo Kotyk on 30.03.2025.
//

import Foundation
//
//struct SessionMetrics {
//    // Basic metrics
//    var sessionDuration: TimeInterval = 0
//    var interventionsDelivered: Int = 0
//    
//    // Emotional coherence
//    var averageCoherenceIndex: Float = 0
//    var emotionalMaskingInstances: Int = 0
//    
//    // Emotional range
//    var emotionsExpressed: Set<EmotionRecord> = []
//    var emotionalRangeIndex: Float = 0 // 0.0-1.0, percentage of all emotions expressed
//    
//    // Dissociation
//    var dissociationEpisodes: Int = 0
//    var totalDissociationTime: TimeInterval = 0
//    var percentageTimeInDissociation: Float = 0
//    
//    // Regulation
//    var peakArousal: Float = 0
//    var timeOfPeakArousal: Date?
//    var regulationRecoveryTime: TimeInterval = 0
//    
//    // Progress indicators
//    var phaseProgress: Float = 0 // 0.0-1.0 for current phase
//    var overallProgress: Float = 0 // 0.0-1.0 for entire program
//    
//    // Assessment scores
//    var preSessionAssessmentScore: Float?
//    var postSessionAssessmentScore: Float?
//}


//// Session metrics to track progress
struct SessionMetrics {
    var sessionDuration: TimeInterval = 0
    var averageCoherenceIndex: Float = 0
    var emotionsExpressed: Set<EmotionRecord> = []
    var emotionalExpressionRange: Float = 0
    var regulationCapacity: Float = 0
    var regulationImprovement: Float = 0
    var totalDissociationTime: TimeInterval = 0
    var dissociationEpisodeCount: Int = 0
    var interactionEngagement: Float = 0
    
    // Regulation
       var peakArousal: Float = 0
       var timeOfPeakArousal: Date?
       var regulationRecoveryTime: TimeInterval = 0
    
    // Dissociation
        var dissociationEpisodes: Int = 0
        var percentageTimeInDissociation: Float = 0
}

// Map EmotionType to integers for set storage
let EmotionTypeMap: [EmotionType: Int] = [
    .neutral: 0,
    .happiness: 1,
    .sadness: 2,
    .anger: 3,
    .fear: 4,
    .surprise: 5,
    .disgust: 6,
    .contempt: 7,
    .dissociation: 8,
    .hypervigilance: 9,
    .freeze: 10,
    .confusion: 11,
    .interest: 12,
    .shame: 13,
    .pride: 14
]

//enum SessionPhase {
//    case connection    // Building initial rapport
//    case awareness     // Increasing emotional awareness
//    case integration   // Connecting felt and expressed emotions
//    case regulation    // Building regulation skills
//    case transfer      // Applying skills to daily life
//}
