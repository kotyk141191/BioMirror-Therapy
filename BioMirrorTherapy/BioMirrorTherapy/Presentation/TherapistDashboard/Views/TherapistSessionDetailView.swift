//
//  TherapistSessionDetailView.swift
//  BioMirrorTherapy
//
//  Created by Mykhailo Kotyk on 30.03.2025.
//

import SwiftUI
import Charts

struct TherapistSessionDetailView: View {
    let session: SessionData
    var onUpdateNotes: (String) -> Void
    
    @State private var therapistNotes: String
    @State private var isEditingNotes = false
    @Environment(\.presentationMode) var presentationMode
    
    init(session: SessionData, onUpdateNotes: @escaping (String) -> Void) {
        self.session = session
        self.onUpdateNotes = onUpdateNotes
        self._therapistNotes = State(initialValue: session.therapistNotes ?? "")
    }
    
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
                    
                    DetailRow(label: "Regulation Events", value: "\(session.regulationEvents)")
                    DetailRow(label: "Avg. Regulation Time", value: session.formattedRegulationTime)
                }
                
                // Therapist notes
                Section(header: Text("Therapist Notes")) {
                    if isEditingNotes {
                        TextEditor(text: $therapistNotes)
                            .frame(minHeight: 120)
                        
                        Button(action: saveNotes) {
                            Text("Save Notes")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    } else {
                        if therapistNotes.isEmpty {
                            Text("No notes for this session")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .padding(.vertical, 4)
                        } else {
                            Text(therapistNotes)
                                .font(.body)
                                .padding(.vertical, 4)
                        }
                        
                        Button(action: { isEditingNotes = true }) {
                            Text("Edit Notes")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
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
                
                // Coherence chart
                Section(header: Text("Coherence Analysis")) {
                    if #available(iOS 16.0, *) {
                        Chart(session.coherenceData) { point in
                            LineMark(
                                x: .value("Time", point.time),
                                y: .value("Coherence", point.coherence)
                            )
                            .foregroundStyle(Color.purple)
                        }
                        .frame(height: 200)
                    } else {
                        // Fallback for iOS 15
                        Text("Coherence analysis chart requires iOS 16+")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.vertical, 8)
                    }
                }
            }
            .navigationTitle("Session Analysis")
            .navigationBarItems(trailing: Button("Close") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    private func saveNotes() {
        isEditingNotes = false
        onUpdateNotes(therapistNotes)
    }
}

// Add Notes View
struct AddNotesView: View {
    let patientName: String
    var onSave: (String) -> Void
    
    @State private var notes = ""
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Add notes for \(patientName)")
                    .font(.headline)
                    .padding(.top)
                
                TextEditor(text: $notes)
                    .padding()
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                    .padding()
                
                Button(action: saveNotes) {
                    Text("Save Notes")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .padding(.horizontal)
                }
                
                Spacer()
            }
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    private func saveNotes() {
        onSave(notes)
        presentationMode.wrappedValue.dismiss()
    }
}
