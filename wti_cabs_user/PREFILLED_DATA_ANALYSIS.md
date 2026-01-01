# Prefilled Data Analysis - Corporate Booking Engine

## Overview
This document analyzes how prefilled data works in `crp_booking_engine.dart`, including data sources, prefilling mechanisms, and the complete flow.

---

## 📊 Data Sources

### 1. **Corporate Login Response** (`CrpLoginResponse`)
**Source:** API call `GetLoginInfoV1` via `LoginInfoController.fetchLoginInfo()`

**Location:** `lib/core/controller/corporate/crp_login_controller/crp_login_controller.dart`

**Data Stored:**
- `entityId` → Saved to storage as `'crpEntityId'` (line 56)
- `genderId` → Saved to storage as `'crpGenderId'` (line 61)
- `payModeID` → Used directly from `crpLoginInfo.value`
- `advancedHourToConfirm` → Used for minimum pickup datetime

**When Saved:**
- After successful corporate login (line 52-64 in login controller)
- Also stored in `LoginInfoController.crpLoginInfo.value` (reactive GetX variable)

---

### 2. **Current Location (Pickup)**
**Source:** Multiple sources with fallback chain:

#### Primary Source: Storage (Fast Path)
**Storage Keys:**
- `'sourceTitle'` - Primary address text
- `'sourceLat'` - Latitude
- `'sourceLng'` - Longitude  
- `'sourcePlaceId'` - Google Place ID
- `'sourceCity'`, `'sourceState'`, `'sourceCountry'` - Location details
- `'sourceTypes'` - JSON array of place types
- `'sourceTerms'` - JSON array of place terms

**When Saved:**
1. **App Start** (`main.dart` lines 427-445):
   - Fetches GPS location on app launch
   - Reverse geocodes to get address
   - Searches place via Google Places API
   - Saves all location data to storage

2. **Map Picker** (`map_picker.dart` lines 148-170):
   - When user selects location on map
   - Saves selected location to storage

#### Fallback Source: GPS (Slow Path)
**When Used:**
- Only if storage doesn't have location data
- Fetches current GPS location
- Reverse geocodes via Google Maps API
- Saves to storage for future use

---

### 3. **Entity List (Corporate Entities)**
**Source:** API call via `CrpGetEntityListController.fetchAllEntities()`

**Storage:** No direct storage, but loaded into controller's reactive variable

**Prefilling Logic:**
- Matches `entityId` from login response with entity list
- Falls back to first entity if no match

---

### 4. **Gender List**
**Source:** API call via `GenderController.fetchGender()`

**Prefilling Logic:**
- Matches `genderId` from login response with gender list
- Uses storage fallback (`'crpGenderId'`) if login response not available

---

### 5. **Payment Modes**
**Source:** API call via `PaymentModeController.fetchPaymentModes()`

**Prefilling Logic:**
- Matches `payModeID` from login response with payment modes list
- Falls back to first item if no match

---

### 6. **Car Providers**
**Source:** API call via `CarProviderController.fetchCarProviders()`

**Prefilling Logic:**
- Always uses first item from list (as per requirement, line 651)

---

## 🔄 Prefilling Flow

### Initialization Sequence (`initState()`)

```
1. Prefill Current Location (IMMEDIATE - Line 108)
   └─> _prefillPickupFromCurrentLocation()
       ├─> Try storage first (fast)
       └─> Fallback to GPS if needed (slow)

2. Initialize Data (Line 113)
   └─> _initializeData()
       ├─> Handle navigation parameters
       ├─> Load preselected run type
       ├─> Load corporate entities
       ├─> Fetch API data (runTypes, payment modes, etc.)
       └─> Apply prefilled data (after delay)

3. Listeners Setup (Lines 116-160)
   ├─> Entity list changes → Retry prefilling
   ├─> Gender list changes → Retry prefilling
   └─> Car provider list changes → Retry prefilling
```

---

### Main Prefilling Method: `_applyPrefilledDataFromLogin()`

**Location:** Lines 454-664

**Execution Order:**
1. **Pickup DateTime** (Lines 486-500)
   - Uses `advancedHourToConfirm` from login response
   - Sets minimum datetime = now + (advancedHourToConfirm * 60 minutes)
   - Defaults to 0 hours if not available

2. **Wait for Lists** (Lines 506-533)
   - Polls up to 50 times (5 seconds) for:
     - Gender list
     - Payment modes list
     - Entity list
     - Car provider list

3. **Get Target IDs** (Lines 538-551)
   - Entity ID: From login response → Storage fallback
   - Gender ID: From login response → Storage fallback

4. **Apply Prefilling** (Lines 555-659)
   - **Booking Type:** Always "Corporate" (first item)
   - **Gender:** Match by `genderId`
   - **Corporate Entity:** Match by `entityId` → Fallback to first
   - **Payment Mode:** Match by `payModeID` → Fallback to first
   - **Car Provider:** Always first item
   - **Pickup DateTime:** Already set in step 1

