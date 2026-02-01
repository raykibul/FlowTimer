# Flow Timer Audio Resources

This directory should contain the audio files for the Flow Timer app. The app will gracefully handle missing audio files by disabling sound playback.

## Required Ambient Sound Files

The following ambient sound files are needed for the app's soundscape feature:

| Filename | Description | Recommended Duration | Format |
|----------|-------------|---------------------|--------|
| `brook.mp3` | Gentle brook/stream water sounds | 2-5 minutes (loops) | MP3, 128-192 kbps |
| `ocean.mp3` | Ocean waves crashing on shore | 2-5 minutes (loops) | MP3, 128-192 kbps |
| `white_noise.mp3` | White noise for focus | 1-2 minutes (loops) | MP3, 128-192 kbps |
| `rain.mp3` | Rain falling, gentle rainfall | 2-5 minutes (loops) | MP3, 128-192 kbps |
| `forest.mp3` | Forest ambience with birds | 2-5 minutes (loops) | MP3, 128-192 kbps |
| `coffee_shop.mp3` | Coffee shop background chatter | 2-5 minutes (loops) | MP3, 128-192 kbps |
| `fireplace.mp3` | Crackling fireplace sounds | 2-5 minutes (loops) | MP3, 128-192 kbps |

## Required Completion Sound

| Filename | Description | Duration | Format |
|----------|-------------|----------|--------|
| `chime.mp3` | Gentle completion chime/bell | 2-5 seconds | MP3, 128-192 kbps |

## Where to Get Audio Files

### Free Sources (Creative Commons / Royalty-Free)

1. **Freesound.org** (https://freesound.org)
   - Large collection of CC-licensed sounds
   - Search for: "brook loop", "ocean waves loop", "rain ambient", etc.
   - Check license requirements for each file

2. **Pixabay** (https://pixabay.com/sound-effects/)
   - Royalty-free sound effects
   - No attribution required
   - Good quality ambient sounds

3. **Mixkit** (https://mixkit.co/free-sound-effects/)
   - Free sound effects for commercial use
   - Good selection of ambient sounds

4. **BBC Sound Effects** (https://sound-effects.bbcrewind.co.uk/)
   - Large archive of sounds
   - Check licensing for app usage

5. **Zapsplat** (https://www.zapsplat.com)
   - Free with attribution
   - Good ambient sound selection

### Tips for Selecting Audio

1. **Looping**: Choose sounds that loop seamlessly. Look for files specifically tagged as "loop" or "seamless"

2. **Quality**: Aim for 128-192 kbps MP3 files. Higher quality increases file size without noticeable benefit for ambient sounds

3. **Duration**: 2-5 minute loops work well. Shorter loops may become repetitive; longer files increase app size

4. **Volume Normalization**: Normalize all files to similar volume levels (-14 to -16 LUFS recommended)

5. **Fade Points**: Ensure loop points have smooth transitions without clicks or pops

## Adding Files to the Project

1. Download and rename files to match the expected filenames above
2. Place all `.mp3` files in this `Sounds/` directory
3. In Xcode, ensure files are added to the target:
   - Select the files in Xcode
   - In the File Inspector, check "Target Membership" for FlowTimer
4. Build and run to test audio playback

## Audio File Specifications

- **Format**: MP3 (AAC also supported)
- **Sample Rate**: 44.1 kHz
- **Bit Rate**: 128-192 kbps
- **Channels**: Stereo preferred, Mono acceptable
- **Loudness**: -14 to -16 LUFS (normalized)

## Graceful Degradation

The app is designed to handle missing audio files gracefully:
- If an ambient sound file is missing, that sound option will be disabled in the UI
- If the chime file is missing, completion will be silent
- No crashes or errors will occur due to missing audio files
