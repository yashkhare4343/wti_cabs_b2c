==============================
1. API INVENTORY
==============================

For EACH API:

**Internal corporate APIs (base: `http://103.208.202.180:120/api/Info` unless noted)**

API Name: GetLoginInfoV1  
Endpoint: `/GetLoginInfoV1`  
HTTP Method: GET  
Base URL Source (env/config/hardcoded): **Hardcoded** in `CprApiService.baseUrl` (`cpr_api_services.dart`)  
Triggered From (Screen/Widget): `corporate_login/cpr_login.dart` (login button / submit handler)  
Controller/Bloc: `LoginInfoController.fetchLoginInfo()` (`crp_login_controller.dart`)  
ApiService Method: `CprApiService.getRequestCrp<CrpLoginResponse>()`  

------------------------------

API Name: GetUserProfileWeb  
Endpoint: `/GetUserProfileWeb`  
HTTP Method: GET  
Base URL Source: **Hardcoded** in `CprApiService.baseUrl`  
Triggered From: `crp_profile/crp_profile.dart` (profile screen init / refresh)  
Controller/Bloc: `CprProfileController.fetchProfileInfo()`  
ApiService Method: `CprApiService.getRequestCrp<CprProfileResponse>()`  

------------------------------

API Name: GetBookingHistory  
Endpoint: `/GetBookingHistory`  
HTTP Method: GET  
Base URL Source: Hardcoded in `CprApiService.baseUrl`  
Triggered From: `crp_home_screen/crp_home_screen.dart` (booking history section / pagination)  
Controller/Bloc: `CrpBookingHistoryController.fetchBookingHistory()`  
ApiService Method: `CprApiService.getRequestCrp<CrpBookingHistoryResponse>()`  

------------------------------

API Name: GetBooking_detail_byorderId  
Endpoint: `/GetBooking_detail_byorderId`  
HTTP Method: GET  
Base URL Source: Hardcoded in `CprApiService.baseUrl`  
Triggered From: `crp_booking_details/crp_booking_details.dart` (booking details screen init)  
Controller/Bloc: `CrpBookingDetailsController.fetchBookingData()`  
ApiService Method: `CprApiService.getRequest<CrpBookingDetailsResponse>()`  

------------------------------

API Name: GetDriveDetails  
Endpoint: `/GetDriveDetails`  
HTTP Method: GET  
Base URL Source: Hardcoded in `CprApiService.baseUrl`  
Triggered From: `crp_booking_details/crp_booking_details.dart` (driver info section)  
Controller/Bloc: `CrpBookingDetailsController.fetchDriverDetails()`  
ApiService Method: `CprApiService.getRequest<CrpDriverDetailsResponse>()`  

------------------------------

API Name: GetBranches_Reg  
Endpoint: `/GetBranches_Reg`  
HTTP Method: GET  
Base URL Source: Hardcoded URL inside `CrpBranchListController` (not via `baseUrl`)  
Triggered From: `corporate_landing_page/corporate_landing_page.dart` (branch selection)  
Controller/Bloc: `CrpBranchListController.fetchBranches()`  
ApiService Method: Direct HTTP via `CprApiService.sendRequestWithRetry()` (no typed wrapper)  

------------------------------

API Name: GetAllCarModelsV1  
Endpoint: `/GetAllCarModelsV1`  
HTTP Method: GET  
Base URL Source: Hardcoded in `CprApiService.baseUrl`  
Triggered From: `crp_inventory/crp_inventory.dart` (inventory screen init/filter)  
Controller/Bloc: `CrpInventoryListController.fetchCarModels()`  
ApiService Method: `CprApiService.getRequestCrp<CrpCarModelsResponse>()`  

------------------------------

API Name: CabTrackingV1  
Endpoint: `/CabTrackingV1`  
HTTP Method: GET  
Base URL Source: Hardcoded in `CprApiService.baseUrl`  
Triggered From: `crp_cab_tracking/crp_cab_tracking_screen.dart` (tracking screen, polling)  
Controller/Bloc: `CrpCabTrackingController.fetchTrackingData()`  
ApiService Method: `CprApiService.getRequest<CrpCabTrackingResponse>()`  

