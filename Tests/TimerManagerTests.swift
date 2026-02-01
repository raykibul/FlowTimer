//
//  TimerManagerTests.swift
//  FlowTimerTests
//
//  Property-based tests for TimerManager state machine validity.
//

import XCTest
@testable import FlowTimer

/// Property-based tests for the TimerManager.
///
/// **Validates: Requirements 1.2**
///
/// These tests verify that the timer state machine follows valid transitions
/// and maintains consistency across all possible action sequences.
final class TimerManagerTests: XCTestCase {
    
    // MARK: - Test Helpers
    
    /// Actions that can be performed on the timer
    enum TimerAction: CaseIterable {
        case start
        case pause
        case resume
        case stop
        case reset
        
        /// Applies this action to the timer manager
        @MainActor
        func apply(to manager: TimerManager) {
            switch self {
            case .start:
                manager.start()
            case .pause:
                manager.pause()
            case .resume:
                manager.resume()
            case .stop:
                manager.stop()
            case .reset:
                manager.reset()
            }
        }
    }
    
    /// Generates a random sequence of timer actions
    func generateRandomActionSequence(length: Int) -> [TimerAction] {
        return (0..<length).map { _ in
            TimerAction.allCases.randomElement()!
        }
    }
    
    // MARK: - Property 1: Timer State Machine Validity
    
    /// **Validates: Requirements 1.2**
    ///
    /// Property: For any sequence of user actions, the timer state is always
    /// in a valid state and all transitions are valid.
    ///
    /// Valid transitions:
    /// - idle → running (start)
    /// - running → paused (pause)
    /// - running → idle (stop/cancel)
    /// - running → completed (time reaches 0)
    /// - paused → running (resume)
    /// - paused → idle (stop/cancel)
    /// - completed → idle (reset)
    @MainActor
    func testStateMachineValidity_RandomActionSequences() async {
        // Run multiple iterations with random action sequences
        let iterations = 100
        let maxSequenceLength = 20
        
        for iteration in 0..<iterations {
            let manager = TimerManager(duration: 10) // Short duration for testing
            var previousState = manager.timerState
            
            let sequenceLength = Int.random(in: 1...maxSequenceLength)
            let actions = generateRandomActionSequence(length: sequenceLength)
            
            for (actionIndex, action) in actions.enumerated() {
                action.apply(to: manager)
                let currentState = manager.timerState
                
                // If state changed, verify it was a valid transition
                if currentState != previousState {
                    let isValid = TimerManager.isValidTransition(from: previousState, to: currentState)
                    XCTAssertTrue(
                        isValid,
                        "Invalid transition from \(previousState) to \(currentState) " +
                        "after action \(action) at index \(actionIndex) in iteration \(iteration)"
                    )
                }
                
                // Verify state is always one of the valid states
                XCTAssertTrue(
                    TimerState.allCases.contains(currentState),
                    "Timer in invalid state: \(currentState)"
                )
                
                previousState = currentState
            }
        }
    }
    
    /// **Validates: Requirements 1.2**
    ///
    /// Property: Starting from idle, the only valid next state is running.
    @MainActor
    func testIdleStateTransitions() async {
        let manager = TimerManager()
        XCTAssertEqual(manager.timerState, .idle)
        
        // Only start should change state from idle
        manager.pause()
        XCTAssertEqual(manager.timerState, .idle, "Pause should not change idle state")
        
        manager.resume()
        XCTAssertEqual(manager.timerState, .idle, "Resume should not change idle state")
        
        manager.stop()
        XCTAssertEqual(manager.timerState, .idle, "Stop should not change idle state")
        
        manager.reset()
        XCTAssertEqual(manager.timerState, .idle, "Reset should not change idle state")
        
        // Start should transition to running
        manager.start()
        XCTAssertEqual(manager.timerState, .running, "Start should transition idle to running")
    }
    
