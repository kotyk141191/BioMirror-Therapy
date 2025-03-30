//
//  EmotionalState.swift
//  BioMirrorTherapy
//
//  Created by Mykhailo Kotyk on 30.03.2025.
//

import Foundation

struct EmotionalState {
    let timestamp: Date
    let primaryEmotion: EmotionType
    let primaryIntensity: Float // 0.0 to 1.0
    let secondaryEmotions: [EmotionType: Float]
    let microExpressions: [MicroExpression]
    let confidence: Float // 0.0 to 1.0
    let faceDetectionQuality: DetectionQuality
    
    var description: String {
        return "Primary: \(primaryEmotion) (\(Int(primaryIntensity * 100))%), Confidence: \(Int(confidence * 100))%"
    }
}

enum EmotionType: String, CaseIterable {
    case neutral = "Neutral"
    case happiness = "Happiness"
    case sadness = "Sadness"
    case anger = "Anger"
    case fear = "Fear"
    case surprise = "Surprise"
    case disgust = "Disgust"
    case contempt = "Contempt"
    
    // Trauma-specific states
    case dissociation = "Dissociation"
    case hypervigilance = "Hypervigilance"
    case freeze = "Freeze"
    
    // Complex emotions
    case confusion = "Confusion"
    case interest = "Interest"
    case shame = "Shame"
    case pride = "Pride"
}

struct MicroExpression {
    let timestamp: Date
    let duration: TimeInterval  // in seconds
    let emotionType: EmotionType
    let intensity: Float
    let facialActionUnits: [FacialActionUnit]
}

struct FacialActionUnit {
    let id: Int  // FACS action unit number
    let name: String
    let intensity: Float  // 0.0 to 1.0
}

enum DetectionQuality {
    case excellent
    case good
    case fair
    case poor
    case noFace
}
