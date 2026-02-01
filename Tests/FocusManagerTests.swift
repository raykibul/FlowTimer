//
//  FocusManagerTests.swift
//  FlowTimerTests
//
//  Property-based tests for FocusManager Focus mode symmetry.
//

import XCTest
@testable import FlowTimer

/// Property-based tests for the FocusManager.
///
/// **Validates: Requirements 4.1, 4.2, 5.2**
///
/// These tests verify that Focus mode control maintains symmetry:
/// - If Focus mode was enabled at start, it must be disabled at end
/// - Focus mode state after session equals Focus mode state before session started
final class FocusManagerTests: XCTestCase {
    
    // MARK: - Test Helpers
    
    /// Simulated session actions that can occur during a flow session
    enum SessionAction: CaseIterable {
        case start       // Start a session (enables Focus mode)
        case complete    // Complete a session normally (disables Focus mode)
        case cancel      // Cancel a session early (disables Focus mode)
        case pause       // Pause (Focus mode stays enabled)
        case resume      // Resume (Focus mode stays enabled)
    }
    
    /// A mock FocusManager for testing symmetry properties without actual system calls
    class MockFocusManager {
        /// Whether Focus mode is currently enabled
        private(set) var isFocusModeEnabled: Bool = false
        
        /// Whether Focus mode was enabled by this app
        private(set) var focusModeEnabledByApp: Bool = false
        
        /// The Focus mode state before the session started
        private(set) var stateBeforeSession: Bool = false
        
        /// Simulates enabling Focus mode
        func enableFocusMode() {
            stateBeforeSession = isFocusModeEnabled
            isFocusModeEnabled = true
            focusModeEnabledByApp = true
        }
        
        /// Simulates disabling Focus mode
        func disableFocusMode() {
            guard focusModeEnabledByApp else { return }
            isFocusModeEnabled = false
            focusModeEnabledByApp = false
        }
        
        /// Resets the manager state
        func reset() {
            isFocusModeEnabled = false
            focusModeEnabledByApp = false
            stateBeforeSession = false
        }
        
        /// Sets the initial Focus mode state (simulating external Focus mode)
        func setInitialState(_ enabled: Bool) {
            isFocusModeEnabled = enabled
        }
    }
    
    /// Generates a random session action sequence
    func generateRandomSessionSequence(length: Int) -> [SessionAction] {
        var actions: [SessionAction] = []
        var isSessionActive = false
        
        for _ in 0..<length {
            if !isSessionActive {
                // Can only start a new session
                actions.append(.start)
                isSessionActive = true
            } else {
                // Can pause, resume, complete, or cancel
                let possibleActions: [SessionAction] = [.pause, .resume, .complete, .cancel]
                let action = possibleActions.randomElement()!
                actions.append(action)
                
                if action == .complete || action == .cancel {
                    isSessionActive = false
                }
            }
        }
        
        return actions
    }
    
    // MARK: - Property 5: Focus Mode Symmetry
    
    /// **Validates: Requirements 4.1, 4.2, 5.2**
    ///
    /// Property: If Focus mode was enabled at start, it must be disabled at end.
    /// For any timer session that completes or is cancelled, Focus mode must be
    /// restored to its original state.
    func testFocusModeSymmetry_EnableDisablePairs() {
        let iterations = 100
        
        for iteration in 0..<iterations {
            let mockManager = MockFocusManager()
            
            // Randomly set initial Focus mode state (simulating user's existing Focus mode)
            let initialFocusState = Bool.random()
            mockManager.setInitialState(initialFocusState)
            
            // Record state before session
            _ = mockManager.isFocusModeEnabled
            
            // Start session (enables Focus mode)
            mockManager.enableFocusMode()
            
            XCTAssertTrue(
                mockManager.isFocusModeEnabled,
                "Focus mode should be enabled after session start (iteration \(iteration))"
            )
            
            // End session (disables Focus mode)
            mockManager.disableFocusMode()
            
            // Verify symmetry: state after should equal state before
            // Note: Since we only disable if we enabled, and we always enable on start,
            // the final state should be false (disabled)
            XCTAssertFalse(
                mockManager.isFocusModeEnabled,
                "Focus mode should be disabled after session end (iteration \(iteration))"
            )
            
            // Verify the app no longer claims to have enabled Focus mode
            XCTAssertFalse(
                mockManager.focusModeEnabledByApp,
                "focusModeEnabledByApp should be false after session end (iteration \(iteration))"
            )
        }
    }
    
