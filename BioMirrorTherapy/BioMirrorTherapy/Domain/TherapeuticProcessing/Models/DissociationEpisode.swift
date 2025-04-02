//
//  DissociationEpisode.swift
//  BioMirrorTherapy
//
//  Created by Mykhailo Kotyk on 31.03.2025.
//

//import Foundation
//
//struct DissociationEpisode {
//    let startTime: Date
//    let endTime: Date
//    let maxIntensity: Float  // 0.0 to 1.0
//    let averageIntensity: Float  // 0.0 to 1.0
//    let physiologicalMarkers: [PhysiologicalMarker]
//    
//    // Duration of the episode in seconds
//    var duration: TimeInterval {
//        return endTime.timeIntervalSince(startTime)
//    }
//    
//    // Simplified constructor for creating an episode
//    static func createEpisode(
//        startTime: Date,
//        endTime: Date,
//        intensityValues: [Float],
//        physiologicalMarkers: [PhysiologicalMarker] = []
//    ) -> DissociationEpisode {
//        
//        let maxIntensity = intensityValues.max() ?? 0.0
//        let averageIntensity = intensityValues.reduce(0.0, +) / Float(intensityValues.count)
//        
//        return DissociationEpisode(
//            startTime: startTime,
//            endTime: endTime,
//            maxIntensity: maxIntensity,
//            averageIntensity: averageIntensity,
//            physiologicalMarkers: physiologicalMarkers
//        )
//    }
//}

// Physiological markers that might indicate dissociation
struct PhysiologicalMarker {
    enum MarkerType {
        case heartRateDecrease
        case respirationRateDecrease
        case skinConductanceDecrease
        case pupilDilation
        case movementFreeze
        case blinkRateDecrease
        case gazeFreezing
    }
    
    let type: MarkerType
    let intensity: Float  // 0.0 to 1.0, how strongly the marker presents
    let confidence: Float  // 0.0 to 1.0, confidence in the detection
    
    // Some common markers predefined for convenience
    static let heartRateDecrease = PhysiologicalMarker(type: .heartRateDecrease, intensity: 0.8, confidence: 0.7)
    static let respirationDecrease = PhysiologicalMarker(type: .respirationRateDecrease, intensity: 0.6, confidence: 0.7)
    static let skinConductanceDecrease = PhysiologicalMarker(type: .skinConductanceDecrease, intensity: 0.7, confidence: 0.6)
    static let gazeFreeze = PhysiologicalMarker(type: .gazeFreezing, intensity: 0.9, confidence: 0.9)
}

//enum DissociationStatus {
//    case none
//    case mild
//    case moderate
//    case severe
//    
//    var description: String {
//        switch self {
//        case .none:
//            return "Connected"
//        case .mild:
//            return "Slightly disconnected"
//        case .moderate:
//            return "Moderately disconnected"
//        case .severe:
//            return "Severely disconnected"
//        }
//    }
//    
//    static func fromIndex(_ index: Float) -> DissociationStatus {
//        switch index {
//        case 0.0..<0.3:
//            return .none
//        case 0.3..<0.5:
//            return .mild
//        case 0.5..<0.8:
//            return .moderate
//        default:
//            return .severe
//        }
//    }
//}
