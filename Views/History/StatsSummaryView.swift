//
//  StatsSummaryView.swift
//  FlowTimer
//
//  Displays summary statistics for flow sessions (daily, weekly, all-time).
//

import SwiftUI

/// A view displaying summary statistics for flow sessions.
///
/// Shows total focus time for different time periods:
/// - Today
/// - This Week
/// - All Time
///
/// **Validates: Requirements 8.3**
struct StatsSummaryView: View {
    /// Statistics for today
    let todayStats: PeriodStats
    
    /// Statistics for this week
    let weekStats: PeriodStats
    
    /// Statistics for all time
    let allTimeStats: PeriodStats
    
    /// Currently selected period for detailed view
    @State private var selectedPeriod: TimePeriod = .today
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 20) {
            // Period selector
            periodSelector
            
            // Stats cards
            HStack(spacing: 16) {
                StatCard(
                    title: "Today",
                    stats: todayStats,
                    isSelected: selectedPeriod == .today,
                    accentColor: .blue
                )
                .onTapGesture { selectedPeriod = .today }
                
                StatCard(
                    title: "This Week",
                    stats: weekStats,
                    isSelected: selectedPeriod == .thisWeek,
                    accentColor: .purple
                )
                .onTapGesture { selectedPeriod = .thisWeek }
                
                StatCard(
                    title: "All Time",
                    stats: allTimeStats,
                    isSelected: selectedPeriod == .allTime,
                    accentColor: .green
                )
                .onTapGesture { selectedPeriod = .allTime }
            }
        }
        .padding(.horizontal, 16)
    }
    
    // MARK: - Period Selector
    
    private var periodSelector: some View {
        HStack {
            Text("Focus Statistics")
                .font(.headline)
                .foregroundColor(.white)
            
            Spacer()
        }
    }
}

/// Statistics for a time period.
struct PeriodStats {
    /// Total number of sessions
    let totalSessions: Int
    
    /// Number of completed sessions
    let completedSessions: Int
    
    /// Total focus time in seconds
    let totalFocusTime: TimeInterval
    
    /// Completion rate (0.0 to 1.0)
    var completionRate: Double {
        guard totalSessions > 0 else { return 0 }
        return Double(completedSessions) / Double(totalSessions)
    }
    
    /// Formatted focus time string
    var formattedFocusTime: String {
        let hours = Int(totalFocusTime) / 3600
        let minutes = (Int(totalFocusTime) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes)m"
        } else {
            return "0m"
        }
    }
    
    /// Empty stats
    static let empty = PeriodStats(totalSessions: 0, completedSessions: 0, totalFocusTime: 0)
}

/// A card displaying statistics for a single time period.
struct StatCard: View {
    let title: String
    let stats: PeriodStats
    let isSelected: Bool
    let accentColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.gray)
                .textCase(.uppercase)
            
            // Focus time (main stat)
            Text(stats.formattedFocusTime)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            // Secondary stats
            HStack(spacing: 16) {
                // Sessions count
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(stats.totalSessions)")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))
                    Text("sessions")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                }
                
                // Completion rate
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(Int(stats.completionRate * 100))%")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))
                    Text("completed")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(cardBackground)
    }
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color(white: isSelected ? 0.15 : 0.08))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? accentColor.opacity(0.5) : Color.white.opacity(0.08),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
    }
}

/// A compact inline stats view for smaller spaces.
struct CompactStatsView: View {
    let todayFocusTime: TimeInterval
    let weekFocusTime: TimeInterval
    
    var body: some View {
        HStack(spacing: 24) {
            statItem(label: "Today", time: todayFocusTime)
            
            Divider()
                .frame(height: 24)
                .background(Color.gray.opacity(0.3))
            
            statItem(label: "This Week", time: weekFocusTime)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(white: 0.1))
        )
    }
    
    private func statItem(label: String, time: TimeInterval) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.gray)
                .textCase(.uppercase)
            
            Text(formatTime(time))
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = (Int(time) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Preview

#Preview("Stats Summary") {
    StatsSummaryView(
        todayStats: PeriodStats(totalSessions: 3, completedSessions: 2, totalFocusTime: 5400),
        weekStats: PeriodStats(totalSessions: 12, completedSessions: 10, totalFocusTime: 28800),
        allTimeStats: PeriodStats(totalSessions: 45, completedSessions: 38, totalFocusTime: 162000)
    )
    .background(Color.black)
    .padding()
}

#Preview("Empty Stats") {
    StatsSummaryView(
        todayStats: .empty,
        weekStats: .empty,
        allTimeStats: .empty
    )
    .background(Color.black)
    .padding()
}

#Preview("Compact Stats") {
    CompactStatsView(
        todayFocusTime: 5400,
        weekFocusTime: 28800
    )
    .background(Color.black)
    .padding()
}
