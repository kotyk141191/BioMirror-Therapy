//
//  ParentDashboardView.swift
//  BioMirrorTherapy
//
//  Created by Mykhailo Kotyk on 30.03.2025.
//

import SwiftUI
import Charts

struct ParentDashboardView: View {
    @StateObject private var viewModel = ParentDashboardViewModel()
    
    var body: some View {
        NavigationView {
            List {
                // Child information section
                childInfoSection
                
                // Recent sessions section
                recentSessionsSection
                
                // Progress overview section
                progressOverviewSection
                
                // Emotional insights section
                emotionalInsightsSection
                
                // Actions section
                actionsSection
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Parent Dashboard")
            .navigationBarItems(trailing: refreshButton)
            .onAppear {
                viewModel.loadData()
            }
            .sheet(isPresented: $viewModel.showingSessionDetail) {
                if let session = viewModel.selectedSession {
                    SessionDetailView(session: session)
                }
            }
            .sheet(isPresented: $viewModel.showingScheduleSession) {
                ScheduleSessionView(onSchedule: { date, duration in
                    viewModel.scheduleSession(date: date, duration: duration)
                })
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
    
    private var childInfoSection: some View {
        Section(header: Text("Child Information")) {
            HStack {
                if viewModel.childImageData != nil {
                    Image(uiImage: UIImage(data: viewModel.childImageData!)!)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 60)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 60, height: 60)
                        .foregroundColor(.gray)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.childName)
                        .font(.headline)
                    
                    Text("Age: \(viewModel.childAge)")
                        .font(.subheadline)
                    
                    Text("Current phase: \(viewModel.currentPhaseName)")
                        .font(.subheadline)
                }
                
                Spacer()
                
                VStack {
                    Text("Progress")
                        .font(.caption)
                    
                    ProgressCircleView(progress: viewModel.overallProgress)
                        .frame(width: 50, height: 50)
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    private var recentSessionsSection: some View {
        Section(header: Text("Recent Sessions")) {
            if viewModel.recentSessions.isEmpty {
                Text("No recent sessions")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.vertical, 8)
            } else {
                ForEach(viewModel.recentSessions) { session in
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
            }
            
            Button(action: {
                viewModel.showAllSessions()
            }) {
                Text("View All Sessions")
                    .font(.headline)
                    .foregroundColor(.blue)
            }
        }
    }
    
    private var progressOverviewSection: some View {
        Section(header: Text("Progress Overview")) {
            VStack(alignment: .leading, spacing: 16) {
                // Progress by phase
                VStack(alignment: .leading, spacing: 8) {
                    Text("Progress by Phase")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 16) {
                        ForEach(viewModel.phaseProgress.indices, id: \.self) { index in
                            let phase = viewModel.phaseProgress[index]
                            
                            VStack(spacing: 8) {
                                ProgressCircleView(progress: phase.progress)
                                    .frame(width: 44, height: 44)
                                
                                Text(phase.name)
                                    .font(.caption)
                                    .multilineTextAlignment(.center)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
                
                Divider()
                
                // Weekly sessions chart
                VStack(alignment: .leading, spacing: 8) {
                    Text("Weekly Sessions")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if #available(iOS 16.0, *) {
                        Chart(viewModel.weeklySessionData) { item in
                            BarMark(
                                x: .value("Day", item.day),
                                y: .value("Minutes", item.minutes)
                            )
                            .foregroundStyle(Color.blue.gradient)
                        }
                        .frame(height: 150)
                    } else {
                        // Basic bar chart fallback for iOS 15
                        WeeklySessionBarChart(data: viewModel.weeklySessionData)
                            .frame(height: 150)
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    private var emotionalInsightsSection: some View {
        Section(header: Text("Emotional Insights")) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Most Frequent Emotions")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        ForEach(viewModel.topEmotions) { emotion in
                            HStack {
                                Circle()
                                    .fill(emotion.color)
                                    .frame(width: 10, height: 10)
                                
                                Text(emotion.name)
                                    .font(.caption)
                                
                                Spacer()
                                
                                Text("\(Int(emotion.percentage * 100))%")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    if #available(iOS 16.0, *) {
                        // Emotions pie chart
                        EmotionsPieChart(emotions: viewModel.topEmotions)
                            .frame(width: 100, height: 100)
                    } else {
                        // Simple circle for older iOS
                        EmotionsCircleView(emotions: viewModel.topEmotions)
                            .frame(width: 100, height: 100)
                    }
                }
                
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Emotional Coherence")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Average: \(Int(viewModel.averageCoherence * 100))%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("Trend: \(viewModel.coherenceTrend)")
                                .font(.caption)
                                .foregroundColor(viewModel.coherenceTrend == "Improving" ? .green : (viewModel.coherenceTrend == "Declining" ? .red : .gray))
                        }
                        
                        Spacer()
                        
                        if #available(iOS 16.0, *) {
                            // Coherence trend line chart
                            Chart(viewModel.coherenceTrendData) { item in
                                LineMark(
                                    x: .value("Day", item.day),
                                    y: .value("Coherence", item.coherence)
                                )
                                .foregroundStyle(Color.purple.gradient)
                            }
                            .frame(width: 120, height: 60)
                        } else {
                            // Simple line for older iOS
                            CoherenceTrendLine(data: viewModel.coherenceTrendData)
                                .stroke(Color.purple, lineWidth: 2)
                                .frame(width: 120, height: 60)
                        }
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    private var actionsSection: some View {
        Section(header: Text("Actions")) {
            Button(action: {
                viewModel.scheduleNewSession()
            }) {
                Label("Schedule Session", systemImage: "calendar.badge.plus")
            }
            
            Button(action: {
                viewModel.contactTherapist()
            }) {
                Label("Contact Therapist", systemImage: "envelope")
            }
            
            Button(action: {
                viewModel.viewResources()
            }) {
                Label("Helpful Resources", systemImage: "book")
            }
            
            Button(action: {
                viewModel.emergencySupport()
            }) {
                Label("Emergency Support", systemImage: "exclamationmark.shield")
                    .foregroundColor(.red)
            }
        }
    }
}

// Supporting Views

struct ProgressCircleView: View {
    let progress: Float
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: 4)
            
            Circle()
                .trim(from: 0, to: CGFloat(min(progress, 1.0)))
                .stroke(
                    progress > 0.75 ? Color.green :
                        (progress > 0.4 ? Color.orange : Color.red),
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear, value: progress)
            
            Text("\(Int(progress * 100))%")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.primary)
        }
    }
}

// WeeklySessionBarChart is a fallback for iOS 15
struct WeeklySessionBarChart: View {
    let data: [SessionDataPoint]
    
    var body: some View {
        GeometryReader { geometry in
            HStack(alignment: .bottom, spacing: 4) {
                ForEach(data) { item in
                    let barHeight = calculateBarHeight(for: item.minutes, in: geometry)
                    
                    VStack {
                        Rectangle()
                            .fill(Color.blue)
                            .frame(height: barHeight)
                        
                        Text(item.day)
                            .font(.caption2)
                            .fixedSize()
                    }
                    .frame(width: geometry.size.width / 8)
                }
            }
            .padding(.bottom, 20)
        }
    }
    
    private func calculateBarHeight(for value: Double, in geometry: GeometryProxy) -> CGFloat {
        let maxValue = data.map { $0.minutes }.max() ?? 1
        let availableHeight = geometry.size.height - 30 // Subtract text height
        return CGFloat(value / maxValue) * availableHeight
    }
}

@available(iOS 16.0, *)
struct EmotionsPieChart: View {
    let emotions: [EmotionData]
    
    var body: some View {
        Chart(emotions) { emotion in
            SectorMark(
                angle: .value("Percentage", emotion.percentage),
                innerRadius: .ratio(0.5),
                angularInset: 1
            )
            .foregroundStyle(emotion.color)
        }
    }
}

// EmotionsCircleView is a fallback for iOS 15
struct EmotionsCircleView: View {
    let emotions: [EmotionData]
    
    var body: some View {
        Canvas { context, size in
            var startAngle: Double = 0
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = min(size.width, size.height) / 2
            
            for emotion in emotions {
                let endAngle = startAngle + emotion.percentage * 2 * .pi
                
                let path = Path { p in
                    p.move(to: center)
                    p.addArc(
                        center: center,
                        radius: radius,
                        startAngle: .radians(startAngle),
                        endAngle: .radians(endAngle),
                        clockwise: false
                    )
                    p.closeSubpath()
                }
                
                context.fill(path, with: .color(emotion.color))
                startAngle = endAngle
            }
            
            // Center hole
            let holePath = Path(ellipseIn: CGRect(
                x: center.x - radius * 0.5,
                y: center.y - radius * 0.5,
                width: radius * 1.0,
                height: radius * 1.0
            ))
            context.blendMode = .clear
            context.fill(holePath, with: .color(.white))
        }
    }
}

// CoherenceTrendLine is a fallback for iOS 15
struct CoherenceTrendLine: Shape {
    let data: [CoherenceDataPoint]
    
    func path(in rect: CGRect) -> Path {
        guard !data.isEmpty else { return Path() }
        
        var path = Path()
        let count = data.count
        let maxCoherence: Double = 1.0
        let minCoherence: Double = 0.0
        let xStep = rect.width / CGFloat(count - 1)
        
        // Start at the first point
        let firstPoint = CGPoint(
            x: 0,
            y: rect.height - CGFloat((data[0].coherence - minCoherence) / (maxCoherence - minCoherence)) * rect.height
        )
        path.move(to: firstPoint)
        
        // Draw line to each point
        for i in 1..<count {
            let point = CGPoint(
                x: xStep * CGFloat(i),
                y: rect.height - CGFloat((data[i].coherence - minCoherence) / (maxCoherence - minCoherence)) * rect.height
            )
            path.addLine(to: point)
        }
        
        return path
    }
}

// Schedule Session View
struct ScheduleSessionView: View {
    @Environment(\.presentationMode) var presentationMode
    
    @State private var selectedDate = Date().addingTimeInterval(86400) // Tomorrow
    @State private var duration: TimeInterval = 20 * 60 // 20 minutes
    
    var onSchedule: (Date, TimeInterval) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Session Time")) {
                    DatePicker("Date & Time", selection: $selectedDate, in: Date()...)
                        .datePickerStyle(GraphicalDatePickerStyle())
                }
                
                Section(header: Text("Session Duration")) {
                    Picker("Duration", selection: $duration) {
                        Text("10 minutes").tag(10 * 60.0)
                        Text("15 minutes").tag(15 * 60.0)
                        Text("20 minutes").tag(20 * 60.0)
                        Text("30 minutes").tag(30 * 60.0)
                    }
                }
                
                Section {
                    Button(action: scheduleSession) {
                        Text("Schedule Session")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
            }
            .navigationTitle("Schedule Session")
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    private func scheduleSession() {
        onSchedule(selectedDate, duration)
        presentationMode.wrappedValue.dismiss()
    }
}

// Session Detail View
struct SessionDetailView: View {
    let session: SessionData
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List {
                // Session information
                Section(header: Text("Session Information")) {
                    DetailRow(label: "Date", value: session.formattedDate)
                    DetailRow(label: "Duration", value: session.formattedDuration)
                    DetailRow(label: "Phase", value: session.phaseName)
                    DetailRow(label: "Status", value: session.completionStatus)
                }
                
                // Session metrics
                Section(header: Text("Session Metrics")) {
                    DetailRow(label: "Emotional Coherence", value: "\(Int(session.coherenceIndex * 100))%")
                    DetailRow(label: "Emotions Expressed", value: session.emotionsExpressed.joined(separator: ", "))
                    
                    if session.dissociationEpisodes > 0 {
                        DetailRow(label: "Dissociation Episodes", value: "\(session.dissociationEpisodes)")
                        DetailRow(label: "Dissociation Duration", value: "\(Int(session.dissociationDuration / 60)) min \(Int(session.dissociationDuration.truncatingRemainder(dividingBy: 60))) sec")
                    }
                }
                
                // Therapist notes
                if let notes = session.therapistNotes, !notes.isEmpty {
                    Section(header: Text("Therapist Notes")) {
                        Text(notes)
                            .font(.body)
                            .padding(.vertical, 4)
                    }
                }
                
                // Emotion chart
                Section(header: Text("Emotional Timeline")) {
                    if #available(iOS 16.0, *) {
                        Chart(session.emotionalTimeline) { point in
                            LineMark(
                                x: .value("Time", point.time),
                                y: .value("Intensity", point.intensity)
                            )
                            .foregroundStyle(by: .value("Emotion", point.emotion))
                        }
                        .frame(height: 200)
                    } else {
                        // Fallback for iOS 15
                        Text("Emotional timeline chart requires iOS 16+")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.vertical, 8)
                    }
                }
            }
            .navigationTitle("Session Details")
            .navigationBarItems(trailing: Button("Close") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .multilineTextAlignment(.trailing)
        }
    }
}
