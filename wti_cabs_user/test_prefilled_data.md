# Test Script: Prefilled Data Verification

## Quick Test Commands

Add these debug methods to `crp_booking_engine.dart` for testing:

```dart
// Add this method to _CprBookingEngineState class
Future<void> _debugPrefilledData() async {
  debugPrint('═══════════════════════════════════════');
  debugPrint('🔍 PREFILLED DATA VERIFICATION');
  debugPrint('═══════════════════════════════════════');
  
  // 1. Check Login Response
  final loginInfo = loginInfoController.crpLoginInfo.value;
  debugPrint('\n📋 LOGIN RESPONSE:');
  debugPrint('  Available: ${loginInfo != null}');
  if (loginInfo != null) {
    debugPrint('  EntityId: ${loginInfo.entityId}');
    debugPrint('  GenderId: ${loginInfo.genderId}');
    debugPrint('  PayModeID: ${loginInfo.payModeID}');
    debugPrint('  AdvancedHours: ${loginInfo.advancedHourToConfirm}');
  }
  
  // 2. Check Storage
  debugPrint('\n💾 STORAGE VALUES:');
  final storage = StorageServices.instance;
  final storedEntityId = await storage.read('crpEntityId');
  final storedGenderId = await storage.read('crpGenderId');
  final sourceTitle = await storage.read('sourceTitle');
  final sourceLat = await storage.read('sourceLat');
  final sourceLng = await storage.read('sourceLng');
  debugPrint('  crpEntityId: $storedEntityId');
  debugPrint('  crpGenderId: $storedGenderId');
  debugPrint('  sourceTitle: $sourceTitle');
  debugPrint('  sourceLat: $sourceLat');
  debugPrint('  sourceLng: $sourceLng');
  
  // 3. Check Lists
  debugPrint('\n📊 API LISTS:');
  debugPrint('  Genders: ${controller.genderList.length}');
  debugPrint('  Payment Modes: ${paymentModeController.modes.length}');
  final entities = crpGetEntityListController.getAllEntityList.value?.getEntityList ?? [];
  debugPrint('  Entities: ${entities.length}');
  debugPrint('  Car Providers: ${carProviderController.carProviderList.length}');
  
  // 4. Check Current Selections
  debugPrint('\n✅ CURRENT SELECTIONS:');
  debugPrint('  Booking Type: $selectedBookingFor');
  debugPrint('  Gender: ${controller.selectedGender.value?.gender} (ID: ${controller.selectedGender.value?.genderID})');
  debugPrint('  Corporate: ${selectedCorporate?.entityName} (ID: ${selectedCorporate?.entityId})');
  debugPrint('  Payment Mode: ${paymentModeController.selectedMode.value?.mode} (ID: ${paymentModeController.selectedMode.value?.id})');
  debugPrint('  Car Provider: ${carProviderController.selectedCarProvider.value?.providerName}');
  debugPrint('  Pickup DateTime: $selectedPickupDateTime');
  debugPrint('  Pickup Location: ${crpSelectPickupController.selectedPlace.value?.primaryText}');
  debugPrint('  Drop Location: ${crpSelectDropController.selectedPlace.value?.primaryText}');
  
  // 5. Check Prefilling Status
  debugPrint('\n🔄 PREFILLING STATUS:');
  debugPrint('  Has Applied: $_hasAppliedPrefilledData');
  debugPrint('  Loading Pickup: $_isLoadingPickupLocation');
  
  debugPrint('═══════════════════════════════════════\n');
}
```

## How to Use

1. **Add the method above** to `_CprBookingEngineState` class
2. **Call it** in `initState()` after `_initializeData()`:
   ```dart
   WidgetsBinding.instance.addPostFrameCallback((_) async {
     await Future.delayed(const Duration(seconds: 2));
     if (mounted) {
       await _debugPrefilledData();
     }
   });
   ```
3. **Check console logs** when booking engine opens

---

## Manual Test Scenarios

### Test 1: Fresh Login
**Steps:**
1. Clear app data
2. Login with corporate account
3. Navigate to booking engine
4. Check console for debug output
5. Verify all fields are prefilled