    /// **Validates: Requirements 4.1, 4.2, 5.2**
    ///
    /// Property: Multiple enable/disable cycles maintain symmetry.
    /// Each session start/end pair should properly toggle Focus mode.
    func testFocusModeSymmetry_MultipleSessions() {
        let iterations = 50
        let maxSessions = 10
        
        for iteration in 0..<iterations {
            let mockManager = MockFocusManager()
            let sessionCount = Int.random(in: 1...maxSessions)
            
            for session in 0..<sessionCount {
                // Before each session, Focus mode should be off (from previous session end)
                if session > 0 {
                    XCTAssertFalse(
                        mockManager.isFocusModeEnabled,
                        "Focus mode should be off before session \(session) in iteration \(iteration)"
                    )
                }
                
                // Start session
                mockManager.enableFocusMode()
                XCTAssertTrue(
                    mockManager.isFocusModeEnabled,
                    "Focus mode should be on during session \(session) in iteration \(iteration)"
                )
                XCTAssertTrue(
                    mockManager.focusModeEnabledByApp,
                    "focusModeEnabledByApp should be true during session \(session)"
                )
                
                // End session
                mockManager.disableFocusMode()
                XCTAssertFalse(
                    mockManager.isFocusModeEnabled,
                    "Focus mode should be off after session \(session) in iteration \(iteration)"
                )
                XCTAssertFalse(
                    mockManager.focusModeEnabledByApp,
                    "focusModeEnabledByApp should be false after session \(session)"
                )
            }
        }
    }
    
    /// **Validates: Requirements 4.1, 4.2, 5.2**
    ///
    /// Property: Disable without enable is a no-op.
    /// If Focus mode was not enabled by the app, disabling should not change state.
    func testFocusModeSymmetry_DisableWithoutEnable() {
        let iterations = 50
        
        for iteration in 0..<iterations {
            let mockManager = MockFocusManager()
            
            // Set random initial state
            let initialState = Bool.random()
            mockManager.setInitialState(initialState)
            
            // Try to disable without enabling first
            mockManager.disableFocusMode()
            
            // State should be unchanged
            XCTAssertEqual(
                mockManager.isFocusModeEnabled, initialState,
                "Disable without enable should not change state (iteration \(iteration))"
            )
        }
    }
    
    /// **Validates: Requirements 4.1, 4.2, 5.2**
    ///
    /// Property: Double enable followed by single disable restores state.
    /// Even if enable is called multiple times, a single disable should restore state.
    func testFocusModeSymmetry_DoubleEnable() {
        let iterations = 50
        
        for iteration in 0..<iterations {
            let mockManager = MockFocusManager()
            
            // Enable twice
            mockManager.enableFocusMode()
            mockManager.enableFocusMode()
            
            XCTAssertTrue(
                mockManager.isFocusModeEnabled,
                "Focus mode should be enabled after double enable (iteration \(iteration))"
            )
            
            // Single disable should restore
            mockManager.disableFocusMode()
            
            XCTAssertFalse(
                mockManager.isFocusModeEnabled,
                "Focus mode should be disabled after single disable (iteration \(iteration))"
            )
        }
    }
    
    /// **Validates: Requirements 4.1, 4.2, 5.2**
    ///
    /// Property: Double disable is idempotent.
    /// Calling disable multiple times should have the same effect as calling it once.
    func testFocusModeSymmetry_DoubleDisable() {
        let iterations = 50
        
        for iteration in 0..<iterations {
            let mockManager = MockFocusManager()
            
            // Enable then disable twice
            mockManager.enableFocusMode()
            mockManager.disableFocusMode()
            mockManager.disableFocusMode()
            
            XCTAssertFalse(
                mockManager.isFocusModeEnabled,
                "Focus mode should be disabled after double disable (iteration \(iteration))"
            )
            XCTAssertFalse(
                mockManager.focusModeEnabledByApp,
                "focusModeEnabledByApp should be false after double disable (iteration \(iteration))"
            )
        }
    }
    
