# Notification Sound Assets

## Overview
This directory contains sound assets used for push notifications in the grocery app.

## Required Files

### notification.mp3
- **Purpose**: Plays when push notifications are received
- **Requirements**:
  - Format: MP3
  - Duration: 1-3 seconds recommended
  - File size: < 500KB recommended
  - Quality: Should be distinct and attention-grabbing but not annoying
  - Volume: Moderate level (respects device volume settings)

## Current Status
⚠️ **ACTION REQUIRED**: The `notification.mp3` file is currently a placeholder (0 bytes).

You need to replace it with an actual notification sound file that meets the requirements above.

## How to Add the Sound File

1. **Find or create a notification sound**:
   - Use royalty-free sound libraries (e.g., freesound.org, zapsplat.com)
   - Create your own using audio editing software
   - Ensure you have the rights to use the sound

2. **Prepare the file**:
   - Convert to MP3 format if needed
   - Trim to 1-3 seconds
   - Normalize audio levels
   - Test on a device to ensure it sounds appropriate

3. **Replace the placeholder**:
   ```bash
   # From the project root directory
   cp /path/to/your/notification-sound.mp3 assets/sounds/notification.mp3
   ```

4. **Verify the file**:
   ```bash
   # Check file size
   ls -lh assets/sounds/notification.mp3
   
   # Run the asset verification test
   flutter test test/assets_test.dart
   ```

## Configuration
The sound asset is already configured in `pubspec.yaml`:
```yaml
flutter:
  assets:
    - assets/sounds/notification.mp3
```

## Usage in Code
The notification sound is played by the `NotificationService`:
```dart
// lib/services/notification_service.dart
await _audioPlayer.play(AssetSource('sounds/notification.mp3'));
```

## User Settings
Users can enable/disable notification sounds in the app settings. The sound respects:
- User's notification sound preference (in-app setting)
- Device notification settings
- Device volume settings

## Testing
After adding the actual sound file:
1. Run the app on a physical device
2. Trigger a notification (e.g., place an order)
3. Verify the sound plays correctly
4. Test with different volume levels
5. Test with notification sounds disabled in settings

## Related Requirements
This asset validates requirements:
- 2.5.5: Sound is distinct and attention-grabbing but not annoying
- 2.5.6: Sound plays for order status updates and admin notifications
- 2.5.7: User can enable/disable notification sounds in settings
- 2.5.8: Sound respects device's notification and volume settings
