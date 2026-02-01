# Flow Timer - Testing Guide

This document outlines the manual testing steps for verifying the Flow Timer app functionality.

## Automated Tests

All property-based and unit tests can be run with:

```bash
cd FlowTimer
swift test
```

### Test Coverage Summary

| Test Suite | Tests | Status |
|------------|-------|--------|
| TimerManagerTests | 17 | ✅ All Passing |
| AudioManagerTests | 17 | ✅ All Passing |
| FocusManagerTests | 14 | ✅ All Passing |
| SessionStoreTests | 15 | ✅ All Passing |
| FlipClockTests | 10 | ✅ All Passing |
| **Total** | **73** | **✅ All Passing** |

### Property-Based Tests Validated

1. **Timer State Machine Validity (Property 1)** - `TimerManagerTests`
   - Validates: Requirements 1.2
   - Tests valid state transitions for all timer states

2. **Time Formatting Correctness (Property 2)** - `FlipClockTests`
   - Validates: Requirements 2.1, 6.2
   - Tests HH:MM:SS formatting for all time values

3. **Volume Bounds (Property 3)** - `AudioManagerTests`
   - Validates: Requirements 3.2
   - Tests volume clamping to [0.0, 1.0]

4. **Session History Integrity (Property 4)** - `SessionStoreTests`
   - Validates: Requirements 8.1, 8.3
   - Tests session persistence and aggregation

5. **Focus Mode Symmetry (Property 5)** - `FocusManagerTests`
   - Validates: Requirements 4.1, 4.2, 5.2
   - Tests Focus mode enable/disable symmetry

---

## Manual Testing Checklist

### 15.2 Full Timer Flow End-to-End

#### Test Case: Complete Timer Session
1. [ ] Launch the app
2. [ ] Select a duration (e.g., 30 minutes)
3. [ ] Click "Start" button
4. [ ] Verify flip clock displays correct time and animates
5. [ ] Verify timer counts down each second
6. [ ] Click "Pause" button
7. [ ] Verify timer stops counting
8. [ ] Click "Resume" button
9. [ ] Verify timer continues from paused time
10. [ ] Click "Stop" button
11. [ ] Verify timer resets to selected duration

#### Test Case: Timer Completion
1. [ ] Set a short duration for testing (or modify code temporarily)
2. [ ] Start the timer
3. [ ] Wait for timer to reach 0:00
4. [ ] Verify completion chime plays (if audio file present)
5. [ ] Verify completion message displays
6. [ ] Verify session is saved to history

### 15.3 Focus Mode Integration on macOS

#### Prerequisites
- Create macOS Shortcuts named "EnableFlowFocus" and "DisableFlowFocus"
- Or grant Accessibility permissions for AppleScript fallback

#### Test Case: Focus Mode Enable/Disable
1. [ ] Note current Focus/DND state before starting
2. [ ] Start a timer session
3. [ ] Verify Focus mode is enabled (check Control Center)
4. [ ] Stop or complete the timer
5. [ ] Verify Focus mode returns to original state

#### Test Case: Permission Handling
1. [ ] Deny Focus mode permissions
2. [ ] Start a timer session
3. [ ] Verify app handles denial gracefully (no crash)
4. [ ] Verify appropriate message is shown to user

### 15.4 Session History Persistence

#### Test Case: Session Saving
1. [ ] Complete a timer session
2. [ ] Open History view
3. [ ] Verify session appears in list with correct:
   - Date/time
   - Duration
   - Completion status

#### Test Case: Persistence Across Launches
1. [ ] Complete 2-3 timer sessions
2. [ ] Note the session history
3. [ ] Quit the app completely
4. [ ] Relaunch the app
5. [ ] Open History view
6. [ ] Verify all previous sessions are still present

#### Test Case: Statistics
1. [ ] Verify daily total focus time is correct
2. [ ] Verify weekly total focus time is correct
3. [ ] Verify all-time total focus time is correct

### 15.5 Menu Bar Functionality

#### Test Case: Menu Bar Display
1. [ ] Start a timer session
2. [ ] Verify remaining time appears in menu bar
3. [ ] Verify time updates every second
4. [ ] Verify format is HH:MM:SS or MM:SS

#### Test Case: Menu Bar Actions
1. [ ] Click menu bar icon
2. [ ] Verify main window opens/focuses
3. [ ] Right-click (or click) menu bar icon
4. [ ] Verify context menu appears with:
   - Pause/Resume option
   - Stop option
   - Open Window option
5. [ ] Test each menu action works correctly

#### Test Case: Background Operation
1. [ ] Start a timer session
2. [ ] Close the main window
3. [ ] Verify app continues running (menu bar visible)
4. [ ] Verify timer continues counting down
5. [ ] Click menu bar to reopen window
6. [ ] Verify timer state is preserved

---

## Audio Testing

### Ambient Sounds (requires audio files)
1. [ ] Select each ambient sound option
2. [ ] Verify sound plays and loops seamlessly
3. [ ] Adjust volume slider
4. [ ] Verify volume changes
5. [ ] Click mute button
6. [ ] Verify sound is muted
7. [ ] Click unmute button
8. [ ] Verify sound resumes at previous volume

### Completion Chime (requires chime.mp3)
1. [ ] Complete a timer session
2. [ ] Verify chime plays once
3. [ ] Verify chime is distinct from ambient sounds

---

## Edge Cases

### Timer Edge Cases
- [ ] Start timer with 0 seconds remaining (should not start)
- [ ] Rapidly click Start/Stop multiple times
- [ ] Change duration while timer is running (should not affect current session)

### Audio Edge Cases
- [ ] Change sound while another is playing
- [ ] Mute/unmute rapidly
- [ ] Set volume to 0 vs muting (both should silence)

### Window Edge Cases
- [ ] Resize window to minimum size
- [ ] Toggle compact mode
- [ ] Close and reopen window multiple times

---

## Known Limitations

1. **Audio Files**: The app requires actual audio files to play sounds. Without them, sound selection will be disabled or silent.

2. **Focus Mode**: Requires either:
   - macOS Shortcuts named "EnableFlowFocus" and "DisableFlowFocus"
   - Accessibility permissions for AppleScript fallback
   
3. **Menu Bar**: Some menu bar features require the app to be built and run as a proper macOS app bundle (not via `swift run`).

---

## Test Environment

- **macOS Version**: 13.0 (Ventura) or later
- **Swift Version**: 5.9+
- **Xcode Version**: 15.0+ (for full app bundle testing)
