//
//  TherapistDashboardModels.swift
//  BioMirrorTherapy
//
//  Created by Mykhailo Kotyk on 30.03.2025.
//

import Foundation
import SwiftUI

struct PatientData: Identifiable {
    let id: String
    let name: String
    let age: Int
    let imageData: Data?
    let startDate: Date
    let sessionCount: Int
    let currentPhaseName: String
    let overallProgress: Float
    let diagnoses: [String]
    let recentNotes: String?
    let notesDate: Date?
    let urgentFlag: Bool
    
    // Emotion regulation metrics
    let emotionCoherence: Float
    let emotionCoherenceTrend: String
    let regulationRate: Float
    let coherenceTrendData: [ChartDataPoint]
    
    // Dissociation metrics
    let dissociationEpisodeCount: Int
    let dissociationDuration: TimeInterval
    let dissociationTrend: String
    let dissociationTrendData: [ChartDataPoint]
    
    // Emotional profile
    let topEmotions: [EmotionData]
    let emotionalRange: String
    
    // Treatment plan
    let phaseObjectives: [String]
    let recommendedActivities: [ActivityRecommendation]
    
    // Recent sessions
    let recentSessions: [SessionData]
    
    var formattedStartDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: startDate)
    }
    
    var formattedNotesDate: String {
        guard let date = notesDate else { return "" }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    var formattedDissociationDuration: String {
        let minutes = Int(dissociationDuration) / 60
        let seconds = Int(dissociationDuration) % 60
        
        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }
}

struct ActivityRecommendation: Identifiable {
    let id: String
    let name: String
    let description: String
    let priority: String // "High", "Medium", "Low"
}

struct ChartDataPoint: Identifiable {
    let id: String
    let session: String
    let value: Double
}

//struct SessionData: Identifiable {
//    let id: String
//    let date: Date
//    let duration: TimeInterval
//    let phase: Int
//    let phaseName: String
//    let completionStatus: String
//    let coherenceIndex: Float
//    let emotionsExpressed: [String]
//    let dissociationEpisodes: Int
//    let dissociationDuration: TimeInterval
//    let regulationEvents: Int
//    let avgRegulationTime: TimeInterval
//    let therapistNotes: String?
//    let emotionalTimeline: [EmotionTimelinePoint]
//    let coherenceData: [CoherenceDataPoint]
//    
//    var formattedDate: String {
//        let formatter = DateFormatter()
//        formatter.dateStyle = .medium
//        formatter.timeStyle = .short
//        return formatter.string(from: date)
//    }
//    
//    var formattedDuration: String {
//        let minutes = Int(duration / 60)
//        return "\(minutes) min"
//    }
//    
//    var formattedRegulationTime: String {
//        let seconds = Int(avgRegulationTime)
//        
//        if seconds >= 60 {
//            let minutes = seconds / 60
//            let remainingSeconds = seconds % 60
//            return "\(minutes)m \(remainingSeconds)s"
//        } else {
//            return "\(seconds)s"
//        }
//    }
//    
//    var statusColor: Color {
//        switch completionStatus {
//        case "Completed":
//            return .green
//        case "Interrupted":
//            return .orange
//        case "Terminated":
//            return .red
//        default:
//            return .gray
//        }
//    }
//}
//
//struct CoherenceDataPoint: Identifiable {
//    let id: String
//    let time: String
//    let coherence: Double
//}
