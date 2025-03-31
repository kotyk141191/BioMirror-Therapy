//
//  ParentDashboardViewModel.swift
//  BioMirrorTherapy
//
//  Created by Mykhailo Kotyk on 30.03.2025.
//

import Foundation
import SwiftUI
import Combine

class ParentDashboardViewModel: ObservableObject {
    // MARK: - Published Properties
    
    // Child info
    @Published var childName: String = "Loading..."
    @Published var childAge: String = ""
    @Published var childImageData: Data?
    @Published var currentPhaseName: String = "Loading..."
    @Published var overallProgress: Float = 0.0
    
    // Sessions
    @Published var recentSessions: [SessionData] = []
    @Published var showingSessionDetail: Bool = false
    @Published var selectedSession: SessionData?
    
    // Progress
    @Published var phaseProgress: [PhaseProgressData] = []
    @Published var weeklySessionData: [SessionDataPoint] = []
    
    // Emotional data
    @Published var topEmotions: [EmotionData] = []
    @Published var averageCoherence: Float = 0.0
    @Published var coherenceTrend: String = ""
    @Published var coherenceTrendData: [CoherenceDataPoint] = []
    
    // UI state
    @Published var showingScheduleSession: Bool = false
    @Published var showingAlert: Bool = false
    @Published var alertTitle: String = ""
    @Published var alertMessage: String = ""
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    private let parentRepository: ParentRepository
    
    // MARK: - Initialization
    
    init(repository: ParentRepository = ParentRepositoryImpl.shared) {
        self.parentRepository = repository
        
        // Load mock data initially for preview
        loadMockData()
    }
    
    // MARK: - Public Methods
    
    func loadData() {
        // Load child info
        parentRepository.getChildInfo()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.showAlert("Error", message: "Failed to load child info: \(error.localizedDescription)")
                }
            } receiveValue: { [weak self] childInfo in
                self?.updateChildInfo(childInfo)
            }
            .store(in: &cancellables)
        
        // Load recent sessions
        parentRepository.getRecentSessions(limit: 3)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.showAlert("Error", message: "Failed to load recent sessions: \(error.localizedDescription)")
                }
            } receiveValue: { [weak self] sessions in
                self?.recentSessions = sessions
            }
            .store(in: &cancellables)
        
        // Load progress data
        parentRepository.getProgressData()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.showAlert("Error", message: "Failed to load progress data: \(error.localizedDescription)")
                }
            } receiveValue: { [weak self] progressData in
                self?.updateProgressData(progressData)
            }
            .store(in: &cancellables)
        
        // Load emotional insights
        parentRepository.getEmotionalInsights()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.showAlert("Error", message: "Failed to load emotional insights: \(error.localizedDescription)")
                }
            } receiveValue: { [weak self] insights in
                self?.updateEmotionalInsights(insights)
            }
            .store(in: &cancellables)
    }
    
    func selectSession(_ session: SessionData) {
        selectedSession = session
        showingSessionDetail = true
    }
    
    func showAllSessions() {
        // This would navigate to a full sessions list view
        // For now, just show a placeholder alert
        showAlert("All Sessions", message: "This would show a full list of all therapy sessions.")
    }
    
    func scheduleNewSession() {
        showingScheduleSession = true
    }
    
    func scheduleSession(date: Date, duration: TimeInterval) {
        parentRepository.scheduleSession(date: date, duration: duration)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.showAlert("Error", message: "Failed to schedule session: \(error.localizedDescription)")
                }
            } receiveValue: { [weak self] success in
                if success {
                    self?.showAlert("Session Scheduled", message: "The therapy session has been scheduled successfully.")
                } else {
                    self?.showAlert("Scheduling Failed", message: "Unable to schedule the session. Please try again.")
                }
            }
            .store(in: &cancellables)
    }
    
    func contactTherapist() {
        // In a real app, this would open email or messaging UI
        showAlert("Contact Therapist", message: "This would open your email app to contact your child's therapist.")
    }
    
    func viewResources() {
        // In a real app, this would navigate to a resources view
        showAlert("Resources", message: "This would show a list of helpful resources for parents.")
    }
    
    func emergencySupport() {
        // In a real app, this would show emergency contact options
        showAlert("Emergency Support", message: "This would show emergency contact information and immediate support resources.")
    }
    
    // MARK: - Private Methods
    
    private func updateChildInfo(_ childInfo: ChildInfo) {
        childName = childInfo.name
        childAge = "\(childInfo.age) years"
        childImageData = childInfo.imageData
        currentPhaseName = childInfo.currentPhase
        overallProgress = childInfo.overallProgress
    }
    
    private func updateProgressData(_ progressData: ProgressData) {
        phaseProgress = progressData.phaseProgress
        weeklySessionData = progressData.weeklySessionData
    }
    
    private func updateEmotionalInsights(_ insights: EmotionalInsights) {
        topEmotions = insights.topEmotions
        averageCoherence = insights.averageCoherence
        coherenceTrend = insights.coherenceTrend
        coherenceTrendData = insights.coherenceTrendData
    }
    
    private func showAlert(_ title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showingAlert = true
    }
    
    // MARK: - Mock Data
    
    private func loadMockData() {
        // Child info
        childName = "Alex Johnson"
        childAge = "9 years"
        currentPhaseName = "Awareness Phase"
        overallProgress = 0.35
        
        // Recent sessions
        recentSessions = [
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
                emotionalTimeline: []
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
                emotionalTimeline: []
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
                emotionalTimeline: []
            )
        ]
        
        // Progress data
        phaseProgress = [
            PhaseProgressData(id: "0", name: "Connection", progress: 0.9),
            PhaseProgressData(id: "1", name: "Awareness", progress: 0.45),
            PhaseProgressData(id: "2", name: "Integration", progress: 0.1),
            PhaseProgressData(id: "3", name: "Transfer", progress: 0.0)
        ]
        
        weeklySessionData = [
            SessionDataPoint(id: "0", day: "Mon", minutes: 15),
            SessionDataPoint(id: "1", day: "Tue", minutes: 0),
            SessionDataPoint(id: "2", day: "Wed", minutes: 20),
            SessionDataPoint(id: "3", day: "Thu", minutes: 0),
            SessionDataPoint(id: "4", day: "Fri", minutes: 15),
            SessionDataPoint(id: "5", day: "Sat", minutes: 10),
            SessionDataPoint(id: "6", day: "Sun", minutes: 0)
        ]
        
        // Emotional data
        topEmotions = [
            EmotionData(id: "1", name: "Happy", percentage: 0.35, color: .blue),
            EmotionData(id: "2", name: "Sad", percentage: 0.25, color: .indigo),
            EmotionData(id: "3", name: "Frustrated", percentage: 0.20, color: .red),
            EmotionData(id: "4", name: "Curious", percentage: 0.15, color: .orange),
            EmotionData(id: "5", name: "Calm", percentage: 0.05, color: .green)
        ]
        
        averageCoherence = 0.62
        coherenceTrend = "Improving"
        coherenceTrendData = [
            CoherenceDataPoint(id: "1", day: "Mon", coherence: 0.45),
            CoherenceDataPoint(id: "2", day: "Tue", coherence: 0.52),
            CoherenceDataPoint(id: "3", day: "Wed", coherence: 0.50),
            CoherenceDataPoint(id: "4", day: "Thu", coherence: 0.58),
            CoherenceDataPoint(id: "5", day: "Fri", coherence: 0.62),
            CoherenceDataPoint(id: "6", day: "Sat", coherence: 0.65),
            CoherenceDataPoint(id: "7", day: "Sun", coherence: 0.68)
        ]
    }
}
