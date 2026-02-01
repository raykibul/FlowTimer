//
//  SoundPickerView.swift
//  FlowTimer
//
//  A view for selecting ambient sounds during flow sessions.
//  Displays available sounds in a grid layout with icons and labels.
//

import SwiftUI

/// A view for selecting ambient sounds during flow sessions.
///
/// The picker displays all available ambient sounds in a grid layout.
/// Each sound is shown with its icon and name, with the selected sound highlighted.
///
/// ## Features
/// - Grid layout of sound options
/// - Visual indication of selected sound
/// - Option to select "None" (no ambient sound)
/// - Dark theme styling to match FlipClockView
///
/// ## Usage
/// ```swift
/// @State var selectedSound: AmbientSound? = .rain
///
/// SoundPickerView(
///     selectedSound: $selectedSound,
///     onSoundSelected: { sound in
///         audioManager.play(sound)
///     }
/// )
/// ```
struct SoundPickerView: View {
    /// The currently selected sound (nil means no sound)
    @Binding var selectedSound: AmbientSound?
    
    /// Callback when a sound is selected
    var onSoundSelected: ((AmbientSound?) -> Void)?
    
    /// Whether the picker is disabled
    var isDisabled: Bool = false
    
    // MARK: - Layout Constants
    
    /// Number of columns in the grid
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    /// Spacing between grid items
    private let gridSpacing: CGFloat = 12
    
    /// Item corner radius
    private let itemCornerRadius: CGFloat = 12
    
    /// Icon size
    private let iconSize: CGFloat = 24
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header with label and "None" option
            HStack {
                Text("Ambient Sound")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.gray)
                    .textCase(.uppercase)
                
                Spacer()
                
                // None button to disable sound
                Button {
                    if !isDisabled {
                        selectedSound = nil
                        onSoundSelected?(nil)
                    }
                } label: {
                    Text("None")
                        .font(.caption)
                        .fontWeight(selectedSound == nil ? .semibold : .regular)
                        .foregroundColor(selectedSound == nil ? .white : .gray)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(selectedSound == nil ? Color.white.opacity(0.2) : Color.clear)
                        )
                }
                .buttonStyle(.plain)
                .disabled(isDisabled)
            }
            
            // Sound grid
            LazyVGrid(columns: columns, spacing: gridSpacing) {
                ForEach(AmbientSound.allCases) { sound in
                    soundItem(for: sound)
                }
            }
        }
        .opacity(isDisabled ? 0.5 : 1.0)
    }
    
    // MARK: - Subviews
    
    /// Creates a grid item for a sound
    @ViewBuilder
    private func soundItem(for sound: AmbientSound) -> some View {
        let isSelected = selectedSound == sound
        
        Button {
            if !isDisabled {
                selectedSound = sound
                onSoundSelected?(sound)
            }
        } label: {
            VStack(spacing: 8) {
                // Icon
                Image(systemName: sound.iconName)
                    .font(.system(size: iconSize, weight: .medium))
                    .foregroundColor(isSelected ? .black : .white)
                
                // Label
                Text(sound.displayName)
                    .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .black : .white.opacity(0.8))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .padding(.horizontal, 8)
            .background(itemBackground(isSelected: isSelected))
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
    }
    
    /// Background for sound items
    @ViewBuilder
    private func itemBackground(isSelected: Bool) -> some View {
        if isSelected {
            // Selected state: bright accent
            RoundedRectangle(cornerRadius: itemCornerRadius)
                .fill(Color.white)
                .shadow(color: Color.white.opacity(0.3), radius: 4, y: 2)
        } else {
            // Unselected state: dark with subtle border
            RoundedRectangle(cornerRadius: itemCornerRadius)
                .fill(Color(white: 0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: itemCornerRadius)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
        }
    }
}

// MARK: - Compact Variant

/// A more compact horizontal sound picker for smaller spaces
struct CompactSoundPickerView: View {
    /// The currently selected sound (nil means no sound)
    @Binding var selectedSound: AmbientSound?
    
    /// Callback when a sound is selected
    var onSoundSelected: ((AmbientSound?) -> Void)?
    
    /// Whether the picker is disabled
    var isDisabled: Bool = false
    
    // MARK: - Body
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                // None option
                compactItem(sound: nil, isSelected: selectedSound == nil)
                
                // Sound options
                ForEach(AmbientSound.allCases) { sound in
                    compactItem(sound: sound, isSelected: selectedSound == sound)
                }
            }
            .padding(.horizontal, 4)
        }
        .opacity(isDisabled ? 0.5 : 1.0)
    }
    
    @ViewBuilder
    private func compactItem(sound: AmbientSound?, isSelected: Bool) -> some View {
        Button {
            if !isDisabled {
                selectedSound = sound
                onSoundSelected?(sound)
            }
        } label: {
            HStack(spacing: 6) {
                if let sound = sound {
                    Image(systemName: sound.iconName)
                        .font(.system(size: 14, weight: .medium))
                    Text(sound.displayName)
                        .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                } else {
                    Image(systemName: "speaker.slash.fill")
                        .font(.system(size: 14, weight: .medium))
                    Text("None")
                        .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                }
            }
            .foregroundColor(isSelected ? .black : .white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.white : Color(white: 0.15))
            )
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
    }
}

// MARK: - Preview

#Preview("Default State") {
    SoundPickerView(selectedSound: .constant(.rain))
        .padding()
        .background(Color.black)
}

#Preview("No Sound Selected") {
    SoundPickerView(selectedSound: .constant(nil))
        .padding()
        .background(Color.black)
}

#Preview("Disabled State") {
    SoundPickerView(selectedSound: .constant(.ocean), isDisabled: true)
        .padding()
        .background(Color.black)
}

#Preview("Compact Variant") {
    CompactSoundPickerView(selectedSound: .constant(.forest))
        .padding()
        .background(Color.black)
}

#Preview("Interactive") {
    struct InteractivePreview: View {
        @State private var selectedSound: AmbientSound? = .rain
        @State private var isDisabled = false
        
        var body: some View {
            VStack(spacing: 20) {
                SoundPickerView(
                    selectedSound: $selectedSound,
                    isDisabled: isDisabled
                )
                
                Divider()
                    .background(Color.gray)
                
                Text("Selected: \(selectedSound?.displayName ?? "None")")
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

#Preview("Interactive Compact") {
    struct InteractiveCompactPreview: View {
        @State private var selectedSound: AmbientSound? = .coffeeShop
        
        var body: some View {
            VStack(spacing: 20) {
                CompactSoundPickerView(selectedSound: $selectedSound)
                
                Text("Selected: \(selectedSound?.displayName ?? "None")")
                    .foregroundColor(.white)
            }
            .padding()
            .background(Color.black)
        }
    }
    
    return InteractiveCompactPreview()
}
