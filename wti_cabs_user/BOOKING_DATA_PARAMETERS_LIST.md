# Complete List of BookingData Parameters Used in `_makeBooking()`

This document lists **ALL** parameters extracted from `CrpBookingData` (widget.bookingData) that are used in the `_makeBooking()` method.

## 📊 Summary
**Total Parameters from BookingData: 18** (15 used in API, 3 for logic/conditionals)

---

## 🗺️ Location/Pickup & Drop Parameters

### 1. **Pickup Place - Primary Text**
- **BookingData Path:** `bookingData.pickupPlace.primaryText`
- **Variable:** `rawPickupAddress` → `pickupAddress`
- **API Parameter:** `'pickupAddress'`
- **Line:** 1246-1248
- **Transformation:** Truncated to 80 characters via `_shortenForApi()`
- **Type:** `String?`
- **Default:** `''` (empty string)
- **Source:** Selected from Google Places autocomplete in booking engine

### 2. **Pickup Place - Latitude**
- **BookingData Path:** `bookingData.pickupPlace.latitude`
- **Variable:** `frmlat`
- **API Parameter:** `'frmlat'`
- **Line:** 1255
- **Transformation:** Converted to String via `.toString()`
- **Type:** `double?`
- **Default:** `''` (empty string)
- **Source:** Google Places coordinates

### 3. **Pickup Place - Longitude**
- **BookingData Path:** `bookingData.pickupPlace.longitude`
- **Variable:** `frmlng`
- **API Parameter:** `'frmlng'`
- **Line:** 1256
- **Transformation:** Converted to String via `.toString()`
- **Type:** `double?`
- **Default:** `''` (empty string)
- **Source:** Google Places coordinates

### 4. **Drop Place - Primary Text**
- **BookingData Path:** `bookingData.dropPlace.primaryText`
- **Variable:** `rawDropAddress` → `dropAddress`
- **API Parameter:** `'dropAddress'`
- **Line:** 1247, 1252
- **Transformation:** 
  - Truncated to 80 characters via `_shortenForApi()` if present
  - Empty string if drop address is empty
- **Type:** `String?`
- **Default:** `''` (empty string) if not provided
- **Source:** Selected from Google Places autocomplete (optional for round trips)

### 5. **Drop Place - Latitude**
- **BookingData Path:** `bookingData.dropPlace.latitude`
- **Variable:** `tolat`
- **API Parameter:** `'tolat'`
- **Line:** 1257
- **Transformation:** Converted to String, only included if drop address exists
- **Type:** `double?`
- **Default:** `''` (empty string if no drop address)
- **Conditional:** Only included if `hasDropAddress == true`

### 6. **Drop Place - Longitude**
- **BookingData Path:** `bookingData.dropPlace.longitude`
- **Variable:** `tolng`
- **API Parameter:** `'tolng'`
- **Line:** 1258
- **Transformation:** Converted to String, only included if drop address exists
- **Type:** `double?`
- **Default:** `''` (empty string if no drop address)
- **Conditional:** Only included if `hasDropAddress == true`

---

## 📅 Date & Time Parameters

### 7. **Pickup Date/Time**
- **BookingData Path:** `bookingData.pickupDateTime`
- **Variable:** `cabRequiredOn`
- **API Parameter:** `'cabRequiredOn'`
- **Line:** 1235
- **Transformation:** Formatted via `_formatDateTimeForAPI()` to ISO format: `'yyyy-MM-ddTHH:mm:ss'`
- **Type:** `DateTime?`
- **Default:** `''` (empty string if null)
- **Example:** `'2025-01-15T14:30:00'`
- **Source:** User-selected pickup date and time in booking engine

### 8. **Drop Date/Time**
- **BookingData Path:** `bookingData.dropDateTime`
- **Variable:** `dropoffDatetime`
- **API Parameter:** `'dropoffDatetime'`
- **Line:** 1236
- **Transformation:** Formatted via `_formatDateTimeForAPI()` to ISO format: `'yyyy-MM-ddTHH:mm:ss'`
- **Type:** `DateTime?`
- **Default:** `''` (empty string if null)
- **Example:** `'2025-01-15T20:30:00'`
- **Source:** User-selected drop/return date and time (for round trips)

---

## 🚗 Trip Type & Run Type Parameters

### 9. **Pickup Type (Run Type String)**
- **BookingData Path:** `bookingData.pickupType`
- **Variable:** Used in `_getRunTypeID()` → `runTypeID`
- **API Parameter:** `'runTypeID'`
- **Line:** 1232
- **Transformation:** 
  - String value passed to `_getRunTypeID()` helper
  - Matched against `CrpServicesController.runTypes` list
  - Returns integer `runTypeID` from matching run type
