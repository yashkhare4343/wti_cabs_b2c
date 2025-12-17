import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:go_router/go_router.dart';
import 'package:wti_cabs_user/core/controller/corporate/crp_services_controller/crp_sevices_controller.dart';
import 'package:wti_cabs_user/core/controller/corporate/crp_login_controller/crp_login_controller.dart';
import 'package:wti_cabs_user/core/controller/corporate/verify_corporate/verify_corporate_controller.dart';
import 'package:wti_cabs_user/core/route_management/app_routes.dart';
import 'package:wti_cabs_user/screens/bottom_nav/bottom_nav.dart';

import '../../../../common_widget/textformfield/read_only_textformfield.dart';
import '../../../../utility/constants/colors/app_colors.dart';
import '../../../core/controller/corporate/crp_branch_list_controller/crp_branch_list_controller.dart';
import '../../../core/services/storage_services.dart';
import '../../../utility/constants/fonts/common_fonts.dart';
import '../../home/home_screen.dart';

class CprHomeScreen extends StatefulWidget {
  const CprHomeScreen({super.key});

  @override
  State<CprHomeScreen> createState() => _CprHomeScreenState();
}

class _CprHomeScreenState extends State<CprHomeScreen> {
  final LoginInfoController loginInfoController = Get.put(LoginInfoController());
  @override
  void initState() {
    super.initState();
    // ✅ Load params asynchronously and then fetch run types
    _loadParamsAndFetchRunTypes();
    
    // Fetch branches and show bottom sheet when screen appears
    _fetchBranchesAndShowBottomSheet();
  }

  /// Load params from storage and fetch run types
  Future<void> _loadParamsAndFetchRunTypes() async {
    try {
      // ✅ Ensure corporate/branch ids are available (fallback to last login)
      var corpId = await StorageServices.instance.read('crpId');
      var branchId = await StorageServices.instance.read('branchId');

      // Fallback to login response if storage is empty (and persist it)
      final loginCorpId = loginInfoController.crpLoginInfo.value?.corpID;
      final loginBranchId = loginInfoController.crpLoginInfo.value?.branchID;

      if (corpId == null || corpId.isEmpty || corpId == '0') {
        if (loginCorpId != null && loginCorpId.isNotEmpty) {
          corpId = loginCorpId;
          await StorageServices.instance.save('crpId', loginCorpId);
          debugPrint('✅ Stored corpId from login response: $loginCorpId');
        }
      }

      if (branchId == null || branchId.isEmpty || branchId == '0') {
        if (loginBranchId != null && loginBranchId.isNotEmpty) {
          branchId = loginBranchId;
          await StorageServices.instance.save('branchId', loginBranchId);
          debugPrint('✅ Stored branchId from login response: $loginBranchId');
        }
      }

      // Final fallbacks
      corpId = corpId ?? '0';
      branchId = branchId ?? '0';
      
      final params = {
        'CorpID': corpId,
        'BranchID': branchId,
      };
      
      debugPrint('✅ Loaded params for run types: $params');
      
      // Fetch run types with actual values
      if (mounted) {
        await runTypeController.fetchRunTypes(params, context);
      }
    } catch (e) {
      debugPrint('❌ Error loading params for run types: $e');
    }
  }

