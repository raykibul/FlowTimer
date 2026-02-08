//
//  SoundPickerView.swift
//  FlowTimer
//
//  A dropdown-style sound picker that shows selected sound name at top,
//  and opens a modal/popover list on click.
//

import SwiftUI

/// A dropdown-style sound picker.
///
/// Shows the currently selected sound name as a clickable label.
/// Clicking opens a popover with a list of all available sounds.
struct SoundPickerView: View {
    @Binding var selectedSound: AmbientSound?
    var onSoundSelected: ((AmbientSound?) -> Void)?
    var isDisabled: Bool = false

    @State private var showDropdown: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            // Dropdown trigger button
            Button {
                if !isDisabled {
                    showDropdown.toggle()
                }
            } label: {
                HStack(spacing: 8) {
                    if let sound = selectedSound {
                        Image(systemName: sound.iconName)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                        Text(sound.displayName)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                    } else {
                        Image(systemName: "speaker.slash.fill")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                        Text("No Sound")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }

                    Spacer()

                    Image(systemName: showDropdown ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.5))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(white: 0.12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(.plain)
            .disabled(isDisabled)
            .popover(isPresented: $showDropdown, arrowEdge: .bottom) {
                soundList
            }
        }
        .opacity(isDisabled ? 0.5 : 1.0)
    }

    // MARK: - Sound List Popover

    private var soundList: some View {
        VStack(spacing: 0) {
            // "None" option
            soundRow(sound: nil, isSelected: selectedSound == nil)

            Divider()
                .background(Color.white.opacity(0.1))

            // All sounds
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(AmbientSound.allCases) { sound in
                        soundRow(sound: sound, isSelected: selectedSound == sound)
                    }
                }
            }
            .frame(maxHeight: 300)
        }
        .frame(width: 220)
        .background(Color(red: 0.1, green: 0.1, blue: 0.12))
    }

    @ViewBuilder
    private func soundRow(sound: AmbientSound?, isSelected: Bool) -> some View {
        Button {
            selectedSound = sound
            onSoundSelected?(sound)
            showDropdown = false
        } label: {
            HStack(spacing: 10) {
                if let sound = sound {
                    Image(systemName: sound.iconName)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(isSelected ? .black : .white.opacity(0.7))
                        .frame(width: 22)
                    Text(sound.displayName)
                        .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                        .foregroundColor(isSelected ? .black : .white)
                } else {
                    Image(systemName: "speaker.slash.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(isSelected ? .black : .white.opacity(0.7))
                        .frame(width: 22)
                    Text("None")
                        .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                        .foregroundColor(isSelected ? .black : .white)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.black)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(isSelected ? Color.white : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Compact Variant (kept for compatibility)

struct CompactSoundPickerView: View {
    @Binding var selectedSound: AmbientSound?
    var onSoundSelected: ((AmbientSound?) -> Void)?
    var isDisabled: Bool = false

    var body: some View {
        SoundPickerView(
            selectedSound: $selectedSound,
            onSoundSelected: onSoundSelected,
            isDisabled: isDisabled
        )
    }
}

// MARK: - Preview

#Preview("Default") {
    SoundPickerView(selectedSound: .constant(.rain))
        .frame(width: 260)
        .padding()
        .background(Color.black)
}

#Preview("No Sound") {
    SoundPickerView(selectedSound: .constant(nil))
        .frame(width: 260)
        .padding()
        .background(Color.black)
}