    /// **Validates: Requirements 1.2**
    ///
    /// Property: From running state, valid transitions are to paused, idle, or completed.
    @MainActor
    func testRunningStateTransitions() async {
        // Test running → paused
        let manager1 = TimerManager()
        manager1.start()
        XCTAssertEqual(manager1.timerState, .running)
        manager1.pause()
        XCTAssertEqual(manager1.timerState, .paused, "Pause should transition running to paused")
        
        // Test running → idle (stop)
        let manager2 = TimerManager()
        manager2.start()
        XCTAssertEqual(manager2.timerState, .running)
        manager2.stop()
        XCTAssertEqual(manager2.timerState, .idle, "Stop should transition running to idle")
        
        // Invalid actions from running
        let manager3 = TimerManager()
        manager3.start()
        manager3.start() // Should be ignored
        XCTAssertEqual(manager3.timerState, .running, "Start should not change running state")
        
        manager3.resume() // Should be ignored
        XCTAssertEqual(manager3.timerState, .running, "Resume should not change running state")
        
        manager3.reset() // Should be ignored
        XCTAssertEqual(manager3.timerState, .running, "Reset should not change running state")
    }
    
    /// **Validates: Requirements 1.2**
    ///
    /// Property: From paused state, valid transitions are to running or idle.
    @MainActor
    func testPausedStateTransitions() async {
        // Test paused → running (resume)
        let manager1 = TimerManager()
        manager1.start()
        manager1.pause()
        XCTAssertEqual(manager1.timerState, .paused)
        manager1.resume()
        XCTAssertEqual(manager1.timerState, .running, "Resume should transition paused to running")
        
        // Test paused → idle (stop)
        let manager2 = TimerManager()
        manager2.start()
        manager2.pause()
        XCTAssertEqual(manager2.timerState, .paused)
        manager2.stop()
        XCTAssertEqual(manager2.timerState, .idle, "Stop should transition paused to idle")
        
        // Invalid actions from paused
        let manager3 = TimerManager()
        manager3.start()
        manager3.pause()
        
        manager3.start() // Should be ignored
        XCTAssertEqual(manager3.timerState, .paused, "Start should not change paused state")
        
        manager3.pause() // Should be ignored
        XCTAssertEqual(manager3.timerState, .paused, "Pause should not change paused state")
        
        manager3.reset() // Should be ignored
        XCTAssertEqual(manager3.timerState, .paused, "Reset should not change paused state")
    }
    
    /// **Validates: Requirements 1.2**
    ///
    /// Property: From completed state, the only valid transition is to idle (reset).
    func testCompletedStateTransitions() {
        // Test that reset works from completed state
        let validTransitions = TimerManager.validTransitions(from: .completed)
        XCTAssertEqual(validTransitions, [.idle], "Only valid transition from completed is to idle")
        
        // Verify transition validity
        XCTAssertTrue(TimerManager.isValidTransition(from: .completed, to: .idle))
        XCTAssertFalse(TimerManager.isValidTransition(from: .completed, to: .running))
        XCTAssertFalse(TimerManager.isValidTransition(from: .completed, to: .paused))
        XCTAssertFalse(TimerManager.isValidTransition(from: .completed, to: .completed))
    }
    
    // MARK: - Property: State Consistency
    
