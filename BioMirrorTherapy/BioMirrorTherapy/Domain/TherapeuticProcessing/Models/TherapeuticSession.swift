//
//  TherapeuticSession.swift
//  BioMirrorTherapy
//
//  Created by Mykhailo Kotyk on 30.03.2025.
//


import Foundation

class TherapeuticSession {
    let id: UUID
    let startTime: Date
    var endTime: Date?
    
    private(set) var sessionPhase: SessionPhase
    private(set) var interventions: [TherapeuticResponse] = []
    private(set) var emotionalStates: [IntegratedEmotionalState] = []
    private(set) var dissociationEpisodes: [DissociationEpisode] = []
    
    private(set) var sessionMetrics = SessionMetrics()
    
    init(id: UUID = UUID(), phase: SessionPhase = .connection) {
        self.id = id
        self.startTime = Date()
        self.sessionPhase = phase
    }
    
    func addEmotionalState(_ state: IntegratedEmotionalState) {
        emotionalStates.append(state)
        updateMetrics()
    }
    
    func addIntervention(_ response: TherapeuticResponse) {
        interventions.append(response)
    }
    
   
    func advanceToPhase(_ phase: SessionPhase) {
        sessionPhase = phase
    }
    
    func endSession() {
        endTime = Date()
        finalizeMetrics()
    }
    
    func getDuration() -> TimeInterval {
        return (endTime ?? Date()).timeIntervalSince(startTime)
    }
    
    private func updateMetrics() {
        guard let latestState = emotionalStates.last else { return }
        
        // Update coherence metrics
        sessionMetrics.averageCoherenceIndex = calculateAverageCoherenceIndex()
        
        // Update emotional range
        if let emotion = EmotionRecord(type: latestState.dominantEmotion, intensity: latestState.emotionalIntensity) {
            sessionMetrics.emotionsExpressed.insert(emotion)
        }
        
        // Update regulation metrics
        updateRegulationMetrics(latestState)
        
        // Update dissociation metrics
        if latestState.dissociationIndex > 0.6 {
            sessionMetrics.totalDissociationTime += 0.2 // Assuming 5Hz sampling rate
        }
    }
    
    private func calculateAverageCoherenceIndex() -> Float {
        guard !emotionalStates.isEmpty else { return 0 }
        
        let sum = emotionalStates.reduce(0) { $0 + $1.coherenceIndex }
        return sum / Float(emotionalStates.count)
    }
    
    private func updateRegulationMetrics(_ state: IntegratedEmotionalState) {
        // Track escalation and recovery
        if state.arousalLevel > 0.7 && sessionMetrics.peakArousal < state.arousalLevel {
            sessionMetrics.peakArousal = state.arousalLevel
            sessionMetrics.timeOfPeakArousal = state.timestamp
        }
        
        // Check for regulation improvement
        if let timeOfPeak = sessionMetrics.timeOfPeakArousal,
           sessionMetrics.peakArousal > 0.7 &&
           state.arousalLevel < sessionMetrics.peakArousal - 0.2 {
            // Calculate recovery time
            let recoveryTime = state.timestamp.timeIntervalSince(timeOfPeak)
            if sessionMetrics.regulationRecoveryTime == 0 || recoveryTime < sessionMetrics.regulationRecoveryTime {
                sessionMetrics.regulationRecoveryTime = recoveryTime
            }
        }
    }
    
    private func finalizeMetrics() {
        guard let endTime = endTime else { return }
        
        // Calculate session duration
        sessionMetrics.sessionDuration = endTime.timeIntervalSince(startTime)
        
        // Calculate emotional range index
        sessionMetrics.emotionalRangeIndex = Float(sessionMetrics.emotionsExpressed.count) / Float(EmotionType.allCases.count)
        
        // Calculate percentage of time in dissociation
        if sessionMetrics.sessionDuration > 0 {
            sessionMetrics.percentageTimeInDissociation = Float(sessionMetrics.totalDissociationTime / sessionMetrics.sessionDuration)
        }
    }
    
    func recordDissociationEpisode(_ episode: DissociationEpisode) {
        dissociationEpisodes.append(episode)
        updateMetrics()
    }
    