------------------------------

API Name: PostMakeBooking  
Endpoint: `/PostMakeBooking`  
HTTP Method: POST (query-string params)  
Base URL Source: Hardcoded in `CprApiService.baseUrl`  
Triggered From: `crp_booking_confirmation/crp_booking_confirmation.dart` (confirm booking button)  
Controller/Bloc: **NONE** (screen calls `CprApiService.postMakeBooking()` directly)  
ApiService Method: `CprApiService.postMakeBooking()` → `postRequestParamsNew()`  

------------------------------

API Name: PostRegisterV1  
Endpoint: `/PostRegisterV1`  
HTTP Method: POST (query-string params)  
Base URL Source: Hardcoded in `CprApiService.baseUrl`  
Triggered From: `crp_register/crp_register.dart` (register/submit action)  
Controller/Bloc: `CrpRegisterController.verifyCrpRegister()`  
ApiService Method: `CprApiService.postRequestParamsNew<CrpRegisterResponse>()`  

------------------------------

API Name: GetCorporateName  
Endpoint: `/GetCorporateName`  
HTTP Method: GET  
Base URL Source: Hardcoded in `CprApiService.baseUrl`  
Triggered From: `corporate_landing_page/corporate_landing_page.dart` (corporate email verification)  
Controller/Bloc: `VerifyCorporateController.verifyCorporate()`  
ApiService Method: `CprApiService.getRequestNew<CprVerifyResponse>()`  

------------------------------

API Name: GetUserEntities  
Endpoint: `/GetUserEntities`  
HTTP Method: GET  
Base URL Source: Hardcoded in `CprApiService.baseUrl`  
Triggered From: `crp_register/crp_register.dart` (entity dropdown loading)  
Controller/Bloc: `CrpGetEntityListController.fetchAllEntities()`  
ApiService Method: `CprApiService.getRequestNew<EntityListResponse>()`  

------------------------------

API Name: GetFiscal  
Endpoint: `/GetFiscal`  
HTTP Method: GET  
Base URL Source: **Hardcoded alternate**: `http://services.aaveg.co.in/api/Info` (inside `CrpFiscalYearController`)  
Triggered From: `crp_booking/crp_booking.dart` (fiscal year selection)  
Controller/Bloc: `CrpFiscalYearController.fetchFiscalYears()`  
ApiService Method: Direct HTTP (not via `CprApiService` wrapper)  

------------------------------

API Name: GetGender  
Endpoint: `/GetGender`  
HTTP Method: GET  
Base URL Source: Hardcoded in `CprApiService.baseUrl`  
Triggered From: `crp_register/crp_register.dart` (gender dropdown)  
Controller/Bloc: `GenderController.fetchGender()`  
ApiService Method: `CprApiService.getRequestCrp<List<GenderModel>>()`  

------------------------------

API Name: GetCarProviders  
Endpoint: `/GetCarProviders`  
HTTP Method: GET  
Base URL Source: Hardcoded in `CprApiService.baseUrl`  
Triggered From: `crp_booking_engine/crp_booking_engine.dart` (car provider dropdown)  
Controller/Bloc: `CarProviderController.fetchCarProviders()`  
ApiService Method: `CprApiService.getRequestCrp<List<CarProviderModel>>()`  

------------------------------

API Name: GetPayMode  
Endpoint: `/GetPayMode`  
HTTP Method: GET  
Base URL Source: Hardcoded in `CprApiService.baseUrl`  
Triggered From: `crp_booking_engine/crp_booking_engine.dart` (payment mode selection)  
Controller/Bloc: `PaymentModeController.fetchPaymentModes()`  
ApiService Method: `CprApiService.getRequestCrp<PaymentModeResponse>()`  

------------------------------