    /// **Validates: Requirements 1.2**
    ///
    /// Property: After any action, the timer state is consistent with its properties.
    @MainActor
    func testStateConsistency_RandomActions() async {
        let iterations = 50
        
        for _ in 0..<iterations {
            let duration = TimeInterval.random(in: 60...14400)
            let manager = TimerManager(duration: duration)
            
            let actions = generateRandomActionSequence(length: Int.random(in: 1...15))
            
            for action in actions {
                action.apply(to: manager)
                
                // Verify state consistency
                switch manager.timerState {
                case .idle:
                    XCTAssertEqual(manager.remainingTime, manager.selectedDuration,
                                   "Idle state should have remainingTime equal to selectedDuration")
                    XCTAssertNil(manager.sessionStartDate,
                                 "Idle state should have nil sessionStartDate")
                    
                case .running:
                    XCTAssertNotNil(manager.sessionStartDate,
                                    "Running state should have sessionStartDate set")
                    XCTAssertGreaterThanOrEqual(manager.remainingTime, 0,
                                                 "Remaining time should be non-negative")
                    XCTAssertLessThanOrEqual(manager.remainingTime, manager.selectedDuration,
                                              "Remaining time should not exceed selected duration")
                    
                case .paused:
                    XCTAssertGreaterThanOrEqual(manager.remainingTime, 0,
                                                 "Remaining time should be non-negative when paused")
                    XCTAssertLessThanOrEqual(manager.remainingTime, manager.selectedDuration,
                                              "Remaining time should not exceed selected duration when paused")
                    
                case .completed:
                    XCTAssertEqual(manager.remainingTime, 0,
                                   "Completed state should have remainingTime of 0")
                }
            }
        }
    }
    
    // MARK: - Property: Duration Presets
    
    /// **Validates: Requirements 1.1**
    ///
    /// Property: All duration presets are valid and correctly defined.
    func testDurationPresets() {
        let expectedPresets: [TimeInterval] = [1800, 3600, 7200, 10800, 14400]
        
        XCTAssertEqual(TimerManager.durationPresets, expectedPresets,
                       "Duration presets should match expected values")
        
        // Verify preset enum values
        XCTAssertEqual(DurationPreset.thirtyMinutes.rawValue, 1800)
        XCTAssertEqual(DurationPreset.oneHour.rawValue, 3600)
        XCTAssertEqual(DurationPreset.twoHours.rawValue, 7200)
        XCTAssertEqual(DurationPreset.threeHours.rawValue, 10800)
        XCTAssertEqual(DurationPreset.fourHours.rawValue, 14400)
        
        // Verify all presets are in the static array
        for preset in DurationPreset.allCases {
            XCTAssertTrue(TimerManager.durationPresets.contains(preset.rawValue),
                          "Preset \(preset) should be in durationPresets array")
        }
    }
    
    /// **Validates: Requirements 1.1**
    ///
    /// Property: Setting duration updates remainingTime when idle.
    @MainActor
    func testSetDuration_UpdatesRemainingTimeWhenIdle() async {
        let iterations = 20
        
        for _ in 0..<iterations {
            let manager = TimerManager()
            let randomDuration = TimeInterval.random(in: 60...14400)
            
            manager.setDuration(randomDuration)
            
            XCTAssertEqual(manager.selectedDuration, randomDuration)
            XCTAssertEqual(manager.remainingTime, randomDuration,
                           "Remaining time should update when setting duration in idle state")
        }
    }
    
    /// **Validates: Requirements 1.1**
    ///
    /// Property: Setting duration does NOT update remainingTime when running or paused.
    @MainActor
    func testSetDuration_DoesNotUpdateRemainingTimeWhenActive() async {
        let manager = TimerManager(duration: 3600)
        manager.start()
        
        let originalRemaining = manager.remainingTime
        manager.setDuration(7200)
        
        XCTAssertEqual(manager.selectedDuration, 7200,
                       "Selected duration should update")
        XCTAssertEqual(manager.remainingTime, originalRemaining,
                       "Remaining time should NOT update when running")
        
        // Test when paused
        manager.pause()
        let pausedRemaining = manager.remainingTime
        manager.setDuration(10800)
        
        XCTAssertEqual(manager.selectedDuration, 10800)
        XCTAssertEqual(manager.remainingTime, pausedRemaining,
                       "Remaining time should NOT update when paused")
    }
    
    // MARK: - Property: Time Bounds
    
