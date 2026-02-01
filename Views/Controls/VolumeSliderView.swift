//
//  VolumeSliderView.swift
//  FlowTimer
//
//  A volume slider with mute toggle button for controlling ambient sound volume.
//

import SwiftUI

/// A volume slider with mute toggle button for controlling ambient sound volume.
///
/// The view displays a horizontal slider for volume control with a mute/unmute
/// toggle button. The slider shows volume icons at both ends to indicate
/// low and high volume.
///
/// ## Features
/// - Horizontal volume slider (0.0 to 1.0)
/// - Mute/unmute toggle button
/// - Volume icons indicating current level
/// - Dark theme styling to match FlipClockView
/// - Visual feedback when muted
///
/// ## Usage
/// ```swift
/// @State var volume: Float = 0.5
/// @State var isMuted: Bool = false
///
/// VolumeSliderView(
///     volume: $volume,
///     isMuted: $isMuted,
///     onVolumeChanged: { newVolume in
///         audioManager.setVolume(newVolume)
///     },
///     onMuteToggled: {
///         audioManager.toggleMute()
///     }
/// )
/// ```
struct VolumeSliderView: View {
    /// Current volume level (0.0 to 1.0)
    @Binding var volume: Float
    
    /// Whether audio is currently muted
    @Binding var isMuted: Bool
    
    /// Callback when volume changes
    var onVolumeChanged: ((Float) -> Void)?
    
    /// Callback when mute is toggled
    var onMuteToggled: (() -> Void)?
    
    /// Whether the slider is disabled
    var isDisabled: Bool = false
    
    // MARK: - Styling Constants
    
    /// Icon size
    private let iconSize: CGFloat = 18
    
    /// Mute button size
    private let muteButtonSize: CGFloat = 36
    
    /// Slider track height
    private let trackHeight: CGFloat = 6
    
    /// Slider corner radius
    private let trackCornerRadius: CGFloat = 3
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Section label
            Text("Volume")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.gray)
                .textCase(.uppercase)
            
            // Volume control row
            HStack(spacing: 12) {
                // Mute toggle button
                muteButton
                
                // Volume slider with icons
                HStack(spacing: 10) {
                    // Low volume icon
                    Image(systemName: "speaker.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.gray)
                    
                    // Custom slider
                    volumeSlider
                    
                    // High volume icon
                    Image(systemName: "speaker.wave.3.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                }
                
                // Volume percentage
                Text("\(Int(volume * 100))%")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(.gray)
                    .frame(width: 40, alignment: .trailing)
            }
        }
        .opacity(isDisabled ? 0.5 : 1.0)
    }
    
    // MARK: - Subviews
    
    /// Mute toggle button
    private var muteButton: some View {
        Button {
            if !isDisabled {
                onMuteToggled?()
            }
        } label: {
            Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                .font(.system(size: iconSize, weight: .medium))
                .foregroundColor(isMuted ? .red.opacity(0.8) : .white)
                .frame(width: muteButtonSize, height: muteButtonSize)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isMuted ? Color.red.opacity(0.2) : Color(white: 0.15))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(isMuted ? Color.red.opacity(0.4) : Color.white.opacity(0.2), lineWidth: 1)
                        )
                )
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
    }
    
    /// Custom volume slider
    private var volumeSlider: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Track background
                RoundedRectangle(cornerRadius: trackCornerRadius)
                    .fill(Color(white: 0.2))
                    .frame(height: trackHeight)
                
                // Filled track
                if isMuted {
                    RoundedRectangle(cornerRadius: trackCornerRadius)
                        .fill(Color.gray.opacity(0.5))
                        .frame(width: CGFloat(volume) * geometry.size.width, height: trackHeight)
                } else {
                    RoundedRectangle(cornerRadius: trackCornerRadius)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.7),
                                    Color.white
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: CGFloat(volume) * geometry.size.width, height: trackHeight)
                }
                
                // Thumb
                Circle()
                    .fill(isMuted ? Color.gray : Color.white)
                    .frame(width: 16, height: 16)
                    .shadow(color: Color.black.opacity(0.3), radius: 2, y: 1)
                    .offset(x: CGFloat(volume) * (geometry.size.width - 16))
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if !isDisabled {
                            let newVolume = Float(max(0, min(1, value.location.x / geometry.size.width)))
                            volume = newVolume
                            onVolumeChanged?(newVolume)
                        }
                    }
            )
        }
        .frame(height: 20)
        .disabled(isDisabled)
    }
}

// MARK: - Convenience Initializer