API Name: GetRunType  
Endpoint: `/GetRunType`  
HTTP Method: GET  
Base URL Source: Hardcoded in `CprApiService.baseUrl`  
Triggered From: `crp_booking_engine/crp_booking_engine.dart` (run type/service type selection)  
Controller/Bloc: `CrpServicesController.fetchRunTypes()`  
ApiService Method: `CprApiService.getRequestCrp<RunTypeResponse>()`  

------------------------------

API Name: GetFeedBackQuestion  
Endpoint: `/GetFeedBackQuestion`  
HTTP Method: GET  
Base URL Source: Hardcoded in `CprApiService.baseUrl`  
Triggered From: `crp_booking_details/crp_booking_details.dart` (feedback bottom sheet)  
Controller/Bloc: `CrpFeedbackQuestionsController.fetchFeedbackQuestions()`  
ApiService Method: `CprApiService.getRequestCrp<CrpFeedbackQuestionsResponse>()`  

------------------------------

API Name: PostFeedBackAnswer  
Endpoint: `/PostFeedBackAnswer`  
HTTP Method: POST (query-string params)  
Base URL Source: Hardcoded in `CprApiService.baseUrl`  
Triggered From: `crp_booking_details/crp_booking_details.dart` (submit feedback)  
Controller/Bloc: `CrpFeedbackQuestionsController.submitFeedback()`  
ApiService Method: `CprApiService.postRequestParamsNew<CrpFeedbackSubmissionResponse>()`  

------------------------------

API Name: PostEditBooking  
Endpoint: `/PostEditBooking`  
HTTP Method: POST (query-string params)  
Base URL Source: Hardcoded in `CprApiService.baseUrl`  
Triggered From: `cpr_modify_booking/cpr_modify_booking.dart` (modify booking confirm)  
Controller/Bloc: **NONE** (screen calls `postRequestParamsNew()` directly)  
ApiService Method: `CprApiService.postRequestParamsNew<Map<String, dynamic>>()`  

------------------------------

API Name: PostCancelBooking  
Endpoint: `/PostCancelBooking`  
HTTP Method: POST (query-string params)  
Base URL Source: Hardcoded in `CprApiService.baseUrl`  
Triggered From: `cpr_modify_booking/cpr_modify_booking.dart` (cancel booking action)  
Controller/Bloc: **NONE** (screen calls `postRequestParamsNew()` directly)  
ApiService Method: `CprApiService.postRequestParamsNew<Map<String, dynamic>>()`  

------------------------------

API Name: PostUpdatePassword  
Endpoint: `/PostUpdatePassword`  
HTTP Method: POST (query-string params)  
Base URL Source: Hardcoded in `CprApiService.baseUrl`  
Triggered From: `cpr_change_password/cpr_change_password.dart` (update password submit)  
Controller/Bloc: **NONE** (screen calls `postRequestParamsNew()` directly)  
ApiService Method: `CprApiService.postRequestParamsNew<Map<String, dynamic>>()`  

------------------------------

API Name: PostUpdateProfile_V2  
Endpoint: `/PostUpdateProfile_V2`  
HTTP Method: POST (query-string params)  
Base URL Source: Hardcoded in `CprApiService.baseUrl`  
Triggered From: `crp_edit_profile/crp_edit_profile_form.dart` (save profile)  
Controller/Bloc: **NONE** (screen calls `postRequestParamsNew()` directly)  
ApiService Method: `CprApiService.postRequestParamsNew<CrpUpdateProfileResponse>()`  

------------------------------

API Name: SOSAlert  
Endpoint: `/SOSAlert`  
HTTP Method: POST  
Base URL Source: Hardcoded in `CprApiService.baseUrl`  
Triggered From: `crp_booking_details/crp_booking_details.dart` (SOS button)  
Controller/Bloc: **NONE** (screen calls `CprApiService.sendRequestWithRetry()` directly)  
ApiService Method: `CprApiService.sendRequestWithRetry()`  

------------------------------

