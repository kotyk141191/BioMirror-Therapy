//
//  ProgressTracker.swift
//  BioMirrorTherapy
//
//  Created by Mykhailo Kotyk on 30.03.2025.
//

import Foundation
import Combine

class ProgressTracker {
    // MARK: - Properties
    
    private var sessionHistory: [UUID: TherapeuticSession] = [:]
    private var childMetrics = ChildMetrics()
    
    // Metrics to track across sessions
    private var progressPublisher = PassthroughSubject<ProgressUpdate, Never>()
    
    // MARK: - Public Methods
    
    func registerSession(_ session: TherapeuticSession) {
        sessionHistory[session.id] = session
    }
    
    func finalizeSession(_ session: TherapeuticSession) {
        // Update child metrics based on session results
        updateMetricsFromSession(session)
        
        // Generate progress update
        let update = generateProgressUpdate(session)
        progressPublisher.send(update)
    }
    
    func getProgressPublisher() -> AnyPublisher<ProgressUpdate, Never> {
        return progressPublisher.eraseToAnyPublisher()
    }
    
    func getChildMetrics() -> ChildMetrics {
        return childMetrics
    }
    
    func getRecommendedPhase() -> SessionPhase {
        // Analyze progress to recommend next session phase
        
        // Check if still in early sessions
        if sessionHistory.count < 3 {
            return .connection
        }
        
        // Check if emotional awareness needs more work
        if childMetrics.averageEmotionalCoherence < 0.4 {
            return .awareness
        }
        
        // Check if integration is needed
        if childMetrics.averageEmotionalMasking > 0.6 || childMetrics.averageDissociationIndex > 0.5 {
            return .integration
        }
        
        // Check if regulation skills need work
        if childMetrics.averageRegulationCapacity < 0.5 {
            return .regulation
        }
        
        // If good progress in all areas, move to transfer
        if childMetrics.averageEmotionalCoherence > 0.6 &&
           childMetrics.averageRegulationCapacity > 0.6 &&
           childMetrics.totalSessions > 10 {
            return .transfer
        }
        
        // Default to continue current phase
        return getLastSessionPhase() ?? .connection
    }
    
    func generateReport() -> ProgressReport {
        // Generate comprehensive progress report
        let report = ProgressReport(
            childMetrics: childMetrics,
            sessionHistory: Array(sessionHistory.values),
            recommendations: generateRecommendations(),
            sessionCount: sessionHistory.count,
            lastSessionDate: getLastSessionDate() ?? Date()
        )
        
        return report
    }
    
    // MARK: - Private Methods
    
    private func updateMetricsFromSession(_ session: TherapeuticSession) {
        // Update total sessions
        childMetrics.totalSessions += 1
        
        // Update total time
        if let endTime = session.endTime {
            let sessionDuration = endTime.timeIntervalSince(session.startTime)
            childMetrics.totalTherapyTime += sessionDuration
        }
        
        // Update emotional coherence
        let sessionCoherence = session.sessionMetrics.averageCoherenceIndex
        childMetrics.averageEmotionalCoherence = updateRunningAverage(
            current: childMetrics.averageEmotionalCoherence,
            new: sessionCoherence,
            count: childMetrics.totalSessions
        )
        
        // Update emotional masking
        // This is a placeholder - in a real implementation, you would calculate this from session data
        let sessionMasking: Float = session.emotionalStates.map { $0.emotionalMaskingIndex }.reduce(0, +) /
                                   Float(max(1, session.emotionalStates.count))
        
        childMetrics.averageEmotionalMasking = updateRunningAverage(
            current: childMetrics.averageEmotionalMasking,
            new: sessionMasking,
            count: childMetrics.totalSessions
        )
        
        // Update dissociation metrics
        let sessionDissociation: Float = session.emotionalStates.map { $0.dissociationIndex }.reduce(0, +) /
                                       Float(max(1, session.emotionalStates.count))
        
        childMetrics.averageDissociationIndex = updateRunningAverage(
            current: childMetrics.averageDissociationIndex,
            new: sessionDissociation,
            count: childMetrics.totalSessions
        )
        
        // Update dissociation episodes
        childMetrics.totalDissociationEpisodes += session.dissociationEpisodes.count
        
        // Update regulation capacity
        childMetrics.averageRegulationCapacity = updateRunningAverage(
            current: childMetrics.averageRegulationCapacity,
            new: session.sessionMetrics.regulationCapacity,
            count: childMetrics.totalSessions
        )
        
        // Update emotional range
        let sessionEmotionalRange = session.sessionMetrics.emotionalExpressionRange
        childMetrics.emotionalExpressionRange = max(childMetrics.emotionalExpressionRange, sessionEmotionalRange)
        
        // Check for important milestones
        checkForMilestones(session)
    }
    
    private func updateRunningAverage(current: Float, new: Float, count: Int) -> Float {
        // Update running average with new value
        return ((current * Float(count - 1)) + new) / Float(count)
    }
    
