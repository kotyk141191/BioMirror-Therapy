//
//  WatchConnectivityManager.swift
//  BioMirrorTherapy
//
//  Created by Mykhailo Kotyk on 30.03.2025.
//

import Foundation
import WatchConnectivity
import Combine

class WatchConnectivityManager: NSObject {
    // MARK: - Singleton
    
    static let shared = WatchConnectivityManager()
    
    // MARK: - Properties
    
    private var session: WCSession?
    
    private let messageSubject = PassthroughSubject<[String: Any], Never>()
    private let connectionStateSubject = PassthroughSubject<WatchConnectionState, Never>()
    private let biometricDataSubject = PassthroughSubject<BiometricDataPacket, Never>()
    private let errorSubject = PassthroughSubject<Error, Never>()
    
    // MARK: - Public Properties
    
    var messagePublisher: AnyPublisher<[String: Any], Never> {
        return messageSubject.eraseToAnyPublisher()
    }
    
    var connectionStatePublisher: AnyPublisher<WatchConnectionState, Never> {
        return connectionStateSubject.eraseToAnyPublisher()
    }
    
    var biometricDataPublisher: AnyPublisher<BiometricDataPacket, Never> {
        return biometricDataSubject.eraseToAnyPublisher()
    }
    
    var errorPublisher: AnyPublisher<Error, Never> {
        return errorSubject.eraseToAnyPublisher()
    }
    
    var isWatchSessionSupported: Bool {
        return WCSession.isSupported()
    }
    
    var isWatchAppInstalled: Bool {
        return session?.isPaired == true && session?.isWatchAppInstalled == true
    }
    
    var isWatchReachable: Bool {
        return session?.isReachable ?? false
    }
    
    var connectionState: WatchConnectionState {
        guard isWatchSessionSupported else {
            return .unsupported
        }
        
        guard session?.activationState == .activated else {
            return .inactive
        }
        
        guard isWatchAppInstalled else {
            return .appNotInstalled
        }
        
        return isWatchReachable ? .reachable : .unreachable
    }
    
    // MARK: - Initialization
    
    private override init() {
        super.init()
    }
    
    // MARK: - Public Methods
    
    /// Start the Watch connectivity session
    func startSession() {
        guard WCSession.isSupported() else {
            connectionStateSubject.send(.unsupported)
            return
        }
        
        session = WCSession.default
        session?.delegate = self
        session?.activate()
    }
    
    /// Send a message to the Watch
    /// - Parameters:
    ///   - message: Message dictionary to send
    ///   - replyHandler: Optional handler for reply
    ///   - errorHandler: Optional error handler
    func sendMessage(_ message: [String: Any], replyHandler: (([String: Any]) -> Void)? = nil, errorHandler: ((Error) -> Void)? = nil) {
        guard let session = session, session.activationState == .activated else {
            let error = WatchConnectivityError.sessionNotActive
            errorHandler?(error)
            errorSubject.send(error)
            return
        }
        
        guard session.isReachable else {
            let error = WatchConnectivityError.watchNotReachable
            errorHandler?(error)
            errorSubject.send(error)
            return
        }
        
        session.sendMessage(message, replyHandler: replyHandler, errorHandler: { error in
            errorHandler?(error)
            self.errorSubject.send(error)
        })
    }
    
    /// Send a command to the Watch
    /// - Parameters:
    ///   - command: Command to send
    ///   - payload: Optional payload data
    ///   - replyHandler: Optional handler for reply
    ///   - errorHandler: Optional error handler
    func sendCommand(_ command: WatchCommand, payload: [String: Any]? = nil, replyHandler: (([String: Any]) -> Void)? = nil, errorHandler: ((Error) -> Void)? = nil) {
        var message: [String: Any] = ["command": command.rawValue]
        
        if let payload = payload {
            message["payload"] = payload
        }
        
        sendMessage(message, replyHandler: replyHandler, errorHandler: errorHandler)
    }
    
    /// Transfer file to the Watch
    /// - Parameters:
    ///   - url: URL of the file to transfer
    ///   - metadata: Optional metadata
    ///   - completion: Completion handler with success status and optional error
    func transferFile(at url: URL, metadata: [String: Any]? = nil, completion: ((Bool, Error?) -> Void)? = nil) {
        guard let session = session, session.activationState == .activated else {
            let error = WatchConnectivityError.sessionNotActive
            completion?(false, error)
            errorSubject.send(error)
            return
        }
        
        let transfer = session.transferFile(url, metadata: metadata)
        
        // Add observer for transfer completion
        NotificationCenter.default.addObserver(forName: .fileTransferFinished, object: transfer, queue: .main) { notification in
            if let error = notification.userInfo?["error"] as? Error {
                completion?(false, error)
            } else {
                completion?(true, nil)
            }
        }
    }
    