**Expected Output:**
```
📋 LOGIN RESPONSE:
  Available: true
  EntityId: [some number]
  GenderId: [some number]
  PayModeID: [some number]
  AdvancedHours: [some number]

✅ CURRENT SELECTIONS:
  Gender: [should match GenderId]
  Corporate: [should match EntityId]
  Payment Mode: [should match PayModeID]
  Pickup Location: [should have value]
```

---

### Test 2: App Restart
**Steps:**
1. Login and verify prefilling works
2. Kill app completely
3. Restart app
4. Navigate to booking engine
5. Check console for debug output

**Expected Output:**
```
💾 STORAGE VALUES:
  crpEntityId: [should have value]
  crpGenderId: [should have value]
  sourceTitle: [should have value]

✅ CURRENT SELECTIONS:
  [All should still be prefilled from storage]
```

---

### Test 3: Location Prefilling
**Steps:**
1. Open app (location saved in main.dart)
2. Navigate to booking engine
3. Check if pickup location appears immediately

**Expected:**
- ✅ Pickup location appears without loading indicator
- ✅ If no storage, shows loading → GPS fetch → Location appears

---

### Test 4: Navigation Scenarios

#### 4a. From Home Screen
**Steps:**
1. From corporate home, tap booking
2. Verify locations cleared then current location appears

**Expected:**
- ✅ Locations cleared first
- ✅ Current location prefilled after clearing

#### 4b. From Location Selection
**Steps:**
1. Navigate to booking engine
2. Tap pickup → Select location
3. Return to booking engine

**Expected:**
- ✅ Selected location preserved
- ✅ Other fields remain prefilled

---

## Automated Test Checklist

Run through each scenario and check:

- [ ] **Login Response Available**
  - [ ] EntityId present
  - [ ] GenderId present
  - [ ] PayModeID present
  - [ ] AdvancedHours present

- [ ] **Storage Values**
  - [ ] crpEntityId saved
  - [ ] crpGenderId saved
  - [ ] sourceTitle saved (location)
  - [ ] sourceLat/sourceLng saved

- [ ] **API Lists Loaded**
  - [ ] Gender list not empty
  - [ ] Payment modes not empty
  - [ ] Entity list not empty
  - [ ] Car provider list not empty

- [ ] **Prefilling Applied**
  - [ ] Gender matches GenderId
  - [ ] Corporate matches EntityId
  - [ ] Payment mode matches PayModeID
  - [ ] Car provider is first item
  - [ ] Pickup datetime set (now + advancedHours)
  - [ ] Pickup location prefilled

- [ ] **Fallback Works**
  - [ ] If login response null, uses storage
  - [ ] If storage null, uses first item
  - [ ] If location not in storage, fetches GPS

---

## Common Issues & Solutions

### Issue: Data Not Prefilling
**Debug Steps:**
1. Check if login response is available
2. Check if storage has values
3. Check if API lists are loaded
4. Check if IDs are matching (compare logs)

**Solution:**
- Ensure login happens before navigating to booking engine
- Check network connectivity for API calls
- Verify storage permissions

---

### Issue: Location Not Prefilling
**Debug Steps:**
1. Check `sourceTitle`, `sourceLat`, `sourceLng` in storage
2. Check GPS permissions
3. Check if `_isLoadingPickupLocation` is stuck

**Solution:**
- Clear storage and let app fetch location again
- Grant location permissions
- Check if GPS is enabled on device

---

### Issue: Prefilling Happens Multiple Times
**Debug Steps:**
1. Check `_hasAppliedPrefilledData` flag
2. Check listener callbacks
3. Check for multiple `setState()` calls

**Solution:**
- Flag should prevent duplicate prefilling
- Listeners should only retry if data not already prefilled

---

## Performance Checks

### Timing Verification
Add timing logs:

```dart
final stopwatch = Stopwatch()..start();
await _applyPrefilledDataFromLogin();
stopwatch.stop();
debugPrint('⏱️ Prefilling took: ${stopwatch.elapsedMilliseconds}ms');
```

**Expected:**
- Location prefilling: < 100ms (from storage)
- Form fields prefilling: 500-2000ms (waiting for API lists)

---

## Success Criteria

✅ **All tests pass if:**
1. All fields prefilled within 2 seconds
2. Location appears immediately (from storage)
3. No crashes or errors
4. Fallback works when data missing
5. Retry mechanism works when lists load late

