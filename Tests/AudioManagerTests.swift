//
//  AudioManagerTests.swift
//  FlowTimerTests
//
//  Property-based tests for AudioManager volume bounds.
//

import XCTest
@testable import FlowTimer

/// Property-based tests for the AudioManager.
///
/// **Validates: Requirements 3.2**
///
/// These tests verify that volume control always maintains valid bounds
/// and the audio manager behaves correctly across all volume operations.
final class AudioManagerTests: XCTestCase {
    
    // MARK: - Property 3: Volume Bounds
    
    /// **Validates: Requirements 3.2**
    ///
    /// Property: Volume is always in range [0.0, 1.0].
    /// For any volume adjustment operation, the resulting volume must be within bounds.
    func testVolumeBounds_AlwaysInRange() {
        let iterations = 100
        
        for _ in 0..<iterations {
            let audioManager = AudioManager()
            
            // Generate random volume values including edge cases and out-of-bounds values
            let testVolumes: [Float] = [
                Float.random(in: -100...100),  // Wide range including negatives
                Float.random(in: -1...2),      // Near boundary values
                Float.random(in: 0...1),       // Valid range
                -Float.greatestFiniteMagnitude,
                Float.greatestFiniteMagnitude,
                -1.0,
                -0.5,
                -0.001,
                0.0,
                0.5,
                1.0,
                1.001,
                1.5,
                2.0
            ]
            
            for testVolume in testVolumes {
                audioManager.setVolume(testVolume)
                
                XCTAssertGreaterThanOrEqual(
                    audioManager.volume, 0.0,
                    "Volume should never be less than 0.0 after setting to \(testVolume)"
                )
                XCTAssertLessThanOrEqual(
                    audioManager.volume, 1.0,
                    "Volume should never be greater than 1.0 after setting to \(testVolume)"
                )
            }
        }
    }
    
    /// **Validates: Requirements 3.2**
    ///
    /// Property: Setting volume below 0 clamps to 0.
    func testVolumeBounds_NegativeClampedToZero() {
        let iterations = 50
        
        for _ in 0..<iterations {
            let audioManager = AudioManager()
            
            // Generate random negative values
            let negativeVolume = -Float.random(in: 0.001...1000)
            audioManager.setVolume(negativeVolume)
            
            XCTAssertEqual(
                audioManager.volume, 0.0,
                "Negative volume \(negativeVolume) should be clamped to 0.0"
            )
        }
    }
    
    /// **Validates: Requirements 3.2**
    ///
    /// Property: Setting volume above 1 clamps to 1.
    func testVolumeBounds_AboveOneClampedToOne() {
        let iterations = 50
        
        for _ in 0..<iterations {
            let audioManager = AudioManager()
            
            // Generate random values above 1.0
            let highVolume = Float.random(in: 1.001...1000)
            audioManager.setVolume(highVolume)
            
            XCTAssertEqual(
                audioManager.volume, 1.0,
                "Volume \(highVolume) above 1.0 should be clamped to 1.0"
            )
        }
    }
    
    /// **Validates: Requirements 3.2**
    ///
    /// Property: Valid volume values [0.0, 1.0] are preserved exactly.
    func testVolumeBounds_ValidValuesPreserved() {
        let iterations = 100
        
        for _ in 0..<iterations {
            let audioManager = AudioManager()
            
            // Generate random valid volume values
            let validVolume = Float.random(in: 0.0...1.0)
            audioManager.setVolume(validVolume)
            
            XCTAssertEqual(
                audioManager.volume, validVolume, accuracy: 0.0001,
                "Valid volume \(validVolume) should be preserved exactly"
            )
        }
    }
    
    /// **Validates: Requirements 3.2**
    ///
    /// Property: Boundary values are handled correctly.
    func testVolumeBounds_BoundaryValues() {
        let audioManager = AudioManager()
        
        // Test exact boundary: 0.0
        audioManager.setVolume(0.0)
        XCTAssertEqual(audioManager.volume, 0.0, "Volume 0.0 should be preserved")
        
        // Test exact boundary: 1.0
        audioManager.setVolume(1.0)
        XCTAssertEqual(audioManager.volume, 1.0, "Volume 1.0 should be preserved")
        
        // Test just below 0
        audioManager.setVolume(-0.0001)
        XCTAssertEqual(audioManager.volume, 0.0, "Volume just below 0 should clamp to 0")
        
        // Test just above 1
        audioManager.setVolume(1.0001)
        XCTAssertEqual(audioManager.volume, 1.0, "Volume just above 1 should clamp to 1")
    }
    
