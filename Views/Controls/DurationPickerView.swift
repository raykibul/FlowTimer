//
//  DurationPickerView.swift
//  FlowTimer
//
//  A view displaying preset duration buttons for selecting flow session length.
//  Supports 30 min, 1 hour, 2 hours, 3 hours, and 4 hours presets.
//

import SwiftUI

/// A view displaying preset duration buttons for selecting flow session length.
///
/// The picker shows horizontal buttons for each duration preset (30min, 1hr, 2hr, 3hr, 4hr).
/// The currently selected duration is highlighted with a distinct style.
///
/// ## Features
/// - Horizontal layout of preset buttons
/// - Visual indication of selected duration
/// - Dark theme styling to match FlipClockView
/// - Disabled state when timer is active
///
/// ## Usage
/// ```swift
/// @StateObject var timerManager = TimerManager()
///
/// DurationPickerView(
///     selectedDuration: $timerManager.selectedDuration,
///     isDisabled: timerManager.timerState.isActive
/// )
/// ```
struct DurationPickerView: View {
    /// The currently selected duration (bound to TimerManager)
    @Binding var selectedDuration: TimeInterval
    
    /// Whether the picker is disabled (e.g., when timer is running)
    var isDisabled: Bool = false
    
    /// Callback when a duration is selected
    var onDurationSelected: ((DurationPreset) -> Void)?
    
    // MARK: - Styling Constants
    
    /// Button corner radius
    private let buttonCornerRadius: CGFloat = 10
    
    /// Button horizontal padding
    private let buttonHorizontalPadding: CGFloat = 16
    
    /// Button vertical padding
    private let buttonVerticalPadding: CGFloat = 10
    
    /// Spacing between buttons
    private let buttonSpacing: CGFloat = 12
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Section label
            Text("Duration")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.gray)
                .textCase(.uppercase)
            
            // Preset buttons
            HStack(spacing: buttonSpacing) {
                ForEach(DurationPreset.allCases) { preset in
                    presetButton(for: preset)
                }
            }
        }
        .opacity(isDisabled ? 0.5 : 1.0)
    }
    
    // MARK: - Subviews
    
    /// Creates a button for a duration preset
    @ViewBuilder
    private func presetButton(for preset: DurationPreset) -> some View {
        let isSelected = selectedDuration == preset.rawValue
        
        Button {
            if !isDisabled {
                selectedDuration = preset.rawValue
                onDurationSelected?(preset)
            }
        } label: {
            Text(preset.displayName)
                .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .black : .white)
                .padding(.horizontal, buttonHorizontalPadding)
                .padding(.vertical, buttonVerticalPadding)
                .background(buttonBackground(isSelected: isSelected))
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
    }
    
    /// Background for preset buttons
    @ViewBuilder
    private func buttonBackground(isSelected: Bool) -> some View {
        if isSelected {
            // Selected state: bright accent color
            RoundedRectangle(cornerRadius: buttonCornerRadius)
                .fill(Color.white)
                .shadow(color: Color.white.opacity(0.3), radius: 4, y: 2)
        } else {
            // Unselected state: dark with subtle border
            RoundedRectangle(cornerRadius: buttonCornerRadius)
                .fill(Color(white: 0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: buttonCornerRadius)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        }
    }
}

// MARK: - Convenience Initializers

extension DurationPickerView {
    /// Creates a duration picker bound to a TimerManager
    init(timerManager: TimerManager) {
        self._selectedDuration = Binding(
            get: { timerManager.selectedDuration },
            set: { timerManager.setDuration($0) }
        )
        self.isDisabled = timerManager.timerState.isActive
    }
}

// MARK: - Preview

#Preview("Default State") {
    DurationPickerView(selectedDuration: .constant(3600))
        .padding()
        .background(Color.black)
}

#Preview("30 Minutes Selected") {
    DurationPickerView(selectedDuration: .constant(1800))
        .padding()
        .background(Color.black)
}

#Preview("4 Hours Selected") {
    DurationPickerView(selectedDuration: .constant(14400))
        .padding()
        .background(Color.black)
}

#Preview("Disabled State") {
    DurationPickerView(selectedDuration: .constant(3600), isDisabled: true)
        .padding()
        .background(Color.black)
}

#Preview("Interactive") {
    struct InteractivePreview: View {
        @State private var duration: TimeInterval = 3600
        @State private var isDisabled = false
        
        var body: some View {
            VStack(spacing: 20) {
                DurationPickerView(
                    selectedDuration: $duration,
                    isDisabled: isDisabled
                )
                
                Text("Selected: \(TimerManager.formatTime(duration))")
                    .foregroundColor(.white)
                
                Toggle("Disabled", isOn: $isDisabled)
                    .foregroundColor(.white)
                    .toggleStyle(.switch)
            }
            .padding()
            .background(Color.black)
        }
    }
    
    return InteractivePreview()
}