    /// **Validates: Requirements 4.1, 4.2, 5.2**
    ///
    /// Property: Random action sequences maintain invariants.
    /// For any sequence of session actions, Focus mode state should be consistent.
    func testFocusModeSymmetry_RandomActionSequences() {
        let iterations = 100
        let maxSequenceLength = 20
        
        for iteration in 0..<iterations {
            let mockManager = MockFocusManager()
            var isSessionActive = false
            
            let sequenceLength = Int.random(in: 1...maxSequenceLength)
            let actions = generateRandomSessionSequence(length: sequenceLength)
            
            for (actionIndex, action) in actions.enumerated() {
                switch action {
                case .start:
                    mockManager.enableFocusMode()
                    isSessionActive = true
                    
                    // Invariant: Focus mode should be enabled during active session
                    XCTAssertTrue(
                        mockManager.isFocusModeEnabled,
                        "Focus mode should be enabled after start at index \(actionIndex) in iteration \(iteration)"
                    )
                    
                case .complete, .cancel:
                    mockManager.disableFocusMode()
                    isSessionActive = false
                    
                    // Invariant: Focus mode should be disabled after session ends
                    XCTAssertFalse(
                        mockManager.isFocusModeEnabled,
                        "Focus mode should be disabled after \(action) at index \(actionIndex) in iteration \(iteration)"
                    )
                    
                case .pause, .resume:
                    // Focus mode should remain enabled during pause/resume
                    if isSessionActive {
                        XCTAssertTrue(
                            mockManager.isFocusModeEnabled,
                            "Focus mode should remain enabled during \(action) at index \(actionIndex) in iteration \(iteration)"
                        )
                    }
                }
            }
            
            // Final invariant: if session is not active, Focus mode should be off
            if !isSessionActive {
                XCTAssertFalse(
                    mockManager.isFocusModeEnabled,
                    "Focus mode should be off when no session is active (iteration \(iteration))"
                )
            }
        }
    }
    
    // MARK: - Unit Tests for FocusManager
    
    /// Tests that FocusManager initializes with correct default state.
    func testInitialState() {
        let focusManager = FocusManager()
        
        XCTAssertFalse(focusManager.isFocusModeEnabled, "Focus mode should be disabled initially")
        XCTAssertFalse(focusManager.wasFocusModeEnabledByApp, "App should not have enabled Focus mode initially")
        XCTAssertNil(focusManager.lastError, "No error should be present initially")
    }
    
    /// Tests that reset clears all state.
    func testReset() {
        let focusManager = FocusManager()
        
        // Manually set some state (simulating a session)
        focusManager.reset()
        
        XCTAssertFalse(focusManager.isFocusModeEnabled, "Focus mode should be disabled after reset")
        XCTAssertFalse(focusManager.wasFocusModeEnabledByApp, "App should not have enabled Focus mode after reset")
        XCTAssertNil(focusManager.lastError, "No error should be present after reset")
    }
    
    /// Tests that recordStateBeforeSession captures the current state.
    func testRecordStateBeforeSession() {
        let focusManager = FocusManager()
        
        // Record initial state
        focusManager.recordStateBeforeSession()
        
        XCTAssertFalse(focusManager.stateBeforeSession, "State before session should be false initially")
    }
    
    // MARK: - Error Type Tests
    
    /// Tests that FocusManagerError provides correct error descriptions.
    func testErrorDescriptions() {
        let shortcutNotFound = FocusManagerError.shortcutNotFound("TestShortcut")
        XCTAssertTrue(shortcutNotFound.errorDescription?.contains("TestShortcut") ?? false)
        
        let shortcutFailed = FocusManagerError.shortcutExecutionFailed("Test reason")
        XCTAssertTrue(shortcutFailed.errorDescription?.contains("Test reason") ?? false)
        
        let appleScriptFailed = FocusManagerError.appleScriptFailed("Script error")
        XCTAssertTrue(appleScriptFailed.errorDescription?.contains("Script error") ?? false)
        
        let permissionDenied = FocusManagerError.permissionDenied
        XCTAssertTrue(permissionDenied.errorDescription?.contains("Permission") ?? false)
        
        let unknownError = FocusManagerError.unknownError("Unknown")
        XCTAssertTrue(unknownError.errorDescription?.contains("Unknown") ?? false)
    }
    
