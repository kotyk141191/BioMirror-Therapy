//
//  SessionInterfaceController.swift
//  BioMirrorTherapyWatch Watch App
//
//  Created by Mykhailo Kotyk on 30.03.2025.
//

import WatchKit
import Foundation

class SessionInterfaceController: WKInterfaceController {
    // MARK: - Outlets
    
    @IBOutlet weak var heartRateLabel: WKInterfaceLabel!
    @IBOutlet weak var hrvLabel: WKInterfaceLabel!
    @IBOutlet weak var sessionStatusLabel: WKInterfaceLabel!
    @IBOutlet weak var sessionGroup: WKInterfaceGroup!
    @IBOutlet weak var startStopButton: WKInterfaceButton!
    
    // MARK: - Properties
    
    private let biometricMonitor = WatchBiometricMonitor.shared
    private let sessionManager = WatchSessionManager.shared
    
    private var isSessionActive = false
    
    // MARK: - Lifecycle Methods
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Set initial UI state
        updateUI()
        
        // Register callbacks for biometric updates
        registerBiometricCallbacks()
    }
    
    override func willActivate() {
        super.willActivate()
        
        // Refresh UI when view becomes active
        updateUI()
    }
    
    // MARK: - Actions
    
    @IBAction func startStopButtonTapped() {
        if isSessionActive {
            // End session
            sessionManager.endSession()
            isSessionActive = false
        } else {
            // Start session
            sessionManager.startSession(sessionId: UUID().uuidString)
            isSessionActive = true
        }
        
        // Update UI
        updateUI()
    }
    
    @IBAction func syncDataButtonTapped() {
        // Synchronize stored data
        sessionManager.synchronizeData()
        
        // Show confirmation
        presentAlert(withTitle: "Syncing", message: "Syncing data with iPhone...", preferredStyle: .alert, actions: [])
        
        // Dismiss alert after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.dismiss()
        }
    }
    
    // MARK: - Private Methods
    
    private func registerBiometricCallbacks() {
        // Register for heart rate updates
        biometricMonitor.heartRateUpdated = { [weak self] heartRate in
            self?.updateHeartRateLabel(heartRate)
        }
        
        // Register for HRV updates
        biometricMonitor.hrvUpdated = { [weak self] hrv in
            self?.updateHRVLabel(hrv)
        }
    }
    
    private func updateUI() {
        // Check session status
        isSessionActive = sessionManager.isSessionActive
        
        // Update button title
        startStopButton.setTitle(isSessionActive ? "End Session" : "Start Session")
        
        // Update session status
        if isSessionActive {
            sessionGroup.setBackgroundColor(.green)
            sessionStatusLabel.setText("Session Active")
        } else {
            sessionGroup.setBackgroundColor(.darkGray)
            sessionStatusLabel.setText("No Active Session")
        }
        
        // Show latest heart rate and HRV if available
        if let heartRate = biometricMonitor.latestHeartRate {
            updateHeartRateLabel(heartRate)
        } else {
            heartRateLabel.setText("-- BPM")
        }
        
        if let hrv = biometricMonitor.latestHRV {
            updateHRVLabel(hrv)
        } else {
            hrvLabel.setText("-- ms")
        }
    }
    
    private func updateHeartRateLabel(_ heartRate: Double) {
        DispatchQueue.main.async {
            self.heartRateLabel.setText(String(format: "%.0f BPM", heartRate))
        }
    }
    
    private func updateHRVLabel(_ hrv: Double) {
        DispatchQueue.main.async {
            self.hrvLabel.setText(String(format: "%.0f ms", hrv))
        }
    }
}