    /// **Validates: Requirements 3.2**
    ///
    /// Property: Multiple sequential volume changes maintain bounds.
    func testVolumeBounds_SequentialChanges() {
        let iterations = 50
        let changesPerIteration = 20
        
        for _ in 0..<iterations {
            let audioManager = AudioManager()
            
            for _ in 0..<changesPerIteration {
                // Generate random volume including out-of-bounds values
                let randomVolume = Float.random(in: -10...10)
                audioManager.setVolume(randomVolume)
                
                // After every change, volume must be in bounds
                XCTAssertGreaterThanOrEqual(audioManager.volume, 0.0)
                XCTAssertLessThanOrEqual(audioManager.volume, 1.0)
            }
        }
    }
    
    /// **Validates: Requirements 3.2**
    ///
    /// Property: Static clampVolume function correctly clamps all values.
    func testClampVolume_StaticFunction() {
        let iterations = 100
        
        for _ in 0..<iterations {
            let randomValue = Float.random(in: -1000...1000)
            let clamped = AudioManager.clampVolume(randomValue)
            
            XCTAssertGreaterThanOrEqual(clamped, 0.0,
                "Clamped value should be >= 0.0 for input \(randomValue)")
            XCTAssertLessThanOrEqual(clamped, 1.0,
                "Clamped value should be <= 1.0 for input \(randomValue)")
            
            // If input was in valid range, output should equal input
            if randomValue >= 0.0 && randomValue <= 1.0 {
                XCTAssertEqual(clamped, randomValue, accuracy: 0.0001,
                    "Valid input \(randomValue) should be preserved")
            }
            
            // If input was below 0, output should be 0
            if randomValue < 0.0 {
                XCTAssertEqual(clamped, 0.0,
                    "Negative input \(randomValue) should clamp to 0.0")
            }
            
            // If input was above 1, output should be 1
            if randomValue > 1.0 {
                XCTAssertEqual(clamped, 1.0,
                    "Input \(randomValue) above 1.0 should clamp to 1.0")
            }
        }
    }
    
    /// **Validates: Requirements 3.2**
    ///
    /// Property: isValidVolume correctly identifies valid and invalid volumes.
    func testIsValidVolume_StaticFunction() {
        let iterations = 100
        
        for _ in 0..<iterations {
            let randomValue = Float.random(in: -10...10)
            let isValid = AudioManager.isValidVolume(randomValue)
            
            let expectedValid = randomValue >= 0.0 && randomValue <= 1.0
            XCTAssertEqual(isValid, expectedValid,
                "isValidVolume(\(randomValue)) should return \(expectedValid)")
        }
        
        // Test boundary cases explicitly
        XCTAssertTrue(AudioManager.isValidVolume(0.0), "0.0 should be valid")
        XCTAssertTrue(AudioManager.isValidVolume(1.0), "1.0 should be valid")
        XCTAssertTrue(AudioManager.isValidVolume(0.5), "0.5 should be valid")
        XCTAssertFalse(AudioManager.isValidVolume(-0.001), "-0.001 should be invalid")
        XCTAssertFalse(AudioManager.isValidVolume(1.001), "1.001 should be invalid")
    }
    
    // MARK: - Initialization Tests
    
    /// **Validates: Requirements 3.2**
    ///
    /// Property: AudioManager initializes with valid default volume.
    func testInitialization_DefaultVolume() {
        let audioManager = AudioManager()
        
        XCTAssertEqual(audioManager.volume, AudioManager.defaultVolume,
            "Default volume should be \(AudioManager.defaultVolume)")
        XCTAssertGreaterThanOrEqual(audioManager.volume, 0.0)
        XCTAssertLessThanOrEqual(audioManager.volume, 1.0)
    }
    
    /// **Validates: Requirements 3.2**
    ///
    /// Property: AudioManager initializes with clamped custom volume.
    func testInitialization_CustomVolume() {
        let iterations = 50
        
        for _ in 0..<iterations {
            let randomVolume = Float.random(in: -10...10)
            let audioManager = AudioManager(volume: randomVolume)
            
            XCTAssertGreaterThanOrEqual(audioManager.volume, 0.0,
                "Initial volume should be >= 0.0 for input \(randomVolume)")
            XCTAssertLessThanOrEqual(audioManager.volume, 1.0,
                "Initial volume should be <= 1.0 for input \(randomVolume)")
            
            // If input was valid, it should be preserved
            if randomVolume >= 0.0 && randomVolume <= 1.0 {
                XCTAssertEqual(audioManager.volume, randomVolume, accuracy: 0.0001)
            }
        }
    }
    
    // MARK: - Mute Tests
    
