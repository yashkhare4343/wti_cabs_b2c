import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wti_cabs_user/core/api/corporate/cpr_api_services.dart';
import 'package:wti_cabs_user/core/controller/corporate/cpr_profile_controller/cpr_profile_controller.dart';
import 'package:wti_cabs_user/core/controller/corporate/crp_gender/crp_gender_controller.dart';
import 'package:wti_cabs_user/core/controller/corporate/crp_branch_list_controller/crp_branch_list_controller.dart';
import 'package:wti_cabs_user/core/controller/corporate/crp_get_entity_all/crp_get_entity_list_controller.dart';
import 'package:wti_cabs_user/core/model/corporate/crp_update_profile_response/crp_update_profile_response.dart';
import 'package:wti_cabs_user/core/model/corporate/crp_gender_response/crp_gender_response.dart';
import 'package:wti_cabs_user/core/model/corporate/get_entity_list/get_entity_list_response.dart';
import 'package:wti_cabs_user/screens/corporate/cpr_profile_response/cpr_profile_response.dart';

import '../../../core/controller/corporate/crp_login_controller/crp_login_controller.dart';
import '../../../core/services/storage_services.dart';

class CrpEditProfileForm extends StatefulWidget {
  final CprProfileResponse? profile;
  final String? email;
  final String? token;
  final int? guestID;

  const CrpEditProfileForm({
    super.key,
    this.profile,
    this.email,
    this.token,
    this.guestID,
  });

  @override
  State<CrpEditProfileForm> createState() => _CrpEditProfileFormState();
}

class _CrpEditProfileFormState extends State<CrpEditProfileForm> {
  final CprApiService _apiService = CprApiService();
  final CprProfileController _profileController = Get.find<CprProfileController>();
  final GenderController _genderController = Get.put(GenderController());
  final CrpBranchListController _branchController = Get.put(CrpBranchListController());
  final CrpGetEntityListController _entityController = Get.put(CrpGetEntityListController());

  bool _isLoading = false;
  
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _mobileController;
  late final TextEditingController _employeeIdController;
  late final TextEditingController _designationController;
  late final TextEditingController _costCodeController;
  late final TextEditingController _cardNoController;
  late final TextEditingController _cardExpiryController;
  
  Entity? _selectedCorporate;
  String? _selectedBranchId;
  String? _selectedBranchName;

  @override
  void initState() {
    super.initState();
    debugPrint('🟢 [Edit Profile] Form initialized');
    
    final profile = widget.profile;
    debugPrint('📋 [Edit Profile] Received profile data:');
    debugPrint('   - Profile: ${profile != null ? "Present" : "NULL"}');
    debugPrint('   - Email: ${widget.email?.isNotEmpty == true ? "${widget.email!.substring(0, widget.email!.indexOf('@'))}@..." : "NULL"}');
    debugPrint('   - Token: ${widget.token?.isNotEmpty == true ? "${widget.token!.substring(0, 20)}..." : "NULL"}');
    debugPrint('   - GuestID: ${widget.guestID ?? "NULL"}');
    
    if (profile != null) {
      debugPrint('   - Guest Name: ${profile.guestName ?? "NULL"}');
      debugPrint('   - Email ID: ${profile.emailID ?? "NULL"}');
      debugPrint('   - Mobile: ${profile.mobile ?? "NULL"}');
      debugPrint('   - Employee ID: ${profile.employeeID ?? "NULL"}');
      debugPrint('   - Gender: ${_formatGender(profile.gender)}');
      debugPrint('   - Corporate ID: ${profile.corporateID ?? "NULL"}');
      debugPrint('   - Branch ID: ${profile.branchID ?? "NULL"}');
    }
    
    _nameController = TextEditingController(text: profile?.guestName ?? '');
    _emailController = TextEditingController(text: profile?.emailID ?? '');
    _mobileController = TextEditingController(text: profile?.mobile ?? '');
    _employeeIdController = TextEditingController(text: profile?.employeeID ?? '');
    _designationController = TextEditingController(text: profile?.designation ?? '');
    _costCodeController = TextEditingController(text: profile?.costCode ?? '');
    _cardNoController = TextEditingController(text: profile?.cardNo ?? '');
    _cardExpiryController = TextEditingController(text: profile?.ccExpiry ?? '');
    
    // Set selected values
    _selectedBranchId = profile?.branchID;
    _selectedBranchName = profile?.branchName;
    
    // Fetch dropdown data
    _loadDropdownData(profile);
    
    debugPrint('✅ [Edit Profile] Controllers initialized with profile data');
  }
  
