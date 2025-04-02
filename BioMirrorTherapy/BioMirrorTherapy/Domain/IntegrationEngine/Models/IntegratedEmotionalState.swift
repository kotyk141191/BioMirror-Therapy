//
//  IntegratedEmotionalState.swift
//  BioMirrorTherapy
//
//  Created by Mykhailo Kotyk on 30.03.2025.
//

import Foundation

struct IntegratedEmotionalState {
    let timestamp: Date
    let emotionalState: EmotionalState
    let physiologicalState: PhysiologicalState
    
    // Coherence metrics
    let coherenceIndex: Float // 0.0 to 1.0, higher means more coherence between face and body
    let emotionalMaskingIndex: Float // 0.0 to 1.0, higher means more masking of emotions
    let dissociationIndex: Float // 0.0 to 1.0, higher means more dissociation
    
    // Comprehensive emotional assessment
    let dominantEmotion: EmotionType
    let emotionalIntensity: Float // 0.0 to 1.0
    let emotionalRegulation: RegulationState
    let arousalLevel: Float // 0.0 to 1.0
    
    // Data quality
    let dataQuality: DataQuality
    
    // Interpretation
    var isFacialEmotionMasked: Bool {
        return emotionalMaskingIndex > 0.6
    }
    
    var isDissociated: Bool {
        return dissociationIndex > 0.6
    }
    
    var isRegulated: Bool {
        return emotionalRegulation == .regulated
    }
}

enum RegulationState {
    case regulated
    case mildDysregulation
    case moderateDysregulation
    case severeDysregulation
}

enum DataQuality: String {
    case excellent = "Excellent"
    case good = "Good"
    case fair = "Fair"
    case poor = "Poor"
    case invalid = "Invalid"
}
