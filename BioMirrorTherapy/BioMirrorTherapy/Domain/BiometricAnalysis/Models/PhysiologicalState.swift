//
//  PhysiologicalState.swift
//  BioMirrorTherapy
//
//  Created by Mykhailo Kotyk on 30.03.2025.
//

import Foundation
import CoreMotion

struct PhysiologicalState {
    let timestamp: Date
    let hrvMetrics: HRVMetrics
    let edaMetrics: EDAMetrics
    let motionMetrics: MotionMetrics
    let respirationMetrics: RespirationMetrics
    let arousalLevel: Float // 0.0 to 1.0, indication of autonomic activation
    let qualityIndex: Float // 0.0 to 1.0, indication of data quality
    
    var isValid: Bool {
        return qualityIndex > 0.5
    }
}

struct HRVMetrics {
    let heartRate: Double // beats per minute
    let heartRateVariability: Double // SDNN in milliseconds
    let rmssd: Double // Root Mean Square of Successive Differences
    let sdnn: Double // Standard Deviation of NN intervals
    let pnn50: Double // Percentage of successive RR intervals that differ by more than 50 ms
    let hrQuality: Float // 0.0 to 1.0
    
    static let empty = HRVMetrics(
        heartRate: 0.0,
        heartRateVariability: 0.0,
        rmssd: 0.0,
        sdnn: 0.0,
        pnn50: 0.0,
        hrQuality: 0.0
    )
}

struct EDAMetrics {
    let skinConductanceLevel: Double // in microSiemens
    let skinConductanceResponses: Int // number of responses in time window
    let peakAmplitude: Double // in microSiemens
    let edaQuality: Float // 0.0 to 1.0
    
    static let empty = EDAMetrics(
        skinConductanceLevel: 0.0,
        skinConductanceResponses: 0,
        peakAmplitude: 0.0,
        edaQuality: 0.0
    )
}

struct MotionMetrics {
    let acceleration: CMAcceleration
    let rotationRate: CMRotationRate
    let tremor: Float // 0.0 to 1.0, indication of tremor intensity
    let freezeIndex: Float // 0.0 to 1.0, indication of immobility
    let motionQuality: Float // 0.0 to 1.0
    
    static let empty = MotionMetrics(
        acceleration: CMAcceleration(x: 0, y: 0, z: 0),
        rotationRate: CMRotationRate(x: 0, y: 0, z: 0),
        tremor: 0.0,
        freezeIndex: 0.0,
        motionQuality: 0.0
    )
}

struct RespirationMetrics {
    let respirationRate: Double // breaths per minute
    let irregularity: Double // 0.0 to 1.0, indication of breathing irregularity
    let depth: Double // relative depth of breathing
    let respirationQuality: Float // 0.0 to 1.0
    
    static let empty = RespirationMetrics(
        respirationRate: 0.0,
        irregularity: 0.0,
        depth: 0.0,
        respirationQuality: 0.0
    )
}
