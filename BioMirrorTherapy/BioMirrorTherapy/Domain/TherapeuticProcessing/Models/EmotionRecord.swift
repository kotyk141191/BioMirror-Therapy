//
//  EmotionRecord.swift
//  BioMirrorTherapy
//
//  Created by Mykhailo Kotyk on 30.03.2025.
//

import Foundation

struct EmotionRecord: Hashable {
    let type: EmotionType
    let intensity: Float
    
    init?(type: EmotionType, intensity: Float) {
        // Only record emotions with meaningful intensity
        guard intensity > 0.3 else { return nil }
        
        self.type = type
        self.intensity = intensity
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(type)
    }
    
    static func == (lhs: EmotionRecord, rhs: EmotionRecord) -> Bool {
        return lhs.type == rhs.type
    }
}