    func advancePhase(to newPhase: SessionPhase) {
        // This method is simply a synonym for advanceToPhase with different parameter names
        sessionPhase = newPhase
    }
  
    
//    private func updateMetrics() {
//        // Update real-time metrics based on latest data
//        guard let latestState = emotionalStates.last else { return }
//        
//        // Update emotional coherence metrics
//        sessionMetrics.averageCoherenceIndex = emotionalStates.map { $0.coherenceIndex }.reduce(0, +) / Float(emotionalStates.count)
//        
//        // Update emotional range
//        if let emotion = EmotionTypeMap[latestState.dominantEmotion] {
//            sessionMetrics.emotionsExpressed.insert(emotion)
//        }
//        
//        // Update regulation metrics
//        sessionMetrics.regulationCapacity = calculateRegulationCapacity()
//        
//        // Update dissociation metrics
//        sessionMetrics.totalDissociationTime = dissociationEpisodes.reduce(0) { $0 + $1.duration }
//        sessionMetrics.dissociationEpisodeCount = dissociationEpisodes.count
//    }
//    
//    private func finalizeMetrics() {
//        // Calculate final session metrics when session ends
//        sessionMetrics.sessionDuration = endTime?.timeIntervalSince(startTime) ?? 0
//        
//        // Calculate emotional expression range
//        sessionMetrics.emotionalExpressionRange = Float(sessionMetrics.emotionsExpressed.count) / Float(EmotionTypeMap.count)
//        
//        // Calculate regulation improvement
//        if emotionalStates.count > 10 {
//            // Compare first third to last third of session
//            let firstThird = Array(emotionalStates.prefix(emotionalStates.count / 3))
//            let lastThird = Array(emotionalStates.suffix(emotionalStates.count / 3))
//            
//            let firstThirdRegulation = firstThird.filter { $0.emotionalRegulation == .regulated }.count
//            let lastThirdRegulation = lastThird.filter { $0.emotionalRegulation == .regulated }.count
//            
//            let firstRatio = Float(firstThirdRegulation) / Float(firstThird.count)
//            let lastRatio = Float(lastThirdRegulation) / Float(lastThird.count)
//            
//            sessionMetrics.regulationImprovement = lastRatio - firstRatio
//        }
//    }
    
    private func calculateRegulationCapacity() -> Float {
        // This is a simplified implementation
        // In a real app, this would use more sophisticated analysis of
        // how quickly the child returns to baseline after emotional activation
        
        guard emotionalStates.count > 5 else { return 0.5 } // Default mid-range if not enough data
        
        // Calculate percentage of regulated states
        let regulatedStates = emotionalStates.filter { $0.emotionalRegulation == .regulated }
        let regulatedRatio = Float(regulatedStates.count) / Float(emotionalStates.count)
        
        // Look for recovery patterns after high arousal
        var recoverySpeed = 0.5 // Default mid-range
        var highArousalEpisodes = 0
        var totalRecoveryTime: TimeInterval = 0
        
        for i in 0..<emotionalStates.count-1 {
            // Detect high arousal
            if emotionalStates[i].arousalLevel > 0.7 {
                highArousalEpisodes += 1
                
                // Look for recovery (return to arousal < 0.4)
                for j in i+1..<emotionalStates.count {
                    if emotionalStates[j].arousalLevel < 0.4 {
                        let recoveryTime = emotionalStates[j].timestamp.timeIntervalSince(emotionalStates[i].timestamp)
                        totalRecoveryTime += recoveryTime
                        break
                    }
                }
            }
        }
        
        // Calculate average recovery time if any high arousal episodes were found
        if highArousalEpisodes > 0 {
            let averageRecoveryTime = totalRecoveryTime / Double(highArousalEpisodes)
            
            // Convert to regulation capacity score (faster recovery = higher capacity)
            // Using a sigmoid function to map recovery time to 0-1 range
            // Assume 60 seconds is average recovery time (0.5 capacity)
            let normalizedTime = averageRecoveryTime / 60.0
            recoverySpeed = Double(Float(1.0 / (1.0 + normalizedTime)))
        }
        
        // Combine regulated ratio and recovery speed
        return (regulatedRatio + Float(recoverySpeed)) / 2.0
    }

}


//    // Session metrics to track progress
//    struct SessionMetrics {
//        var sessionDuration: TimeInterval = 0
//        var averageCoherenceIndex: Float = 0
//        var emotionsExpressed: Set<Int> = []
//        var emotionalExpressionRange: Float = 0
//        var regulationCapacity: Float = 0
//        var regulationImprovement: Float = 0
//        var totalDissociationTime: TimeInterval = 0
//        var dissociationEpisodeCount: Int = 0
//        var interactionEngagement: Float = 0
//    }

//    // Map EmotionType to integers for set storage
//    let EmotionTypeMap: [EmotionType: Int] = [
//        .neutral: 0,
//        .happiness: 1,
//        .sadness: 2,
//        .anger: 3,
//        .fear: 4,
//        .surprise: 5,
//        .disgust: 6,
//        .contempt: 7,
//        .dissociation: 8,
//        .hypervigilance: 9,
//        .freeze: 10,
//        .confusion: 11,
//        .interest: 12,
//        .shame: 13,
//        .pride: 14
//    ]

//    enum SessionPhase {
//        case connection    // Building initial rapport
//        case awareness     // Increasing emotional awareness
//        case integration   // Connecting felt and expressed emotions
//        case regulation    // Building regulation skills
//        case transfer      // Applying skills to daily life
//    }