  Future<void> _loadDropdownData(CprProfileResponse? profile) async {
    // Fetch gender list
    await _genderController.fetchGender(context);
    
    // Pre-select gender if available
    if (profile?.gender != null) {
      final gender = _genderController.genderList.firstWhereOrNull(
        (g) => g.genderID == profile?.gender,
      );
      if (gender != null) {
        _genderController.selectGender(gender);
      }
    }
    
    // Fetch corporate entities
    if (widget.email != null && widget.email!.isNotEmpty) {
      await _entityController.fetchAllEntities(widget.email!, profile?.branchID ?? '');
      
      // Pre-select corporate if available
      if (profile?.corporateID != null) {
        final entity = _entityController.getAllEntityList.value?.getEntityList?.firstWhereOrNull(
          (e) => e.entityId.toString() == profile?.corporateID,
        );
        if (entity != null) {
          _selectedCorporate = entity;
        }
      }
    }
    
    // Fetch branches if corporate ID is available
    final corpId = profile?.corporateID ?? _selectedCorporate?.entityId.toString();
    if (corpId != null && corpId.isNotEmpty) {
      await _branchController.fetchBranches(corpId);
      
      // Pre-select branch if available
      if (profile?.branchName != null) {
        _branchController.selectBranch(profile?.branchName);
      }
    }
  }

