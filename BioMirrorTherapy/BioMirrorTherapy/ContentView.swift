//
//  ContentView.swift
//  BioMirrorTherapy
//
//  Created by Mykhailo Kotyk on 30.03.2025.
//

import SwiftUI
import CoreData
import WatchConnectivity

struct ContentView: View {
    @ObservedObject var sessionViewModel = WatchSessionViewModel()
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("BioMirror Status")) {
                    HStack {
                        Text("Session")
                        Spacer()
                        Text(sessionViewModel.isSessionActive ? "Active" : "Inactive")
                            .foregroundColor(sessionViewModel.isSessionActive ? .green : .red)
                    }
                    
                    if sessionViewModel.isSessionActive {
                        HStack {
                            Text("Heart Rate")
                            Spacer()
                            Text(sessionViewModel.heartRateText)
                        }
                        
                        HStack {
                            Text("Duration")
                            Spacer()
                            Text(sessionViewModel.sessionDurationText)
                        }
                    }
                }
                
                Section {
                    Button(sessionViewModel.isSessionActive ? "Stop Session" : "Start Session") {
                        if sessionViewModel.isSessionActive {
                            sessionViewModel.stopSession()
                        } else {
                            sessionViewModel.startSession()
                        }
                    }
                    .foregroundColor(sessionViewModel.isSessionActive ? .red : .green)
                    
                    if !sessionViewModel.isStoreDataEmpty {
                        Button("Sync Data (\(sessionViewModel.storedDataCount))") {
                            sessionViewModel.syncData()
                        }
                        .foregroundColor(.blue)
                    }
                }
            }
            .navigationTitle("BioMirror")
        }
    }
}

class WatchSessionViewModel: ObservableObject {
    @Published var isSessionActive = false
    @Published var heartRate: Double = 0
    @Published var sessionDuration: TimeInterval = 0
    @Published var storedDataCount: Int = 0
    
    private let sessionManager = WatchSessionManager.shared
    private let biometricMonitor = WatchBiometricMonitor.shared
    
    private var timer: Timer?
    
    init() {
        // Subscribe to biometric updates
        biometricMonitor.heartRateUpdated = { [weak self] rate in
            DispatchQueue.main.async {
                self?.heartRate = rate
                self?.objectWillChange.send()
            }
        }
        
        // Start timer to update UI
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateUI()
        }
    }
    
    var heartRateText: String {
        return String(format: "%.0f BPM", heartRate)
    }
    
    var sessionDurationText: String {
        let minutes = Int(sessionDuration) / 60
        let seconds = Int(sessionDuration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var isStoreDataEmpty: Bool {
        return storedDataCount == 0
    }
    
    func startSession() {
        sessionManager.startSession(sessionId: UUID().uuidString)
        isSessionActive = true
    }
    
    func stopSession() {
        sessionManager.endSession()
        isSessionActive = false
    }
    
    func syncData() {
        sessionManager.synchronizeData()
    }
    
    private func updateUI() {
        isSessionActive = sessionManager.isSessionActive
        
        if isSessionActive {
            sessionDuration += 1.0
        }
        
        // Update stored data count
        storedDataCount = sessionManager.storedDataCount
        
        objectWillChange.send()
    }
}