---

## 🧪 Testing Checklist

### Test Case 1: Fresh Login (First Time)
**Scenario:** User logs in for the first time

**Expected Behavior:**
- ✅ Gender prefilled from login response `genderId`
- ✅ Corporate entity prefilled from login response `entityId`
- ✅ Payment mode prefilled from login response `payModeID`
- ✅ Car provider prefilled (first item)
- ✅ Pickup datetime = now + `advancedHourToConfirm` hours
- ✅ Pickup location = current location from storage (if available)

**How to Test:**
1. Clear app data
2. Login with corporate credentials
3. Navigate to booking engine
4. Verify all fields are prefilled

---

### Test Case 2: App Restart (Storage Fallback)
**Scenario:** User restarts app after login

**Expected Behavior:**
- ✅ Gender prefilled from storage `'crpGenderId'` (login response may be null)
- ✅ Corporate entity prefilled from storage `'crpEntityId'`
- ✅ Payment mode prefilled from login response (if available) or first item
- ✅ Car provider prefilled (first item)
- ✅ Pickup location = current location from storage

**How to Test:**
1. Login and navigate to booking engine (verify prefilled)
2. Kill app completely
3. Restart app
4. Navigate to booking engine
5. Verify all fields still prefilled from storage

---

### Test Case 3: Current Location Prefilling
**Scenario:** Pickup location should be prefilled automatically

**Expected Behavior:**
- ✅ If storage has location → Instant prefilling (no GPS fetch)
- ✅ If storage empty → GPS fetch + reverse geocode (slower)
- ✅ Loading indicator shown while fetching

**How to Test:**
1. **With Storage:**
   - Open app (location saved in main.dart)
   - Navigate to booking engine
   - Verify pickup location appears immediately

2. **Without Storage:**
   - Clear storage keys: `sourceTitle`, `sourceLat`, `sourceLng`
   - Navigate to booking engine
   - Verify loading indicator → GPS fetch → Location appears

---

### Test Case 4: Navigation from Home Screen
**Scenario:** User taps booking from corporate home screen

**Expected Behavior:**
- ✅ Pickup and drop locations cleared
- ✅ Current location prefilled immediately
- ✅ All other fields prefilled as normal

**How to Test:**
1. From corporate home screen, tap booking
2. Verify locations are cleared then current location appears
3. Verify other fields prefilled

---

### Test Case 5: Navigation from Location Selection
**Scenario:** User selects pickup/drop location and returns

**Expected Behavior:**
- ✅ Selected location preserved (not cleared)
- ✅ Other fields remain prefilled

**How to Test:**
1. Navigate to booking engine
2. Tap pickup location → Select a place
3. Return to booking engine
4. Verify selected location is preserved

---

### Test Case 6: API List Loading Delays
**Scenario:** API calls are slow or fail

**Expected Behavior:**
- ✅ Retry prefilling when lists become available (via listeners)
- ✅ No crashes if lists are empty
- ✅ Graceful fallback to first item if matching fails

**How to Test:**
1. Simulate slow network (throttle in dev tools)
2. Navigate to booking engine
3. Verify prefilling happens when lists load (check debug logs)
4. Verify no errors if lists are empty

---

### Test Case 7: Preselected Run Type
**Scenario:** User selects run type from home screen

**Expected Behavior:**
- ✅ Run type ID saved to storage `'cprSelectedRunTypeId'`
- ✅ Run type prefilled when booking engine opens
- ✅ Storage cleared after prefilling

**How to Test:**
1. From home screen, select a run type (e.g., "Airport")
2. Navigate to booking engine
3. Verify run type is prefilled
4. Verify storage is cleared

---

## 🔍 Key Methods Reference

### `_applyPrefilledDataFromLogin()` (Lines 454-664)
**Purpose:** Main prefilling method for all form fields

**Dependencies:**
- `loginInfoController.crpLoginInfo.value` - Login response
- `controller.genderList` - Gender options
- `paymentModeController.modes` - Payment modes
- `crpGetEntityListController.getAllEntityList` - Corporate entities
- `carProviderController.carProviderList` - Car providers

**Fallback Chain:**
1. Login response → Storage → First item (for entity/gender)
2. Login response → First item (for payment mode)
3. First item only (for car provider)

---

### `_prefillPickupFromCurrentLocation()` (Lines 820-889)
**Purpose:** Prefill pickup location from storage or GPS

**Flow:**
1. Check if location already selected → Skip
2. Try storage → Fast path
3. Fallback to GPS → Slow path (background)

---

### `_loadCurrentLocationFromStorage()` (Lines 715-815)
**Purpose:** Load location data from storage

**Returns:** `SuggestionPlacesResponse?` or `null` if not available

**Storage Keys Read:**
- `sourceTitle`, `sourceLat`, `sourceLng` (required)
- `sourcePlaceId`, `sourceCity`, `sourceState`, `sourceCountry` (optional)
- `sourceTypes`, `sourceTerms` (optional, JSON)

