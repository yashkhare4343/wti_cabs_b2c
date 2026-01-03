# Parameter Trace Analysis for `_makeBooking()` Method

This document traces the source of all parameters used in the `_makeBooking()` method located in:
`lib/screens/corporate/crp_booking_confirmation/crp_booking_confirmation.dart` (lines 1204-1342)

## 📋 Parameter Sources Overview

### 1. Storage Services Parameters (Async Reads)

#### `corporateID` (line 1216)
```dart
final corporateID = await StorageServices.instance.read('crpId') ?? 
    cprProfileController.crpProfileInfo.value?.corporateID.toString();
```
**Source:**
- **Primary:** Storage key `'crpId'` saved in:
  - File: `lib/screens/corporate/corporate_login/cpr_login.dart` (line 58)
  - Source: `LoginInfoController.fetchLoginInfo()` → `CrpLoginResponse.corpID`
  - Saved after successful corporate login
- **Fallback:** `CprProfileController.crpProfileInfo.value?.corporateID`
  - Populated by: `CprProfileController.fetchProfileInfo()` → API `GetUserProfileWeb`
  - File: `lib/core/controller/corporate/cpr_profile_controller/cpr_profile_controller.dart`

#### `branchID` (line 1217)
```dart
final branchID = crpBranchListController.selectedBranchId.value ?? 
    cprProfileController.crpProfileInfo.value?.branchID.toString();
```
**Source:**
- **Primary:** `CrpBranchListController.selectedBranchId.value`
  - Set by: `CrpBranchListController.selectBranch()` (line 74 in crp_branch_list_controller.dart)
  - File: `lib/core/controller/corporate/crp_branch_list_controller/crp_branch_list_controller.dart`
  - Selected from branch dropdown in UI
- **Fallback:** `CprProfileController.crpProfileInfo.value?.branchID`
  - From profile API response

#### `token` (line 1218)
```dart
final token = await StorageServices.instance.read('crpKey') ?? '';
```
**Source:**
- **Storage key:** `'crpKey'`
- **Saved in:** `lib/screens/corporate/corporate_login/cpr_login.dart` (line 57)
- **Source:** `LoginInfoController.fetchLoginInfo()` → `CrpLoginResponse.key`
- **API:** `GetLoginInfoV1`

#### `user` (line 1219)
```dart
final user = await StorageServices.instance.read('email') ?? 
    cprProfileController.crpProfileInfo.value?.emailID;
```
**Source:**
- **Primary:** Storage key `'email'`
  - **Saved in:** `lib/screens/corporate/corporate_login/cpr_login.dart` (line 81)
  - Also saved in: `ProfileController.fetchData()` (line 42 in profile_controller.dart)
  - Also saved in: Various profile update flows
- **Fallback:** `CprProfileController.crpProfileInfo.value?.emailID`

#### `uID` (line 1220) ⚠️ **POTENTIAL BUG**
```dart
final uID = await StorageServices.instance.read('guestID') ??   
    cprProfileController.crpProfileInfo.value?.guestID.toString();
```
**Source:**
- **Primary:** Storage key `'guestID'` (uppercase 'ID')
- **⚠️ ISSUE:** Storage saves as `'guestId'` (lowercase 'Id') in:
  - File: `lib/screens/corporate/corporate_login/cpr_login.dart` (line 60)
  - This mismatch means the storage read will always return null!
- **Fallback:** `CprProfileController.crpProfileInfo.value?.guestID`
- **Should read:** `'guestId'` (lowercase) to match the save operation

#### `contactCode` (line 1222)
```dart
final contactCode = await StorageServices.instance.read('contactCode') ?? 
    cprProfileController.crpProfileInfo.value?.mobile.toString();
```
**Source:**
- **Primary:** Storage key `'contactCode'`
  - **Saved in:** `ProfileController.fetchData()` (line 39 in profile_controller.dart)
  - **Source:** `ProfileResponse.result.contactCode`
  - **API:** `user/getUserDetails` (B2C API, not corporate API)
