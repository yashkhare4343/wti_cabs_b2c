import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shimmer/shimmer.dart';
import 'package:wti_cabs_user/core/route_management/app_routes.dart';
import 'package:wti_cabs_user/utility/constants/colors/app_colors.dart';
import 'package:wti_cabs_user/utility/constants/fonts/common_fonts.dart';
import 'package:wti_cabs_user/core/controller/corporate/crp_inventory_list_controller/crp_inventory_list_controller.dart';

import '../../../core/model/corporate/crp_car_models/crp_car_models_response.dart';
import '../../../core/services/storage_services.dart';

class CrpInventory extends StatefulWidget {
  const CrpInventory({super.key});

  @override
  State<CrpInventory> createState() => _CrpInventoryState();
}

class _CrpInventoryState extends State<CrpInventory> {
  final CrpInventoryListController crpInventoryListController = Get.put(CrpInventoryListController());
  bool isLoading = false;
  final controller = Get.put(CrpInventoryListController());

  String? guestId, token, user, corpId, branchId;

  @override
  void initState() {
    super.initState();
    fetchCardModel();    // TODO: Initialize inventory data
  }

  Future<void> fetchParameter() async {
    guestId = await StorageServices.instance.read('branchId');
    token = await StorageServices.instance.read('crpKey');
    user = await StorageServices.instance.read('email');
    corpId = await StorageServices.instance.read('crpId');
    branchId = await StorageServices.instance.read('branchId');
  }

  void fetchCardModel()async{
    await fetchParameter();
    final Map<String, dynamic> params = {
      'token' : token,
      'user' : user,
      'CorpID': corpId,
      'BranchID': branchId,
      'RunTypeID': 1
    };
   await controller.fetchCarModels(params, context);


  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBgPrimary1,
      body: SafeArea(
        child: _BookingBody(),
      ),
    );
  }
}


class _BookingBody extends StatefulWidget {
  const _BookingBody({super.key});

  @override
  State<_BookingBody> createState() => _BookingBodyState();
}

class _BookingBodyState extends State<_BookingBody> {
  final CameraPosition _initialCameraPosition = const CameraPosition(
    target: LatLng(28.5562, 77.1000), // IGI example
    zoom: 13,
  );

  GoogleMapController? _mapController;

  final CrpInventoryListController _inventoryController =
      Get.put(CrpInventoryListController());

  @override
  void initState() {
    super.initState();
    // Fetch corporate inventory car models after first frame
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Full-screen Google Map
        Column(
          children: [
            SizedBox(
              height: 300,
              child: GoogleMap(
                initialCameraPosition: _initialCameraPosition,
                onMapCreated: (c) => _mapController = c,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                compassEnabled: false,
              ),
            ),
            Expanded(child: const _VehicleSection())
          ],
        ),
        SizedBox(
          height: 83,
            child: const _RouteCard()),

      ],
    );
  }
}
class _RouteCard extends StatelessWidget {
  const _RouteCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 16, left: 14, right: 14),
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.only(top: 14, right: 14, left:14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // From -> To row
              Row(
                children: [
                  const Icon(Icons.arrow_back, size: 16, color: Colors.black87),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Terminal 1 C Indira Gan.. to Honda Chowk, Sector',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.edit_outlined, size: 18, color: Colors.grey),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(left: 24.0),
                child: Row(
                  children: [
                    Text(
                      '05 June, 2025, 11:00 hrs',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    SizedBox(width: 8,),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3F2FD),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Outstation Round Trip',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1E88E5),
                        ),
                      ),
                    ),

                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
class _VehicleSection extends StatefulWidget {
  const _VehicleSection();

  @override
  State<_VehicleSection> createState() => _VehicleSectionState();
}

class _VehicleSectionState extends State<_VehicleSection> {
  final controller = Get.put(CrpInventoryListController());

  @override
  Widget build(BuildContext context) {

    return Obx(() {
      if (controller.isLoading.value) {
        return const _InventoryShimmer();
      }

      return Container(
        color: Colors.white,
        child: Column(
          children: [
            const SizedBox(height: 12),
            _VehicleFilterChips(),
            const SizedBox(height: 8),
            const Divider(height: 1),
            Expanded(
              child: controller.models.isEmpty
                  ? const Center(
                      child: Text(
                        'No vehicles available',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      itemCount: controller.models.length,
                      itemBuilder: (_, index) =>
                          _VehicleCard(model: controller.models[index]),
                    ),
            ),
          ],
        ),
      );
    });
  }
}

class _VehicleFilterChips extends StatefulWidget {
  @override
  State<_VehicleFilterChips> createState() => _VehicleFilterChipsState();
}

class _VehicleFilterChipsState extends State<_VehicleFilterChips> {
  String selected = 'Sedan';
  final options = ['All', 'Sedan', 'Hatchback', 'SUV'];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: options.length,
        itemBuilder: (_, i) {
          final isSelected = options[i] == selected;
          return GestureDetector(
            onTap: () => setState(() => selected = options[i]),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF424242) : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isSelected ? Colors.transparent : Colors.grey.shade300,
                ),
              ),
              child: Text(
                options[i],
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white : Colors.black87,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  final CrpCarModel model;

  const _VehicleCard({required this.model});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Car image
          Container(
            width: 72,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Image.asset(
              'assets/car_sedan.png',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 12),
          // Text details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  model.carType ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    const Text('4', style: TextStyle(fontSize: 11)),
                    const SizedBox(width: 10),
                    const Icon(Icons.luggage_outlined, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    const Text('2', style: TextStyle(fontSize: 11)),
                    const SizedBox(width: 10),
                    const Icon(Icons.access_time, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    const Text('2 hrs', style: TextStyle(fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InventoryShimmer extends StatelessWidget {
  const _InventoryShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Column(
          children: [
            const SizedBox(height: 12),
            // Fake filter chips row
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemCount: 4,
                itemBuilder: (_, __) => Container(
                  width: 70,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: 5,
                itemBuilder: (_, __) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