---

### `_getPrefillGenderId()` (Lines 415-436)
**Purpose:** Get gender ID for prefilling with fallback

**Priority:**
1. `loginInfoController.crpLoginInfo.value?.genderId`
2. Storage `'crpGenderId'`
3. Return 0 (no prefilling)

---

### `_tryPrefillCorporateEntity()` (Lines 667-710)
**Purpose:** Prefill corporate entity when list becomes available

**Triggered By:**
- Entity list listener (line 116)
- Build method check (line 1259)

---

## 🐛 Common Issues & Debugging

### Issue 1: Data Not Prefilling
**Check:**
1. Is login response available? → `loginInfoController.crpLoginInfo.value`
2. Are lists loaded? → Check controller list lengths
3. Are IDs matching? → Check debug logs for ID comparison
4. Is storage available? → Check `StorageServices.instance.read()`

**Debug Logs to Check:**
- `🔄 Starting _applyPrefilledDataFromLogin()`
- `✅ Prefilled Gender: ...`
- `✅ Prefilled Corporate Entity: ...`
- `💾 Stored EntityId: ...`

---

### Issue 2: Location Not Prefilling
**Check:**
1. Is location in storage? → Check `sourceTitle`, `sourceLat`, `sourceLng`
2. Is GPS permission granted?
3. Is loading state stuck? → Check `_isLoadingPickupLocation`

**Debug Logs to Check:**
- `✅ Prefilled pickup from stored location: ...`
- `⚠️ No stored location found, will fetch GPS in background`

---

### Issue 3: Prefilling Happens Multiple Times
**Check:**
- `_hasAppliedPrefilledData` flag (line 456)
- Listener callbacks (lines 116-160)
- Multiple `setState()` calls

**Solution:**
- Flag prevents duplicate prefilling
- Listeners only retry if data not already prefilled

---

## 📝 Storage Keys Summary

| Key | Source | Used For | Location Saved |
|-----|--------|----------|----------------|
| `crpEntityId` | Login API | Corporate Entity | `crp_login_controller.dart:56` |
| `crpGenderId` | Login API | Gender | `crp_login_controller.dart:61` |
| `sourceTitle` | GPS/Map | Pickup Location | `main.dart:428`, `map_picker.dart:150` |
| `sourceLat` | GPS/Map | Pickup Location | `choose_pickup_controller.dart:152` |
| `sourceLng` | GPS/Map | Pickup Location | `choose_pickup_controller.dart:153` |
| `sourcePlaceId` | GPS/Map | Pickup Location | `main.dart:427`, `map_picker.dart:149` |
| `sourceCity` | GPS/Map | Pickup Location | `main.dart:429` |
| `sourceState` | GPS/Map | Pickup Location | `main.dart:430` |
| `sourceCountry` | GPS/Map | Pickup Location | `main.dart:431` |
| `sourceTypes` | GPS/Map | Pickup Location | `main.dart:434` |
| `sourceTerms` | GPS/Map | Pickup Location | `main.dart:441` |
| `cprSelectedRunTypeId` | Home Screen | Run Type | Set when user selects run type |

---

## ✅ Verification Steps

1. **Check Login Response:**
   ```dart
   print('Login Info: ${loginInfoController.crpLoginInfo.value?.toJson()}');
   ```

2. **Check Storage:**
   ```dart
   final entityId = await StorageServices.instance.read('crpEntityId');
   final genderId = await StorageServices.instance.read('crpGenderId');
   final sourceTitle = await StorageServices.instance.read('sourceTitle');
   print('EntityId: $entityId, GenderId: $genderId, Source: $sourceTitle');
   ```

3. **Check Lists:**
   ```dart
   print('Genders: ${controller.genderList.length}');
   print('Payment Modes: ${paymentModeController.modes.length}');
   print('Entities: ${crpGetEntityListController.getAllEntityList.value?.getEntityList?.length ?? 0}');
   ```

4. **Check Prefilling Status:**
   ```dart
   print('Gender Selected: ${controller.selectedGender.value?.gender}');
   print('Entity Selected: ${selectedCorporate?.entityName}');
   print('Payment Mode: ${paymentModeController.selectedMode.value?.mode}');
   ```

---

## 🎯 Summary

**Prefilled Data Sources:**
1. **Corporate Login API** → Entity, Gender, Payment Mode, Advanced Hours
2. **Storage (from Login)** → Entity ID, Gender ID (fallback)
3. **Storage (from GPS/Map)** → Current Location
4. **API Lists** → Gender options, Payment modes, Entities, Car providers

**Prefilling Strategy:**
- **Immediate:** Current location (from storage)
- **Delayed:** Form fields (wait for API lists, then match IDs)
- **Fallback:** Storage → First item → Null

**Key Features:**
- ✅ Retry mechanism via listeners
- ✅ Storage fallback for app restart
- ✅ Fast location prefilling (storage first)
- ✅ Graceful handling of missing data

