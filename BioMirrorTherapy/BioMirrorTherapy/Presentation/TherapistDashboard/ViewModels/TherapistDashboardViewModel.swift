//
//  TherapistDashboardViewModel.swift
//  BioMirrorTherapy
//
//  Created by Mykhailo Kotyk on 30.03.2025.
//

import Foundation
import SwiftUI
import Combine

class TherapistDashboardViewModel: ObservableObject {
    // MARK: - Published Properties
    
    // Patients
    @Published var patients: [PatientData] = []
    @Published var selectedPatient: PatientData?
    
    // Session
    @Published var selectedSession: SessionData?
    @Published var showingSessionDetail: Bool = false
    
    // UI state
    @Published var showingAddNotes: Bool = false
    @Published var showingAlert: Bool = false
    @Published var alertTitle: String = ""
    @Published var alertMessage: String = ""
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    private let therapistRepository: TherapistRepository
    
    // MARK: - Initialization
    
    init(repository: TherapistRepository = TherapistRepositoryImpl.shared) {
        self.therapistRepository = repository
        
        // Load mock data initially for preview
        loadMockData()
    }
    
    // MARK: - Public Methods
    
    func loadData() {
        // Load patients
        therapistRepository.getPatients()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.showAlert("Error", message: "Failed to load patients: \(error.localizedDescription)")
                }
            } receiveValue: { [weak self] patients in
                self?.patients = patients
                
                // Select the first patient if none selected
                if self?.selectedPatient == nil && !patients.isEmpty {
                    self?.selectedPatient = patients.first
                } else if let currentPatient = self?.selectedPatient {
                    // Update selected patient with new data
                    if let updatedPatient = patients.first(where: { $0.id == currentPatient.id }) {
                        self?.selectedPatient = updatedPatient
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    func selectPatient(_ patient: PatientData) {
        selectedPatient = patient
    }
    
    func selectSession(_ session: SessionData) {
        selectedSession = session
        showingSessionDetail = true
    }
    
    func updateSessionNotes(session: SessionData, notes: String) {
        therapistRepository.updateSessionNotes(sessionId: session.id, notes: notes)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.showAlert("Error", message: "Failed to update notes: \(error.localizedDescription)")
                }
            } receiveValue: { [weak self] success in
                if success {
                    // Reload data to refresh UI
                    self?.loadData()
                } else {
                    self?.showAlert("Error", message: "Failed to update notes")
                }
            }
            .store(in: &cancellables)
    }
    
    func savePatientNotes(patient: PatientData, notes: String) {
        therapistRepository.addPatientNotes(patientId: patient.id, notes: notes)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.showAlert("Error", message: "Failed to save notes: \(error.localizedDescription)")
                }
            } receiveValue: { [weak self] success in
                if success {
                    // Reload data to refresh UI
                    self?.loadData()
                } else {
                    self?.showAlert("Error", message: "Failed to save notes")
                }
            }
            .store(in: &cancellables)
    }
    
    func addNotes(patient: PatientData) {
        showingAddNotes = true
    }
    
    func viewAllSessions(patient: PatientData) {
        // In a real app, this would navigate to a sessions list
        showAlert("Sessions", message: "This would show all sessions for \(patient.name)")
    }
    
    func updateTreatmentPlan(patient: PatientData) {
        // In a real app, this would navigate to treatment plan editor
        showAlert("Treatment Plan", message: "This would open the treatment plan editor for \(patient.name)")
    }
    
    func scheduleSession(patient: PatientData) {
        // In a real app, this would open scheduling interface
        showAlert("Schedule Session", message: "This would open the session scheduler for \(patient.name)")
    }
    
    func contactParent(patient: PatientData) {
        // In a real app, this would open messaging interface
        showAlert("Contact Parent", message: "This would open messaging interface to contact \(patient.name)'s parent")
    }
    
    func generateReport(patient: PatientData) {
        // In a real app, this would generate and show report
        showAlert("Generate Report", message: "This would generate a progress report for \(patient.name)")
    }
    
    func clearUrgentFlag(patient: PatientData) {
        therapistRepository.clearUrgentFlag(patientId: patient.id)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.showAlert("Error", message: "Failed to clear flag: \(error.localizedDescription)")
                }
            } receiveValue: { [weak self] success in
                if success {
                    // Reload data to refresh UI
                    self?.loadData()
                } else {
                    self?.showAlert("Error", message: "Failed to clear urgent flag")
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Private Methods
    
    private func showAlert(_ title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showingAlert = true
    }
    
    // MARK: - Mock Data
    
    private func loadMockData() {
        // Create sample patients
        patients = [
            PatientData(
                id: "1",
                name: "Alex Johnson",
                age: 9,
                imageData: nil,
                startDate: Date().addingTimeInterval(-90 * 86400), // 90 days ago
                sessionCount: 12,
                currentPhaseName: "Awareness Phase",
                overallProgress: 0.35,
                diagnoses: ["PTSD", "Anxiety"],
                recentNotes: "Alex is showing progress in emotional recognition but still struggles with regulating intense emotions. Continue focusing on grounding techniques.",
                notesDate: Date().addingTimeInterval(-7 * 86400), // 7 days ago
                urgentFlag: false,
                emotionCoherence: 0.62,
                emotionCoherenceTrend: "Improving",
                regulationRate: 0.54,
                coherenceTrendData: [
                    ChartDataPoint(id: "c1", session: "1", value: 0.42),
                    ChartDataPoint(id: "c2", session: "2", value: 0.45),
                    ChartDataPoint(id: "c3", session: "3", value: 0.40),
                    ChartDataPoint(id: "c4", session: "4", value: 0.48),
                    ChartDataPoint(id: "c5", session: "5", value: 0.52),
                    ChartDataPoint(id: "c6", session: "6", value: 0.55),
                    ChartDataPoint(id: "c7", session: "7", value: 0.58),
                    ChartDataPoint(id: "c8", session: "8", value: 0.60),
                    ChartDataPoint(id: "c9", session: "9", value: 0.58),
                    ChartDataPoint(id: "c10", session: "10", value: 0.61),
                    ChartDataPoint(id: "c11", session: "11", value: 0.59),
                    ChartDataPoint(id: "c12", session: "12", value: 0.62)
                ],
                dissociationEpisodeCount: 8,
                dissociationDuration: 45,
                dissociationTrend: "Decreasing",
                dissociationTrendData: [
                    ChartDataPoint(id: "d1", session: "1", value: 3),
                    ChartDataPoint(id: "d2", session: "2", value: 2),
                    ChartDataPoint(id: "d3", session: "3", value: 2),
                    ChartDataPoint(id: "d4", session: "4", value: 1),
                    ChartDataPoint(id: "d5", session: "5", value: 1),
                    ChartDataPoint(id: "d6", session: "6", value: 2),
                    ChartDataPoint(id: "d7", session: "7", value: 1),
                    ChartDataPoint(id: "d8", session: "8", value: 0),
                    ChartDataPoint(id: "d9", session: "9", value: 1),
                    ChartDataPoint(id: "d10", session: "10", value: 0),
                    ChartDataPoint(id: "d11", session: "11", value: 0),
                    ChartDataPoint(id: "d12", session: "12", value: 0)
                ],
                topEmotions: [
                    EmotionData(id: "e1", name: "Happy", percentage: 0.35, color: .blue),
                    EmotionData(id: "e2", name: "Sad", percentage: 0.25, color: .indigo),
                    EmotionData(id: "e3", name: "Frustrated", percentage: 0.20, color: .red),
                    EmotionData(id: "e4", name: "Curious", percentage: 0.15, color: .orange),
                    EmotionData(id: "e5", name: "Calm", percentage: 0.05, color: .green)
                ],
                emotionalRange: "Moderate",
                phaseObjectives: [
                    "Increase recognition of emotional states",
                    "Connect physical sensations to emotions",
                    "Identify personal triggers",
                    "Develop ability to name emotional states"
                ],
                recommendedActivities: [
                    ActivityRecommendation(id: "a1", name: "Emotion Explorer", description: "Practice identifying different emotions", priority: "High"),
                    ActivityRecommendation(id: "a2", name: "Body Mapping", description: "Connect emotions to physical sensations", priority: "Medium"),
                    ActivityRecommendation(id: "a3", name: "Emotion Vocabulary", description: "Expand emotional word bank", priority: "Medium")
                ],
                recentSessions: [
                    SessionData(
                        id: "s1",
                        date: Date().addingTimeInterval(-7 * 86400),
                        duration: 15 * 60,
                        phase: 1,
                        phaseName: "Awareness Phase",
                        completionStatus: "Completed",
                        coherenceIndex: 0.65,
                        emotionsExpressed: ["Happy", "Sad", "Curious"],
                        dissociationEpisodes: 0,
                        dissociationDuration: 0,
                        regulationEvents: 2,
                        avgRegulationTime: 45,
                        therapistNotes: "Alex showed improved emotion recognition and was able to identify body sensations associated with sadness.",
                        emotionalTimeline: [
                            EmotionTimelinePoint(id: "e1", time: "0:00", emotion: "Neutral", intensity: 0.5),
                            EmotionTimelinePoint(id: "e2", time: "5:00", emotion: "Happy", intensity: 0.7),
                            EmotionTimelinePoint(id: "e3", time: "10:00", emotion: "Sad", intensity: 0.6),
                            EmotionTimelinePoint(id: "e4", time: "15:00", emotion: "Curious", intensity: 0.8)
                        ],
                        coherenceData: [
                            CoherenceDataPoint(id: "c1", time: "0:00", coherence: 0.50),
                            CoherenceDataPoint(id: "c2", time: "3:00", coherence: 0.55),
                            CoherenceDataPoint(id: "c3", time: "6:00", coherence: 0.60),
                            CoherenceDataPoint(id: "c4", time: "9:00", coherence: 0.65),
                            CoherenceDataPoint(id: "c5", time: "12:00", coherence: 0.70),
                            CoherenceDataPoint(id: "c6", time: "15:00", coherence: 0.65)
                        ]
                    ),
                    SessionData(
                        id: "s2",
                        date: Date().addingTimeInterval(-14 * 86400),
                        duration: 20 * 60,
                        phase: 1,
                        phaseName: "Awareness Phase",
                        completionStatus: "Completed",
                        coherenceIndex: 0.58,
                        emotionsExpressed: ["Confused", "Happy", "Frustrated"],
                        dissociationEpisodes: 1,
                        dissociationDuration: 45,
                        regulationEvents: 3,
                        avgRegulationTime: 60,
                        therapistNotes: "Alex did well identifying emotions but had one brief dissociative episode when discussing school.",
                        emotionalTimeline: [],
                        coherenceData: []
                    ),
                    SessionData(
                        id: "s3",
                        date: Date().addingTimeInterval(-21 * 86400),
                        duration: 12 * 60,
                        phase: 1,
                        phaseName: "Awareness Phase",
                        completionStatus: "Interrupted",
                        coherenceIndex: 0.42,
                        emotionsExpressed: ["Frustrated", "Angry"],
                        dissociationEpisodes: 2,
                        dissociationDuration: 120,
                        regulationEvents: 1,
                        avgRegulationTime: 180,
                        therapistNotes: "Session ended early due to difficulty regulating emotions.",
                        emotionalTimeline: [],
                        coherenceData: []
                    )
                ]
            ),
            PatientData(
                id: "2",
                name: "Maya Singh",
                age: 11,
                imageData: nil,
                startDate: Date().addingTimeInterval(-60 * 86400), // 60 days ago
                sessionCount: 8,
                currentPhaseName: "Connection Phase",
                overallProgress: 0.25,
                diagnoses: ["PTSD"],
                recentNotes: nil,
                notesDate: nil,
                urgentFlag: true,
                emotionCoherence: 0.45,
                emotionCoherenceTrend: "Fluctuating",
                regulationRate: 0.30,
                coherenceTrendData: [],
                dissociationEpisodeCount: 12,
                dissociationDuration: 90,
                dissociationTrend: "Increasing",
                dissociationTrendData: [],
                topEmotions: [],
                emotionalRange: "Limited",
                phaseObjectives: [],
                recommendedActivities: [],
                recentSessions: []
            ),
            PatientData(
                id: "3",
                name: "Ethan Williams",
                age: 10,
                imageData: nil,
                startDate: Date().addingTimeInterval(-120 * 86400), // 120 days ago
                sessionCount: 18,
                currentPhaseName: "Integration Phase",
                overallProgress: 0.65,
                diagnoses: ["Anxiety", "Sleep Disturbance"],
                recentNotes: nil,
                notesDate: nil,
                urgentFlag: false,
                emotionCoherence: 0.78,
                emotionCoherenceTrend: "Improving",
                regulationRate: 0.72,
                coherenceTrendData: [],
                dissociationEpisodeCount: 3,
                dissociationDuration: 30,
                dissociationTrend: "Decreasing",
                dissociationTrendData: [],
                topEmotions: [],
                emotionalRange: "Broad",
                phaseObjectives: [],
                recommendedActivities: [],
                recentSessions: []
            )
        ]
        
        // Set initial selected patient
        selectedPatient = patients.first
    }
}