- **Type:** `String?`
- **Default:** `'2'` (if runTypeID lookup fails)
- **Examples:** `'One Way'`, `'Round Trip'`, `'Local'`, etc.
- **Source:** User-selected trip type from booking engine

### 10. **Run Type ID (Direct)**
- **BookingData Path:** `bookingData.runTypeId`
- **Variable:** Not directly used in `_makeBooking()`
- **Note:** This field exists in `CrpBookingData` model but is NOT used in `_makeBooking()`
- **Type:** `int?`
- **Purpose:** May be used elsewhere or for future reference

---

## 👤 User Selection Parameters

### 11. **Gender ID**
- **BookingData Path:** `bookingData.gender.genderID`
- **Variable:** `genderID`
- **API Parameter:** `'gender'`
- **Line:** 1239
- **Transformation:** Converted to String for API
- **Type:** `int?`
- **Default:** `1` (Male)
- **Possible Values:**
  - `1` = Male
  - `2` = Female
  - `3` = Other
- **Source:** User-selected gender from dropdown in booking engine

### 12. **Payment Mode ID**
- **BookingData Path:** `bookingData.paymentMode.id`
- **Variable:** `payMode`
- **API Parameter:** `'payMode'`
- **Line:** 1242
- **Transformation:** Converted to String for API
- **Type:** `int?`
- **Default:** `1`
- **Source:** User-selected payment mode (Cash, Card, Corporate, etc.)

### 13. **Car Provider ID**
- **BookingData Path:** `bookingData.carProvider.providerID`
- **Variable:** `providerID`
- **API Parameter:** `'providerID'`
- **Line:** 1241
- **Transformation:** Converted to String for API
- **Type:** `int?`
- **Default:** `1`
- **Source:** User-selected car provider/vendor from booking engine

### 14. **Booking Type (Corporate/Myself)**
- **BookingData Path:** `bookingData.bookingType`
- **Variable:** `bookingType`
- **API Parameter:** `'BookingType'`
- **Line:** 1243
- **Transformation:** 
  - `'Corporate'` → `'1'`
  - `'Myself'` or other → `'0'`
- **Type:** `String?`
- **Default:** `'0'` (if not 'Corporate')
- **Possible Values:** `'Corporate'` or `'Myself'`

---

## 🏢 Corporate Entity Parameter

### 15. **Entity ID (Corporate Entity)**
- **BookingData Path:** `bookingData.entityId`
- **Variable:** `bookingEntityId` → `corporateIdForApi`
- **API Parameter:** `'corporateID'`
- **Line:** 1271-1274
- **Logic:** 
  - If `entityId` is not null and not 0, use it as `corporateID`
  - Otherwise, fallback to `corporateID` from storage/profile
- **Type:** `int?`
- **Purpose:** Allows booking for different corporate entities within the same corporate account
- **Source:** User-selected entity from entity dropdown in booking engine

---

## 📝 Optional Text Fields

### 16. **Flight Details / Arrival Details**
- **BookingData Path:** `bookingData.flightDetails`
- **Variable:** `arrivalDetails`
- **API Parameter:** `'arrivalDetails'`
- **Line:** 1261
- **Type:** `String?`
- **Default:** `''` (empty string)
- **Purpose:** Flight number, train number, or other arrival details
- **Source:** User-entered text field in booking engine

### 17. **Special Instructions**
- **BookingData Path:** `bookingData.specialInstruction`
- **Variable:** `specialInstructionsRaw` → `specialInstructions`
- **API Parameter:** `'specialInstructions'`
- **Line:** 1262-1265
- **Transformation:** Truncated to 120 characters via `_shortenForApi()`
- **Type:** `String?`
- **Default:** `''` (empty string)
- **Source:** User-entered text field in booking engine

### 18. **Reference Number / Remarks**
- **BookingData Path:** `bookingData.referenceNumber`
- **Variable:** `remarks`
- **API Parameter:** `'remarks'`
- **Line:** 1267
- **Type:** `String?`
- **Default:** `''` (empty string)
- **Purpose:** User-entered reference number or notes
- **Source:** User-entered text field in booking engine

### 19. **Cost Code** ⚠️ **NOT USED IN API**
- **BookingData Path:** `bookingData.costCode`
- **Variable:** `costCode`
- **API Parameter:** `'costCode'` (set to `null`, not used)
- **Line:** 1266, 1299
- **Type:** `String?`
- **Status:** **Extracted but NOT sent to API** - explicitly set to `null` in params (line 1299)
- **Note:** Code commented out suggests it was previously used but disabled

---

