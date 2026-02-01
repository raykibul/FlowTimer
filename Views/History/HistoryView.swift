//
//  HistoryView.swift
//  FlowTimer
//
//  Main history view combining session list and statistics summary.
//

import SwiftUI

/// Main history view combining session list and statistics.
///
/// Displays:
/// - Statistics summary (daily, weekly, all-time totals)
/// - List of past sessions
/// - Navigation back to main timer view
///
/// **Validates: Requirements 8.2, 8.3**
struct HistoryView: View {
    /// Binding to control visibility (for navigation back)
    @Binding var showHistory: Bool
    
    /// The session store for fetching data
    @EnvironmentObject var sessionStore: SessionStore
    
    /// Sessions fetched from the store
    @State private var sessions: [FlowSession] = []
    
    /// Statistics for different periods
    @State private var todayStats: PeriodStats = .empty
    @State private var weekStats: PeriodStats = .empty
    @State private var allTimeStats: PeriodStats = .empty
    
    /// Selected filter period
    @State private var filterPeriod: TimePeriod? = nil
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with back button
            header
            
            // Stats summary
            StatsSummaryView(
                todayStats: todayStats,
                weekStats: weekStats,
                allTimeStats: allTimeStats
            )
            .padding(.vertical, 20)
            
            // Filter tabs
            filterTabs
            
            // Divider
            Divider()
                .background(Color.gray.opacity(0.3))
                .padding(.horizontal, 16)
            
            // Sessions list
            SessionListView(
                sessions: filteredSessions,
                onDelete: deleteSession
            )
        }
        .background(backgroundGradient)
        .onAppear {
            loadData()
        }
    }
    
    // MARK: - Header
    
    private var header: some View {
        HStack {
            // Back button
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showHistory = false
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Timer")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(.white.opacity(0.7))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.1))
                )
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            // Title
            Text("Session History")
                .font(.headline)
                .foregroundColor(.white)
            
            Spacer()
            
            // Placeholder for symmetry
            Color.clear
                .frame(width: 80, height: 32)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    // MARK: - Filter Tabs
    
    private var filterTabs: some View {
        HStack(spacing: 12) {
            filterTab(title: "All", period: nil)
            filterTab(title: "Today", period: .today)
            filterTab(title: "This Week", period: .thisWeek)
            
            Spacer()
            
            // Session count
            Text("\(filteredSessions.count) sessions")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    private func filterTab(title: String, period: TimePeriod?) -> some View {
        let isSelected = filterPeriod == period
        
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                filterPeriod = period
            }
        } label: {
            Text(title)
                .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .white : .gray)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isSelected ? Color.white.opacity(0.15) : Color.clear)
                )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Background
    
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.05, green: 0.05, blue: 0.08),
                Color(red: 0.02, green: 0.02, blue: 0.04)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
    
    // MARK: - Computed Properties
    
    private var filteredSessions: [FlowSession] {
        guard let period = filterPeriod else {
            return sessions
        }
        
        let (startDate, endDate) = period.dateRange
        
        return sessions.filter { session in
            if let start = startDate {
                return session.startDate >= start && session.startDate <= endDate
            }
            return session.startDate <= endDate
        }
    }
    
    // MARK: - Data Loading
    
    private func loadData() {
        // Fetch all sessions
        sessions = sessionStore.fetchAllSessions()
        
        // Calculate statistics
        let todayData = sessionStore.statistics(for: .today)
        todayStats = PeriodStats(
            totalSessions: todayData.total,
            completedSessions: todayData.completed,
            totalFocusTime: todayData.focusTime
        )
        
        let weekData = sessionStore.statistics(for: .thisWeek)
        weekStats = PeriodStats(
            totalSessions: weekData.total,
            completedSessions: weekData.completed,
            totalFocusTime: weekData.focusTime
        )
        
        let allTimeData = sessionStore.statistics(for: .allTime)
        allTimeStats = PeriodStats(
            totalSessions: allTimeData.total,
            completedSessions: allTimeData.completed,
            totalFocusTime: allTimeData.focusTime
        )
    }
    
    private func deleteSession(_ session: FlowSession) {
        sessionStore.deleteSession(session)
        loadData() // Refresh data
    }
}

// MARK: - Standalone History View (for separate window)

/// A standalone history view that can be used in a separate window.
struct StandaloneHistoryView: View {
    @EnvironmentObject var sessionStore: SessionStore
    
    @State private var sessions: [FlowSession] = []
    @State private var todayStats: PeriodStats = .empty
    @State private var weekStats: PeriodStats = .empty
    @State private var allTimeStats: PeriodStats = .empty
    @State private var filterPeriod: TimePeriod? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Session History")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            
            // Stats summary
            StatsSummaryView(
                todayStats: todayStats,
                weekStats: weekStats,
                allTimeStats: allTimeStats
            )
            .padding(.vertical, 16)
            
            Divider()
                .background(Color.gray.opacity(0.3))
                .padding(.horizontal, 16)
            
            // Sessions list
            SessionListView(
                sessions: sessions,
                onDelete: deleteSession
            )
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.08),
                    Color(red: 0.02, green: 0.02, blue: 0.04)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .onAppear {
            loadData()
        }
    }
    
    private func loadData() {
        sessions = sessionStore.fetchAllSessions()
        
        let todayData = sessionStore.statistics(for: .today)
        todayStats = PeriodStats(
            totalSessions: todayData.total,
            completedSessions: todayData.completed,
            totalFocusTime: todayData.focusTime
        )
        
        let weekData = sessionStore.statistics(for: .thisWeek)
        weekStats = PeriodStats(
            totalSessions: weekData.total,
            completedSessions: weekData.completed,
            totalFocusTime: weekData.focusTime
        )
        
        let allTimeData = sessionStore.statistics(for: .allTime)
        allTimeStats = PeriodStats(
            totalSessions: allTimeData.total,
            completedSessions: allTimeData.completed,
            totalFocusTime: allTimeData.focusTime
        )
    }
    
    private func deleteSession(_ session: FlowSession) {
        sessionStore.deleteSession(session)
        loadData()
    }
}

// MARK: - Preview

#Preview("History View") {
    struct PreviewWrapper: View {
        @State private var showHistory = true
        
        var body: some View {
            if let store = try? SessionStore.inMemory() {
                HistoryView(showHistory: $showHistory)
                    .environmentObject(store)
                    .frame(width: 800, height: 600)
            }
        }
    }
    
    return PreviewWrapper()
}
