//
//  ParentRepository.swift
//  BioMirrorTherapy
//
//  Created by Mykhailo Kotyk on 30.03.2025.
//

import Foundation
import Combine

protocol ParentRepository {
    func getChildInfo() -> AnyPublisher<ChildInfo, Error>
    func getRecentSessions(limit: Int) -> AnyPublisher<[SessionData], Error>
    func getProgressData() -> AnyPublisher<ProgressData, Error>
    func getEmotionalInsights() -> AnyPublisher<EmotionalInsights, Error>
    func scheduleSession(date: Date, duration: TimeInterval) -> AnyPublisher<Bool, Error>
}

class ParentRepositoryImpl: ParentRepository {
    static let shared = ParentRepositoryImpl()
    
    private init() {}
    
    func getChildInfo() -> AnyPublisher<ChildInfo, Error> {
        // In a real app, this would fetch data from a backend API or local database
        
        // Create a mock ChildInfo
        let childInfo = ChildInfo(
            name: "Alex Johnson",
            age: 9,
            imageData: nil,
            currentPhase: "Awareness Phase",
            overallProgress: 0.35
        )
        
        return Just(childInfo)
            .setFailureType(to: Error.self)
            .delay(for: .seconds(0.5), scheduler: RunLoop.main)
            .eraseToAnyPublisher()
    }
    
    func getRecentSessions(limit: Int) -> AnyPublisher<[SessionData], Error> {
        // In a real app, this would fetch data from a backend API or local database
        
        // Create mock sessions
        let sessions = [
            SessionData(
                id: "1",
                date: Date().addingTimeInterval(-86400),
                duration: 15 * 60,
                phase: 1,
                phaseName: "Awareness Phase",
                completionStatus: "Completed",
                coherenceIndex: 0.65,
                emotionsExpressed: ["Happy", "Sad", "Curious"],
                dissociationEpisodes: 0,
                dissociationDuration: 0,
                therapistNotes: nil,
                emotionalTimeline: [
                    EmotionTimelinePoint(id: "1", time: "0:00", emotion: "Neutral", intensity: 0.5),
                    EmotionTimelinePoint(id: "2", time: "5:00", emotion: "Happy", intensity: 0.7),
                    EmotionTimelinePoint(id: "3", time: "10:00", emotion: "Sad", intensity: 0.6),
                    EmotionTimelinePoint(id: "4", time: "15:00", emotion: "Curious", intensity: 0.8)
                ]
            ),
            SessionData(
                id: "2",
                date: Date().addingTimeInterval(-3 * 86400),
                duration: 20 * 60,
                phase: 1,
                phaseName: "Awareness Phase",
                completionStatus: "Completed",
                coherenceIndex: 0.58,
                emotionsExpressed: ["Confused", "Happy", "Frustrated"],
                dissociationEpisodes: 1,
                dissociationDuration: 45,
                therapistNotes: "Alex did well identifying emotions but had one brief dissociative episode when discussing school.",
                emotionalTimeline: [
                    EmotionTimelinePoint(id: "1", time: "0:00", emotion: "Neutral", intensity: 0.5),
                    EmotionTimelinePoint(id: "2", time: "5:00", emotion: "Happy", intensity: 0.6),
                    EmotionTimelinePoint(id: "3", time: "10:00", emotion: "Confused", intensity: 0.7),
                    EmotionTimelinePoint(id: "4", time: "15:00", emotion: "Frustrated", intensity: 0.8),
                    EmotionTimelinePoint(id: "5", time: "20:00", emotion: "Happy", intensity: 0.6)
                ]
            ),
            SessionData(
                id: "3",
                date: Date().addingTimeInterval(-5 * 86400),
                duration: 12 * 60,
                phase: 1,
                phaseName: "Awareness Phase",
                completionStatus: "Interrupted",
                coherenceIndex: 0.42,
                emotionsExpressed: ["Frustrated", "Angry"],
                dissociationEpisodes: 2,
                dissociationDuration: 120,
                therapistNotes: "Session ended early due to difficulty regulating emotions.",
                emotionalTimeline: [
                    EmotionTimelinePoint(id: "1", time: "0:00", emotion: "Neutral", intensity: 0.5),
                    EmotionTimelinePoint(id: "2", time: "3:00", emotion: "Frustrated", intensity: 0.6),
                    EmotionTimelinePoint(id: "3", time: "6:00", emotion: "Angry", intensity: 0.8),
                    EmotionTimelinePoint(id: "4", time: "9:00", emotion: "Angry", intensity: 0.9),
                    EmotionTimelinePoint(id: "5", time: "12:00", emotion: "Frustrated", intensity: 0.7)
                ]
            )
        ]
        
        return Just(Array(sessions.prefix(limit)))
            .setFailureType(to: Error.self)
            .delay(for: .seconds(0.5), scheduler: RunLoop.main)
            .eraseToAnyPublisher()
    }
    
