//
//  DissociationDetector.swift
//  BioMirrorTherapy
//
//  Created by Mykhailo Kotyk on 30.03.2025.
//

import Foundation

class DissociationDetector {
    // Duration thresholds for dissociation episodes
    private let mildDissociationThreshold: TimeInterval = 5.0 // 5 seconds
    private let moderateDissociationThreshold: TimeInterval = 30.0 // 30 seconds
    private let severeDissociationThreshold: TimeInterval = 120.0 // 2 minutes
    
    // Intensity thresholds
    private let dissociationIntensityThreshold: Float = 0.6
    
    // Current dissociation episode tracking
    private var dissociationStartTime: Date?
    private var currentDissociationIntensity: Float = 0.0
    private var isDissociated = false
    
    // History
    private var recentDissociationEpisodes: [DissociationEpisode] = []
    
    func processDissociationState(_ state: IntegratedEmotionalState) -> DissociationStatus {
        // Check if current state indicates dissociation
        let currentlyDissociated = state.dissociationIndex > dissociationIntensityThreshold
        
        if currentlyDissociated {
            // Start or continue dissociation episode
            if !isDissociated {
                // New episode starting
                dissociationStartTime = state.timestamp
                isDissociated = true
                currentDissociationIntensity = state.dissociationIndex
            } else {
                // Ongoing episode - update intensity if higher
                currentDissociationIntensity = max(currentDissociationIntensity, state.dissociationIndex)
            }
            
            // Calculate current duration
            guard let startTime = dissociationStartTime else {
                // Should never happen, but reset state if it does
                dissociationStartTime = state.timestamp
                return .none
            }
            
            let duration = state.timestamp.timeIntervalSince(startTime)
            
            // Determine severity based on duration and intensity
            let severity: DissociationSeverity
            if duration > severeDissociationThreshold {
                severity = .severe
            } else if duration > moderateDissociationThreshold {
                severity = .moderate
            } else if duration > mildDissociationThreshold {
                severity = .mild
            } else {
                // Too brief to classify yet
                severity = .potential
            }
            
            return .active(severity: severity, duration: duration, intensity: currentDissociationIntensity)
            
        } else if isDissociated {
            // Dissociation episode ending
            guard let startTime = dissociationStartTime else {
                // Reset state
                isDissociated = false
                return .none
            }
            
            let duration = state.timestamp.timeIntervalSince(startTime)
            
            // Only record episodes that lasted long enough to be classified
            if duration > mildDissociationThreshold {
                // Record the episode
                let episode = DissociationEpisode(
                    startTime: startTime,
                    endTime: state.timestamp,
                    duration: duration,
                    maxIntensity: currentDissociationIntensity
                )
                
                recentDissociationEpisodes.append(episode)
                
                // Limit history size
                if recentDissociationEpisodes.count > 20 {
                    recentDissociationEpisodes.removeFirst()
                }
                
                // Determine severity
                let severity: DissociationSeverity
                if duration > severeDissociationThreshold {
                    severity = .severe
                } else if duration > moderateDissociationThreshold {
                    severity = .moderate
                } else {
                    severity = .mild
                }
                
                // Reset tracking
                isDissociated = false
                dissociationStartTime = nil
                currentDissociationIntensity = 0.0
                
                return .recent(severity: severity, duration: duration, intensity: currentDissociationIntensity)
            } else {
                // Episode too brief to record
                isDissociated = false
                dissociationStartTime = nil
                currentDissociationIntensity = 0.0
                return .none
            }
        }
        
        return .none
    }
    
    func getDissociationEpisodes(since date: Date) -> [DissociationEpisode] {
        return recentDissociationEpisodes.filter { $0.startTime ?? Date() >= date }
    }
    
    func getTotalDissociationTime(since date: Date) -> TimeInterval {
        let episodes = getDissociationEpisodes(since: date)
        return episodes.reduce(0) { $0 + $1.duration }
    }
}

struct DissociationEpisode {
    let startTime: Date
    let endTime: Date
    let duration: TimeInterval
    let maxIntensity: Float
    
    var severity: DissociationSeverity {
        if duration > 120 || maxIntensity > 0.9 {
            return .severe
        } else if duration > 30 || maxIntensity > 0.8 {
            return .moderate
        } else {
            return .mild
        }
    }
}

enum DissociationSeverity {
    case potential
    case mild
    case moderate
    case severe
}

enum DissociationStatus {
    case none
    case active(severity: DissociationSeverity, duration: TimeInterval, intensity: Float)
    case recent(severity: DissociationSeverity, duration: TimeInterval, intensity: Float)
}
