//
//  SessionStoreTests.swift
//  FlowTimerTests
//
//  Property-based tests for SessionStore session history integrity.
//

import XCTest
import SwiftData
@testable import FlowTimer

/// Property-based tests for the SessionStore.
///
/// **Validates: Requirements 8.1, 8.3**
///
/// These tests verify that session history maintains integrity across
/// save, fetch, and aggregation operations.
final class SessionStoreTests: XCTestCase {
    
    // MARK: - Test Helpers
    
    /// Creates an in-memory SessionStore for testing.
    @MainActor
    func createTestStore() throws -> SessionStore {
        return try SessionStore.inMemory()
    }
    
    /// Generates a random FlowSession for testing.
    func generateRandomSession(
        startDate: Date? = nil,
        completed: Bool? = nil
    ) -> FlowSession {
        let start = startDate ?? Date().addingTimeInterval(-TimeInterval.random(in: 0...86400 * 30))
        let duration = TimeInterval.random(in: 1800...14400) // 30 min to 4 hours
        let actualDuration = completed == true ? duration : TimeInterval.random(in: 0...duration)
        let isCompleted = completed ?? Bool.random()
        
        let sounds = AmbientSound.allCases
        let sound = Bool.random() ? sounds.randomElement() : nil
        
        return FlowSession(
            startDate: start,
            duration: duration,
            actualDuration: isCompleted ? duration : actualDuration,
            completed: isCompleted,
            sound: sound
        )
    }
    
    /// Generates multiple random sessions.
    func generateRandomSessions(count: Int) -> [FlowSession] {
        return (0..<count).map { _ in generateRandomSession() }
    }
    
    /// Generates sessions within a specific date range.
    func generateSessionsInRange(
        count: Int,
        from: Date,
        to: Date
    ) -> [FlowSession] {
        return (0..<count).map { _ in
            let randomInterval = TimeInterval.random(in: 0...to.timeIntervalSince(from))
            let startDate = from.addingTimeInterval(randomInterval)
            return generateRandomSession(startDate: startDate)
        }
    }
    
    // MARK: - Property 4: Session History Integrity
    
    /// **Validates: Requirements 8.1**
    ///
    /// Property: For any completed session, the session is persisted with
    /// correct start date, duration, and completion status.
    @MainActor
    func testSessionPersistence_CorrectData() async throws {
        let iterations = 50
        
        for _ in 0..<iterations {
            let store = try createTestStore()
            let session = generateRandomSession()
            
            // Store original values
            let originalId = session.id
            let originalStartDate = session.startDate
            let originalDuration = session.duration
            let originalActualDuration = session.actualDuration
            let originalCompleted = session.completed
            let originalSoundUsed = session.soundUsed
            
            // Save the session
            store.saveSession(session)
            
            // Fetch and verify
            let fetchedSessions = store.fetchAllSessions()
            XCTAssertEqual(fetchedSessions.count, 1, "Should have exactly one session")
            
            guard let fetched = fetchedSessions.first else {
                XCTFail("Failed to fetch saved session")
                continue
            }
            
            // Verify all properties are preserved
            XCTAssertEqual(fetched.id, originalId, "ID should be preserved")
            XCTAssertEqual(fetched.startDate, originalStartDate, "Start date should be preserved")
            XCTAssertEqual(fetched.duration, originalDuration, "Duration should be preserved")
            XCTAssertEqual(fetched.actualDuration, originalActualDuration, "Actual duration should be preserved")
            XCTAssertEqual(fetched.completed, originalCompleted, "Completion status should be preserved")
            XCTAssertEqual(fetched.soundUsed, originalSoundUsed, "Sound used should be preserved")
        }
    }
    
    /// **Validates: Requirements 8.1**
    ///
    /// Property: Multiple sessions can be saved and retrieved correctly.
    @MainActor
    func testMultipleSessionPersistence() async throws {
        let iterations = 20
        
        for iteration in 0..<iterations {
            let store = try createTestStore()
            let sessionCount = Int.random(in: 1...20)
            let sessions = generateRandomSessions(count: sessionCount)
            
            // Save all sessions
            for session in sessions {
                store.saveSession(session)
            }
            
            // Fetch and verify count
            let fetchedSessions = store.fetchAllSessions()
            XCTAssertEqual(
                fetchedSessions.count,
                sessionCount,
                "Should have \(sessionCount) sessions in iteration \(iteration)"
            )
            
            // Verify all session IDs are present
            let originalIds = Set(sessions.map { $0.id })
            let fetchedIds = Set(fetchedSessions.map { $0.id })
            XCTAssertEqual(originalIds, fetchedIds, "All session IDs should be preserved")
        }
    }
    
