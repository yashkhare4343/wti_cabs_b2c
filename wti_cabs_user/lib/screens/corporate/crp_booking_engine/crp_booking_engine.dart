import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:intl/intl.dart';
import '../../../../common_widget/textformfield/booking_textformfield.dart';
import '../../../../utility/constants/colors/app_colors.dart';
import '../../../../utility/constants/fonts/common_fonts.dart';
import '../../../core/controller/corporate/crp_services_controller/crp_sevices_controller.dart';
import '../../../core/model/corporate/crp_services/crp_services_response.dart';

class CprBookingEngine extends StatefulWidget {
  const CprBookingEngine({super.key});

  @override
  State<CprBookingEngine> createState() => _CprBookingEngineState();
}

class _CprBookingEngineState extends State<CprBookingEngine> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    runTypeController.fetchRunTypes(params, context);
  }
  final CrpServicesController runTypeController = Get.put(CrpServicesController());

  int selectedTabIndex = 0;
  String? selectedPickupType;
  String? selectedBookingFor;
  String? selectedPaymentMethod;

  final params = {
    'CorpID' : '1',
    'BranchID' : '1'
  };



  final TextEditingController pickupController = TextEditingController(text: 'D-21, Dwarka, New Delhi...');
  final TextEditingController dropController = TextEditingController();

  DateTime? selectedPickupDateTime;

  bool isBookingForExpanded = false;
  bool isPaymentMethodsExpanded = false;
  bool isAdditionalOptionsExpanded = false;

  final List<String> bookingForList = ['Myself', 'Corporate'];
  

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
              Obx(() => _buildTabsSection()),
              const SizedBox(height: 24),

              // Location Input Section
              _buildLocationSection(),
              const SizedBox(height: 24),

              // Pick Up Date and Pick Up Type Buttons
              _buildDateAndTypeButtons(),
              const SizedBox(height: 20),

              // Booking For
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedBookingFor,
                    isExpanded: true,
                    hint: Row(
                      children: [
                        Icon(Icons.person_outline_outlined, color: AppColors.greyText3, size: 20),
                        const SizedBox(width: 12),
                        const Text(
                          'Booking For',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    selectedItemBuilder: (BuildContext context) {
                      return bookingForList.map((bookingFor) {
                        return Row(
                          children: [
                            Icon(Icons.description_outlined, color: AppColors.greyText3, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                bookingFor,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        );
                      }).toList();
                    },
                    icon: const Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.grey,
                      size: 20,
                    ),
                    dropdownColor: Colors.white,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                    items: bookingForList.map((bookingFor) {
                      return DropdownMenuItem<String>(
                        value: bookingFor,
                        child: Text(
                          bookingFor,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      );
                    }).toList(),
                    onChanged: (String? value) {
                      setState(() {
                        selectedBookingFor = value;
                      });
                    },
                  ),
                ),
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
    final List<RunTypeItem> allRunTypes = runTypeController.runTypes.value?.runTypes ?? [];
    final List<String> allTabs = allRunTypes.map((val) => val.run ?? '').toList();
    
    // Show loading or empty state if no tabs
    if (runTypeController.isLoading.value) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    if (allTabs.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              // All tabs
              ...List.generate(allTabs.length > 3 ? 3 : allTabs.length, (index) {
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
                        allTabs[index],
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
            ],
          ),
        ),
      ],
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
          // Padding(
          //   padding: const EdgeInsets.only(top: 4),
          //   child: GestureDetector(
          //     onTap: () {
          //       // Handle add location
          //     },
          //     child: Container(
          //       width: 36,
          //       height: 36,
          //       decoration: BoxDecoration(
          //         color: AppColors.mainButtonBg,
          //         shape: BoxShape.circle,
          //       ),
          //       child: const Icon(
          //         Icons.add,
          //         color: Colors.white,
          //         size: 20,
          //       ),
          //     ),
          //   ),
          // ),
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
            label: selectedPickupDateTime != null
                ? _formatDateTime(selectedPickupDateTime!)
                : 'Pick Up Date',
            onTap: () {
              _showCupertinoDateTimePicker(context);
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Obx(() => _buildPickUpTypeButton()),
        ),
      ],
    );
  }

  Widget _buildPickUpTypeButton() {
    final List<RunTypeItem> allRunTypes = runTypeController.runTypes.value?.runTypes ?? [];
    final List<String> allPickupTypes = allRunTypes.map((val) => val.run ?? '').toList();
    
    if (allPickupTypes.isEmpty) {
      return _buildActionButton(
        icon: Icons.description_outlined,
        label: 'Pick Up Type',
        onTap: () {},
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedPickupType,
          isExpanded: true,
          hint: Row(
            children: [
              Icon(Icons.description_outlined, color: AppColors.greyText3, size: 20),
              const SizedBox(width: 12),
              const Text(
                'Pick Up Type',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          selectedItemBuilder: (BuildContext context) {
            return allPickupTypes.map((pickupType) {
              return Row(
                children: [
                  Icon(Icons.description_outlined, color: AppColors.greyText3, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      pickupType,
                      style: TextStyle(
                        fontSize: pickupType.length > 15 ? 10 : 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              );
            }).toList();
          },
          icon: const Icon(
            Icons.keyboard_arrow_down,
            color: Colors.grey,
            size: 20,
          ),
          dropdownColor: Colors.white,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
          items: allPickupTypes.map((pickupType) {
            return DropdownMenuItem<String>(
              value: pickupType,
              child: Text(
                pickupType,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            );
          }).toList(),
          onChanged: (String? value) {
            setState(() {
              selectedPickupType = value;
            });
          },
        ),
      ),
    );
  }

  void _showCupertinoDateTimePicker(BuildContext context) {
    final DateTime now = DateTime.now();
    final DateTime minimumDate = now;
    // Use selected date if it exists and is not in the past, otherwise use now
    // Ensure initial date is always >= minimum date
    DateTime tempDateTime = selectedPickupDateTime != null && 
                            selectedPickupDateTime!.isAfter(minimumDate)
        ? selectedPickupDateTime!
        : minimumDate;
    
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 300,
          color: Colors.white,
          child: Column(
            children: [
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.dateAndTime,
                  initialDateTime: tempDateTime,
                  minimumDate: minimumDate,
                  onDateTimeChanged: (DateTime newDateTime) {
                    tempDateTime = newDateTime;
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[300],
                          foregroundColor: Colors.black87,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            selectedPickupDateTime = tempDateTime;
                          });
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.mainButtonBg,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Done'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDateTime(DateTime dateTime) {
    // Format: 2016-05-16 15:39:05.277
    // return DateFormat('yyyy MM dd HH:mm:ss.SSS').format(dateTime);
    return DateFormat('dd MMM yyyy').format(dateTime);
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
                style: TextStyle(
                  fontSize: label.length > 15 ? 10 : 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
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