  Future<void> _fetchBranchesAndShowBottomSheet() async {
    // Get corporate ID - use from verifyCorporateController or fallback to params
    final corpId = await StorageServices.instance.read('crpId');

    // Fetch branches
    await crpGetBranchListController.fetchBranches(corpId ?? '');

    // Show bottom sheet after a short delay to ensure screen is fully built

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _showBranchSelectorBottomSheet();
          }
        });
      }
    });
  }

  Future<void> _showBranchSelectorBottomSheet({bool forceShow = false}) async {
    // Fetch branches if not already loaded
    if (crpGetBranchListController.branchNames.isEmpty) {
      final corpId = await StorageServices.instance.read('crpId');
      await crpGetBranchListController.fetchBranches(corpId ?? '');
    }

    final items = crpGetBranchListController.branchNames;
    final selected = crpGetBranchListController.selectedBranchName.value ?? '';

    if (items.isEmpty) {
      Get.snackbar("No Branches", "No branches found for this corporate ID",
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    // Always show bottom sheet if forceShow is true (manual tap from OfficeBranchTile)
    // Otherwise, only show if count is 0 (first time automatic display)
    if(forceShow) {
      // Always show when manually tapped from OfficeBranchTile
      _displayBranchBottomSheet(context, items, selected);
    } else if(crpGetBranchListController.count.value == 0) {
      // Only show automatically on first load if no branch is selected yet
      _displayBranchBottomSheet(context, items, selected);
    }
  }

  void _displayBranchBottomSheet(BuildContext context, List<String> items, String selected) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        // Keep track of the temporary selection so we can highlight instantly
        String? tempSelected = selected.isNotEmpty ? selected : null;

        return PopScope(
          canPop: false,
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.9,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Top Illustration/Banner
                      Padding(
                        padding:
                            const EdgeInsets.only(left: 20, right: 20, top: 25),
                        child: ClipRRect(
                          borderRadius:
                              const BorderRadius.all(Radius.circular(10)),
                          child: Container(
                            height: 228,
                            width: double.infinity,
                            color: Colors.white, // optional background
                            child: Image.asset(
                              'assets/images/select_branch_img.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),

                      // Heading Section
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                        child: Row(
                          children: [
                            const Text(
                              "Choose City Branch",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF000000),
                                // letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Branch List
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: items.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final name = items[index];
                            final isSelected = name == tempSelected;

                            return Material(
                              color: Colors.transparent,
                              child: InkWell(
                                splashColor: Colors.transparent,
                                onTap: () {
                                  // Update controller value
                                  crpGetBranchListController.selectBranch(name);
                                  // Update local temp selection so UI highlights instantly
                                  setModalState(() {
                                    tempSelected = name;
                                  });
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 10,
                                  ),
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(
                                            0xFFE3F2FD) // Light blue background
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    name,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      color: isSelected
                                          ? const Color(
                                              0xFF333333) // Blue text when selected
                                          : const Color(
                                              0xFF333333), // Gray text when not selected
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity, // full width
                        height: 48,
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              crpGetBranchListController.count.value ++;
                            });
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4082F1), // #4082F1
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(39),
                              side: const BorderSide(
                                  color: Color(0xFFD9D9D9), width: 1),
                            ),
                            elevation: 0, // Remove default shadow
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // gap: 12px
                              const Text(
                                "Confirm",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }


  final CrpServicesController runTypeController =
      Get.put(CrpServicesController());
  final VerifyCorporateController verifyCorporateController =
      Get.put(VerifyCorporateController());
  final CrpBranchListController crpGetBranchListController =
      Get.put(CrpBranchListController());

  // getImageForService

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
          child: Column(
        children: [
          SizedBox(height: 290, child: TopBanner()),
          // services dynamic
          SizedBox(height: 20),
          // selected location
          //  Padding(
          //    padding: const EdgeInsets.symmetric(horizontal: 20.0),
          //    child: Row(
          //      children: [
          //        Text('Selected Location', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),),
          //      ],
          //    ),
          //  ),
          //  SizedBox(height: 10,),
          // Obx(()=> Material(
          //   color: Colors.transparent,
          //   child: InkWell(
          //     onTap: () async {
          //       // await _showBranchSelectorBottomSheet();
          //     },
          //     borderRadius: BorderRadius.circular(8),
          //     child: Padding(
          //       padding: const EdgeInsets.symmetric(horizontal: 16.0),
          //       child: Container(
          //         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          //         decoration: BoxDecoration(
          //           color: Colors.white,
          //           borderRadius: BorderRadius.circular(8),
          //           border: Border.all(color: Colors.grey.shade300),
          //         ),
          //         child: Row(
          //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //           children: [
          //             Text(
          //               crpGetBranchListController.selectedBranchName.value??'Select Location',
          //               style: TextStyle(
          //                 fontSize: 15,
          //                 color: Colors.black87,
          //               ),
          //             ),
          //             Icon(
          //               Icons.arrow_forward_ios,
          //               size: 16,
          //               color: Colors.grey.shade600,
          //             ),
          //           ],
          //         ),
          //       ),
          //     ),
          //   ),
          // )),
          OfficeBranchTile(
            onTap: () async {
              await _showBranchSelectorBottomSheet(forceShow: true);
            },
          ),
          SizedBox(
            height: 16,
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              children: [
                Text(
                  'Services',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    fontFamily: 'Montserrat',
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 10,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Obx(() {
              final list = runTypeController.runTypes.value?.runTypes ?? [];

              if (list.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              const maxPerRow = 3;
              const spacing = 12.0;
              const double tileHeight = 110;
              const horizontalPadding = 40.0;

              final screenWidth = MediaQuery.of(context).size.width;

              // --- CHUNKING LOGIC ---
              List<List<dynamic>> rows = [];
              int index = 0;

              while (index < list.length) {
                int remaining = list.length - index;

                // Special: exactly 4 items → 2 + 2
                if (remaining == 4) {
                  rows.add(list.sublist(index, index + 2));
                  rows.add(list.sublist(index + 2, index + 4));
                  break;
                }

                int take = remaining >= maxPerRow ? maxPerRow : remaining;
                rows.add(list.sublist(index, index + take));
                index += take;
              }

              // Aspect ratio calculator
              double calcAspect(int count) {
                final availableWidth = screenWidth - horizontalPadding;
                final itemWidth =
                    (availableWidth - (count - 1) * spacing) / count;
                return itemWidth / tileHeight;
              }

              // Row builder
              Widget rowBuilder(List rowData, int startIndex) {
                int count = rowData.length;

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: rowData.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: count,
                    crossAxisSpacing: spacing,
                    mainAxisSpacing: spacing,
                    childAspectRatio: calcAspect(count),
                  ),
                  itemBuilder: (context, index) => CrpServiceTile(
                    item: rowData[index],
                    index: startIndex + index,
                  ),
                );
              }

              // Build final UI with proper indexing
              List<Widget> children = [];
              int globalIndex = 0;

              for (var row in rows) {
                children.add(rowBuilder(row, globalIndex));
                children.add(const SizedBox(height: 16));
                globalIndex += row.length;
              }

              return Column(children: children);
            }),
          )
        ],
      )),
    );
  }
}

class CrpServiceTile extends StatefulWidget {
  final dynamic item;
  final int index;

  const CrpServiceTile({
    Key? key,
    required this.item,
    required this.index,
  }) : super(key: key);

  @override
  State<CrpServiceTile> createState() => _CrpServiceTileState();
}

class _CrpServiceTileState extends State<CrpServiceTile> {
  final CrpServicesController runTypeController =
      Get.put(CrpServicesController());
  final VerifyCorporateController verifyCorporateController =
      Get.put(VerifyCorporateController());
  final CrpBranchListController crpGetBranchListController =
      Get.put(CrpBranchListController());

  Future<void> _showBranchSelectorBottomSheet() async {
    // Fetch branches if not already loaded
    if (crpGetBranchListController.branchNames.isEmpty) {
      final corpId = await StorageServices.instance.read('crpId');
      await crpGetBranchListController.fetchBranches(corpId ?? '');
    }

    final items = crpGetBranchListController.branchNames;
    final selected = crpGetBranchListController.selectedBranchName.value ?? '';

    if (items.isEmpty) {
      Get.snackbar(
        "No Branches",
        "No branches found for this corporate ID",
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (crpGetBranchListController.count.value == 0) {
      showModalBottomSheet(
        context: context,
        isDismissible: false,
        enableDrag: true,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) {
          // Keep track of the temporary selection so we can highlight instantly
          String? tempSelected = selected.isNotEmpty ? selected : null;

          return PopScope(
            canPop: false,
            child: StatefulBuilder(
              builder: (context, setModalState) {
                return Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.9,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(15)),
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Top Illustration/Banner
                        Padding(
                          padding: const EdgeInsets.only(
                              left: 20, right: 20, top: 25),
                          child: ClipRRect(
                            borderRadius:
                                const BorderRadius.all(Radius.circular(10)),
                            child: Container(
                              height: 228,
                              width: double.infinity,
                              color: Colors.white, // optional background
                              child: Image.asset(
                                'assets/images/select_branch_img.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),

                        // Heading Section
                        Padding(
                          padding:
                              const EdgeInsets.fromLTRB(20, 24, 20, 20),
                          child: Row(
                            children: const [
                              Text(
                                "Choose City Branch",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF000000),
                                  // letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Branch List
                        Flexible(
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: items.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final name = items[index];
                              final isSelected = name == tempSelected;

                              return Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  splashColor: Colors.transparent,
                                  onTap: () {
                                    // Update controller value
                                    crpGetBranchListController
                                        .selectBranch(name);
                                    // Update local temp selection so UI highlights instantly
                                    setModalState(() {
                                      tempSelected = name;
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 10,
                                    ),
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(
                                              0xFFE3F2FD) // Light blue background
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      name,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                        color: isSelected
                                            ? const Color(
                                                0xFF333333) // Blue text when selected
                                            : const Color(
                                                0xFF333333), // Gray text when not selected
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 20),
                        Container(
                          width: double.infinity, // full width
                          height: 48,
                          margin:
                              const EdgeInsets.symmetric(horizontal: 20),
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                crpGetBranchListController.count.value++;
                              });
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color(0xFF4082F1), // #4082F1
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(39),
                                side: const BorderSide(
                                    color: Color(0xFFD9D9D9), width: 1),
                              ),
                              elevation: 0, // Remove default shadow
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Text(
                                  "Confirm",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      );
    }
  }

  String _getImageForService(int id) {
    switch (id) {
      case 1:
        return 'assets/images/rental.png'; // Local / Disposal
      case 2:
        return 'assets/images/airport.png'; // Airport
      case 3:
        return 'assets/images/outstation.png'; // One Way Outstation
      case 4:
        return 'assets/images/self_drive.png'; // Self Drive
      default:
        return 'assets/images/rental.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    const fixedHeight = 110.0;
    final item = widget.item;
    final index = widget.index;

    return InkWell(
      splashColor: Colors.transparent,
      onTap: () async {
        if (item.runTypeID != null) {
          await StorageServices.instance
              .save('cprSelectedRunTypeId', item.runTypeID!.toString());
          await StorageServices.instance
              .save('tabIndex', index.toString());
        }
        // Pass the selected pickup type (run) to booking engine
        if (crpGetBranchListController.count.value == 0) {
          await _showBranchSelectorBottomSheet();
        } else {
          GoRouter.of(context).push(
            AppRoutes.cprBookingEngine,
            extra: item.run, // Pass the pickup type name
          );
        }
      },
      child: Container(
        height: fixedHeight,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1F192653),
              offset: Offset(0, 3),
              blurRadius: 12,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(
              height: 60,
              child: Image.asset(
                _getImageForService(item.runTypeID ?? 0),
                fit: BoxFit.contain,
              ),
            ),
            Text(
              item.run ?? "",
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF192653),
                fontFamily: 'Montserrat',
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class TopBanner extends StatefulWidget {
  @override
  State<TopBanner> createState() => _TopBannerState();
}

class _TopBannerState extends State<TopBanner> {
  final CrpBranchListController crpGetBranchListController =
  Get.put(CrpBranchListController());
  Future<void> _showBranchSelectorBottomSheet() async {
    // Fetch branches if not already loaded
    if (crpGetBranchListController.branchNames.isEmpty) {
      final corpId = await StorageServices.instance.read('crpId');
      await crpGetBranchListController.fetchBranches(corpId ?? '');
    }

    final items = crpGetBranchListController.branchNames;
    final selected = crpGetBranchListController.selectedBranchName.value ?? '';

    if (items.isEmpty) {
      Get.snackbar("No Branches", "No branches found for this corporate ID",
          snackPosition: SnackPosition.BOTTOM);
      return;
    }


    if(crpGetBranchListController.count.value == 0) showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        // Keep track of the temporary selection so we can highlight instantly
        String? tempSelected = selected.isNotEmpty ? selected : null;

        return PopScope(
          canPop: false,
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.9,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Top Illustration/Banner
                      Padding(
                        padding:
                        const EdgeInsets.only(left: 20, right: 20, top: 25),
                        child: ClipRRect(
                          borderRadius:
                          const BorderRadius.all(Radius.circular(10)),
                          child: Container(
                            height: 228,
                            width: double.infinity,
                            color: Colors.white, // optional background
                            child: Image.asset(
                              'assets/images/select_branch_img.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),

                      // Heading Section
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                        child: Row(
                          children: [
                            const Text(
                              "Choose City Branch",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF000000),
                                // letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Branch List
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: items.length,
                          separatorBuilder: (_, __) =>
                          const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final name = items[index];
                            final isSelected = name == tempSelected;

                            return Material(
                              color: Colors.transparent,
                              child: InkWell(
                                splashColor: Colors.transparent,
                                onTap: () {
                                  // Update controller value
                                  crpGetBranchListController.selectBranch(name);
                                  // Update local temp selection so UI highlights instantly
                                  setModalState(() {
                                    tempSelected = name;
                                  });
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 10,
                                  ),
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(
                                        0xFFE3F2FD) // Light blue background
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    name,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      color: isSelected
                                          ? const Color(
                                          0xFF333333) // Blue text when selected
                                          : const Color(
                                          0xFF333333), // Gray text when not selected
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity, // full width
                        height: 48,
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              crpGetBranchListController.count.value ++;
                            });
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4082F1), // #4082F1
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(39),
                              side: const BorderSide(
                                  color: Color(0xFFD9D9D9), width: 1),
                            ),
                            elevation: 0, // Remove default shadow
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // gap: 12px
                              const Text(
                                "Confirm",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Gradient Sky Background
        Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(
                  'assets/images/crp_home_banner.png'), // Use your image path here
              fit: BoxFit.cover, // Choose fit as per your layout
            ),
          ),
        ),
        // Foreground content
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 24, 0, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row for logo and button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          // const CircleAvatar(
                          //   radius: 24,
                          //   backgroundImage: AssetImage('assets/images/user.png'),
                          // ),
                          // InkWell(
                          //   splashColor: Colors.transparent,
                          //   onTap: () {
                          //     showGeneralDialog(
                          //       context: context,
                          //       barrierDismissible: true,
                          //       barrierLabel: "Drawer",
                          //       barrierColor: Colors
                          //           .black54, // transparent black background
                          //       transitionDuration: const Duration(
                          //           milliseconds: 300),
                          //       pageBuilder: (_, __, ___) =>
                          //           const CustomDrawerSheet(),
                          //       transitionBuilder:
                          //           (_, anim, __, child) {
                          //         return SlideTransition(
                          //           position: Tween<Offset>(
                          //             begin: const Offset(-1,
                          //                 0), // slide in from left
                          //             end: Offset.zero,
                          //           ).animate(CurvedAnimation(
                          //             parent: anim,
                          //             curve: Curves.easeOutCubic,
                          //           )),
                          //           child: child,
                          //         );
                          //       },
                          //     );
                          //   },
                          //   child: Transform.translate(
                          //     offset: Offset(0.0, -4.0),
                          //     child: Container(
                          //       width:
                          //           28, // same as 24dp with padding
                          //       height: 28,
                          //       decoration: BoxDecoration(
                          //         color: Color.fromRGBO(
                          //             0, 44, 192, 0.1), // deep blue
                          //         borderRadius:
                          //             BorderRadius.circular(
                          //                 4), // rounded square
                          //       ),
                          //       child: const Icon(
                          //         Icons.density_medium_outlined,
                          //         color:
                          //             Color.fromRGBO(0, 17, 73, 1),
                          //         size: 16,
                          //       ),
                          //     ),
                          //   ),
                          // ),
                          // const SizedBox(width: 12),
                          Transform.translate(
                            offset: Offset(0.0, -2.0),
                            child: SizedBox(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                 children: [
                                  SizedBox(
                                    height: 4,
                                  ),
                                  Image.asset(
                                    'assets/images/wti_crp.png',
                                    height: 50,
                                    width: 180,
                                  )
                                  // Text(
                                  //   "Good Morning! Yash",
                                  //   style: CommonFonts.HomeTextBold,
                                  // ),
                                  // Row(
                                  //   children: [
                                  //     Container(
                                  //       width: MediaQuery.of(context)
                                  //               .size
                                  //               .width *
                                  //           0.45,
                                  //       child: Text(
                                  //         address,
                                  //         overflow:
                                  //             TextOverflow.ellipsis,
                                  //         maxLines: 1,
                                  //         style: CommonFonts
                                  //             .greyTextMedium,
                                  //       ),
                                  //     ),
                                  //     // const SizedBox(width:),
                                  //     const Icon(
                                  //       Icons.keyboard_arrow_down,
                                  //       color: AppColors.greyText6,
                                  //       size: 18,
                                  //     ),
                                  //   ],
                                  // ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        // Transform.translate(
                        //     offset: Offset(0.0, -4.0),
                        //     child: Image.asset(
                        //       'assets/images/wallet.png',
                        //       height: 31,
                        //       width: 28,
                        //     )),
                        SizedBox(
                          width: 12,
                        ),
                        Container(
                          height: 35,
                          decoration: BoxDecoration(
                            /*gradient: const LinearGradient(
                                          colors: [Color(0xFF0052D4), Color(0xFF4364F7), Color(0xFF6FB1FC)],
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                        ),*/
                            color: AppColors.mainButtonBg,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors
                                  .transparent, // transparent to show gradient
                              shadowColor:
                                  Colors.transparent, // remove default shadow
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 4, horizontal: 8),
                            ),
                            onPressed: () async {
                              Navigator.of(context).push(
                                PlatformFlipPageRoute(
                                  builder: (context) => const BottomNavScreen(),
                                ),
                              );
                            },
                            child: const Text(
                              "Home",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Montserrat',
                              ),
                            ),
                          ),
                        )

                        // upcomingBookingController
                        //             .isLoggedIn.value ==
                        //         true
                        //     ? InkWell(
                        //         splashColor: Colors.transparent,
                        //         onTap: () async {
                        //           print(
                        //               'homepage yash token for profile : ${await StorageServices.instance.read('token') == null}');
                        //           if (await StorageServices
                        //                   .instance
                        //                   .read('token') ==
                        //               null) {
                        //             _showAuthBottomSheet();
                        //           }
                        //           if (await StorageServices
                        //                   .instance
                        //                   .read('token') !=
                        //               null) {
                        //             GoRouter.of(context)
                        //                 .push(AppRoutes.profile);
                        //           }
                        //         },
                        //         child: SizedBox(
                        //           width: 30,
                        //           height: 30,
                        //           child: NameInitialHomeCircle(
                        //               name: profileController
                        //                       .profileResponse
                        //                       .value
                        //                       ?.result
                        //                       ?.firstName ??
                        //                   ''),
                        //         ),
                        //       )
                        //     : InkWell(
                        //         splashColor: Colors.transparent,
                        //         onTap: () async {
                        //           print(
                        //               'homepage yash token for profile : ${await StorageServices.instance.read('token') == null}');
                        //           if (await StorageServices
                        //                   .instance
                        //                   .read('token') ==
                        //               null) {
                        //             _showAuthBottomSheet();
                        //           }
                        //           if (await StorageServices
                        //                   .instance
                        //                   .read('token') !=
                        //               null) {
                        //             GoRouter.of(context)
                        //                 .push(AppRoutes.profile);
                        //           }
                        //         },
                        //         child: Transform.translate(
                        //           offset: Offset(0.0, -4.0),
                        //           child: const CircleAvatar(
                        //             foregroundColor:
                        //                 Colors.transparent,
                        //             backgroundColor:
                        //                 Colors.transparent,
                        //             radius: 14,
                        //             backgroundImage: AssetImage(
                        //               'assets/images/user.png',
                        //             ),
                        //           ),
                        //         ),
                        //       ),
                      ],
                    )
                  ],
                ),
              ),
              SizedBox(height: 16),
              // Search field
              GestureDetector(
                onTap: () {
                  if(crpGetBranchListController.count.value == 0){
                    _showBranchSelectorBottomSheet();
                  }
                  else {
                    GoRouter.of(context).push(AppRoutes.cprSelectDrop);
                  }
                },
                child: Container(
                  width: double.infinity,
                  height: 48,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  margin: const EdgeInsets.symmetric(
                    horizontal: 20,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white, // background #FFFFFF
                    borderRadius: BorderRadius.circular(35),
                    // border: Border.all(
                    //   color: Color(0xFFD9D9D9), // border #D9D9D9
                    //   width: 1,
                    // ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.search,
                        color: Color(0xFF333333),
                        size: 20,
                      ),

                      const SizedBox(width: 8), // gap: 12px

                      Expanded(
                        child: Text(
                          "Where to?",
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF333333),
                            fontWeight: FontWeight.w400,
                            fontFamily: 'Montserrat',
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 48),

              // Car image with background buildings
              SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }
}

class OfficeBranchTile extends StatefulWidget {
  final void Function()? onTap;
  OfficeBranchTile({super.key, this.onTap});

  @override
  State<OfficeBranchTile> createState() => _OfficeBranchTileState();
}

class _OfficeBranchTileState extends State<OfficeBranchTile> {
  final CrpBranchListController crpGetBranchListController =
      Get.put(CrpBranchListController());
  @override
  Widget build(BuildContext context) {
    return Obx(() => InkWell(
          splashColor: Colors.white,
          onTap: widget.onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF), // light bluish background
              borderRadius:
                  BorderRadius.circular(30), // pill shape [web:8][web:14]
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Left circular icon background
                Image.asset(
                  'assets/images/city.png',
                  height: 30,
                  width: 30,
                ),
                const SizedBox(width: 12),
                // Texts
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Choose Branch',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF373737),
                        letterSpacing: 0,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      crpGetBranchListController.selectedBranchName.value ??
                          'Select Location',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF7B7B7B),
                        letterSpacing: 0,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                  ],
                ),
                Spacer(),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Color(0xFF1D1B20),
                  size: 16,
                  weight: 2.0,
                )
              ],
            ),
          ),
        ));
  }
}