- **Fallback:** `CprProfileController.crpProfileInfo.value?.mobile` (NOTE: This seems wrong - should be contactCode, not mobile)

#### `contact` (line 1223)
```dart
final contact = await StorageServices.instance.read('contact') ?? 
    widget.contactController.text.trim();
```
**Source:**
- **Primary:** Storage key `'contact'`
  - **Saved in:** `ProfileController.fetchData()` (line 38 in profile_controller.dart)
  - **Source:** `ProfileResponse.result.contact`
- **Fallback:** `widget.contactController.text` (from form field)

---

### 2. Widget/Form Controller Parameters

#### `passengerName` (line 1227)
```dart
final passengerName = '${widget.selectedTitle} ${widget.firstNameController.text.trim()}';
```
**Source:**
- `widget.selectedTitle`: Title selected from form (Mr./Ms./Mrs.) - initialized in `_CrpBookingConfirmationState` (line 43)
- `widget.firstNameController.text`: TextEditingController for passenger name
  - Prefilled in: `_TravelerDetailsFormState._loadPrefilledData()` (lines 674-682)
  - Sources: `CprProfileController.crpProfileInfo.value?.guestName` or `LoginInfoController.crpLoginInfo.value?.guestName`

#### `email` (line 1228)
```dart
final email = widget.emailController.text.trim();
```
**Source:**
- `widget.emailController.text`: TextEditingController for email
  - Prefilled in: `_TravelerDetailsFormState._loadPrefilledData()` (lines 684-693)
  - Sources: `CprProfileController.crpProfileInfo.value?.emailID` or storage `'email'`

#### `mobile` (line 1229)
```dart
final mobile = contact.length == 10 ? contact : widget.contactController.text.trim();
```
**Source:**
- Uses `contact` (from storage) if it's 10 digits, otherwise uses `widget.contactController.text`
- `widget.contactController.text`: TextEditingController for contact number
  - Prefilled in: `_TravelerDetailsFormState._loadPrefilledData()` (lines 695-713)
  - Sources: `CprProfileController.crpProfileInfo.value?.mobile` or storage `'contact'`

---

### 3. BookingData Parameters (from widget.bookingData)

#### `runTypeID` (line 1232)
```dart
final runTypeID = _getRunTypeID(bookingData?.pickupType);
```
**Source:**
- `bookingData?.pickupType`: String from `CrpBookingData.pickupType`
- `_getRunTypeID()`: Helper method (lines 1087-1104) that:
  - Gets `CrpServicesController.runTypes.value?.runTypes`
  - Matches `pickupType` string to `runTypes[].run` (case-insensitive)
  - Returns `runTypeID` integer

#### `cabRequiredOn` (line 1235)
```dart
final cabRequiredOn = _formatDateTimeForAPI(bookingData?.pickupDateTime);
```
**Source:**
- `bookingData?.pickupDateTime`: DateTime from `CrpBookingData.pickupDateTime`
- Set in booking engine when user selects pickup date/time
- Formatted by `_formatDateTimeForAPI()` to ISO format: `'yyyy-MM-ddTHH:mm:ss'`

#### `dropoffDatetime` (line 1236)
```dart
final dropoffDatetime = _formatDateTimeForAPI(bookingData?.dropDateTime);
```
**Source:**
- `bookingData?.dropDateTime`: DateTime from `CrpBookingData.dropDateTime`
- Set in booking engine when user selects drop date/time (for round trips)
- Can be null for one-way trips

#### `genderID` (line 1239)
```dart
final genderID = bookingData?.gender?.genderID ?? 1;
```
**Source:**
- `bookingData?.gender?.genderID`: From `CrpBookingData.gender.genderID`
- Set in booking engine from gender selection dropdown
- Default: `1` (Male)