    /// **Validates: Requirements 1.2**
    ///
    /// Property: Remaining time is always within valid bounds [0, selectedDuration].
    @MainActor
    func testRemainingTimeBounds_RandomActions() async {
        let iterations = 50
        
        for _ in 0..<iterations {
            let duration = TimeInterval.random(in: 60...14400)
            let manager = TimerManager(duration: duration)
            
            let actions = generateRandomActionSequence(length: Int.random(in: 1...20))
            
            for action in actions {
                action.apply(to: manager)
                
                XCTAssertGreaterThanOrEqual(manager.remainingTime, 0,
                                             "Remaining time should never be negative")
                XCTAssertLessThanOrEqual(manager.remainingTime, manager.selectedDuration,
                                          "Remaining time should never exceed selected duration")
            }
        }
    }
    
    // MARK: - Property: Transition Validity Matrix
    
    /// **Validates: Requirements 1.2**
    ///
    /// Property: The transition validity function correctly identifies all valid and invalid transitions.
    func testTransitionValidityMatrix() {
        // Valid transitions
        let validTransitions: [(TimerState, TimerState)] = [
            (.idle, .running),
            (.running, .paused),
            (.running, .idle),
            (.running, .completed),
            (.paused, .running),
            (.paused, .idle),
            (.completed, .idle)
        ]
        
        for (from, to) in validTransitions {
            XCTAssertTrue(TimerManager.isValidTransition(from: from, to: to),
                          "Transition from \(from) to \(to) should be valid")
        }
        
        // Invalid transitions (all other combinations)
        let allStates = TimerState.allCases
        for from in allStates {
            for to in allStates {
                let shouldBeValid = validTransitions.contains { $0.0 == from && $0.1 == to }
                let isValid = TimerManager.isValidTransition(from: from, to: to)
                
                if shouldBeValid {
                    XCTAssertTrue(isValid, "Transition from \(from) to \(to) should be valid")
                } else {
                    XCTAssertFalse(isValid, "Transition from \(from) to \(to) should be invalid")
                }
            }
        }
    }
    
    // MARK: - Property: Valid Transitions Function
    
    /// **Validates: Requirements 1.2**
    ///
    /// Property: The validTransitions function returns correct target states for each state.
    func testValidTransitionsFunction() {
        XCTAssertEqual(TimerManager.validTransitions(from: .idle), [.running])
        XCTAssertEqual(Set(TimerManager.validTransitions(from: .running)), Set([.paused, .idle, .completed]))
        XCTAssertEqual(Set(TimerManager.validTransitions(from: .paused)), Set([.running, .idle]))
        XCTAssertEqual(TimerManager.validTransitions(from: .completed), [.idle])
    }
    
    // MARK: - Time Formatting Tests
    
    /// Tests that time formatting produces correct HH:MM:SS format.
    func testTimeFormatting() {
        XCTAssertEqual(TimerManager.formatTime(0), "00:00:00")
        XCTAssertEqual(TimerManager.formatTime(59), "00:00:59")
        XCTAssertEqual(TimerManager.formatTime(60), "00:01:00")
        XCTAssertEqual(TimerManager.formatTime(3599), "00:59:59")
        XCTAssertEqual(TimerManager.formatTime(3600), "01:00:00")
        XCTAssertEqual(TimerManager.formatTime(3661), "01:01:01")
        XCTAssertEqual(TimerManager.formatTime(14400), "04:00:00")
    }
    