    /// Update application context (persistent state)
    /// - Parameter context: Context dictionary to update
    /// - Throws: Error if context update fails
    func updateApplicationContext(_ context: [String: Any]) throws {
        guard let session = session, session.activationState == .activated else {
            throw WatchConnectivityError.sessionNotActive
        }
        
        try session.updateApplicationContext(context)
    }
    
    /// Send configuration to Watch app
    /// - Parameter config: Configuration settings
    func sendConfiguration(_ config: SessionConfiguration) {
        let payload: [String: Any] = [
            "samplingFrequency": config.samplingFrequency.rawValue,
            "includeHRV": config.includeHRV,
            "includeEDA": config.includeEDA,
            "includeMotion": config.includeMotion,
            "includeRespiration": config.includeRespiration,
            "sessionMode": config.sessionMode.rawValue
        ]
        
        sendCommand(.configure, payload: payload)
    }
    
    /// Start biometric monitoring on the Watch
    /// - Parameter sessionId: Unique ID for the session
    func startBiometricMonitoring(sessionId: String) {
        sendCommand(.startMonitoring, payload: ["sessionId": sessionId])
    }
    
    /// Stop biometric monitoring on the Watch
    func stopBiometricMonitoring() {
        sendCommand(.stopMonitoring)
    }
}

// MARK: - WCSessionDelegate

extension WatchConnectivityManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            if let error = error {
                self.errorSubject.send(error)
            }
            
            self.connectionStateSubject.send(self.connectionState)
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        DispatchQueue.main.async {
            self.connectionStateSubject.send(.inactive)
        }
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        DispatchQueue.main.async {
            self.connectionStateSubject.send(.inactive)
            
            // Reactivate session for next connection
            self.session?.activate()
        }
    }
    
    func sessionWatchStateDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.connectionStateSubject.send(self.connectionState)
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        DispatchQueue.main.async {
            self.messageSubject.send(message)
            self.processIncomingMessage(message)
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        DispatchQueue.main.async {
            self.messageSubject.send(message)
            self.processIncomingMessage(message)
            
            // Send generic acknowledgment
            replyHandler(["received": true, "timestamp": Date().timeIntervalSince1970])
        }
    }
    
    // MARK: - Message Processing
    
    private func processIncomingMessage(_ message: [String: Any]) {
        if let commandString = message["command"] as? String,
           let command = WatchCommand(rawValue: commandString) {
            
            switch command {
            case .biometricData:
                processBiometricData(message)
                
            case .statusUpdate:
                processStatusUpdate(message)
                
            case .error:
                processErrorMessage(message)
                
            default:
                break
            }
        }
    }
    
    private func processBiometricData(_ message: [String: Any]) {
        guard let payload = message["payload"] as? [String: Any] else { return }
        
        do {
            // Convert payload to BiometricDataPacket
            let data = try JSONSerialization.data(withJSONObject: payload)
            let packet = try JSONDecoder().decode(BiometricDataPacket.self, from: data)
            
            biometricDataSubject.send(packet)
        } catch {
            errorSubject.send(error)
        }
    }
    
    private func processStatusUpdate(_ message: [String: Any]) {
        if let payload = message["payload"] as? [String: Any],
           let isReachable = payload["reachable"] as? Bool {
            
            let newState: WatchConnectionState = isReachable ? .reachable : .unreachable
            connectionStateSubject.send(newState)
        }
    }
    
    private func processErrorMessage(_ message: [String: Any]) {
        if let payload = message["payload"] as? [String: Any],
           let errorMessage = payload["message"] as? String,
           let errorCode = payload["code"] as? Int {
            
            let error = WatchAppError(message: errorMessage, code: errorCode)
            errorSubject.send(error)
        }
    }
}

// MARK: - Supporting Types

enum WatchConnectionState {
    case unsupported
    case inactive
    case appNotInstalled
    case unreachable
    case reachable
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

enum SamplingFrequency: String, Codable {
    case low    // 1Hz
    case medium // 5Hz
    case high   // 10Hz
}

enum SessionMode: String, Codable {
    case standard
    case background
    case lowPower
    case highPrecision
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

enum WatchConnectivityError: Error {
    case sessionNotActive
    case watchNotReachable
    case messageDataInvalid
    case applicationContextUpdateFailed
}

struct WatchAppError: Error {
    let message: String
    let code: Int
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let fileTransferFinished = Notification.Name("WatchFileTransferFinished")
}