#### `providerID` (line 1241)
```dart
final providerID = bookingData?.carProvider?.providerID ?? 1;
```
**Source:**
- `bookingData?.carProvider?.providerID`: From `CrpBookingData.carProvider.providerID`
- Set in booking engine from car provider selection
- Default: `1`

#### `payMode` (line 1242)
```dart
final payMode = bookingData?.paymentMode?.id ?? 1;
```
**Source:**
- `bookingData?.paymentMode?.id`: From `CrpBookingData.paymentMode.id`
- Set in booking engine from payment mode selection
- Default: `1`

#### `bookingType` (line 1243)
```dart
final bookingType = bookingData?.bookingType == 'Corporate' ? '1' : '0';
```
**Source:**
- `bookingData?.bookingType`: String from `CrpBookingData.bookingType`
- Values: `'Corporate'` or `'Myself'`
- Converted to: `'1'` for Corporate, `'0'` for Myself

#### `pickupAddress` (lines 1246-1248)
```dart
final rawPickupAddress = bookingData?.pickupPlace?.primaryText ?? '';
final pickupAddress = _shortenForApi(rawPickupAddress, maxChars: 80);
```
**Source:**
- `bookingData?.pickupPlace?.primaryText`: From `CrpBookingData.pickupPlace.primaryText`
- `pickupPlace`: `SuggestionPlacesResponse` object selected from Google Places autocomplete
- Shortened to 80 characters max by `_shortenForApi()`

#### `dropAddress` (lines 1250-1252)
```dart
final rawDropAddress = bookingData?.dropPlace?.primaryText ?? '';
final dropAddress = hasDropAddress ? _shortenForApi(rawDropAddress, maxChars: 80) : '';
```
**Source:**
- `bookingData?.dropPlace?.primaryText`: From `CrpBookingData.dropPlace.primaryText`
- Can be empty for round trips or when no drop is selected
- Shortened to 80 characters max if present

#### `frmlat`, `frmlng` (lines 1255-1256)
```dart
final frmlat = bookingData?.pickupPlace?.latitude?.toString() ?? '';
final frmlng = bookingData?.pickupPlace?.longitude?.toString() ?? '';
```
**Source:**
- `bookingData?.pickupPlace?.latitude/longitude`: Coordinates from `SuggestionPlacesResponse`

#### `tolat`, `tolng` (lines 1257-1258)
```dart
final tolat = hasDropAddress ? (bookingData?.dropPlace?.latitude?.toString() ?? '') : '';
final tolng = hasDropAddress ? (bookingData?.dropPlace?.longitude?.toString() ?? '') : '';
```
**Source:**
- `bookingData?.dropPlace?.latitude/longitude`: Coordinates from `SuggestionPlacesResponse`
- Only included if drop address exists

#### `arrivalDetails` (line 1261)
```dart
final arrivalDetails = bookingData?.flightDetails ?? '';
```
**Source:**
- `bookingData?.flightDetails`: String from `CrpBookingData.flightDetails`
- User-entered flight/train details (optional)

#### `specialInstructions` (lines 1262-1265)
```dart
final specialInstructionsRaw = widget.bookingData?.specialInstruction ?? '';
final specialInstructions = _shortenForApi(specialInstructionsRaw, maxChars: 120);
```
**Source:**
- `bookingData?.specialInstruction`: String from `CrpBookingData.specialInstruction`
- User-entered special instructions
- Shortened to 120 characters max

#### `costCode` (line 1266)
```dart
final costCode = widget.bookingData?.costCode ?? '';
```
**Source:**
- `bookingData?.costCode`: String from `CrpBookingData.costCode`
- User-entered cost code (optional)
- **NOTE:** Not used in API params (line 1299 sets `'costCode': null`)

#### `remarks` (line 1267)
```dart
final remarks = widget.bookingData?.referenceNumber ?? '';
```
**Source:**
- `bookingData?.referenceNumber`: String from `CrpBookingData.referenceNumber`
- User-entered reference number/remarks

