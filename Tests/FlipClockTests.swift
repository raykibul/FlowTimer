//
//  FlipClockTests.swift
//  FlowTimerTests
//
//  Property-based tests for time formatting correctness in the flip clock display.
//

import XCTest
@testable import FlowTimer

/// Property-based tests for time formatting correctness.
///
/// **Validates: Requirements 2.1, 6.2**
///
/// These tests verify that time formatting produces correct HH:MM:SS strings
/// and that the formatting is reversible (round-trip property).
final class FlipClockTests: XCTestCase {
    
    // MARK: - Property 2: Time Formatting Correctness
    
    /// **Validates: Requirements 2.1, 6.2**
    ///
    /// Property: For any time value T in seconds (0 ≤ T ≤ 14400):
    /// - formatTime(T) produces a string in format "HH:MM:SS"
    /// - Parsing the formatted string back yields the original value T
    /// - Hours = T / 3600, Minutes = (T % 3600) / 60, Seconds = T % 60
    func testTimeFormattingCorrectness_Property() {
        // Test all values in the valid range (0 to 14400 seconds = 4 hours)
        // This is a comprehensive property test covering the entire input space
        let maxTime = 14400 // 4 hours in seconds
        
        for time in 0...maxTime {
            let timeInterval = TimeInterval(time)
            
            // Get the formatted string
            let formatted = TimerManager.formatTime(timeInterval)
            
            // Property 1: Format is HH:MM:SS
            assertValidFormat(formatted, forTime: time)
            
            // Property 2: Round-trip - parsing back yields original value
            assertRoundTrip(formatted, originalTime: time)
            
            // Property 3: Component calculation is correct
            assertCorrectComponents(formatted, forTime: time)
        }
    }
    
    /// **Validates: Requirements 2.1, 6.2**
    ///
    /// Property: Random sampling of time values produces valid formatted strings.
    func testTimeFormattingCorrectness_RandomSampling() {
        let iterations = 1000
        
        for _ in 0..<iterations {
            // Generate random time in valid range [0, 14400]
            let time = Int.random(in: 0...14400)
            let timeInterval = TimeInterval(time)
            
            let formatted = TimerManager.formatTime(timeInterval)
            
            // Verify all properties
            assertValidFormat(formatted, forTime: time)
            assertRoundTrip(formatted, originalTime: time)
            assertCorrectComponents(formatted, forTime: time)
        }
    }
    
    /// **Validates: Requirements 2.1, 6.2**
    ///
    /// Property: Digit extraction produces valid digits (0-9) for all time values.
    func testDigitExtraction_Property() {
        let maxTime = 14400
        
        for time in 0...maxTime {
            let timeInterval = TimeInterval(time)
            let digits = TimerManager.extractDigits(timeInterval)
            
            // All digits should be in range [0, 9]
            XCTAssertTrue((0...9).contains(digits.0), "Hours tens digit should be 0-9, got \(digits.0) for time \(time)")
            XCTAssertTrue((0...9).contains(digits.1), "Hours ones digit should be 0-9, got \(digits.1) for time \(time)")
            XCTAssertTrue((0...9).contains(digits.2), "Minutes tens digit should be 0-9, got \(digits.2) for time \(time)")
            XCTAssertTrue((0...9).contains(digits.3), "Minutes ones digit should be 0-9, got \(digits.3) for time \(time)")
            XCTAssertTrue((0...9).contains(digits.4), "Seconds tens digit should be 0-9, got \(digits.4) for time \(time)")
            XCTAssertTrue((0...9).contains(digits.5), "Seconds ones digit should be 0-9, got \(digits.5) for time \(time)")
            
            // Minutes tens should be 0-5 (0-59 minutes)
            XCTAssertTrue((0...5).contains(digits.2), "Minutes tens should be 0-5, got \(digits.2) for time \(time)")
            
            // Seconds tens should be 0-5 (0-59 seconds)
            XCTAssertTrue((0...5).contains(digits.4), "Seconds tens should be 0-5, got \(digits.4) for time \(time)")
        }
    }
    