    /// **Validates: Requirements 8.3**
    ///
    /// Property: Total focus time aggregation equals sum of all session
    /// durations in the period.
    @MainActor
    func testTotalFocusTimeAggregation() async throws {
        let iterations = 30
        
        for _ in 0..<iterations {
            let store = try createTestStore()
            let sessionCount = Int.random(in: 1...15)
            let sessions = generateRandomSessions(count: sessionCount)
            
            // Calculate expected total
            let expectedTotal = sessions.reduce(0) { $0 + $1.actualDuration }
            
            // Save all sessions
            for session in sessions {
                store.saveSession(session)
            }
            
            // Verify aggregation
            let actualTotal = store.totalFocusTime(period: .allTime)
            XCTAssertEqual(
                actualTotal,
                expectedTotal,
                accuracy: 0.001,
                "Total focus time should equal sum of all session durations"
            )
        }
    }
    
    /// **Validates: Requirements 8.3**
    ///
    /// Property: Total focus time with date filtering correctly sums only
    /// sessions within the specified range.
    @MainActor
    func testTotalFocusTimeWithDateFiltering() async throws {
        let iterations = 20
        
        for _ in 0..<iterations {
            let store = try createTestStore()
            
            // Create date ranges
            let now = Date()
            let oneWeekAgo = now.addingTimeInterval(-7 * 24 * 3600)
            let twoWeeksAgo = now.addingTimeInterval(-14 * 24 * 3600)
            
            // Generate sessions in different periods
            let recentSessions = generateSessionsInRange(
                count: Int.random(in: 1...5),
                from: oneWeekAgo,
                to: now
            )
            let olderSessions = generateSessionsInRange(
                count: Int.random(in: 1...5),
                from: twoWeeksAgo,
                to: oneWeekAgo.addingTimeInterval(-1)
            )
            
            // Save all sessions
            for session in recentSessions + olderSessions {
                store.saveSession(session)
            }
            
            // Calculate expected totals
            let expectedRecentTotal = recentSessions.reduce(0) { $0 + $1.actualDuration }
            let expectedOlderTotal = olderSessions.reduce(0) { $0 + $1.actualDuration }
            let expectedAllTotal = expectedRecentTotal + expectedOlderTotal
            
            // Verify filtered aggregation
            let actualRecentTotal = store.totalFocusTime(from: oneWeekAgo, to: now)
            let actualAllTotal = store.totalFocusTime(from: nil, to: nil)
            
            XCTAssertEqual(
                actualRecentTotal,
                expectedRecentTotal,
                accuracy: 0.001,
                "Recent total should match expected"
            )
            XCTAssertEqual(
                actualAllTotal,
                expectedAllTotal,
                accuracy: 0.001,
                "All-time total should match expected"
            )
        }
    }
    
    /// **Validates: Requirements 8.1, 8.3**
    ///
    /// Property: Deleting a session removes it from aggregations.
    @MainActor
    func testDeleteSessionRemovesFromAggregation() async throws {
        let iterations = 30
        
        for _ in 0..<iterations {
            let store = try createTestStore()
            let sessionCount = Int.random(in: 2...10)
            let sessions = generateRandomSessions(count: sessionCount)
            
            // Save all sessions
            for session in sessions {
                store.saveSession(session)
            }
            
            // Verify initial total
            let initialTotal = store.totalFocusTime(period: .allTime)
            let expectedInitialTotal = sessions.reduce(0) { $0 + $1.actualDuration }
            XCTAssertEqual(initialTotal, expectedInitialTotal, accuracy: 0.001)
            
            // Delete a random session
            let indexToDelete = Int.random(in: 0..<sessionCount)
            let sessionToDelete = sessions[indexToDelete]
            let deletedDuration = sessionToDelete.actualDuration
            
            // Fetch the actual persisted session to delete
            let fetchedSessions = store.fetchAllSessions()
            if let sessionInStore = fetchedSessions.first(where: { $0.id == sessionToDelete.id }) {
                store.deleteSession(sessionInStore)
            }
            
            // Verify updated total
            let updatedTotal = store.totalFocusTime(period: .allTime)
            let expectedUpdatedTotal = expectedInitialTotal - deletedDuration
            XCTAssertEqual(
                updatedTotal,
                expectedUpdatedTotal,
                accuracy: 0.001,
                "Total should decrease by deleted session's duration"
            )
            
            // Verify session count decreased
            let remainingSessions = store.fetchAllSessions()
            XCTAssertEqual(
                remainingSessions.count,
                sessionCount - 1,
                "Session count should decrease by 1"
            )
            
            // Verify deleted session is not in results
            let deletedSessionStillExists = remainingSessions.contains { $0.id == sessionToDelete.id }
            XCTAssertFalse(
                deletedSessionStillExists,
                "Deleted session should not be in fetch results"
            )
        }
    }
    
