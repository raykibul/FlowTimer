//
//  AudioManager.swift
//  FlowTimer
//
//  Manages ambient sound playback and completion chimes using AVFoundation.
//

import Foundation
import AVFoundation
import Combine

/// Manages audio playback for ambient sounds and completion chimes.
///
/// This class handles:
/// - Playing ambient sounds with seamless looping
/// - Volume control with clamping to [0.0, 1.0]
/// - Mute/unmute functionality
/// - One-shot completion chime playback
///
/// ## Usage
/// ```swift
/// let audioManager = AudioManager()
/// audioManager.play(.rain)
/// audioManager.setVolume(0.7)
/// audioManager.toggleMute()
/// audioManager.playCompletionChime()
/// ```
class AudioManager: ObservableObject {
    
    // MARK: - Published Properties
    
    /// The currently playing ambient sound, or nil if no sound is playing
    @Published private(set) var currentSound: AmbientSound?
    
    /// The current volume level, clamped to [0.0, 1.0]
    @Published private(set) var volume: Float = 0.5
    
    /// Whether audio is currently muted
    @Published private(set) var isMuted: Bool = false
    
    /// Whether an ambient sound is currently playing
    @Published private(set) var isPlaying: Bool = false
    
    // MARK: - Private Properties
    
    /// Audio player for ambient sounds (loops continuously)
    private var audioPlayer: AVAudioPlayer?
    
    /// Audio player for completion chime (plays once)
    private var chimePlayer: AVAudioPlayer?
    
    /// Volume level before muting (for restore on unmute)
    private var volumeBeforeMute: Float = 0.5
    
    // MARK: - Constants
    
    /// Minimum allowed volume
    static let minVolume: Float = 0.0
    
    /// Maximum allowed volume
    static let maxVolume: Float = 1.0
    
    /// Default volume level
    static let defaultVolume: Float = 0.5
    
    /// File name for the completion chime sound
    static let chimeFileName = "chime"
    
    /// Audio file extension
    static let audioFileExtension = "mp3"
    
    /// Fallback audio file extension
    static let fallbackAudioFileExtension = "wav"
    
    // MARK: - Initialization
    
    init() {
        // Initialize with default volume
        volume = AudioManager.defaultVolume
    }
    
    /// Initialize with a specific volume level
    /// - Parameter initialVolume: Initial volume level (will be clamped to [0.0, 1.0])
    init(volume initialVolume: Float) {
        self.volume = AudioManager.clampVolume(initialVolume)
    }
    
    // MARK: - Ambient Sound Playback
    
    /// Plays the specified ambient sound with seamless looping.
    ///
    /// If another sound is currently playing, it will be stopped first.
    /// The sound will loop continuously until `stop()` is called.
    ///
    /// - Parameter sound: The ambient sound to play
    func play(_ sound: AmbientSound) {
        // Stop any currently playing sound
        stop()
        
        // Try to load the audio file with different extensions
        var url: URL? = Bundle.main.url(forResource: sound.rawValue, withExtension: AudioManager.audioFileExtension)
        if url == nil {
            url = Bundle.main.url(forResource: sound.rawValue, withExtension: AudioManager.fallbackAudioFileExtension)
        }
        
        guard let audioURL = url else {
            print("AudioManager: Could not find audio file for \(sound.rawValue) (tried .mp3 and .wav)")
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: audioURL)
            audioPlayer?.numberOfLoops = -1 // Loop indefinitely
            audioPlayer?.volume = isMuted ? 0 : volume
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            
            currentSound = sound
            isPlaying = true
            print("AudioManager: Playing \(sound.rawValue)")
        } catch {
            print("AudioManager: Error loading audio file: \(error.localizedDescription)")
        }
    }
    
    /// Stops the currently playing ambient sound.
    ///
    /// After calling this method, `currentSound` will be nil and `isPlaying` will be false.
    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
        currentSound = nil
        isPlaying = false
    }
    
    // MARK: - Volume Control
    
    /// Sets the volume level, clamping to the valid range [0.0, 1.0].
    ///
    /// **Validates: Requirements 3.2**
    ///
    /// - Parameter newVolume: The desired volume level
    ///   - Values below 0.0 are clamped to 0.0
    ///   - Values above 1.0 are clamped to 1.0
    func setVolume(_ newVolume: Float) {
        volume = AudioManager.clampVolume(newVolume)
        
        // Update the audio player volume if not muted
        if !isMuted {
            audioPlayer?.volume = volume
        }
    }
    
    /// Clamps a volume value to the valid range [0.0, 1.0].
    ///
    /// - Parameter value: The volume value to clamp
    /// - Returns: The clamped volume value
    static func clampVolume(_ value: Float) -> Float {
        return min(max(value, minVolume), maxVolume)
    }
    
    /// Checks if a volume value is within the valid range [0.0, 1.0].
    ///
    /// - Parameter value: The volume value to check
    /// - Returns: True if the value is within [0.0, 1.0]
    static func isValidVolume(_ value: Float) -> Bool {
        return value >= minVolume && value <= maxVolume
    }
    
    // MARK: - Mute Control
    
    /// Toggles the mute state.
    ///
    /// When muting:
    /// - The current volume is saved
    /// - Audio player volume is set to 0
    ///
    /// When unmuting:
    /// - The saved volume is restored
    /// - Audio player volume is set to the restored value
    func toggleMute() {
        if isMuted {
            // Unmute: restore volume
            isMuted = false
            audioPlayer?.volume = volume
        } else {
            // Mute: set volume to 0
            isMuted = true
            audioPlayer?.volume = 0
        }
    }
    
    /// Sets the mute state directly.
    ///
    /// - Parameter muted: Whether audio should be muted
    func setMuted(_ muted: Bool) {
        if muted != isMuted {
            toggleMute()
        }
    }
    
    // MARK: - Completion Chime
    
    /// Plays the completion chime sound once.
    ///
    /// The chime plays at the current volume level (unless muted).
    /// This does not affect the currently playing ambient sound.
    func playCompletionChime() {
        // Try to load the chime file with different extensions
        var url: URL? = Bundle.main.url(forResource: AudioManager.chimeFileName, withExtension: AudioManager.audioFileExtension)
        if url == nil {
            url = Bundle.main.url(forResource: AudioManager.chimeFileName, withExtension: AudioManager.fallbackAudioFileExtension)
        }
        
        guard let chimeURL = url else {
            print("AudioManager: Could not find chime audio file (tried .mp3 and .wav)")
            return
        }
        
        do {
            chimePlayer = try AVAudioPlayer(contentsOf: chimeURL)
            chimePlayer?.numberOfLoops = 0 // Play once
            chimePlayer?.volume = isMuted ? 0 : volume
            chimePlayer?.prepareToPlay()
            chimePlayer?.play()
        } catch {
            print("AudioManager: Error loading chime audio file: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Cleanup
    
    /// Stops all audio playback and releases resources.
    func cleanup() {
        stop()
        chimePlayer?.stop()
        chimePlayer = nil
    }
    
    deinit {
        cleanup()
    }
}