API Name: GetSendPassOTP  
Endpoint: `/GetSendPassOTP`  
HTTP Method: GET  
Base URL Source: Hardcoded in `CprApiService.baseUrl` or local constant (inside forgot-password screen)  
Triggered From: `cpr_forgot_password/cpr_forgot_password.dart` (`_sendOTP()`, `_resendOTP()`)  
Controller/Bloc: **NONE** (screen uses direct HTTP)  
ApiService Method: Direct `http.get` (not via `CprApiService`)  

------------------------------

API Name: GetCheckPassOTP  
Endpoint: `/GetCheckPassOTP`  
HTTP Method: GET  
Base URL Source: Hardcoded in same forgot-password context  
Triggered From: `cpr_forgot_password/cpr_forgot_password.dart` (`_verifyOTPAndResetPassword()`)  
Controller/Bloc: **NONE** (screen uses direct HTTP)  
ApiService Method: Direct `http.get`  

------------------------------

API Name: auth/refresh (internal)  
Endpoint: `/auth/refresh`  
HTTP Method: POST  
Base URL Source: Likely derived from same corporate base; exact construction **UNKNOWN** (internal to `CprApiService._refreshToken()`)  
Triggered From: **NONE (internal)** – called from `CprApiService` on 401 (currently mostly prefers logout flow)  
Controller/Bloc: **NONE (internal)**  
ApiService Method: `CprApiService._refreshToken()`  

------------------------------

**External APIs (Google)**

API Name: Google Places Autocomplete  
Endpoint: `/maps/api/place/autocomplete/json`  
HTTP Method: GET  
Base URL Source: Hardcoded `https://maps.googleapis.com` in pickup/drop controllers  
Triggered From: corporate select pickup/drop screens (under `screens/corporate/select_pickup` and `select_drop`)  
Controller/Bloc: `CrpSelectPickupController`, `CrpSelectDropController`  
ApiService Method: Direct `http.get` (no shared wrapper)  

------------------------------

API Name: Google Place Details  
Endpoint: `/maps/api/place/details/json`  
HTTP Method: GET  
Base URL Source: Hardcoded `https://maps.googleapis.com`  
Triggered From: same pickup/drop flows when user selects a suggestion  
Controller/Bloc: `CrpSelectPickupController`, `CrpSelectDropController`  
ApiService Method: Direct `http.get`  

------------------------------

API Name: Google Directions  
Endpoint: `/maps/api/directions/json`  
HTTP Method: GET  
Base URL Source: Hardcoded `https://maps.googleapis.com`  
Triggered From: `crp_cab_tracking/crp_cab_tracking_screen.dart` (route polyline for tracking)  
Controller/Bloc: `CrpCabTrackingController.fetchRoute()`  
ApiService Method: Direct `http.get`  

------------------------------


==============================
2. REQUEST ANALYSIS
==============================

See the in-editor report for headers, parameters, and body analysis per API. This markdown file mirrors the structure of the PDF you can export from your editor.

==============================
3. RESPONSE ANALYSIS
==============================

As detailed in the assistant report: for each API, list the success and error response handling based on your UI and controller usage.

==============================
4. API FLOW & DEPENDENCIES
==============================

Login → token & IDs saved → booking/profile/engine APIs → feedback, modify/cancel, tracking as described in the assistant report.

==============================
5. VALIDATION & TEST CASES
==============================

Use this file as the canonical source to define positive and negative test cases per API, based on the patterns already outlined by the assistant.

==============================
6. SECURITY & COMPLIANCE CHECK
==============================

Summarizes HTTP vs HTTPS usage, query-string sensitive data, basic auth, and Google API key exposure.

==============================
7. IMPROVEMENT SUGGESTIONS
==============================

Captures missing validations, unsafe patterns, redundant params, type/model gaps, error handling, and performance issues.

==============================
8. FINAL SUMMARY
==============================

Total APIs found, high-risk APIs, validation gaps, error handling gaps, and tight UI coupling are summarized for PDF export.