    /// **Validates: Requirements 2.1, 6.2**
    ///
    /// Property: Digit extraction is consistent with formatTime.
    func testDigitExtractionConsistency_Property() {
        let iterations = 1000
        
        for _ in 0..<iterations {
            let time = Int.random(in: 0...14400)
            let timeInterval = TimeInterval(time)
            
            let formatted = TimerManager.formatTime(timeInterval)
            let digits = TimerManager.extractDigits(timeInterval)
            
            // Extract digits from formatted string
            let components = formatted.split(separator: ":")
            let hoursStr = String(components[0])
            let minutesStr = String(components[1])
            let secondsStr = String(components[2])
            
            // Verify consistency
            let expectedHoursTens = Int(String(hoursStr.first!))!
            let expectedHoursOnes = Int(String(hoursStr.last!))!
            let expectedMinutesTens = Int(String(minutesStr.first!))!
            let expectedMinutesOnes = Int(String(minutesStr.last!))!
            let expectedSecondsTens = Int(String(secondsStr.first!))!
            let expectedSecondsOnes = Int(String(secondsStr.last!))!
            
            XCTAssertEqual(digits.0, expectedHoursTens, "Hours tens mismatch for time \(time)")
            XCTAssertEqual(digits.1, expectedHoursOnes, "Hours ones mismatch for time \(time)")
            XCTAssertEqual(digits.2, expectedMinutesTens, "Minutes tens mismatch for time \(time)")
            XCTAssertEqual(digits.3, expectedMinutesOnes, "Minutes ones mismatch for time \(time)")
            XCTAssertEqual(digits.4, expectedSecondsTens, "Seconds tens mismatch for time \(time)")
            XCTAssertEqual(digits.5, expectedSecondsOnes, "Seconds ones mismatch for time \(time)")
        }
    }
    
    /// **Validates: Requirements 2.1, 6.2**
    ///
    /// Property: Negative time values are handled gracefully (clamped to 0).
    func testNegativeTimeHandling_Property() {
        let negativeValues = [-1, -60, -3600, -14400, Int.min]
        
        for negativeTime in negativeValues {
            let timeInterval = TimeInterval(negativeTime)
            
            let formatted = TimerManager.formatTime(timeInterval)
            let digits = TimerManager.extractDigits(timeInterval)
            
            // Should be formatted as 00:00:00
            XCTAssertEqual(formatted, "00:00:00", "Negative time \(negativeTime) should format as 00:00:00")
            
            // All digits should be 0
            XCTAssertEqual(digits.0, 0)
            XCTAssertEqual(digits.1, 0)
            XCTAssertEqual(digits.2, 0)
            XCTAssertEqual(digits.3, 0)
            XCTAssertEqual(digits.4, 0)
            XCTAssertEqual(digits.5, 0)
        }
    }
    
    /// **Validates: Requirements 2.1, 6.2**
    ///
    /// Property: Time values beyond 4 hours are formatted correctly (extended range).
    func testExtendedTimeRange_Property() {
        // Test values beyond the typical 4-hour range
        let extendedValues = [14401, 36000, 86400, 359999] // Up to 99:59:59
        
        for time in extendedValues {
            let timeInterval = TimeInterval(time)
            let formatted = TimerManager.formatTime(timeInterval)
            
            // Should still produce valid HH:MM:SS format
            assertValidFormat(formatted, forTime: time)
            assertRoundTrip(formatted, originalTime: time)
        }
    }
    
    /// **Validates: Requirements 2.1, 6.2**
    ///
    /// Property: Boundary values are handled correctly.
    func testBoundaryValues() {
        // Test specific boundary values
        let boundaryTests: [(Int, String)] = [
            (0, "00:00:00"),           // Minimum
            (1, "00:00:01"),           // One second
            (59, "00:00:59"),          // 59 seconds
            (60, "00:01:00"),          // One minute
            (61, "00:01:01"),          // One minute one second
            (3599, "00:59:59"),        // 59 minutes 59 seconds
            (3600, "01:00:00"),        // One hour
            (3601, "01:00:01"),        // One hour one second
            (3660, "01:01:00"),        // One hour one minute
            (3661, "01:01:01"),        // One hour one minute one second
            (7199, "01:59:59"),        // One hour 59 minutes 59 seconds
            (7200, "02:00:00"),        // Two hours
            (14399, "03:59:59"),       // 3 hours 59 minutes 59 seconds
            (14400, "04:00:00"),       // Four hours (max preset)
        ]
        
        for (time, expected) in boundaryTests {
            let formatted = TimerManager.formatTime(TimeInterval(time))
            XCTAssertEqual(formatted, expected, "Time \(time) should format as \(expected)")
        }
    }
    