## 📋 Fields in CrpBookingData Model NOT Used in _makeBooking()

These fields exist in the `CrpBookingData` model but are **NOT extracted or used** in `_makeBooking()`:

1. **`selectedTabIndex`** (int?)
   - Purpose: Tracks which tab was selected in UI (when run types <= 3)
   - Used for: UI state management only

2. **`runTypeId`** (int?)
   - Note: Not used even though `pickupType` is used to derive `runTypeID`
   - Could potentially be used directly instead of lookup

3. **`pickupPlace.secondaryText`** (String?)
   - Available but not extracted - only `primaryText` is used

4. **`pickupPlace.city`** (String?)
5. **`pickupPlace.state`** (String?)
6. **`pickupPlace.country`** (String?)
7. **`pickupPlace.placeId`** (String?)
8. **`dropPlace.secondaryText`** (String?)
9. **`dropPlace.city`** (String?)
10. **`dropPlace.state`** (String?)
11. **`dropPlace.country`** (String?)
12. **`dropPlace.placeId`** (String?)
13. **`gender.gender`** (String? - gender name, not just ID)
14. **`paymentMode` object** (only `.id` is used, other fields like name not extracted)
15. **`carProvider.providerName`** (String? - only `.providerID` is used)

---

## 📊 API Parameters Mapping Table

| BookingData Field | Variable Name | API Parameter | Required? | Default Value |
|-------------------|---------------|---------------|-----------|---------------|
| `pickupPlace.primaryText` | `pickupAddress` | `'pickupAddress'` | ✅ | `''` |
| `pickupPlace.latitude` | `frmlat` | `'frmlat'` | ✅ | `''` |
| `pickupPlace.longitude` | `frmlng` | `'frmlng'` | ✅ | `''` |
| `dropPlace.primaryText` | `dropAddress` | `'dropAddress'` | ⚠️ Conditional | `''` |
| `dropPlace.latitude` | `tolat` | `'tolat'` | ⚠️ Conditional | `''` |
| `dropPlace.longitude` | `tolng` | `'tolng'` | ⚠️ Conditional | `''` |
| `pickupDateTime` | `cabRequiredOn` | `'cabRequiredOn'` | ✅ | `''` |
| `dropDateTime` | `dropoffDatetime` | `'dropoffDatetime'` | ✅ | `''` |
| `pickupType` (via lookup) | `runTypeID` | `'runTypeID'` | ✅ | `'2'` |
| `gender.genderID` | `genderID` | `'gender'` | ✅ | `1` |
| `paymentMode.id` | `payMode` | `'payMode'` | ✅ | `1` |
| `carProvider.providerID` | `providerID` | `'providerID'` | ✅ | `1` |
| `bookingType` | `bookingType` | `'BookingType'` | ✅ | `'0'` |
| `entityId` | `corporateIdForApi` | `'corporateID'` | ⚠️ Fallback | Storage value |
| `flightDetails` | `arrivalDetails` | `'arrivalDetails'` | ❌ Optional | `''` |
| `specialInstruction` | `specialInstructions` | `'specialInstructions'` | ❌ Optional | `''` |
| `referenceNumber` | `remarks` | `'remarks'` | ❌ Optional | `''` |
| `costCode` | `costCode` | `'costCode'` | ❌ **NOT USED** | `null` |

---

## 🔍 Key Observations

1. **Character Limits Applied:**
   - `pickupAddress`: Max 80 characters
   - `dropAddress`: Max 80 characters
   - `specialInstructions`: Max 120 characters

2. **Conditional Logic:**
   - Drop address/coordinates only included if drop address is not empty
   - Entity ID only used if not null and not 0, otherwise falls back to storage corporateID

3. **Type Conversions:**
   - All numeric IDs converted to String for API
   - Dates formatted to ISO 8601 format
   - Coordinates converted to String

4. **Defaults:**
   - Most optional fields default to empty string
   - IDs default to `1` if not provided
   - `runTypeID` defaults to `'2'` if lookup fails

5. **Unused Fields:**
   - `costCode` is extracted but explicitly set to `null` in API params
   - Many `SuggestionPlacesResponse` fields (city, state, country, etc.) are not used

---

## 📁 Related Files

- **Model:** `lib/core/model/corporate/crp_booking_data/crp_booking_data.dart`
- **Usage:** `lib/screens/corporate/crp_booking_confirmation/crp_booking_confirmation.dart` (lines 1225-1274)
- **Helper Methods:**
  - `_formatDateTimeForAPI()` - Lines 1074-1078
  - `_shortenForApi()` - Lines 1082-1085
  - `_getRunTypeID()` - Lines 1087-1104

