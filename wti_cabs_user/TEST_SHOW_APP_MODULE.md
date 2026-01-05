# How to Test "Show App Module" Screen

## Method 1: Reset App Data (Recommended for Testing)

### On Android:
1. Go to **Settings** → **Apps** → **WTI Cabs**
2. Tap **Storage** → **Clear Data** (or **Clear Storage**)
3. Uninstall and reinstall the app, OR
4. Use ADB command:
   ```bash
   adb shell pm clear com.wti.cabbooking
   ```

### On iOS (Simulator):
1. Delete the app from simulator
2. Reinstall the app

### On iOS (Physical Device):
1. Delete the app
2. Reinstall from Xcode/TestFlight

## Method 2: Navigate Directly (For Quick Testing)

You can temporarily navigate directly to the screen by modifying the initial route in `main.dart`:

```dart
// Temporarily change line 254 in main.dart:
initialRoute = AppRoutes.showAppModule; // Instead of AppRoutes.walkthrough
```

## Method 3: Clear SharedPreferences Programmatically

Add this code temporarily in your app to clear the flags:

```dart
final prefs = await SharedPreferences.getInstance();
await prefs.remove("isFirstTime");
await prefs.remove("hasSeenAppModule");
```

## Expected Flow:

1. **First Time User:**
   - Splash Screen → Walkthrough → **Show App Module** → Personal/Business

2. **After First Time:**
   - Splash Screen → Bottom Nav (skips both Walkthrough and Show App Module)

## Testing Checklist:

- [ ] Screen appears after walkthrough completes
- [ ] "Personal" button navigates correctly
- [ ] "Business" button navigates correctly
- [ ] Screen only shows once (after first walkthrough)
- [ ] Screen doesn't appear on subsequent app launches

