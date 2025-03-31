//
//  SoundManager.swift
//  BioMirrorTherapy
//
//  Created by Mykhailo Kotyk on 30.03.2025.
//

import Foundation
import AVFoundation

class SoundManager {
    // Singleton instance
    static let shared = SoundManager()
    
    // Sound players
    private var audioPlayers: [URL: AVAudioPlayer] = [:]
    
    private init() {
        // Configure audio session
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to configure audio session: \(error)")
        }
    }
    
    /// Play a sound file
    /// - Parameters:
    ///   - url: URL of the sound file
    ///   - volume: Playback volume (0.0-1.0)
    ///   - completion: Called when playback completes
    func playSound(at url: URL, volume: Float = 1.0, completion: (() -> Void)? = nil) {
        // Check if we already have a player for this URL
        if let existingPlayer = audioPlayers[url] {
            existingPlayer.stop()
            existingPlayer.currentTime = 0
            existingPlayer.volume = volume
            existingPlayer.play()
            
            if let completion = completion {
                NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: existingPlayer)
                NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: existingPlayer, queue: .main) { _ in
                    completion()
                }
            }
            
            return
        }
        
        // Create a new audio player
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = volume
            player.prepareToPlay()
            
            // Store the player
            audioPlayers[url] = player
            
            // Add completion handler if provided
            if let completion = completion {
                NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player, queue: .main) { _ in
                    completion()
                }
            }
            
            // Play the sound
            player.play()
        } catch {
            print("Failed to play sound: \(error)")
        }
    }
    
    /// Stop playing a sound
    /// - Parameter url: URL of the sound to stop
    func stopSound(at url: URL) {
        guard let player = audioPlayers[url] else { return }
        player.stop()
    }
    
    /// Stop all sounds
    func stopAllSounds() {
        for player in audioPlayers.values {
            player.stop()
        }
    }
    
    /// Preload a sound for quicker playback
    /// - Parameter url: URL of the sound to preload
    func preloadSound(at url: URL) {
        if audioPlayers[url] == nil {
            do {
                let player = try AVAudioPlayer(contentsOf: url)
                player.prepareToPlay()
                audioPlayers[url] = player
            } catch {
                print("Failed to preload sound: \(error)")
            }
        }
    }
}
