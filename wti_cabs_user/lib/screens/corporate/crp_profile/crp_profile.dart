import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:wti_cabs_user/core/controller/profile_controller/profile_controller.dart';
import 'package:wti_cabs_user/core/route_management/app_routes.dart';
import 'package:wti_cabs_user/core/services/storage_services.dart';
import 'package:wti_cabs_user/utility/constants/colors/app_colors.dart';

class CrpProfile extends StatefulWidget {
  const CrpProfile({super.key});

  @override
  State<CrpProfile> createState() => _CrpProfileState();
}

class _CrpProfileState extends State<CrpProfile> {
  final ProfileController profileController = Get.put(ProfileController());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      profileController.fetchData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) {
          context.go(AppRoutes.cprBottomNav);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text(
            "Profile",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
              fontFamily: 'Montserrat',
            ),
          ),
          centerTitle: true,
          elevation: 0.5,
          backgroundColor: Colors.white,
          automaticallyImplyLeading: false,
        ),
        body: Obx(() {
          final profileData = profileController.profileResponse.value?.result;
          final firstName = profileData?.firstName ?? '';
          final email = profileData?.emailID ?? '';
          final contact = profileData?.contact ?? '';

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  // Profile Avatar
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.blue2.withOpacity(0.1),
                    child: Text(
                      firstName.isNotEmpty
                          ? '${firstName}}'
                          : 'U',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.blue2,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Name
                  Text(
                    '$firstName'.trim().isEmpty ? 'User' : '$firstName',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                      fontFamily: 'Montserrat',
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Email
                  if (email.isNotEmpty)
                    Text(
                      email,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                  const SizedBox(height: 30),

                  // Profile Info Cards
                  _buildInfoCard(
                    icon: Icons.email_outlined,
                    title: "Email",
                    value: email.isEmpty ? 'Not available' : email,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    icon: Icons.phone_outlined,
                    title: "Contact",
                    value: '9179419377',
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    icon: Icons.business_outlined,
                    title: "Corporate Account",
                    value: "Active",
                  ),
                  const SizedBox(height: 40),

                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () async {
                        // Clear all corporate session data
                        await StorageServices.instance.delete('crpKey');
                        await StorageServices.instance.delete('crpId');
                        await StorageServices.instance.delete('branchId');
                        await StorageServices.instance.delete('guestId');
                        await StorageServices.instance.delete('email');
                        await StorageServices.instance.delete('token');
                        
                        if (context.mounted) {
                          context.go(AppRoutes.cprLogin);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade50,
                        foregroundColor: Colors.red,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.red.shade200),
                        ),
                      ),
                      child: const Text(
                        "Logout",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Montserrat',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.blue2.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: AppColors.blue2,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontFamily: 'Montserrat',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                    fontFamily: 'Montserrat',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

