//
//  SessionListView.swift
//  FlowTimer
//
//  Displays a list of past flow sessions with details.
//

import SwiftUI

/// A view displaying a list of past flow sessions.
///
/// Shows session history with date, duration, completion status,
/// and ambient sound used. Sessions are sorted by date (most recent first).
///
/// **Validates: Requirements 8.2**
struct SessionListView: View {
    /// The sessions to display
    let sessions: [FlowSession]
    
    /// Callback when a session is deleted
    var onDelete: ((FlowSession) -> Void)?
    
    // MARK: - Body
    
    var body: some View {
        if sessions.isEmpty {
            emptyStateView
        } else {
            sessionsList
        }
    }
    
    // MARK: - Sessions List
    
    private var sessionsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(sessions, id: \.id) { session in
                    SessionRowView(session: session)
                        .contextMenu {
                            Button(role: .destructive) {
                                onDelete?(session)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.badge.questionmark")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(.gray.opacity(0.5))
            
            Text("No Sessions Yet")
                .font(.headline)
                .foregroundColor(.gray)
            
            Text("Complete a flow session to see it here")
                .font(.subheadline)
                .foregroundColor(.gray.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

/// A single row displaying session details.
struct SessionRowView: View {
    let session: FlowSession
    
    // MARK: - Date Formatter
    
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
    
    // MARK: - Body
    
    var body: some View {
        HStack(spacing: 16) {
            // Status indicator
            statusIndicator
            
            // Session details
            VStack(alignment: .leading, spacing: 4) {
                // Date and time
                Text(Self.dateFormatter.string(from: session.startDate))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                
                // Duration info
                HStack(spacing: 8) {
                    Text(session.formattedDuration)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    
                    if !session.completed {
                        Text("of \(formatDuration(session.duration))")
                            .font(.system(size: 12))
                            .foregroundColor(.gray.opacity(0.7))
                    }
                }
            }
            
            Spacer()
            
            // Sound used (if any)
            if let sound = session.ambientSound {
                HStack(spacing: 4) {
                    Image(systemName: sound.iconName)
                        .font(.system(size: 12))
                    Text(sound.displayName)
                        .font(.system(size: 11))
                }
                .foregroundColor(.gray.opacity(0.7))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.05))
                )
            }
            
            // Completion badge
            completionBadge
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(rowBackground)
    }
    
    // MARK: - Subviews
    
    private var statusIndicator: some View {
        Circle()
            .fill(session.completed ? Color.green : Color.orange)
            .frame(width: 10, height: 10)
    }
    
    private var completionBadge: some View {
        Text(session.completed ? "Completed" : "Cancelled")
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(session.completed ? .green : .orange)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(session.completed ? Color.green.opacity(0.15) : Color.orange.opacity(0.15))
            )
    }
    
    private var rowBackground: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(Color(white: 0.1))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
    }
    
    // MARK: - Helpers
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Preview

#Preview("With Sessions") {
    let sessions = [
        FlowSession(
            startDate: Date(),
            duration: 3600,
            actualDuration: 3600,
            completed: true,
            sound: .rain
        ),
        FlowSession(
            startDate: Date().addingTimeInterval(-86400),
            duration: 7200,
            actualDuration: 5400,
            completed: false,
            sound: .forest
        ),
        FlowSession(
            startDate: Date().addingTimeInterval(-172800),
            duration: 1800,
            actualDuration: 1800,
            completed: true,
            sound: nil
        )
    ]
    
    return SessionListView(sessions: sessions)
        .background(Color.black)
}

#Preview("Empty State") {
    SessionListView(sessions: [])
        .background(Color.black)
        .frame(height: 300)
}