#### `bookingEntityId` (line 1271)
```dart
final bookingEntityId = bookingData?.entityId;
```
**Source:**
- `bookingData?.entityId`: Integer from `CrpBookingData.entityId`
- Selected corporate entity ID from booking engine
- Used to determine `corporateIdForApi` (line 1272-1274)

---

### 4. Widget.selectedCar Parameter

#### `carTypeID` (line 1240)
```dart
final carTypeID = widget.selectedCar?.makeId ?? 1;
```
**Source:**
- `widget.selectedCar`: `CrpCarModel` object passed to `CrpBookingConfirmation` widget
- **Passed from:** `CrpInventory` screen when user selects a car
- **Route:** `app_page.dart` (line 296) - passed via route `extra` parameter
- `selectedCar.makeId`: Car type/make ID from inventory API response
- Default: `1`

---

## 🔍 Flow Diagram

```
Corporate Login (cpr_login.dart)
    ↓
LoginInfoController.fetchLoginInfo()
    ↓
Save to Storage:
  - crpKey → token
  - crpId → corporateID
  - branchId → branchID (also saved)
  - guestId → uID ⚠️ (mismatch: saved as 'guestId', read as 'guestID')
  - email → user
    ↓
CprProfileController.fetchProfileInfo()
    ↓
Populate crpProfileInfo (fallback for storage values)
    ↓
Booking Engine (crp_booking_engine.dart)
    ↓
Create CrpBookingData (pickup, drop, dates, etc.)
    ↓
CrpInventory Screen
    ↓
User selects car → CrpCarModel
    ↓
Navigate to CrpBookingConfirmation(bookingData, selectedCar)
    ↓
User fills form (prefilled from profile/storage)
    ↓
_makeBooking() called
    ↓
Read all parameters (storage + controllers + bookingData + selectedCar)
    ↓
Build API params
    ↓
CprApiService.postMakeBooking()
```

---

## ⚠️ Issues Found

### 1. Storage Key Mismatch for guestID
- **Location:** Line 1220 in `crp_booking_confirmation.dart`
- **Issue:** Reads `'guestID'` (uppercase) but storage saves `'guestId'` (lowercase)
- **Impact:** `uID` will always be null, falls back to profile controller
- **Fix:** Change to `await StorageServices.instance.read('guestId')`

### 2. contactCode Fallback Logic
- **Location:** Line 1222
- **Issue:** Falls back to `cprProfileController.crpProfileInfo.value?.mobile` but should be `contactCode`
- **Impact:** May use wrong value if storage read fails

---

## 📝 Testing Recommendations

1. **Test Storage Key Consistency:**
   - Verify all storage reads match their corresponding saves
   - Check case sensitivity: `'guestID'` vs `'guestId'`

2. **Test Fallback Chains:**
   - Test when storage values are null (fresh install)
   - Test when profile controller is empty
   - Test when bookingData is missing fields

3. **Test Parameter Validation:**
   - Test with empty bookingData
   - Test with null selectedCar
   - Test with missing storage values

4. **Test Edge Cases:**
   - Round trip vs one-way (dropAddress empty)
   - Missing coordinates
   - Very long addresses (truncation at 80 chars)
   - Very long special instructions (truncation at 120 chars)

---

## 📚 Related Files

- Storage saves: `lib/screens/corporate/corporate_login/cpr_login.dart`
- Profile controller: `lib/core/controller/corporate/cpr_profile_controller/cpr_profile_controller.dart`
- Branch controller: `lib/core/controller/corporate/crp_branch_list_controller/crp_branch_list_controller.dart`
- Booking data model: `lib/core/model/corporate/crp_booking_data/crp_booking_data.dart`
- Booking confirmation: `lib/screens/corporate/crp_booking_confirmation/crp_booking_confirmation.dart`
- Route definition: `lib/core/route_management/app_page.dart`

