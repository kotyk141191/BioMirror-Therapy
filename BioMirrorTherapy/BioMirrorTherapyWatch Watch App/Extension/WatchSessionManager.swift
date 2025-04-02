//
//  WatchSessionManager.swift
//  BioMirrorTherapyWatch Watch App
//
//  Created by Mykhailo Kotyk on 30.03.2025.
//

import Foundation
//import WatchKit
import CoreMotion
import WatchConnectivity

class WatchSessionManager {
    // MARK: - Singleton
    
    static let shared = WatchSessionManager()
    
    // MARK: - Properties
    
    private let biometricMonitor = WatchBiometricMonitor.shared
    private let connectivityManager = WatchConnectivityManager.shared
    
    var isSessionActive = false
    private var isPaused = false
    private var currentSessionId: String?
    private var configuration: SessionConfiguration = .default
    
    private var dataUpdateTimer: Timer?
    private var storedData: [BiometricDataPacket] = []
    
    private var lastDataSyncTime = Date()
    
    // MARK: - Initialization
    
    var storedDataCount: Int {
           // In a real implementation, this would check local storage
           // for unsynchronized data
           return _storedDataCount
       }
       
       // Private state
       private var _storedDataCount: Int = 0
    
    private init() {}
    
    // MARK: - Public Methods
    
    func startSession(sessionId: String) {
        // Check if there's already an active session
        guard !isSessionActive else {
            // If same session, just unpause if paused
            if currentSessionId == sessionId && isPaused {
                resumeSession()
            }
            return
        }
        
        // Store session ID
        currentSessionId = sessionId
        
        // Start monitoring
        biometricMonitor.startMonitoring(options: configuration)
        
        // Start data update timer
        startDataUpdateTimer()
        
        isSessionActive = true
        isPaused = false
        
        // Send initial status to iPhone
        sendStatusUpdate()
    }
    
    func endSession() {
        // Check if there's an active session
        guard isSessionActive else { return }
        
        // Stop monitoring
        biometricMonitor.stopMonitoring()
        
        // Stop data update timer
        dataUpdateTimer?.invalidate()
        dataUpdateTimer = nil
        
        isSessionActive = false
        isPaused = false
        currentSessionId = nil
        
        // Synchronize any remaining data
        synchronizeData()
        
        // Send status update to iPhone
        sendStatusUpdate()
    }
    
    func pauseSession() {
        // Check if there's an active session
        guard isSessionActive && !isPaused else { return }
        
        // Pause timer
        dataUpdateTimer?.invalidate()
        dataUpdateTimer = nil
        
        isPaused = true
        
        // Send status update to iPhone
        sendStatusUpdate()
    }
    
    func resumeSession() {
        // Check if there's a paused session
        guard isSessionActive && isPaused else { return }
        
        // Restart data update timer
        startDataUpdateTimer()
        
        isPaused = false
        
        // Send status update to iPhone
        sendStatusUpdate()
    }
    
    func resumeSessionIfNeeded() {
        // Resume session if it was active when app went to background
        if isSessionActive && isPaused {
            resumeSession()
        }
    }
    
    func prepareForBackground() {
        // Pause session if active
        if isSessionActive && !isPaused {
            pauseSession()
        }
    }
    
    func updateConfiguration(_ config: SessionConfiguration) {
        self.configuration = config
        
        // If session is active, restart monitoring with new configuration
        if isSessionActive {
            biometricMonitor.stopMonitoring()
            biometricMonitor.startMonitoring(options: configuration)
            
            // Update timer interval
            if dataUpdateTimer != nil {
                startDataUpdateTimer()
            }
        }
    }
    
    func synchronizeData() {
        // Check if there's data to sync
        guard !storedData.isEmpty else { return }
        
        // Send stored data to iPhone
        for packet in storedData {
            connectivityManager.sendBiometricData(packet)
        }
        
        // Clear stored data
        storedData.removeAll()
        
        // Update last sync time
        lastDataSyncTime = Date()
    }
    
    // MARK: - Private Methods
    
    private func startDataUpdateTimer() {
        // Stop existing timer if any
        dataUpdateTimer?.invalidate()
        
        // Create new timer with sampling frequency from configuration
        let interval = configuration.samplingFrequency.interval
        dataUpdateTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.collectAndSendBiometricData()
        }
    }
    
    private func collectAndSendBiometricData() {
        guard let sessionId = currentSessionId else { return }
        
        // Get current biometric state
        let state = biometricMonitor.getCurrentBiometricState()
        
        // Create biometric data packet
        let packet = createBiometricDataPacket(from: state, sessionId: sessionId)
        
        // Send data to iPhone using WCSession
        if WCSession.default.isReachable {
            connectivityManager.sendBiometricData(packet)
        } else {
            // Store data for later synchronization
            storedData.append(packet)
            
            // Limit stored data size
            if storedData.count > 1000 {
                storedData.removeFirst(storedData.count - 1000)
            }
        }
        
        // Periodically synchronize stored data when reachable
        if WCSession.default.isReachable &&
           Date().timeIntervalSince(lastDataSyncTime) > 60 &&
           !storedData.isEmpty {
            synchronizeData()
        }
    }
//    private func collectAndSendBiometricData() {
//        guard let sessionId = currentSessionId else { return }
//        
//        // Get current biometric state
//        let state = biometricMonitor.getCurrentBiometricState()
//        
//        // Create biometric data packet
//        let packet = createBiometricDataPacket(from: state, sessionId: sessionId)
//        
//        // Send data to iPhone
//        if WKInterfaceDevice.current().isReachable {
//            connectivityManager.sendBiometricData(packet)
//        } else {
//            // Store data for later synchronization
//            storedData.append(packet)
//            
//            // Limit stored data size
//            if storedData.count > 1000 {
//                storedData.removeFirst(storedData.count - 1000)
//            }
//        }
//        
//        // Periodically synchronize stored data when reachable
//        if WKInterfaceDevice.current().isReachable &&
//           Date().timeIntervalSince(lastDataSyncTime) > 60 &&
//           !storedData.isEmpty {
//            synchronizeData()
//        }
//    }
    
    private func createBiometricDataPacket(from state: BiometricDataState, sessionId: String) -> BiometricDataPacket {
        // Convert acceleration to AccelerationData if available
        var accelerationData: AccelerationData?
        if let acceleration = state.acceleration {
            accelerationData = AccelerationData(
                x: acceleration.x,
                y: acceleration.y,
                z: acceleration.z,
                timestamp: state.timestamp.timeIntervalSince1970
            )
        }
        
        // Create packet
        return BiometricDataPacket(
            timestamp: state.timestamp.timeIntervalSince1970,
            heartRate: state.heartRate,
            heartRateVariability: state.heartRateVariability,
            skinConductance: nil, // Not directly available on Apple Watch
            skinConductanceResponses: nil,
            acceleration: accelerationData,
            respirationRate: state.respirationRate,
            batteryLevel: Double(WKInterfaceDevice.current().batteryLevel),
            dataQuality: state.dataQuality,
            sessionId: sessionId,
            packetId: UUID()
        )
    }
    
    private func sendStatusUpdate() {
        // Create status message
        let payload: [String: Any] = [
            "isSessionActive": isSessionActive,
            "isPaused": isPaused,
            "sessionId": currentSessionId ?? "",
            "batteryLevel": WKInterfaceDevice.current().batteryLevel,
            "timestamp": Date().timeIntervalSince1970,
            "storedDataCount": storedData.count
        ]
        
        // Send message
        connectivityManager.sendMessage([
            "command": "statusUpdate",
            "payload": payload
        ])
    }
}
