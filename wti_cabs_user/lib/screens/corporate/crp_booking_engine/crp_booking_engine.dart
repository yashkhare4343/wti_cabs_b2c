import 'package:flutter/material.dart';
import '../../../../utility/constants/colors/app_colors.dart';
import '../../../../utility/constants/fonts/common_fonts.dart';
import '../../../common_widget/textformfield/booking_textformfield.dart';

class CprBookingEngine extends StatefulWidget {
  const CprBookingEngine({super.key});

  @override
  State<CprBookingEngine> createState() => _CprBookingEngineState();
}

class _CprBookingEngineState extends State<CprBookingEngine> {
  int selectedTabIndex = 0;
  final List<String> tabs = ['Local', 'Airport', 'OutStation'];
  
  final TextEditingController pickupController = TextEditingController(text: 'D-21, Dwarka, New Delhi...');
  final TextEditingController dropController = TextEditingController();
  
  bool isBookingForExpanded = false;
  bool isPaymentMethodsExpanded = false;
  bool isAdditionalOptionsExpanded = false;

  @override
  void dispose() {
    pickupController.dispose();
    dropController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Book a Cab',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tabs Section
              _buildTabsSection(),
              const SizedBox(height: 24),
              
              // Location Input Section
              _buildLocationSection(),
              const SizedBox(height: 24),
              
              // Pick Up Date and Pick Up Type Buttons
              _buildDateAndTypeButtons(),
              const SizedBox(height: 20),
              
              // Booking For
              _buildExpandableTile(
                icon: Icons.person_outline,
                iconColor: const Color(0xFF87CEEB),
                title: 'Booking For',
                isExpanded: isBookingForExpanded,
                onTap: () {
                  setState(() {
                    isBookingForExpanded = !isBookingForExpanded;
                  });
                },
              ),
              const SizedBox(height: 12),
              
              // Payment Methods
              _buildExpandableTile(
                icon: Icons.wallet_outlined,
                iconColor: const Color(0xFF87CEEB),
                title: 'Payment Methods',
                isExpanded: isPaymentMethodsExpanded,
                onTap: () {
                  setState(() {
                    isPaymentMethodsExpanded = !isPaymentMethodsExpanded;
                  });
                },
              ),
              const SizedBox(height: 12),
              
              // Additional Options
              _buildExpandableTile(
                icon: Icons.add_circle_outline,
                iconColor: Colors.grey,
                title: 'Additional Options',
                isExpanded: isAdditionalOptionsExpanded,
                onTap: () {
                  setState(() {
                    isAdditionalOptionsExpanded = !isAdditionalOptionsExpanded;
                  });
                },
              ),
              const SizedBox(height: 32),
              
              // View Cabs Button
              _buildViewCabsButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabsSection() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = selectedTabIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  selectedTabIndex = index;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.mainButtonBg : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  tabs[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildLocationSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vertical line with icons
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(
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
                Container(
                  width: 3,
                  height: 60,
                  color: AppColors.mainButtonBg,
                ),
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
              ],
            ),
          ),
          const SizedBox(width: 12),
          
          // Text fields
          Expanded(
            child: Column(
              children: [
                BookingTextFormField(
                  hintText: '',
                  controller: pickupController,
                  onTap: () {
                    // Handle pickup location tap
                  },
                ),
                const SizedBox(height: 12),
                BookingTextFormField(
                  hintText: 'Enter drop location',
                  controller: dropController,
                  onTap: () {
                    // Handle drop location tap
                  },
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          
          // Plus icon button
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: GestureDetector(
              onTap: () {
                // Handle add location
              },
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.mainButtonBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateAndTypeButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            icon: Icons.access_time,
            label: 'Pick Up Date',
            onTap: () {
              // Handle date picker
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            icon: Icons.description_outlined,
            label: 'Pick Up Type',
            onTap: () {
              // Handle pick up type selection
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.greyText3, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down,
              color: Colors.grey,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandableTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required bool isExpanded,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
            Icon(
              isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: Colors.grey,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewCabsButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          // Handle view cabs
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.mainButtonBg,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: const Text(
          'View Cabs',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

