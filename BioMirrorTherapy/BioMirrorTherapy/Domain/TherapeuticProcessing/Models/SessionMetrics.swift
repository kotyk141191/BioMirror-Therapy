//
//  SessionMetrics.swift
//  BioMirrorTherapy
//
//  Created by Mykhailo Kotyk on 30.03.2025.
//

import Foundation

struct SessionMetrics {
    // Basic metrics
    var sessionDuration: TimeInterval = 0
    var interventionsDelivered: Int = 0
    
    // Emotional coherence
    var averageCoherenceIndex: Float = 0
    var emotionalMaskingInstances: Int = 0
    
    // Emotional range
    var emotionsExpressed: Set<EmotionRecord> = []
    var emotionalRangeIndex: Float = 0 // 0.0-1.0, percentage of all emotions expressed
    
    // Dissociation
    var dissociationEpisodes: Int = 0
    var totalDissociationTime: TimeInterval = 0
    var percentageTimeInDissociation: Float = 0
    
    // Regulation
    var peakArousal: Float = 0
    var timeOfPeakArousal: Date?
    var regulationRecoveryTime: TimeInterval = 0
    
    // Progress indicators
    var phaseProgress: Float = 0 // 0.0-1.0 for current phase
    var overallProgress: Float = 0 // 0.0-1.0 for entire program
    
    // Assessment scores
    var preSessionAssessmentScore: Float?
    var postSessionAssessmentScore: Float?
}