extension VolumeSliderView {
    /// Creates a volume slider bound to an AudioManager
    init(audioManager: AudioManager) {
        self._volume = Binding(
            get: { audioManager.volume },
            set: { audioManager.setVolume($0) }
        )
        self._isMuted = Binding(
            get: { audioManager.isMuted },
            set: { _ in audioManager.toggleMute() }
        )
        self.onVolumeChanged = { audioManager.setVolume($0) }
        self.onMuteToggled = { audioManager.toggleMute() }
    }
}

// MARK: - Compact Variant

/// A more compact horizontal volume control
struct CompactVolumeView: View {
    /// Current volume level (0.0 to 1.0)
    @Binding var volume: Float
    
    /// Whether audio is currently muted
    @Binding var isMuted: Bool
    
    /// Callback when volume changes
    var onVolumeChanged: ((Float) -> Void)?
    
    /// Callback when mute is toggled
    var onMuteToggled: (() -> Void)?
    
    var body: some View {
        HStack(spacing: 8) {
            // Mute button
            Button {
                onMuteToggled?()
            } label: {
                Image(systemName: isMuted ? "speaker.slash.fill" : volumeIcon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isMuted ? .red.opacity(0.8) : .white)
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            
            // Native slider
            Slider(value: Binding(
                get: { Double(volume) },
                set: { 
                    volume = Float($0)
                    onVolumeChanged?(Float($0))
                }
            ), in: 0...1)
            .tint(.white)
            .frame(width: 100)
            .disabled(isMuted)
            .opacity(isMuted ? 0.5 : 1.0)
        }
    }
    
    /// Returns appropriate volume icon based on level
    private var volumeIcon: String {
        if volume == 0 {
            return "speaker.fill"
        } else if volume < 0.33 {
            return "speaker.wave.1.fill"
        } else if volume < 0.66 {
            return "speaker.wave.2.fill"
        } else {
            return "speaker.wave.3.fill"
        }
    }
}

// MARK: - Preview

#Preview("Default State") {
    VolumeSliderView(
        volume: .constant(0.5),
        isMuted: .constant(false)
    )
    .padding()
    .background(Color.black)
}

#Preview("Muted State") {
    VolumeSliderView(
        volume: .constant(0.5),
        isMuted: .constant(true)
    )
    .padding()
    .background(Color.black)
}

#Preview("Low Volume") {
    VolumeSliderView(
        volume: .constant(0.1),
        isMuted: .constant(false)
    )
    .padding()
    .background(Color.black)
}

#Preview("Max Volume") {
    VolumeSliderView(
        volume: .constant(1.0),
        isMuted: .constant(false)
    )
    .padding()
    .background(Color.black)
}

#Preview("Disabled State") {
    VolumeSliderView(
        volume: .constant(0.7),
        isMuted: .constant(false),
        isDisabled: true
    )
    .padding()
    .background(Color.black)
}

#Preview("Compact Variant") {
    CompactVolumeView(
        volume: .constant(0.6),
        isMuted: .constant(false)
    )
    .padding()
    .background(Color.black)
}

#Preview("Interactive") {
    struct InteractivePreview: View {
        @State private var volume: Float = 0.5
        @State private var isMuted: Bool = false
        @State private var isDisabled: Bool = false
        
        var body: some View {
            VStack(spacing: 30) {
                VolumeSliderView(
                    volume: $volume,
                    isMuted: $isMuted,
                    onVolumeChanged: { newVolume in
                        print("Volume changed to: \(newVolume)")
                    },
                    onMuteToggled: {
                        isMuted.toggle()
                        print("Mute toggled: \(isMuted)")
                    },
                    isDisabled: isDisabled
                )
                
                Divider()
                    .background(Color.gray)
                
                VStack(spacing: 10) {
                    Text("Volume: \(Int(volume * 100))%")
                        .foregroundColor(.white)
                    
                    Text("Muted: \(isMuted ? "Yes" : "No")")
                        .foregroundColor(.white)
                    
                    Toggle("Disabled", isOn: $isDisabled)
                        .foregroundColor(.white)
                        .toggleStyle(.switch)
                }
            }
            .padding()
            .background(Color.black)
        }
    }
    
    return InteractivePreview()
}

#Preview("Interactive Compact") {
    struct InteractiveCompactPreview: View {
        @State private var volume: Float = 0.5
        @State private var isMuted: Bool = false
        
        var body: some View {
            VStack(spacing: 20) {
                CompactVolumeView(
                    volume: $volume,
                    isMuted: $isMuted,
                    onMuteToggled: { isMuted.toggle() }
                )
                
                Text("Volume: \(Int(volume * 100))%")
                    .foregroundColor(.white)
            }
            .padding()
            .background(Color.black)
        }
    }
    
    return InteractiveCompactPreview()
}