  @override
  void dispose() {
    debugPrint('🔴 [Edit Profile] Form disposed - cleaning up controllers');
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _employeeIdController.dispose();
    _designationController.dispose();
    _costCodeController.dispose();
    _cardNoController.dispose();
    _cardExpiryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        surfaceTintColor: Colors.transparent,
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildUnderlineField(label: 'Name', controller: _nameController),
                          _buildUnderlineField(label: 'Email', controller: _emailController, keyboardType: TextInputType.emailAddress),
                          _buildUnderlineField(label: 'Mobile', controller: _mobileController, keyboardType: TextInputType.phone),
                          _buildUnderlineField(label: 'Employee ID', controller: _employeeIdController),
                          _buildUnderlineField(label: 'Designation', controller: _designationController),
                          _buildUnderlineField(label: 'Cost Code', controller: _costCodeController),
                          _buildGenderDropdown(),
                          _buildCorporateDropdown(),
                          _buildBranchDropdown(),
                          _buildUnderlineField(label: 'Card Number', controller: _cardNoController),
                          _buildUnderlineField(label: 'Card Expiry', controller: _cardExpiryController),
                        ].map((field) => Padding(padding: const EdgeInsets.only(bottom: 18), child: field)).toList(),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0052D4),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Save Changes',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Full-screen loader overlay when saving
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0052D4)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUnderlineField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            fontFamily: 'Montserrat',
          ),
        ),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.only(top: 12, bottom: 4),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFCCCCCC)),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF0052D4), width: 1.4),
            ),
          ),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  String _formatGender(int? value) {
    switch (value) {
      case 1:
        return 'Male';
      case 2:
        return 'Female';
      case 3:
        return 'Other';
      default:
        return '';
    }
  }

  Widget _buildGenderDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Gender',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            fontFamily: 'Montserrat',
          ),
        ),
        const SizedBox(height: 10),
        Obx(() {
          return GestureDetector(
            onTap: () => _showGenderBottomSheet(),
            child: Container(
              padding: const EdgeInsets.only(bottom: 4),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color(0xFFCCCCCC)),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _genderController.selectedGender.value?.gender ?? 'Select Gender',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _genderController.selectedGender.value != null
                            ? Colors.black
                            : Colors.grey,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    color: Color(0xFF666666),
                    size: 20,
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildCorporateDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Corporate',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            fontFamily: 'Montserrat',
          ),
        ),
        const SizedBox(height: 10),
        Obx(() {
          final entities = _entityController.getAllEntityList.value?.getEntityList ?? [];
          return GestureDetector(
            onTap: () => _showCorporateBottomSheet(),
            child: Container(
              padding: const EdgeInsets.only(bottom: 4),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color(0xFFCCCCCC)),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedCorporate?.entityName ?? 'Select Corporate',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _selectedCorporate != null
                            ? Colors.black
                            : Colors.grey,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    color: Color(0xFF666666),
                    size: 20,
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildBranchDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Branch',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            fontFamily: 'Montserrat',
          ),
        ),
        const SizedBox(height: 10),
        Obx(() {
          return GestureDetector(
            onTap: () => _showBranchBottomSheet(),
            child: Container(
              padding: const EdgeInsets.only(bottom: 4),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color(0xFFCCCCCC)),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _branchController.selectedBranchName.value ?? 'Select Branch',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _branchController.selectedBranchName.value != null
                            ? Colors.black
                            : Colors.grey,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    color: Color(0xFF666666),
                    size: 20,
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  void _showGenderBottomSheet() {
    final list = _genderController.genderList;
    showModalBottomSheet<GenderModel>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Text(
                  'Select Gender',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final item = list[index];
                    final isSelected = _genderController.selectedGender.value == item;
                    return ListTile(
                      title: Text(item.gender ?? ''),
                      trailing: isSelected
                          ? const Icon(Icons.check, color: Color(0xFF0052D4))
                          : null,
                      onTap: () {
                        _genderController.selectGender(item);
                        Navigator.of(ctx).pop();
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _showCorporateBottomSheet() {
    final entities = _entityController.getAllEntityList.value?.getEntityList ?? [];
    if (entities.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No corporate entities found'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showModalBottomSheet<Entity>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Text(
                  'Select Corporate',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: entities.length,
                  itemBuilder: (context, index) {
                    final item = entities[index];
                    final isSelected = _selectedCorporate?.entityId == item.entityId;
                    return ListTile(
                      title: Text(item.entityName ?? ''),
                      trailing: isSelected
                          ? const Icon(Icons.check, color: Color(0xFF0052D4))
                          : null,
                      onTap: () {
                        setState(() {
                          _selectedCorporate = item;
                          // Fetch branches for selected corporate
                          _branchController.fetchBranches(item.entityId.toString());
                        });
                        Navigator.of(ctx).pop();
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _showBranchBottomSheet() {
    final branches = _branchController.branchNames;
    if (branches.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No branches found. Please select a corporate first.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Text(
                  'Select Branch',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: branches.length,
                  itemBuilder: (context, index) {
                    final branchName = branches[index];
                    final isSelected = _branchController.selectedBranchName.value == branchName;
                    return ListTile(
                      title: Text(branchName),
                      trailing: isSelected
                          ? const Icon(Icons.check, color: Color(0xFF0052D4))
                          : null,
                      onTap: () {
                        _branchController.selectBranch(branchName);
                        setState(() {
                          _selectedBranchId = _branchController.selectedBranchId.value;
                          _selectedBranchName = branchName;
                        });
                        Navigator.of(ctx).pop();
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleSave() async {
    final LoginInfoController loginInfoController = Get.put(LoginInfoController());

    if (_isLoading) {
      debugPrint('⏸️ [Edit Profile] Save button tapped but already loading, ignoring');
      return;
    }

    debugPrint('🔵 [Edit Profile] Save button tapped');
    
    setState(() {
      _isLoading = true;
    });

    try {
      // Get required values from widget parameters
      final email = widget.email ?? '';
      final token = widget.token ?? '';
      final guestID = widget.guestID ?? widget.profile?.guestID ?? 0;

      debugPrint('📋 [Edit Profile] Extracted values:');
      debugPrint('   - Email: ${email.isNotEmpty ? "${email.substring(0, email.indexOf('@'))}@..." : "EMPTY"}');
      debugPrint('   - Token: ${token.isNotEmpty ? "${token.substring(0, 20)}..." : "EMPTY"}');
      debugPrint('   - GuestID: $guestID');

      if (email.isEmpty || token.isEmpty) {
        debugPrint('❌ [Edit Profile] Missing required authentication data');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Missing required authentication data'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Log all form field values before preparing params
      debugPrint('📝 [Edit Profile] Form field values:');
      debugPrint('   - Name: ${_nameController.text.trim()}');
      debugPrint('   - Email: ${_emailController.text.trim()}');
      debugPrint('   - Mobile: ${_mobileController.text.trim()}');
      debugPrint('   - Employee ID: ${_employeeIdController.text.trim()}');
      debugPrint('   - Designation: ${_designationController.text.trim()}');
      debugPrint('   - Cost Code: ${_costCodeController.text.trim()}');
      debugPrint('   - Branch Name: ${_branchController.selectedBranchName.value ?? "NULL"}');
      debugPrint('   - Branch ID: ${_branchController.selectedBranchId.value ?? "NULL"}');
      debugPrint('   - Corporate Name: ${_selectedCorporate?.entityName ?? "NULL"}');
      debugPrint('   - Corporate ID: ${_selectedCorporate?.entityId.toString() ?? "NULL"}');
      debugPrint('   - Card Number: ${_cardNoController.text.trim()}');
      debugPrint('   - Card Expiry: ${_cardExpiryController.text.trim()}');
      debugPrint('   - Gender: ${_genderController.selectedGender.value?.gender ?? "NULL"}');
      debugPrint('   - Gender ID: ${_genderController.selectedGender.value?.genderID ?? "NULL"}');

      // Prepare API parameters
      final genderId = _genderController.selectedGender.value?.genderID;
      final branchId = _branchController.selectedBranchId.value ?? _selectedBranchId ?? '';
      final corporateId = _selectedCorporate?.entityId.toString() ?? '';
      
      final params = <String, dynamic>{
        'gID': guestID,
        'employeeID': _employeeIdController.text.trim(),
        'mobile': _mobileController.text.trim(),
        'designation': _designationController.text.trim(),
        'branchID': branchId,
        'costCode': _costCodeController.text.trim(),
        'gender': genderId?.toString() ?? '',
        'approving_auth_emailID': email,
        'corporateID': corporateId,
        'token': loginInfoController.crpLoginInfo.value?.key??'',
        'user': await StorageServices.instance.read('email'),
      };

      debugPrint('📤 [Edit Profile] API Request:');
      debugPrint('   - Endpoint: PostUpdateProfile_V2');
      debugPrint('   - Params: $params');
      debugPrint('   - Gender ID: $genderId');
      debugPrint('   - Branch ID: $branchId');
      debugPrint('   - Corporate ID: $corporateId');

      // Call API
      final response = await _apiService.postRequestParamsNew<CrpUpdateProfileResponse>(
        'PostUpdateProfile_V2',
        params,
        (data) {
          debugPrint('📥 [Edit Profile] Raw API Response:');
          debugPrint('   - Type: ${data.runtimeType}');
          debugPrint('   - Data: $data');
          
          // The API service already handles double-encoding, so data should be a Map or String
          if (data is String) {
            // If it's still a string, try to decode it
            try {
              String decoded = data;
              debugPrint('   - Decoding string response...');
              // Remove outer quotes if present
              if (decoded.startsWith('"') && decoded.endsWith('"')) {
                decoded = decoded.substring(1, decoded.length - 1);
                debugPrint('   - Removed outer quotes');
              }
              // Try to parse as JSON
              if (decoded.startsWith('{') && decoded.endsWith('}')) {
                final jsonMap = jsonDecode(decoded) as Map<String, dynamic>;
                debugPrint('   - Parsed JSON: $jsonMap');
                return CrpUpdateProfileResponse.fromJson(jsonMap);
              }
              // If not JSON, treat as message
              debugPrint('   - Treating as message string');
              return CrpUpdateProfileResponse(sMessage: decoded);
            } catch (e) {
              debugPrint('   - Error decoding: $e');
              return CrpUpdateProfileResponse(sMessage: data);
            }
          }
          if (data is Map<String, dynamic>) {
            debugPrint('   - Response is Map, parsing directly');
            return CrpUpdateProfileResponse.fromJson(data);
          }
          // Fallback
          debugPrint('   - Fallback: empty response');
          return CrpUpdateProfileResponse.fromJson({});
        },
        context,
      );

      debugPrint('✅ [Edit Profile] Parsed Response:');
      debugPrint('   - bStatus: ${response.bStatus}');
      debugPrint('   - sMessage: ${response.sMessage}');

      // Show message based on bStatus
      if (response.bStatus == true) {
        debugPrint('✅ [Edit Profile] Update successful');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.sMessage ?? 'Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Fetch updated profile data
        debugPrint('🔄 [Edit Profile] Fetching updated profile data...');
        try {
          final refreshParams = <String, dynamic>{
            'email': email,
            'GuestID': guestID.toString(),
            'token': token,
            'user': email,
          };
          
          await _profileController.fetchProfileInfo(refreshParams, context);
          debugPrint('✅ [Edit Profile] Profile data refreshed successfully');
        } catch (e) {
          debugPrint('⚠️ [Edit Profile] Error refreshing profile: $e');
          // Continue with navigation even if refresh fails
        }
        
        // Pop back to previous screen on success
        debugPrint('⏳ [Edit Profile] Waiting 500ms before navigating back');
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            debugPrint('🔙 [Edit Profile] Navigating back to previous screen');
            Navigator.of(context).pop();
          } else {
            debugPrint('⚠️ [Edit Profile] Widget unmounted, skipping navigation');
          }
        });
      } else {
        debugPrint('❌ [Edit Profile] Update failed');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.sMessage ?? 'Failed to update profile'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [Edit Profile] Exception occurred:');
      debugPrint('   - Error: $e');
      debugPrint('   - StackTrace: $stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        debugPrint('🔄 [Edit Profile] Resetting loading state');
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
