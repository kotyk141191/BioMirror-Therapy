//
//  SpeechSynthesizer.swift
//  BioMirrorTherapy
//
//  Created by Mykhailo Kotyk on 30.03.2025.
//

import Foundation
import AVFoundation

class SpeechSynthesizer {
    // Singleton instance
    static let shared = SpeechSynthesizer()
    
    // Speech synthesizer
    private let synthesizer = AVSpeechSynthesizer()
    
    private init() {}
    
    /// Speak text using the speech synthesizer
    /// - Parameters:
    ///   - text: Text to speak
    ///   - voice: Voice type to use
    ///   - rate: Speech rate (0.0-1.0)
    ///   - completion: Called when speech is complete
    func speak(_ text: String, voice: VoiceType, rate: Float = 0.5, completion: (() -> Void)? = nil) {
        // Stop any current speech
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        // Create utterance
        let utterance = AVSpeechUtterance(string: text)
        
        // Set voice based on voice type
        let voiceLanguage = "en-US"
        switch voice {
        case .neutral:
            utterance.voice = AVSpeechSynthesisVoice(identifier: "com.apple.ttsbundle.Samantha-compact")
        case .gentle:
            utterance.voice = AVSpeechSynthesisVoice(identifier: "com.apple.ttsbundle.Karen-compact")
        case .energetic:
            utterance.voice = AVSpeechSynthesisVoice(identifier: "com.apple.ttsbundle.Daniel-compact")
        case .calm:
            utterance.voice = AVSpeechSynthesisVoice(identifier: "com.apple.ttsbundle.Alex-compact")
        case .soft:
            utterance.voice = AVSpeechSynthesisVoice(identifier: "com.apple.ttsbundle.Tessa-compact")
        }
        
        // Fallback to default voice if specified voice not available
        if utterance.voice == nil {
            utterance.voice = AVSpeechSynthesisVoice(language: voiceLanguage)
        }
        
        // Configure speech parameters
        utterance.rate = rate
        utterance.pitchMultiplier = 1.0
        utterance.volume = 0.8
        
        // Speak
        synthesizer.speak(utterance)
        
        // Handle completion
        if let completion = completion {
            NotificationCenter.default.addObserver(forName: AVSpeechSynthesizer.didFinishSpeechUtteranceNotification, object: synthesizer, queue: .main) { _ in
                completion()
                NotificationCenter.default.removeObserver(self, name: AVSpeechSynthesizer.didFinishSpeechUtteranceNotification, object: self.synthesizer)
            }
        }
    }
}