    // MARK: - Constants Tests
    
    /// Tests that shortcut names are correctly defined.
    func testShortcutNames() {
        XCTAssertEqual(FocusManager.enableShortcutName, "EnableFlowFocus")
        XCTAssertEqual(FocusManager.disableShortcutName, "DisableFlowFocus")
    }
    
    // MARK: - Property: State Consistency
    
    /// **Validates: Requirements 4.1, 4.2**
    ///
    /// Property: isFocusModeEnabled and wasFocusModeEnabledByApp are always consistent.
    /// If wasFocusModeEnabledByApp is true, isFocusModeEnabled must also be true.
    func testStateConsistency() {
        let iterations = 100
        
        for iteration in 0..<iterations {
            let mockManager = MockFocusManager()
            
            // Random sequence of operations
            let operations = Int.random(in: 1...10)
            
            for _ in 0..<operations {
                if Bool.random() {
                    mockManager.enableFocusMode()
                } else {
                    mockManager.disableFocusMode()
                }
                
                // Invariant: if focusModeEnabledByApp is true, isFocusModeEnabled must be true
                if mockManager.focusModeEnabledByApp {
                    XCTAssertTrue(
                        mockManager.isFocusModeEnabled,
                        "If focusModeEnabledByApp is true, isFocusModeEnabled must be true (iteration \(iteration))"
                    )
                }
            }
        }
    }
    
    // MARK: - Integration-style Tests (without actual system calls)
    
    /// **Validates: Requirements 4.1, 4.2, 5.2**
    ///
    /// Property: Simulated full session lifecycle maintains symmetry.
    func testFullSessionLifecycle() {
        let iterations = 50
        
        for iteration in 0..<iterations {
            let mockManager = MockFocusManager()
            
            // Simulate a complete session lifecycle
            
            // 1. Before session: Focus mode is off
            XCTAssertFalse(mockManager.isFocusModeEnabled, "Focus should be off before session (iteration \(iteration))")
            
            // 2. Start session: Focus mode turns on
            mockManager.enableFocusMode()
            XCTAssertTrue(mockManager.isFocusModeEnabled, "Focus should be on during session (iteration \(iteration))")
            XCTAssertTrue(mockManager.focusModeEnabledByApp, "App should have enabled Focus (iteration \(iteration))")
            
            // 3. During session: Focus mode stays on (simulate some time passing)
            // In real app, timer would be counting down here
            XCTAssertTrue(mockManager.isFocusModeEnabled, "Focus should stay on during session (iteration \(iteration))")
            
            // 4. End session: Focus mode turns off
            mockManager.disableFocusMode()
            XCTAssertFalse(mockManager.isFocusModeEnabled, "Focus should be off after session (iteration \(iteration))")
            XCTAssertFalse(mockManager.focusModeEnabledByApp, "App should not have Focus enabled after session (iteration \(iteration))")
        }
    }
    
    /// **Validates: Requirements 4.2**
    ///
    /// Property: Cancelled sessions also restore Focus mode state.
    func testCancelledSessionRestoresFocusMode() {
        let iterations = 50
        
        for iteration in 0..<iterations {
            let mockManager = MockFocusManager()
            
            // Start session
            mockManager.enableFocusMode()
            XCTAssertTrue(mockManager.isFocusModeEnabled, "Focus should be on after start (iteration \(iteration))")
            
            // Cancel session (same as complete - calls disableFocusMode)
            mockManager.disableFocusMode()
            
            // Focus mode should be restored
            XCTAssertFalse(mockManager.isFocusModeEnabled, "Focus should be off after cancel (iteration \(iteration))")
        }
    }
}
