//
//  TimePeriod.swift
//  FlowTimer
//
//  Represents time periods for statistics aggregation.
//

import Foundation

/// Represents time periods for aggregating session statistics.
enum TimePeriod: String, CaseIterable, Identifiable, Equatable {
    /// Statistics for the current day
    case today
    
    /// Statistics for the current week (Sunday to Saturday)
    case thisWeek
    
    /// Statistics for all recorded sessions
    case allTime
    
    /// Unique identifier for SwiftUI lists
    var id: String { rawValue }
    
    /// Human-readable display name for the period
    var displayName: String {
        switch self {
        case .today:
            return "Today"
        case .thisWeek:
            return "This Week"
        case .allTime:
            return "All Time"
        }
    }
    
    /// Returns the start date for this time period.
    ///
    /// - Returns: The start date, or nil for allTime (no lower bound)
    var startDate: Date? {
        let calendar = Calendar.current
        let now = Date()
        
        switch self {
        case .today:
            return calendar.startOfDay(for: now)
            
        case .thisWeek:
            // Get the start of the current week (Sunday)
            let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
            return calendar.date(from: components)
            
        case .allTime:
            return nil
        }
    }
    
    /// Returns the end date for this time period.
    ///
    /// - Returns: The end date (typically now or end of current period)
    var endDate: Date {
        return Date()
    }
    
    /// Returns a date range tuple for filtering sessions.
    ///
    /// - Returns: A tuple of (startDate, endDate) where startDate may be nil for allTime
    var dateRange: (start: Date?, end: Date) {
        return (startDate, endDate)
    }
}