    /// **Validates: Requirements 3.4**
    ///
    /// Property: Mute toggle preserves volume value.
    func testMuteToggle_PreservesVolume() {
        let iterations = 50
        
        for _ in 0..<iterations {
            let audioManager = AudioManager()
            let testVolume = Float.random(in: 0.0...1.0)
            
            audioManager.setVolume(testVolume)
            let volumeBeforeMute = audioManager.volume
            
            // Mute
            audioManager.toggleMute()
            XCTAssertTrue(audioManager.isMuted, "Should be muted after toggle")
            XCTAssertEqual(audioManager.volume, volumeBeforeMute,
                "Volume value should be preserved when muted")
            
            // Unmute
            audioManager.toggleMute()
            XCTAssertFalse(audioManager.isMuted, "Should be unmuted after second toggle")
            XCTAssertEqual(audioManager.volume, volumeBeforeMute,
                "Volume should be restored after unmute")
        }
    }
    
    /// **Validates: Requirements 3.4**
    ///
    /// Property: setMuted correctly sets mute state.
    func testSetMuted_CorrectState() {
        let audioManager = AudioManager()
        
        XCTAssertFalse(audioManager.isMuted, "Should start unmuted")
        
        audioManager.setMuted(true)
        XCTAssertTrue(audioManager.isMuted, "Should be muted after setMuted(true)")
        
        audioManager.setMuted(true)
        XCTAssertTrue(audioManager.isMuted, "Should remain muted after setMuted(true) again")
        
        audioManager.setMuted(false)
        XCTAssertFalse(audioManager.isMuted, "Should be unmuted after setMuted(false)")
        
        audioManager.setMuted(false)
        XCTAssertFalse(audioManager.isMuted, "Should remain unmuted after setMuted(false) again")
    }
    
    // MARK: - State Tests
    
    /// Property: Initial state is correct.
    func testInitialState() {
        let audioManager = AudioManager()
        
        XCTAssertNil(audioManager.currentSound, "No sound should be playing initially")
        XCTAssertFalse(audioManager.isPlaying, "Should not be playing initially")
        XCTAssertFalse(audioManager.isMuted, "Should not be muted initially")
        XCTAssertEqual(audioManager.volume, AudioManager.defaultVolume)
    }
    
    /// Property: Stop clears current sound state.
    func testStop_ClearsState() {
        let audioManager = AudioManager()
        
        // Even without playing, stop should work
        audioManager.stop()
        
        XCTAssertNil(audioManager.currentSound, "currentSound should be nil after stop")
        XCTAssertFalse(audioManager.isPlaying, "isPlaying should be false after stop")
    }
    
    /// Property: Cleanup releases all resources.
    func testCleanup_ReleasesResources() {
        let audioManager = AudioManager()
        
        audioManager.cleanup()
        
        XCTAssertNil(audioManager.currentSound, "currentSound should be nil after cleanup")
        XCTAssertFalse(audioManager.isPlaying, "isPlaying should be false after cleanup")
    }
    
    // MARK: - Constants Tests
    
    /// Property: Constants are correctly defined.
    func testConstants() {
        XCTAssertEqual(AudioManager.minVolume, 0.0, "Min volume should be 0.0")
        XCTAssertEqual(AudioManager.maxVolume, 1.0, "Max volume should be 1.0")
        XCTAssertGreaterThanOrEqual(AudioManager.defaultVolume, AudioManager.minVolume)
        XCTAssertLessThanOrEqual(AudioManager.defaultVolume, AudioManager.maxVolume)
        XCTAssertEqual(AudioManager.chimeFileName, "chime")
        XCTAssertEqual(AudioManager.audioFileExtension, "mp3")
    }
    
    // MARK: - Volume Change During Mute Tests
    
    /// **Validates: Requirements 3.2, 3.4**
    ///
    /// Property: Volume changes while muted are still clamped and preserved.
    func testVolumeChangeDuringMute_StillClamped() {
        let iterations = 50
        
        for _ in 0..<iterations {
            let audioManager = AudioManager()
            
            // Mute first
            audioManager.toggleMute()
            XCTAssertTrue(audioManager.isMuted)
            
            // Change volume while muted
            let testVolume = Float.random(in: -10...10)
            audioManager.setVolume(testVolume)
            
            // Volume should still be clamped
            XCTAssertGreaterThanOrEqual(audioManager.volume, 0.0)
            XCTAssertLessThanOrEqual(audioManager.volume, 1.0)
            
            // Unmute and verify volume is correct
            audioManager.toggleMute()
            XCTAssertFalse(audioManager.isMuted)
            XCTAssertGreaterThanOrEqual(audioManager.volume, 0.0)
            XCTAssertLessThanOrEqual(audioManager.volume, 1.0)
        }
    }
}
