import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:wti_cabs_user/core/route_management/app_routes.dart';
import 'package:wti_cabs_user/utility/constants/colors/app_colors.dart';
import 'package:wti_cabs_user/utility/constants/fonts/common_fonts.dart';

class CrpInventory extends StatefulWidget {
  const CrpInventory({super.key});

  @override
  State<CrpInventory> createState() => _CrpInventoryState();
}

class _CrpInventoryState extends State<CrpInventory> {
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    // TODO: Initialize inventory data
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBgPrimary1,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Available Cabs',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Location Summary Card
              _buildLocationSummaryCard(),
              const SizedBox(height: 16),
              // Inventory List
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildInventoryList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: AppColors.mainButtonBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_on,
                  color: Colors.white,
                  size: 14,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Pickup Location',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 32),
            child: Text(
              'Please Select Pickup',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: AppColors.mainButtonBg,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(
                  Icons.place,
                  color: Colors.white,
                  size: 14,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Drop Location',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 32),
            child: Text(
              'Enter drop location',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryList() {
    // TODO: Replace with actual inventory data from controller
    final List<Map<String, dynamic>> dummyInventory = [
      {
        'carImageUrl': 'https://via.placeholder.com/60x50',
        'type': 'Sedan',
        'carTagLine': 'Swift Dzire',
        'seats': '4 Seater',
        'price': '₹1,200',
        'originalPrice': '₹1,500',
        'discount': '20% OFF',
      },
      {
        'carImageUrl': 'https://via.placeholder.com/60x50',
        'type': 'SUV',
        'carTagLine': 'Innova Crysta',
        'seats': '7 Seater',
        'price': '₹2,500',
        'originalPrice': '₹3,000',
        'discount': '17% OFF',
      },
      {
        'carImageUrl': 'https://via.placeholder.com/60x50',
        'type': 'Hatchback',
        'carTagLine': 'Swift',
        'seats': '4 Seater',
        'price': '₹1,000',
        'originalPrice': '₹1,200',
        'discount': '17% OFF',
      },
    ];

    if (dummyInventory.isEmpty) {
      return const Center(
        child: Text(
          "No cabs available on this route",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: dummyInventory.length,
      itemBuilder: (context, index) {
        final item = dummyInventory[index];
        return _buildInventoryCard(item);
      },
    );
  }

  Widget _buildInventoryCard(Map<String, dynamic> item) {
    return Card(
      color: Colors.white,
      elevation: 0.3,
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    Container(
                      width: 60,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: item['carImageUrl'] != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                item['carImageUrl'],
                                width: 60,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Icons.directions_car,
                                    color: Colors.grey.shade400,
                                    size: 30,
                                  );
                                },
                              ),
                            )
                          : Icon(
                              Icons.directions_car,
                              color: Colors.grey.shade400,
                              size: 30,
                            ),
                    ),
                    const SizedBox(height: 4),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: const Color(0xFFE3F2FD),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        side: const BorderSide(
                            color: Colors.transparent, width: 1),
                        foregroundColor: const Color(0xFF1565C0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      onPressed: () {},
                      child: Text(
                        item['type'] ?? '',
                        style: const TextStyle(
                            fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                    )
                  ],
                ),
                const SizedBox(width: 5),
                Expanded(
                  flex: 0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            width: 55,
                            child: Text(
                              item['carTagLine'] ?? '',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16),
                              overflow: TextOverflow.clip,
                              maxLines: 1,
                            ),
                          ),
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              backgroundColor: const Color(0xFFE8F5E9),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              minimumSize: Size.zero,
                              side: const BorderSide(
                                  color: Colors.transparent, width: 1),
                              foregroundColor: const Color(0xFF2E7D32),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            onPressed: () {},
                            child: Text(
                              item['seats'] ?? '',
                              style: const TextStyle(
                                  fontSize: 9, fontWeight: FontWeight.w600),
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            item['price'] ?? '',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                                color: Color(0xFF1565C0)),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            item['originalPrice'] ?? '',
                            style: TextStyle(
                                decoration: TextDecoration.lineThrough,
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                                color: Colors.grey.shade600),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFE0B2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              item['discount'] ?? '',
                              style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFE65100)),
                            ),
                          )
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.mainButtonBg, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      // TODO: Handle view details
                    },
                    child: Text(
                      'View Details',
                      style: TextStyle(
                        color: AppColors.mainButtonBg,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.mainButtonBg,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () {
                      // TODO: Handle book now
                    },
                    child: const Text(
                      'Book Now',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

