//
//  ParentDashboardModels.swift
//  BioMirrorTherapy
//
//  Created by Mykhailo Kotyk on 30.03.2025.
//

import Foundation
import SwiftUI

struct ChildInfo {
    let name: String
    let age: Int
    let imageData: Data?
    let currentPhase: String
    let overallProgress: Float
}

// Fix for SessionData in TherapistDashboardModels.swift
struct SessionData: Identifiable {
    let id: String
    let date: Date
    let duration: TimeInterval
    let phase: Int
    let phaseName: String
    let completionStatus: String
    let coherenceIndex: Float
    let emotionsExpressed: [String]
    let dissociationEpisodes: Int
    let dissociationDuration: TimeInterval
    let regulationEvents: Int
    let avgRegulationTime: TimeInterval
    let therapistNotes: String?
    let emotionalTimeline: [EmotionTimelinePoint]
    let coherenceData: [CoherenceDataPoint]
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    var formattedDuration: String {
        let minutes = Int(duration / 60)
        return "\(minutes) min"
    }
    
    var formattedRegulationTime: String {
        let seconds = Int(avgRegulationTime)
        
        if seconds >= 60 {
            let minutes = seconds / 60
            let remainingSeconds = seconds % 60
            return "\(minutes)m \(remainingSeconds)s"
        } else {
            return "\(seconds)s"
        }
    }
    
    var statusColor: Color {
        switch completionStatus {
        case "Completed":
            return .green
        case "Interrupted":
            return .orange
        case "Terminated":
            return .red
        default:
            return .gray
        }
    }
}

struct EmotionTimelinePoint: Identifiable {
    let id: String
    let time: String
    let emotion: String
    let intensity: Double
}

struct PhaseProgressData: Identifiable {
    let id: String
    let name: String
    let progress: Float
}

struct SessionDataPoint: Identifiable {
    let id: String
    let day: String
    let minutes: Double
}

struct EmotionData: Identifiable {
    let id: String
    let name: String
    let percentage: Double
    let color: Color
}

struct CoherenceDataPoint: Identifiable {
    let id: String
    let day: String
    let coherence: Double
}

struct ProgressData {
    let phaseProgress: [PhaseProgressData]
    let weeklySessionData: [SessionDataPoint]
}

struct EmotionalInsights {
    let topEmotions: [EmotionData]
    let averageCoherence: Float
    let coherenceTrend: String
    let coherenceTrendData: [CoherenceDataPoint]
}