    func getProgressData() -> AnyPublisher<ProgressData, Error> {
        // In a real app, this would fetch data from a backend API or local database
        
        // Create mock progress data
        let progressData = ProgressData(
            phaseProgress: [
                PhaseProgressData(id: "0", name: "Connection", progress: 0.9),
                PhaseProgressData(id: "1", name: "Awareness", progress: 0.45),
                PhaseProgressData(id: "2", name: "Integration", progress: 0.1),
                PhaseProgressData(id: "3", name: "Transfer", progress: 0.0)
            ],
            weeklySessionData: [
                SessionDataPoint(id: "0", day: "Mon", minutes: 15),
                SessionDataPoint(id: "1", day: "Tue", minutes: 0),
                SessionDataPoint(id: "2", day: "Wed", minutes: 20),
                SessionDataPoint(id: "3", day: "Thu", minutes: 0),
                SessionDataPoint(id: "4", day: "Fri", minutes: 15),
                SessionDataPoint(id: "5", day: "Sat", minutes: 10),
                SessionDataPoint(id: "6", day: "Sun", minutes: 0)
            ]
        )
        
        return Just(progressData)
            .setFailureType(to: Error.self)
            .delay(for: .seconds(0.5), scheduler: RunLoop.main)
            .eraseToAnyPublisher()
    }
    
    func getEmotionalInsights() -> AnyPublisher<EmotionalInsights, Error> {
        // In a real app, this would fetch data from a backend API or local database
        
        // Create mock emotional insights
        let insights = EmotionalInsights(
            topEmotions: [
                EmotionData(id: "1", name: "Happy", percentage: 0.35, color: .blue),
                EmotionData(id: "2", name: "Sad", percentage: 0.25, color: .indigo),
                EmotionData(id: "3", name: "Frustrated", percentage: 0.20, color: .red),
                EmotionData(id: "4", name: "Curious", percentage: 0.15, color: .orange),
                EmotionData(id: "5", name: "Calm", percentage: 0.05, color: .green)
            ],
            averageCoherence: 0.62,
            coherenceTrend: "Improving",
            coherenceTrendData: [
                CoherenceDataPoint(id: "1", day: "Mon", coherence: 0.45),
                CoherenceDataPoint(id: "2", day: "Tue", coherence: 0.52),
                CoherenceDataPoint(id: "3", day: "Wed", coherence: 0.50),
                CoherenceDataPoint(id: "4", day: "Thu", coherence: 0.58),
                CoherenceDataPoint(id: "5", day: "Fri", coherence: 0.62),
                CoherenceDataPoint(id: "6", day: "Sat", coherence: 0.65),
                CoherenceDataPoint(id: "7", day: "Sun", coherence: 0.68)
            ]
        )
        
        return Just(insights)
            .setFailureType(to: Error.self)
            .delay(for: .seconds(0.5), scheduler: RunLoop.main)
            .eraseToAnyPublisher()
    }
    
    func scheduleSession(date: Date, duration: TimeInterval) -> AnyPublisher<Bool, Error> {
        // In a real app, this would send a request to a backend API
        
        // Simulate a successful request
        return Just(true)
            .setFailureType(to: Error.self)
            .delay(for: .seconds(1.0), scheduler: RunLoop.main)
            .eraseToAnyPublisher()
    }
}
