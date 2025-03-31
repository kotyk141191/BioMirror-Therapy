//
//  TherapistDashboardView.swift
//  BioMirrorTherapy
//
//  Created by Mykhailo Kotyk on 30.03.2025.
//

import SwiftUI
import Charts

struct TherapistDashboardView: View {
    @StateObject private var viewModel = TherapistDashboardViewModel()
    
    var body: some View {
        NavigationView {
            List {
                // Patients section
                patientsSection
                
                if let selectedPatient = viewModel.selectedPatient {
                    // Patient overview section
                    patientOverviewSection(selectedPatient)
                    
                    // Detailed analysis section
                    detailedAnalysisSection(selectedPatient)
                    
                    // Session history section
                    sessionHistorySection(selectedPatient)
                    
                    // Treatment plan section
                    treatmentPlanSection(selectedPatient)
                    
                    // Actions section
                    actionsSection(selectedPatient)
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Therapist Dashboard")
            .navigationBarItems(trailing: refreshButton)
            .onAppear {
                viewModel.loadData()
            }
            .sheet(isPresented: $viewModel.showingSessionDetail) {
                if let session = viewModel.selectedSession {
                    TherapistSessionDetailView(session: session, onUpdateNotes: { notes in
                        viewModel.updateSessionNotes(session: session, notes: notes)
                    })
                }
            }
            .sheet(isPresented: $viewModel.showingAddNotes) {
                if let patient = viewModel.selectedPatient {
                    AddNotesView(patientName: patient.name, onSave: { notes in
                        viewModel.savePatientNotes(patient: patient, notes: notes)
                    })
                }
            }
            .alert(isPresented: $viewModel.showingAlert) {
                Alert(
                    title: Text(viewModel.alertTitle),
                    message: Text(viewModel.alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    // MARK: - View Components
    
    private var refreshButton: some View {
        Button(action: {
            viewModel.loadData()
        }) {
            Image(systemName: "arrow.clockwise")
        }
    }
    
    private var patientsSection: some View {
        Section(header: Text("Patients")) {
            if viewModel.patients.isEmpty {
                Text("Loading patients...")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.vertical, 8)
            } else {
                ForEach(viewModel.patients) { patient in
                    Button(action: {
                        viewModel.selectPatient(patient)
                    }) {
                        HStack {
                            if patient.imageData != nil {
                                Image(uiImage: UIImage(data: patient.imageData!)!)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 40, height: 40)
                                    .clipShape(Circle())
                            } else {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .frame(width: 40, height: 40)
                                    .foregroundColor(.gray)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(patient.name)
                                    .font(.headline)
                                
                                Text("Age: \(patient.age) • \(patient.currentPhaseName)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if patient.urgentFlag {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                            }
                            
                            if patient.id == viewModel.selectedPatient?.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    private func patientOverviewSection(_ patient: PatientData) -> some View {
        Section(header: Text("Patient Overview")) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Current Phase: \(patient.currentPhaseName)")
                            .font(.subheadline)
                        
                        Text("Started: \(patient.formattedStartDate)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("Sessions: \(patient.sessionCount)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if !patient.diagnoses.isEmpty {
                            Text("Diagnoses: \(patient.diagnoses.joined(separator: ", "))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Progress")
                            .font(.caption)
                        
                        ProgressCircleView(progress: patient.overallProgress)
                            .frame(width: 50, height: 50)
                    }
                }
                
                Divider()
                
                // Recent notes
                if let recentNotes = patient.recentNotes, !recentNotes.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Recent Notes (\(patient.formattedNotesDate))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(recentNotes)
                            .font(.caption2)
                            .lineLimit(3)
                    }
                    
                    Button(action: {
                        viewModel.addNotes(patient: patient)
                    }) {
                        Text("Add Notes")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                } else {
                    Button(action: {
                        viewModel.addNotes(patient: patient)
                    }) {
                        Text("Add Notes")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    private func detailedAnalysisSection(_ patient: PatientData) -> some View {
        Section(header: Text("Detailed Analysis")) {
            VStack(spacing: 20) {
                // Emotion regulation
                VStack(alignment: .leading, spacing: 8) {
                    Text("Emotion Regulation")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Coherence: \(Int(patient.emotionCoherence * 100))%")
                                .font(.caption)
                            
                            Text("Trend: \(patient.emotionCoherenceTrend)")
                                .font(.caption)
                                .foregroundColor(patient.emotionCoherenceTrend == "Improving" ? .green : (patient.emotionCoherenceTrend == "Declining" ? .red : .gray))
                            
                            Text("Regulation Rate: \(Int(patient.regulationRate * 100))%")
                                .font(.caption)
                        }
                        
                        Spacer()
                        
                        if #available(iOS 16.0, *) {
                            // Coherence trend chart
                            Chart(patient.coherenceTrendData) { data in
                                LineMark(
                                    x: .value("Session", data.session),
                                    y: .value("Coherence", data.value)
                                )
                                .foregroundStyle(Color.purple.gradient)
                            }
                            .frame(width: 120, height: 70)
                        } else {
                            // Fallback for iOS 15
                            LineChartView(dataPoints: patient.coherenceTrendData.map { $0.value })
                                .frame(width: 120, height: 70)
                        }
                    }
                }
                
                Divider()
                
                // Dissociation analysis
                VStack(alignment: .leading, spacing: 8) {
                    Text("Dissociation Analysis")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Episodes: \(patient.dissociationEpisodeCount)")
                                .font(.caption)
                            
                            Text("Recent duration: \(patient.formattedDissociationDuration)")
                                .font(.caption)
                            
                            Text("Trend: \(patient.dissociationTrend)")
                                .font(.caption)
                                .foregroundColor(patient.dissociationTrend == "Decreasing" ? .green : (patient.dissociationTrend == "Increasing" ? .red : .gray))
                        }
                        
                        Spacer()
                        
                        if #available(iOS 16.0, *) {
                            // Dissociation trend chart
                            Chart(patient.dissociationTrendData) { data in
                                LineMark(
                                    x: .value("Session", data.session),
                                    y: .value("Episodes", data.value)
                                )
                                .foregroundStyle(Color.orange.gradient)
                            }
                            .frame(width: 120, height: 70)
                        } else {
                            // Fallback for iOS 15
                            LineChartView(dataPoints: patient.dissociationTrendData.map { $0.value })
                                .frame(width: 120, height: 70)
                        }
                    }
                }
                
                Divider()
                
                // Emotional profile
                VStack(alignment: .leading, spacing: 8) {
                    Text("Emotional Profile")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(patient.topEmotions.prefix(3)) { emotion in
                                HStack {
                                    Circle()
                                        .fill(emotion.color)
                                        .frame(width: 8, height: 8)
                                    
                                    Text(emotion.name)
                                        .font(.caption)
                                    
                                    Text("(\(Int(emotion.percentage * 100))%)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Text("Emotional range: \(patient.emotionalRange)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if #available(iOS 16.0, *) {
                            // Emotions pie chart
                            Chart(patient.topEmotions) { emotion in
                                SectorMark(
                                    angle: .value("Percentage", emotion.percentage),
                                    innerRadius: .ratio(0.5),
                                    angularInset: 1
                                )
                                .foregroundStyle(emotion.color)
                            }
                            .frame(width: 100, height: 100)
                        } else {
                            // Simple fallback for iOS 15
                            EmotionsCircleView(emotions: patient.topEmotions)
                                .frame(width: 100, height: 100)
                        }
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    private func sessionHistorySection(_ patient: PatientData) -> some View {
        Section(header: Text("Session History")) {
            if patient.recentSessions.isEmpty {
                Text("No sessions yet")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.vertical, 8)
            } else {
                ForEach(patient.recentSessions) { session in
                    Button(action: {
                        viewModel.selectSession(session)
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(session.formattedDate)
                                    .font(.headline)
                                
                                Text(session.phaseName)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("\(session.formattedDuration)")
                                    .font(.subheadline)
                                
                                Text(session.completionStatus)
                                    .font(.caption)
                                    .foregroundColor(session.statusColor)
                            }
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                Button(action: {
                    viewModel.viewAllSessions(patient: patient)
                }) {
                    Text("View All Sessions")
                        .font(.headline)
                        .foregroundColor(.blue)
                }
            }
        }
    }
    
    private func treatmentPlanSection(_ patient: PatientData) -> some View {
        Section(header: Text("Treatment Plan")) {
            VStack(alignment: .leading, spacing: 16) {
                // Phase objectives
                VStack(alignment: .leading, spacing: 8) {
                    Text("Current Phase Objectives")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    ForEach(patient.phaseObjectives, id: \.self) { objective in
                        HStack(alignment: .top) {
                            Image(systemName: "circle.fill")
                                .font(.system(size: 6))
                                .padding(.top, 6)
                            
                            Text(objective)
                                .font(.caption)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                
                Divider()
                
                // Recommended activities
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recommended Activities")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    ForEach(patient.recommendedActivities, id: \.id) { activity in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(activity.name)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                
                                Text(activity.description)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Text(activity.priority)
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    activity.priority == "High" ? Color.red.opacity(0.2) :
                                        (activity.priority == "Medium" ? Color.orange.opacity(0.2) : Color.green.opacity(0.2))
                                )
                                .cornerRadius(4)
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                Button(action: {
                    viewModel.updateTreatmentPlan(patient: patient)
                }) {
                    Text("Update Treatment Plan")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    private func actionsSection(_ patient: PatientData) -> some View {
        Section(header: Text("Actions")) {
            Button(action: {
                viewModel.scheduleSession(patient: patient)
            }) {
                Label("Schedule Session", systemImage: "calendar.badge.plus")
            }
            
            Button(action: {
                viewModel.contactParent(patient: patient)
            }) {
                Label("Contact Parent", systemImage: "envelope")
            }
            
            Button(action: {
                viewModel.generateReport(patient: patient)
            }) {
                Label("Generate Report", systemImage: "doc.text")
            }
            
            if patient.urgentFlag {
                Button(action: {
                    viewModel.clearUrgentFlag(patient: patient)
                }) {
                    Label("Clear Urgent Flag", systemImage: "exclamationmark.triangle")
                        .foregroundColor(.red)
                }
            }
        }
    }
}

// Supporting Views for iOS 15 compatibility
struct LineChartView: View {
    let dataPoints: [Double]
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let width = geometry.size.width
                let height = geometry.size.height
                
                // Find min and max values
                let minValue = dataPoints.min() ?? 0
                let maxValue = max((dataPoints.max() ?? 1), minValue + 1)
                
                // Starting point
                path.move(to: CGPoint(
                    x: 0,
                    y: height - CGFloat((dataPoints[0] - minValue) / (maxValue - minValue)) * height
                ))
                
                // Draw lines to each point
                for index in 1..<dataPoints.count {
                    let point = CGPoint(
                        x: width * CGFloat(index) / CGFloat(dataPoints.count - 1),
                        y: height - CGFloat((dataPoints[index] - minValue) / (maxValue - minValue)) * height
                    )
                    path.addLine(to: point)
                }
            }
            .stroke(Color.purple, lineWidth: 2)
        }
    }
}
