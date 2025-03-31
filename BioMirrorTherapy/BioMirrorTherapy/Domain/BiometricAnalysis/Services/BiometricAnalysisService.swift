//
//  BiometricAnalysisService.swift
//  BioMirrorTherapy
//
//  Created by Mykhailo Kotyk on 30.03.2025.
//

import Foundation
import Combine

protocol BiometricAnalysisService {
    // Status
    var isRunning: Bool { get }
    var status: BiometricAnalysisStatus { get }
    var statusPublisher: AnyPublisher<BiometricAnalysisStatus, Never> { get }
    
    // Data
    var currentPhysiologicalState: PhysiologicalState? { get }
    var physiologicalStatePublisher: AnyPublisher<PhysiologicalState, Never> { get }
    
    // Control
    func startMonitoring() throws
    func stopMonitoring()
    func pauseMonitoring()
    func resumeMonitoring()
    
    // Configuration
    func configure(with options: BiometricAnalysisOptions)
}

enum BiometricAnalysisStatus {
    case notStarted
    case initializing
    case running
    case paused
    case failed(Error)
}

enum BiometricAnalysisError: Error {
    case watchNotConnected
    case watchNotSupported
    case missingPermissions
    case sensorUnavailable
    case internalError(String)
}

struct BiometricAnalysisOptions {
    let samplingFrequency: SamplingFrequency
    let includeHeartRateVariability: Bool
    let includeElectrodermalActivity: Bool
    let includeMotionAnalysis: Bool
    let includeRespirationAnalysis: Bool
    
    static let `default` = BiometricAnalysisOptions(
        samplingFrequency: .medium,
        includeHeartRateVariability: true,
        includeElectrodermalActivity: true,
        includeMotionAnalysis: true,
        includeRespirationAnalysis: true
    )
}

//enum SamplingFrequency {
//    case low   // 1 Hz
//    case medium // 5 Hz
//    case high  // 10+ Hz
//}