    /// Tests digit extraction for flip clock display.
    func testDigitExtraction() {
        let digits1 = TimerManager.extractDigits(0)
        XCTAssertEqual(digits1.0, 0) // hours tens
        XCTAssertEqual(digits1.1, 0) // hours ones
        XCTAssertEqual(digits1.2, 0) // minutes tens
        XCTAssertEqual(digits1.3, 0) // minutes ones
        XCTAssertEqual(digits1.4, 0) // seconds tens
        XCTAssertEqual(digits1.5, 0) // seconds ones
        
        let digits2 = TimerManager.extractDigits(3661) // 1:01:01
        XCTAssertEqual(digits2.0, 0) // hours tens
        XCTAssertEqual(digits2.1, 1) // hours ones
        XCTAssertEqual(digits2.2, 0) // minutes tens
        XCTAssertEqual(digits2.3, 1) // minutes ones
        XCTAssertEqual(digits2.4, 0) // seconds tens
        XCTAssertEqual(digits2.5, 1) // seconds ones
        
        let digits3 = TimerManager.extractDigits(14400) // 4:00:00
        XCTAssertEqual(digits3.0, 0) // hours tens
        XCTAssertEqual(digits3.1, 4) // hours ones
        XCTAssertEqual(digits3.2, 0) // minutes tens
        XCTAssertEqual(digits3.3, 0) // minutes ones
        XCTAssertEqual(digits3.4, 0) // seconds tens
        XCTAssertEqual(digits3.5, 0) // seconds ones
        
        let digits4 = TimerManager.extractDigits(45296) // 12:34:56
        XCTAssertEqual(digits4.0, 1) // hours tens
        XCTAssertEqual(digits4.1, 2) // hours ones
        XCTAssertEqual(digits4.2, 3) // minutes tens
        XCTAssertEqual(digits4.3, 4) // minutes ones
        XCTAssertEqual(digits4.4, 5) // seconds tens
        XCTAssertEqual(digits4.5, 6) // seconds ones
    }
    
    /// **Validates: Requirements 1.2**
    ///
    /// Property: Time formatting is consistent for random time values.
    func testTimeFormatting_RandomValues() {
        let iterations = 100
        
        for _ in 0..<iterations {
            let time = TimeInterval.random(in: 0...14400)
            let formatted = TimerManager.formatTime(time)
            
            // Verify format is HH:MM:SS
            let components = formatted.split(separator: ":")
            XCTAssertEqual(components.count, 3, "Format should have 3 components")
            
            for component in components {
                XCTAssertEqual(component.count, 2, "Each component should have 2 digits")
                XCTAssertNotNil(Int(component), "Each component should be a valid integer")
            }
            
            // Verify values are within bounds
            if let hours = Int(components[0]),
               let minutes = Int(components[1]),
               let seconds = Int(components[2]) {
                XCTAssertGreaterThanOrEqual(hours, 0)
                XCTAssertLessThanOrEqual(hours, 99)
                XCTAssertGreaterThanOrEqual(minutes, 0)
                XCTAssertLessThan(minutes, 60)
                XCTAssertGreaterThanOrEqual(seconds, 0)
                XCTAssertLessThan(seconds, 60)
            }
        }
    }
    
    // MARK: - Property: Elapsed Time and Progress
    
    /// **Validates: Requirements 1.2**
    ///
    /// Property: Elapsed time and progress are always consistent with remaining time.
    @MainActor
    func testElapsedTimeAndProgress() async {
        let manager = TimerManager(duration: 3600)
        
        // In idle state
        XCTAssertEqual(manager.elapsedTime, 0)
        XCTAssertEqual(manager.progress, 0)
        
        // After starting
        manager.start()
        XCTAssertEqual(manager.elapsedTime, 0)
        XCTAssertEqual(manager.progress, 0)
        
        // Verify progress formula
        let duration = manager.selectedDuration
        let remaining = manager.remainingTime
        let expectedProgress = 1.0 - (remaining / duration)
        XCTAssertEqual(manager.progress, expectedProgress, accuracy: 0.001)
    }
    
    // MARK: - Property: Formatted Time Strings
    
    /// **Validates: Requirements 1.2**
    ///
    /// Property: Formatted time strings are always valid.
    @MainActor
    func testFormattedTimeStrings() async {
        let manager = TimerManager(duration: 7200) // 2 hours
        
        XCTAssertEqual(manager.formattedSelectedDuration, "02:00:00")
        XCTAssertEqual(manager.formattedRemainingTime, "02:00:00")
        
        manager.start()
        // Remaining time should still be formatted correctly
        let formatted = manager.formattedRemainingTime
        XCTAssertTrue(formatted.contains(":"), "Formatted time should contain colons")
    }
}