    /// **Validates: Requirements 2.1, 6.2**
    ///
    /// Property: Monotonicity - incrementing time by 1 second changes exactly one digit
    /// (or causes a cascade of changes at boundaries).
    func testMonotonicity_Property() {
        for time in 0..<14400 {
            let current = TimerManager.extractDigits(TimeInterval(time))
            let next = TimerManager.extractDigits(TimeInterval(time + 1))
            
            // At least one digit should change
            let changed = (current.0 != next.0) || (current.1 != next.1) ||
                          (current.2 != next.2) || (current.3 != next.3) ||
                          (current.4 != next.4) || (current.5 != next.5)
            
            XCTAssertTrue(changed, "At least one digit should change from time \(time) to \(time + 1)")
            
            // Seconds ones should always change (or wrap)
            // When seconds ones wraps from 9 to 0, seconds tens should change
            // And so on up the chain
            if current.5 < 9 {
                XCTAssertEqual(next.5, current.5 + 1, "Seconds ones should increment from \(current.5) to \(current.5 + 1) at time \(time)")
            } else {
                XCTAssertEqual(next.5, 0, "Seconds ones should wrap to 0 at time \(time)")
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Asserts that the formatted string is in valid HH:MM:SS format.
    private func assertValidFormat(_ formatted: String, forTime time: Int) {
        // Check overall format
        let components = formatted.split(separator: ":")
        XCTAssertEqual(components.count, 3, "Format should have 3 components for time \(time), got: \(formatted)")
        
        // Check each component has exactly 2 digits
        for (index, component) in components.enumerated() {
            XCTAssertEqual(component.count, 2, "Component \(index) should have 2 digits for time \(time), got: \(component)")
            XCTAssertNotNil(Int(component), "Component \(index) should be a valid integer for time \(time), got: \(component)")
        }
        
        // Check component ranges
        if let hours = Int(components[0]),
           let minutes = Int(components[1]),
           let seconds = Int(components[2]) {
            XCTAssertGreaterThanOrEqual(hours, 0, "Hours should be >= 0 for time \(time)")
            XCTAssertLessThanOrEqual(hours, 99, "Hours should be <= 99 for time \(time)")
            XCTAssertGreaterThanOrEqual(minutes, 0, "Minutes should be >= 0 for time \(time)")
            XCTAssertLessThan(minutes, 60, "Minutes should be < 60 for time \(time)")
            XCTAssertGreaterThanOrEqual(seconds, 0, "Seconds should be >= 0 for time \(time)")
            XCTAssertLessThan(seconds, 60, "Seconds should be < 60 for time \(time)")
        }
    }
    
    /// Asserts that parsing the formatted string back yields the original time.
    private func assertRoundTrip(_ formatted: String, originalTime time: Int) {
        let components = formatted.split(separator: ":")
        guard components.count == 3,
              let hours = Int(components[0]),
              let minutes = Int(components[1]),
              let seconds = Int(components[2]) else {
            XCTFail("Failed to parse formatted string: \(formatted)")
            return
        }
        
        let reconstructed = hours * 3600 + minutes * 60 + seconds
        XCTAssertEqual(reconstructed, time, "Round-trip failed: \(time) -> \(formatted) -> \(reconstructed)")
    }
    
    /// Asserts that the formatted components match the expected calculation.
    private func assertCorrectComponents(_ formatted: String, forTime time: Int) {
        let expectedHours = time / 3600
        let expectedMinutes = (time % 3600) / 60
        let expectedSeconds = time % 60
        
        let components = formatted.split(separator: ":")
        guard components.count == 3,
              let hours = Int(components[0]),
              let minutes = Int(components[1]),
              let seconds = Int(components[2]) else {
            XCTFail("Failed to parse formatted string: \(formatted)")
            return
        }
        
        XCTAssertEqual(hours, expectedHours, "Hours mismatch for time \(time): expected \(expectedHours), got \(hours)")
        XCTAssertEqual(minutes, expectedMinutes, "Minutes mismatch for time \(time): expected \(expectedMinutes), got \(minutes)")
        XCTAssertEqual(seconds, expectedSeconds, "Seconds mismatch for time \(time): expected \(expectedSeconds), got \(seconds)")
    }
    
    // MARK: - Edge Case Tests
    
    /// Tests fractional seconds are handled correctly (truncated to integer).
    func testFractionalSeconds() {
        let fractionalTests: [(TimeInterval, String)] = [
            (0.5, "00:00:00"),
            (0.9, "00:00:00"),
            (1.1, "00:00:01"),
            (59.9, "00:00:59"),
            (60.5, "00:01:00"),
            (3600.999, "01:00:00"),
        ]
        
        for (time, expected) in fractionalTests {
            let formatted = TimerManager.formatTime(time)
            XCTAssertEqual(formatted, expected, "Time \(time) should format as \(expected)")
        }
    }
    
    /// Tests that very large time values don't cause overflow.
    func testLargeTimeValues() {
        // Test values that might cause overflow issues
        let largeValues: [TimeInterval] = [
            359999,     // 99:59:59
            360000,     // 100:00:00 (wraps in 2-digit hours display)
        ]
        
        for time in largeValues {
            // Should not crash
            let formatted = TimerManager.formatTime(time)
            let _ = TimerManager.extractDigits(time)
            
            // Should still be valid format
            let components = formatted.split(separator: ":")
            XCTAssertEqual(components.count, 3, "Large time \(time) should still produce 3 components")
        }
    }
}
