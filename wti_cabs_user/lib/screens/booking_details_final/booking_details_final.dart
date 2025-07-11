import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:wti_cabs_user/core/controller/cab_booking/cab_booking_controller.dart';

import '../../core/controller/booking_ride_controller.dart';
import '../../core/model/cab_booking/global_cab_booking.dart';
import '../../core/model/cab_booking/india_cab_booking.dart';
import '../../core/services/storage_services.dart';
import '../../utility/constants/colors/app_colors.dart';
import '../../utility/constants/fonts/common_fonts.dart';

class BookingDetailsFinal extends StatefulWidget {
  const BookingDetailsFinal({super.key});

  @override
  State<BookingDetailsFinal> createState() => _BookingDetailsFinalState();
}

class _BookingDetailsFinalState extends State<BookingDetailsFinal> {
  String? _country;
  final CabBookingController cabBookingController =
      Get.put(CabBookingController());

  @override
  void initState() {
    super.initState();
    loadInitialData();
  }

  Future<void> loadInitialData() async {
    _country = await StorageServices.instance.read('country');
    setState(() {}); // to trigger rebuild once _country is loaded
    print('📦 3rd page country: $_country');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBgPrimary1,
      body: SafeArea(
        child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  BookingTopBar(),
                  const SizedBox(height: 16),
                  GetBuilder<CabBookingController>(
                    builder: (cabBookingController) {
                      if (_country == null) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (_country!.toLowerCase() == 'india') {
                        final indiaData = cabBookingController.indiaData.value;
                        if (indiaData == null || indiaData.inventory == null) {
                          return const Center(
                              child: Text('No India booking data available.'));
                        }
                        return _buildIndiaCard(indiaData);
                      }

                      final globalData = cabBookingController.globalData.value;
                      if (globalData == null ||
                          globalData.vehicleDetails == null) {
                        return const Center(
                            child: Text('No Global booking data available.'));
                      }

                      return _buildGlobalCard();
                    },
                  ),
                  ExtrasSelectionCard(),
                  SizedBox(
                    height: 16,
                  ),
                  TravelerDetailsForm()
                ],
              ),
            )),
      ),
    );
  }
}

Widget _buildIndiaCard(IndiaCabBooking data) {
  final carInventory = data.inventory;
  final carTripType = data.tripType;
  final carOffer = data.offerObject;

  return Padding(
    padding: const EdgeInsets.only(bottom: 16.0),
    child: Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.greyBorder1, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Image.network(
                  carInventory?.carTypes?.carImageUrl ?? '',
                  width: 66,
                  height: 66,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Image.asset(
                      'assets/images/inventory_car.png',
                      width: 66,
                      height: 66,
                      fit: BoxFit.contain,
                    );
                  },
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Text(cabBookingController.indiaData.value?.inventory?.carTypes?.carTagLine ?? '', style: CommonFonts.bodyText1Bold),
                      Text(carInventory?.carTypes?.carTagLine ?? '',
                          style: CommonFonts.bodyText1Bold),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                              carInventory?.carTypes?.rating?.ratePoints
                                      .toString() ??
                                  '',
                              style: CommonFonts.bodyText1),
                          const SizedBox(width: 4),
                          Icon(Icons.star, color: AppColors.yellow1, size: 12),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.airline_seat_recline_extra, size: 13),
                          const SizedBox(width: 4),
                          Text('${carInventory?.carTypes?.seats} Seat',
                              style: CommonFonts.bodyTextXS),
                          const SizedBox(width: 8),
                          Icon(Icons.luggage_outlined, size: 13),
                          const SizedBox(width: 4),
                          Text('${carInventory?.carTypes?.luggageCapacity}',
                              style: CommonFonts.bodyTextXS),
                          const SizedBox(width: 8),
                          Icon(Icons.speed_outlined, size: 13),
                          const SizedBox(width: 4),
                          Text(
                            '${carInventory?.distanceBooked} km',
                            style: CommonFonts.bodyTextXS,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.info_outline, size: 16),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildGlobalCard() {
  final CabBookingController cabBookingController =
      Get.find<CabBookingController>();

  return Obx(() {
    final globalBooking = cabBookingController.globalData.value;
    final results = globalBooking?.vehicleDetails;
    final tripDetail = globalBooking?.tripTypeDetails;
    final fareDetails = globalBooking?.fareBreakUpDetails;

    if (results == null) {
      return const Center(child: Text('No Global booking data available.'));
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Card(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppColors.greyBorder1, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Image.network(
                    results.vehicleImageLink ?? '',
                    width: 66,
                    height: 66,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset(
                        'assets/images/inventory_car.png',
                        width: 66,
                        height: 66,
                        fit: BoxFit.contain,
                      );
                    },
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(results.title ?? '',
                            style: CommonFonts.bodyText1Bold),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              results.rating?.toString() ?? '',
                              style: CommonFonts.bodyText1,
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.star,
                                color: AppColors.yellow1, size: 12),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.airline_seat_recline_extra,
                                size: 13),
                            const SizedBox(width: 4),
                            Text('${results.passengerCapacity ?? '-'} Seat',
                                style: CommonFonts.bodyTextXS),
                            const SizedBox(width: 8),
                            const Icon(Icons.luggage_outlined, size: 13),
                            const SizedBox(width: 4),
                            Text('${results?.cabinLuggageCapacity ?? '-'}',
                                style: CommonFonts.bodyTextXS),
                            const SizedBox(width: 8),
                            const Icon(Icons.speed_outlined, size: 13),
                            const SizedBox(width: 4),
                            Text(
                              '${globalBooking?.totalDistance ?? '-'} km',
                              style: CommonFonts.bodyTextXS,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.info_outline, size: 16),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  });
}

