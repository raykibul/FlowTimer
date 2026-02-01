//
//  SessionStore.swift
//  FlowTimer
//
//  Manages persistence of flow session history using SwiftData.
//

import Foundation
import SwiftData

/// Manages persistence and retrieval of flow session history.
///
/// SessionStore provides a clean interface for saving, fetching, and aggregating
/// session data using SwiftData for persistence.
///
/// **Validates: Requirements 8.1, 8.3, 8.4**
@MainActor
class SessionStore: ObservableObject {
    
    // MARK: - Properties
    
    /// The SwiftData model container for persistence
    private let modelContainer: ModelContainer
    
    /// The model context for database operations
    private var modelContext: ModelContext {
        modelContainer.mainContext
    }
    
    // MARK: - Initialization
    
    /// Creates a new SessionStore with the default model container.
    ///
    /// - Throws: An error if the model container cannot be created.
    init() throws {
        let schema = Schema([FlowSession.self])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )
        self.modelContainer = try ModelContainer(
            for: schema,
            configurations: [modelConfiguration]
        )
    }
    
    /// Creates a SessionStore with a custom model container.
    ///
    /// This initializer is primarily used for testing with in-memory storage.
    ///
    /// - Parameter container: The model container to use for persistence.
    init(container: ModelContainer) {
        self.modelContainer = container
    }
    
    /// Creates an in-memory SessionStore for testing purposes.
    ///
    /// - Returns: A SessionStore configured with in-memory storage.
    /// - Throws: An error if the model container cannot be created.
    static func inMemory() throws -> SessionStore {
        let schema = Schema([FlowSession.self])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )
        let container = try ModelContainer(
            for: schema,
            configurations: [modelConfiguration]
        )
        return SessionStore(container: container)
    }
    
    // MARK: - Save Operations
    
    /// Saves a flow session to persistent storage.
    ///
    /// **Validates: Requirements 8.1**
    ///
    /// - Parameter session: The session to save.
    func saveSession(_ session: FlowSession) {
        modelContext.insert(session)
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to save session: \(error)")
        }
    }
    
    // MARK: - Fetch Operations
    
    /// Fetches sessions within an optional date range.
    ///
    /// **Validates: Requirements 8.2**
    ///
    /// - Parameters:
    ///   - from: The start date for filtering (inclusive). If nil, no lower bound.
    ///   - to: The end date for filtering (inclusive). If nil, no upper bound.
    /// - Returns: An array of sessions matching the date criteria, sorted by start date descending.
    func fetchSessions(from: Date? = nil, to: Date? = nil) -> [FlowSession] {
        var descriptor = FetchDescriptor<FlowSession>(
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )
        
        // Build predicate based on date range
        if let fromDate = from, let toDate = to {
            descriptor.predicate = #Predicate<FlowSession> { session in
                session.startDate >= fromDate && session.startDate <= toDate
            }
        } else if let fromDate = from {
            descriptor.predicate = #Predicate<FlowSession> { session in
                session.startDate >= fromDate
            }
        } else if let toDate = to {
            descriptor.predicate = #Predicate<FlowSession> { session in
                session.startDate <= toDate
            }
        }
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Failed to fetch sessions: \(error)")
            return []
        }
    }
    
    /// Fetches all sessions from persistent storage.
    ///
    /// - Returns: An array of all sessions, sorted by start date descending.
    func fetchAllSessions() -> [FlowSession] {
        return fetchSessions(from: nil, to: nil)
    }
    
    // MARK: - Aggregation Operations
    
    /// Calculates the total focus time for a given time period.
    ///
    /// **Validates: Requirements 8.3**
    ///
    /// Total focus time is calculated as the sum of `actualDuration` for all
    /// sessions within the specified period.
    ///
    /// - Parameter period: The time period to aggregate.
    /// - Returns: The total focus time in seconds.
    func totalFocusTime(period: TimePeriod) -> TimeInterval {
        let (startDate, endDate) = period.dateRange
        let sessions = fetchSessions(from: startDate, to: endDate)
        
        return sessions.reduce(0) { total, session in
            total + session.actualDuration
        }
    }
    
    /// Calculates the total focus time for sessions within a custom date range.
    ///
    /// - Parameters:
    ///   - from: The start date for filtering (inclusive). If nil, no lower bound.
    ///   - to: The end date for filtering (inclusive). If nil, no upper bound.
    /// - Returns: The total focus time in seconds.
    func totalFocusTime(from: Date? = nil, to: Date? = nil) -> TimeInterval {
        let sessions = fetchSessions(from: from, to: to)
        
        return sessions.reduce(0) { total, session in
            total + session.actualDuration
        }
    }
    
    // MARK: - Delete Operations
    
    /// Deletes a session from persistent storage.
    ///
    /// - Parameter session: The session to delete.
    func deleteSession(_ session: FlowSession) {
        modelContext.delete(session)
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to delete session: \(error)")
        }
    }
    
    /// Deletes all sessions from persistent storage.
    ///
    /// This method is primarily used for testing and resetting data.
    func deleteAllSessions() {
        let sessions = fetchAllSessions()
        for session in sessions {
            modelContext.delete(session)
        }
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to delete all sessions: \(error)")
        }
    }
    
    // MARK: - Statistics
    
    /// Returns the count of sessions within a date range.
    ///
    /// - Parameters:
    ///   - from: The start date for filtering (inclusive). If nil, no lower bound.
    ///   - to: The end date for filtering (inclusive). If nil, no upper bound.
    /// - Returns: The number of sessions matching the criteria.
    func sessionCount(from: Date? = nil, to: Date? = nil) -> Int {
        return fetchSessions(from: from, to: to).count
    }
    
    /// Returns the count of completed sessions within a date range.
    ///
    /// - Parameters:
    ///   - from: The start date for filtering (inclusive). If nil, no lower bound.
    ///   - to: The end date for filtering (inclusive). If nil, no upper bound.
    /// - Returns: The number of completed sessions matching the criteria.
    func completedSessionCount(from: Date? = nil, to: Date? = nil) -> Int {
        return fetchSessions(from: from, to: to).filter { $0.completed }.count
    }
    
    /// Returns statistics for a given time period.
    ///
    /// - Parameter period: The time period to get statistics for.
    /// - Returns: A tuple containing (totalSessions, completedSessions, totalFocusTime).
    func statistics(for period: TimePeriod) -> (total: Int, completed: Int, focusTime: TimeInterval) {
        let (startDate, endDate) = period.dateRange
        let sessions = fetchSessions(from: startDate, to: endDate)
        
        let total = sessions.count
        let completed = sessions.filter { $0.completed }.count
        let focusTime = sessions.reduce(0) { $0 + $1.actualDuration }
        
        return (total, completed, focusTime)
    }
}