    /// **Validates: Requirements 8.1**
    ///
    /// Property: Deleting all sessions results in empty store and zero aggregation.
    @MainActor
    func testDeleteAllSessions() async throws {
        let iterations = 10
        
        for _ in 0..<iterations {
            let store = try createTestStore()
            let sessionCount = Int.random(in: 1...10)
            let sessions = generateRandomSessions(count: sessionCount)
            
            // Save all sessions
            for session in sessions {
                store.saveSession(session)
            }
            
            // Verify sessions exist
            XCTAssertEqual(store.fetchAllSessions().count, sessionCount)
            XCTAssertGreaterThan(store.totalFocusTime(period: .allTime), 0)
            
            // Delete all sessions
            store.deleteAllSessions()
            
            // Verify empty store
            XCTAssertEqual(store.fetchAllSessions().count, 0, "Store should be empty")
            XCTAssertEqual(
                store.totalFocusTime(period: .allTime),
                0,
                "Total focus time should be 0"
            )
        }
    }
    
    // MARK: - Date Filtering Tests
    
    /// **Validates: Requirements 8.2**
    ///
    /// Property: fetchSessions with date range returns only sessions within range.
    @MainActor
    func testFetchSessionsDateFiltering() async throws {
        let iterations = 20
        
        for _ in 0..<iterations {
            let store = try createTestStore()
            
            let now = Date()
            let oneWeekAgo = now.addingTimeInterval(-7 * 24 * 3600)
            let twoWeeksAgo = now.addingTimeInterval(-14 * 24 * 3600)
            
            // Generate sessions in different periods
            let recentCount = Int.random(in: 1...5)
            let olderCount = Int.random(in: 1...5)
            
            let recentSessions = generateSessionsInRange(
                count: recentCount,
                from: oneWeekAgo,
                to: now
            )
            let olderSessions = generateSessionsInRange(
                count: olderCount,
                from: twoWeeksAgo,
                to: oneWeekAgo.addingTimeInterval(-1)
            )
            
            // Save all sessions
            for session in recentSessions + olderSessions {
                store.saveSession(session)
            }
            
            // Fetch with date filter
            let fetchedRecent = store.fetchSessions(from: oneWeekAgo, to: now)
            
            // Verify count
            XCTAssertEqual(
                fetchedRecent.count,
                recentCount,
                "Should fetch only recent sessions"
            )
            
            // Verify all fetched sessions are within range
            for session in fetchedRecent {
                XCTAssertGreaterThanOrEqual(
                    session.startDate,
                    oneWeekAgo,
                    "Session should be after start date"
                )
                XCTAssertLessThanOrEqual(
                    session.startDate,
                    now,
                    "Session should be before end date"
                )
            }
        }
    }
    
    /// **Validates: Requirements 8.2**
    ///
    /// Property: fetchSessions returns sessions sorted by start date descending.
    @MainActor
    func testFetchSessionsSortOrder() async throws {
        let iterations = 15
        
        for _ in 0..<iterations {
            let store = try createTestStore()
            let sessionCount = Int.random(in: 2...10)
            let sessions = generateRandomSessions(count: sessionCount)
            
            // Save all sessions
            for session in sessions {
                store.saveSession(session)
            }
            
            // Fetch sessions
            let fetchedSessions = store.fetchAllSessions()
            
            // Verify sort order (descending by start date)
            for i in 0..<(fetchedSessions.count - 1) {
                XCTAssertGreaterThanOrEqual(
                    fetchedSessions[i].startDate,
                    fetchedSessions[i + 1].startDate,
                    "Sessions should be sorted by start date descending"
                )
            }
        }
    }
    
    // MARK: - Statistics Tests
    
    /// **Validates: Requirements 8.3**
    ///
    /// Property: Session count matches number of saved sessions.
    @MainActor
    func testSessionCount() async throws {
        let iterations = 20
        
        for _ in 0..<iterations {
            let store = try createTestStore()
            let sessionCount = Int.random(in: 0...15)
            let sessions = generateRandomSessions(count: sessionCount)
            
            // Save all sessions
            for session in sessions {
                store.saveSession(session)
            }
            
            // Verify count
            XCTAssertEqual(
                store.sessionCount(),
                sessionCount,
                "Session count should match saved sessions"
            )
        }
    }
    