class BookingTopBar extends StatefulWidget {
  @override
  State<BookingTopBar> createState() => _BookingTopBarState();
}

class _BookingTopBarState extends State<BookingTopBar> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getCurrentTripCode();
  }

  String _monthName(int month) {
    const months = [
      '', // 0th index unused
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month];
  }

  String formatDateTime(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = _monthName(dateTime.month);
    final year = dateTime.year;
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');

    return '$day $month, $year, $hour:$minute hrs';
  }

  final BookingRideController bookingRideController =
      Get.put(BookingRideController());
  String? tripCode;

  void getCurrentTripCode() async {
    tripCode = await StorageServices.instance.read('currentTripCode');
    setState(() {});
    print('yash trip code : $tripCode');
  }

  @override
  Widget build(BuildContext context) {
    String? _country;
    final pickupDateTime = bookingRideController.localStartTime.value;
    final formattedPickup = formatDateTime(pickupDateTime);
    final isIndia = _country?.toLowerCase() == 'india';

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8), // 8px radius
            boxShadow: [
              BoxShadow(
                color: const Color(0x0A000000), // #0000000A with 4% opacity
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
            leading: const Icon(Icons.arrow_back, size: 20),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    '${bookingRideController.prefilled.value} to ${bookingRideController.prefilledDrop.value}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                GestureDetector(
                    onTap: () {},
                    child: Icon(Icons.edit,
                        size: 16, color: AppColors.mainButtonBg)),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 0),
              child: Row(
                children: [
                  Text(
                    formattedPickup,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.greyText5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(width: 8),
                  if (tripCode == '0')
                    Text(
                      'Outstation One Way Trip',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.mainButtonBg,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  if (tripCode == '1')
                    Text(
                      'Outstation Round Trip',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.mainButtonBg,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  if (tripCode == '2')
                    Text(
                      'Airport Trip',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.mainButtonBg,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  if (tripCode == '3')
                    Text(
                      'Rental Trip',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.mainButtonBg,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ExtrasSelectionCard extends StatefulWidget {
  @override
  _ExtrasSelectionCardState createState() => _ExtrasSelectionCardState();
}

class _ExtrasSelectionCardState extends State<ExtrasSelectionCard> {
  List<SelectableExtra> indiaExtras = [];
  List<SelectableExtra> globalExtras = [];
  bool isLoading = true;
  String? _country;

  final CabBookingController cabBookingController = Get.put(CabBookingController());

  @override
  void initState() {
    super.initState();
    loadInitialData();
  }

  Future<void> loadInitialData() async {
    // Replace this with your actual country read method
    _country = await StorageServices.instance.read('country');

    final rawIndiaExtras = cabBookingController.indiaData.value?.inventory?.carTypes?.extrasIdArray ?? [];
    final rawGlobalExtras = cabBookingController.globalData.value?.vehicleDetails?.extraArray ?? [];

    setState(() {
      indiaExtras = rawIndiaExtras
          .map((e) => SelectableExtra(
        label: e.name ?? '',
        price: e.price?.daily ?? 0,
      )).toList();

      globalExtras = rawGlobalExtras
          .map((e) => SelectableExtra(
        label: e.name ?? '',
        price: e.price?.daily ?? 0,
      )).toList();

      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading || _country == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final isIndia = _country!.toLowerCase() == 'india';
    final extras = isIndia ? indiaExtras : globalExtras;
    final title = isIndia ? "Choose Extras" : "Choose Extras";

    return _buildExtrasCard(title: title, extras: extras);
  }

  Widget _buildExtrasCard({
    required String title,
    required List<SelectableExtra> extras,
  }) {
    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            if (extras.isEmpty)
              const Text("No extras available", style: TextStyle(color: Colors.grey, fontSize: 14))
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: extras.length,
                itemBuilder: (context, index) {
                  final item = extras[index];

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Row(
                      children: [
                        CustomCheckbox(
                          value: item.isSelected,
                          onChanged: (val) {
                            setState(() {
                              item.isSelected = val;
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.label,
                            style: const TextStyle(fontSize: 14, color: Colors.black87),
                          ),
                        ),
                        Text(
                         _country?.toLowerCase() == 'india' ? '₹ ${item.price.toStringAsFixed(0)}' : 'USD ${item.price.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 4),
                        const Padding(
                          padding: EdgeInsets.only(right: 8.0),
                          child: Text(
                            'per day',
                            style: TextStyle(fontSize: 12, color: Colors.black54),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class ExtraItem {
  String label;
  int price;
  bool isSelected;

  ExtraItem({
    required this.label,
    required this.price,
    this.isSelected = false,
  });
}

class TravelerDetailsForm extends StatefulWidget {
  @override
  _TravelerDetailsFormState createState() => _TravelerDetailsFormState();
}

class _TravelerDetailsFormState extends State<TravelerDetailsForm> {
  String selectedTitle = 'Mr.';
  final List<String> titles = ['Mr.', 'Ms.', 'Mrs.'];

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.greyBorder1, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Top Row: Title + Info icon
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Travelers Details",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                Icon(Icons.info_outline, size: 18, color: Colors.black54),
              ],
            ),

            const SizedBox(height: 12),

            /// Title Buttons
            Row(
              children: titles.map((title) {
                final isSelected = selectedTitle == title;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                    label: Text(title),
                    selected: isSelected,
                    selectedColor: AppColors.mainButtonBg,
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                      side: BorderSide(color: AppColors.mainButtonBg),
                    ),
                    showCheckmark: false, // 🔍 This removes the check icon
                    onSelected: (_) => setState(() {
                      selectedTitle = title;
                    }),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            /// Full Name
            _buildTextField(hint: "Enter full name"),

            /// Email
            _buildTextField(hint: "Enter email id"),

            /// Phone
            _buildPhoneField(),

            /// Pickup
            _buildTextField(
              hint: "Enter Pickup Address",
              tag: "New Delhi, Delhi, India",
            ),

            /// Drop
            _buildTextField(
              hint: "Enter Dropping Address",
              tag: "Agra, Uttar Pradesh, India",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({required String hint, String? tag}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.black45),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.black54),
              ),
              contentPadding: EdgeInsets.symmetric(vertical: 4),
            ),
          ),
          if (tag != null) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Color(0xFFFFF4C4), // Yellow highlight
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                tag,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildPhoneField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Text(
            "+91",
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: "Enter mobile number",
                hintStyle: TextStyle(color: Colors.black45),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.black54),
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SelectableExtra {
  final String label;
  final num price;
  bool isSelected;

  SelectableExtra({
    required this.label,
    required this.price,
    this.isSelected = false,
  });
}

// UI custom checkbox
class CustomCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const CustomCheckbox({
    Key? key,
    required this.value,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: value ? AppColors.mainButtonBg : Colors.white,
          border: Border.all(
            color: AppColors.mainButtonBg,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: value
            ? const Icon(Icons.check, size: 16, color: Colors.white)
            : null,
      ),
    );
  }
}