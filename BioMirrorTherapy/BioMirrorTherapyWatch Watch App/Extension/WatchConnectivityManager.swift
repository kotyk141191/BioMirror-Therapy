//
//  WatchConnectivityManager.swift
//  BioMirrorTherapyWatch Watch App
//
//  Created by Mykhailo Kotyk on 30.03.2025.
//

import Foundation
import WatchConnectivity
import WatchKit

class WatchConnectivityManager: NSObject, WCSessionDelegate {
    // MARK: - Singleton
    
    static let shared = WatchConnectivityManager()
    
    // MARK: - Properties
    
    private var session: WCSession?
    
    // MARK: - Initialization
    
    private override init() {
        super.init()
    }
    
    // MARK: - Public Methods
    
    func startSession() {
        guard WCSession.isSupported() else { return }
        
        session = WCSession.default
        session?.delegate = self
        session?.activate()
    }
    
    func sendMessage(_ message: [String: Any], replyHandler: (([String: Any]) -> Void)? = nil, errorHandler: ((Error) -> Void)? = nil) {
        guard let session = session, session.activationState == .activated else {
            errorHandler?(WatchConnectivityError.sessionNotActive)
            return
        }
        
        session.sendMessage(message, replyHandler: replyHandler, errorHandler: errorHandler)
    }
    
    func sendBiometricData(_ data: BiometricDataPacket) {
        do {
            let encoder = JSONEncoder()
            let jsonData = try encoder.encode(data)
            
            guard let payload = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
                return
            }
            
            let message: [String: Any] = [
                "command": "biometricData",
                "payload": payload
            ]
            
            sendMessage(message)
        } catch {
            print("Failed to encode biometric data: \(error)")
        }
    }
    
    func sendStatusUpdate() {
        let statusMessage: [String: Any] = [
            "command": "statusUpdate",
            "payload": [
                "reachable": true,
                "batteryLevel": WKInterfaceDevice.current().batteryLevel,
                "timestamp": Date().timeIntervalSince1970
            ]
        ]
        
        sendMessage(statusMessage)
    }
    
    func sendError(_ error: Error, code: Int = 0) {
        let errorMessage: [String: Any] = [
            "command": "error",
            "payload": [
                "message": error.localizedDescription,
                "code": code,
                "timestamp": Date().timeIntervalSince1970
            ]
        ]
        
        sendMessage(errorMessage)
    }
    
    // MARK: - WCSessionDelegate
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("WCSession activation failed: \(error.localizedDescription)")
            return
        }
        
        print("WCSession activated: \(activationState.rawValue)")
        
        // Send initial status update
        sendStatusUpdate()
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        handleIncomingMessage(message)
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        handleIncomingMessage(message)
        
        // Send generic acknowledgment
        replyHandler(["received": true, "timestamp": Date().timeIntervalSince1970])
    }
    
    // MARK: - Private Methods
    
    private func handleIncomingMessage(_ message: [String: Any]) {
        guard let commandString = message["command"] as? String,
              let command = WatchCommand(rawValue: commandString) else {
            return
        }
        
        switch command {
        case .configure:
            handleConfigureCommand(message)
            
        case .startMonitoring:
            handleStartMonitoringCommand(message)
            
        case .stopMonitoring:
            handleStopMonitoringCommand()
            
        case .pauseMonitoring:
            handlePauseMonitoringCommand()
            
        case .resumeMonitoring:
            handleResumeMonitoringCommand()
            
        case .synchronize:
            handleSynchronizeCommand()
            
        default:
            print("Unhandled command: \(commandString)")
        }
    }
    
    private func handleConfigureCommand(_ message: [String: Any]) {
        guard let payload = message["payload"] as? [String: Any] else { return }
        
        do {
            let data = try JSONSerialization.data(withJSONObject: payload)
            let config = try JSONDecoder().decode(SessionConfiguration.self, from: data)
            
            // Apply configuration
            WatchSessionManager.shared.updateConfiguration(config)
            
            print("Applied configuration: \(config)")
        } catch {
            print("Failed to decode configuration: \(error)")
            sendError(error)
        }
    }
    
    private func handleStartMonitoringCommand(_ message: [String: Any]) {
        guard let payload = message["payload"] as? [String: Any],
              let sessionId = payload["sessionId"] as? String else {
            return
        }
        
        // Start monitoring session
        WatchSessionManager.shared.startSession(sessionId: sessionId)
    }
    
    private func handleStopMonitoringCommand() {
        // Stop monitoring session
        WatchSessionManager.shared.endSession()
    }
    
    private func handlePauseMonitoringCommand() {
        // Pause monitoring
        WatchSessionManager.shared.pauseSession()
    }
    
    private func handleResumeMonitoringCommand() {
        // Resume monitoring
        WatchSessionManager.shared.resumeSession()
    }
    
    private func handleSynchronizeCommand() {
        // Synchronize stored data
        WatchSessionManager.shared.synchronizeData()
    }
}


// MARK: - Supporting Types

enum WatchConnectivityError: Error {
    case sessionNotActive
    case messageDataInvalid
}

enum WatchCommand: String {
    case configure
    case startMonitoring
    case stopMonitoring
    case pauseMonitoring
    case resumeMonitoring
    case biometricData
    case statusUpdate
    case error
    case synchronize
}

struct SessionConfiguration: Codable {
    let samplingFrequency: SamplingFrequency
    let includeHRV: Bool
    let includeEDA: Bool
    let includeMotion: Bool
    let includeRespiration: Bool
    let sessionMode: SessionMode
    
    static let `default` = SessionConfiguration(
        samplingFrequency: .medium,
        includeHRV: true,
        includeEDA: true,
        includeMotion: true,
        includeRespiration: true,
        sessionMode: .standard
    )
}

enum SamplingFrequency: String, Codable {
    case low    // 1Hz
    case medium // 5Hz
    case high   // 10Hz
    
    var interval: TimeInterval {
        switch self {
        case .low: return 1.0
        case .medium: return 0.2
        case .high: return 0.1
        }
    }
}

enum SessionMode: String, Codable {
    case standard
    case background
    case lowPower
    case highPrecision
}

struct BiometricDataPacket: Codable {
    let timestamp: TimeInterval
    let heartRate: Double?
    let heartRateVariability: Double?
    let skinConductance: Double?
    let skinConductanceResponses: Int?
    let acceleration: AccelerationData?
    let respirationRate: Double?
    let batteryLevel: Double?
    let dataQuality: String
    let sessionId: String
    let packetId: UUID
}

struct AccelerationData: Codable {
    let x: Double
    let y: Double
    let z: Double
    let timestamp: TimeInterval
}