    private func generateProgressUpdate(_ session: TherapeuticSession) -> ProgressUpdate {
        // Calculate changes since last session
        let lastPhase = getLastSessionPhase() ?? .connection
        let phaseChanged = lastPhase != session.sessionPhase
        
        // Calculate key metrics changes
        let coherenceChange = calculateMetricChange(
            previousAverage: childMetrics.averageEmotionalCoherence,
            sessionValue: session.sessionMetrics.averageCoherenceIndex
        )
        
        let regulationChange = calculateMetricChange(
            previousAverage: childMetrics.averageRegulationCapacity,
            sessionValue: session.sessionMetrics.regulationCapacity
        )
        
        // Identify significant improvements
        var significantImprovements: [String] = []
        
        if coherenceChange > 0.1 {
            significantImprovements.append("Emotional awareness")
        }
        
        if regulationChange > 0.1 {
            significantImprovements.append("Emotional regulation")
        }
        
        if session.dissociationEpisodes.isEmpty && childMetrics.averageDissociationIndex > 0.4 {
            significantImprovements.append("Reduced dissociation")
        }
        
        return ProgressUpdate(
            sessionId: session.id,
            sessionDate: session.startTime,
            phaseName: session.sessionPhase.name,
            phaseChanged: phaseChanged,
            coherenceScore: session.sessionMetrics.averageCoherenceIndex,
            coherenceChange: coherenceChange,
            regulationCapacity: session.sessionMetrics.regulationCapacity,
            regulationChange: regulationChange,
            emotionalRange: session.sessionMetrics.emotionalExpressionRange,
            significantImprovements: significantImprovements,
            recommendedNextPhase: getRecommendedPhase()
        )
    }
    
    private func calculateMetricChange(previousAverage: Float, sessionValue: Float) -> Float {
        return sessionValue - previousAverage
    }
    
    private func checkForMilestones(_ session: TherapeuticSession) {
        // Check for important therapeutic milestones
        // This is a placeholder implementation
        
        // Example: First session with no dissociation
        if session.dissociationEpisodes.isEmpty &&
           childMetrics.totalDissociationEpisodes > 0 &&
           !childMetrics.milestones.contains(.noDissociation) {
            childMetrics.milestones.insert(.noDissociation)
        }
        
        // Example: First session with high coherence
        if session.sessionMetrics.averageCoherenceIndex > 0.7 &&
           !childMetrics.milestones.contains(.highCoherence) {
            childMetrics.milestones.insert(.highCoherence)
        }
        
        // Example: First session with high regulation capacity
        if session.sessionMetrics.regulationCapacity > 0.7 &&
           !childMetrics.milestones.contains(.highRegulation) {
            childMetrics.milestones.insert(.highRegulation)
        }
    }
    
    private func generateRecommendations() -> [String] {
        // Generate tailored recommendations based on progress
        var recommendations: [String] = []
        
        if childMetrics.averageEmotionalCoherence < 0.4 {
            recommendations.append("Continue work on emotional awareness and recognition")
        }
        
        if childMetrics.averageEmotionalMasking > 0.6 {
            recommendations.append("Focus on connecting facial expressions with bodily feelings")
        }
        
        if childMetrics.averageDissociationIndex > 0.5 {
            recommendations.append("Prioritize grounding exercises and present-moment awareness")
        }
        
        if childMetrics.emotionalExpressionRange < 0.3 {
            recommendations.append("Explore a wider range of emotions in safe context")
        }
        
        if childMetrics.averageRegulationCapacity < 0.4 {
            recommendations.append("Practice emotional regulation skills with gradually increasing intensity")
        }
        
        return recommendations
    }
    
    private func getLastSessionPhase() -> SessionPhase? {
        // Find most recent session
        guard let lastSession = sessionHistory.values.max(by: { $0.startTime < $1.startTime }) else {
            return nil
        }
        
        return lastSession.sessionPhase
    }
    
    private func getLastSessionDate() -> Date? {
        // Find date of most recent session
        return sessionHistory.values.map { $0.startTime }.max()
    }
    
  
}

// Progress tracking models
struct ChildMetrics {
    var totalSessions: Int = 0
    var totalTherapyTime: TimeInterval = 0
    var averageEmotionalCoherence: Float = 0.0
    var averageEmotionalMasking: Float = 0.0
    var averageDissociationIndex: Float = 0.0
    var totalDissociationEpisodes: Int = 0
    var averageRegulationCapacity: Float = 0.0
    var emotionalExpressionRange: Float = 0.0
    var milestones: Set<TherapeuticMilestone> = []
}

enum TherapeuticMilestone {
    case firstSession
    case phaseCompletion
    case noDissociation
    case highCoherence
    case highRegulation
    case emotionalVocabulary
    case selfRegulation
}

struct ProgressUpdate {
    let sessionId: UUID
    let sessionDate: Date
    let phaseName: String
    let phaseChanged: Bool
    let coherenceScore: Float
    let coherenceChange: Float
    let regulationCapacity: Float
    let regulationChange: Float
    let emotionalRange: Float
    let significantImprovements: [String]
    let recommendedNextPhase: SessionPhase
}

struct ProgressReport {
    let childMetrics: ChildMetrics
    let sessionHistory: [TherapeuticSession]
    let recommendations: [String]
    let sessionCount: Int
    let lastSessionDate: Date
}

// Extension to get human-readable phase names

   