    /// **Validates: Requirements 8.3**
    ///
    /// Property: Completed session count matches number of completed sessions.
    @MainActor
    func testCompletedSessionCount() async throws {
        let iterations = 20
        
        for _ in 0..<iterations {
            let store = try createTestStore()
            
            // Generate mix of completed and cancelled sessions
            let completedCount = Int.random(in: 0...5)
            let cancelledCount = Int.random(in: 0...5)
            
            let completedSessions = (0..<completedCount).map { _ in
                generateRandomSession(completed: true)
            }
            let cancelledSessions = (0..<cancelledCount).map { _ in
                generateRandomSession(completed: false)
            }
            
            // Save all sessions
            for session in completedSessions + cancelledSessions {
                store.saveSession(session)
            }
            
            // Verify completed count
            XCTAssertEqual(
                store.completedSessionCount(),
                completedCount,
                "Completed session count should match"
            )
        }
    }
    
    /// **Validates: Requirements 8.3**
    ///
    /// Property: Statistics function returns consistent values.
    @MainActor
    func testStatisticsConsistency() async throws {
        let iterations = 15
        
        for _ in 0..<iterations {
            let store = try createTestStore()
            let sessionCount = Int.random(in: 1...10)
            let sessions = generateRandomSessions(count: sessionCount)
            
            // Save all sessions
            for session in sessions {
                store.saveSession(session)
            }
            
            // Get statistics
            let stats = store.statistics(for: .allTime)
            
            // Verify consistency with individual methods
            XCTAssertEqual(stats.total, store.sessionCount())
            XCTAssertEqual(stats.completed, store.completedSessionCount())
            XCTAssertEqual(stats.focusTime, store.totalFocusTime(period: .allTime), accuracy: 0.001)
        }
    }
    
    // MARK: - Edge Cases
    
    /// Property: Empty store returns empty results and zero aggregations.
    @MainActor
    func testEmptyStore() async throws {
        let store = try createTestStore()
        
        XCTAssertEqual(store.fetchAllSessions().count, 0)
        XCTAssertEqual(store.totalFocusTime(period: .allTime), 0)
        XCTAssertEqual(store.totalFocusTime(period: .today), 0)
        XCTAssertEqual(store.totalFocusTime(period: .thisWeek), 0)
        XCTAssertEqual(store.sessionCount(), 0)
        XCTAssertEqual(store.completedSessionCount(), 0)
        
        let stats = store.statistics(for: .allTime)
        XCTAssertEqual(stats.total, 0)
        XCTAssertEqual(stats.completed, 0)
        XCTAssertEqual(stats.focusTime, 0)
    }
    
    /// Property: Sessions with zero duration are handled correctly.
    @MainActor
    func testZeroDurationSession() async throws {
        let store = try createTestStore()
        
        let session = FlowSession(
            startDate: Date(),
            duration: 3600,
            actualDuration: 0,
            completed: false
        )
        
        store.saveSession(session)
        
        let fetched = store.fetchAllSessions()
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.actualDuration, 0)
        XCTAssertEqual(store.totalFocusTime(period: .allTime), 0)
    }
    
    /// Property: Very long sessions are handled correctly.
    @MainActor
    func testLongDurationSession() async throws {
        let store = try createTestStore()
        
        let longDuration: TimeInterval = 14400 // 4 hours (max preset)
        let session = FlowSession(
            startDate: Date(),
            duration: longDuration,
            actualDuration: longDuration,
            completed: true
        )
        
        store.saveSession(session)
        
        let fetched = store.fetchAllSessions()
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.actualDuration, longDuration)
        XCTAssertEqual(store.totalFocusTime(period: .allTime), longDuration)
    }
    
    /// Property: Sessions at date boundaries are handled correctly.
    @MainActor
    func testDateBoundaries() async throws {
        let store = try createTestStore()
        
        let calendar = Calendar.current
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)
        let endOfYesterday = startOfToday.addingTimeInterval(-1)
        
        // Session exactly at start of today
        let todaySession = FlowSession(
            startDate: startOfToday,
            duration: 3600,
            actualDuration: 3600,
            completed: true
        )
        
        // Session at end of yesterday
        let yesterdaySession = FlowSession(
            startDate: endOfYesterday,
            duration: 3600,
            actualDuration: 1800,
            completed: false
        )
        
        store.saveSession(todaySession)
        store.saveSession(yesterdaySession)
        
        // Fetch today's sessions
        let todaySessions = store.fetchSessions(from: startOfToday, to: now)
        XCTAssertEqual(todaySessions.count, 1)
        XCTAssertEqual(todaySessions.first?.id, todaySession.id)
        
        // Verify today's total
        let todayTotal = store.totalFocusTime(from: startOfToday, to: now)
        XCTAssertEqual(todayTotal, 3600)
    }
}
