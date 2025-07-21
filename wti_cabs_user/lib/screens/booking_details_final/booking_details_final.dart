import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:go_router/go_router.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:wti_cabs_user/common_widget/buttons/main_button.dart';
import 'package:wti_cabs_user/core/controller/cab_booking/cab_booking_controller.dart';
import 'package:wti_cabs_user/core/controller/coupons/apply_coupon_controller.dart';
import 'package:wti_cabs_user/core/controller/coupons/fetch_coupons_controller.dart';
import 'package:wti_cabs_user/core/controller/payment/global/global_provisional_booking.dart';
import 'package:wti_cabs_user/core/controller/payment/india/provisional_booking_controller.dart';
import 'package:wti_cabs_user/core/controller/profile_controller/profile_controller.dart';
import 'package:wti_cabs_user/core/model/fetch_coupon/fetch_coupon_response.dart';

import '../../core/controller/booking_ride_controller.dart';
import '../../core/controller/inventory/search_cab_inventory_controller.dart';
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
  String? token;
  String? firstName;
  String? email;
  String? contact;
  String? contactCode;
  final CabBookingController cabBookingController =
      Get.put(CabBookingController());
  final ProfileController profileController = Get.put(ProfileController());
  final CouponController couponController = Get.put(CouponController());

  @override
  void initState() {
    super.initState();
    loadInitialData();
  }

  Future<void> loadInitialData() async {
    _country = await StorageServices.instance.read('country');
    token = await StorageServices.instance.read('token');

    await profileController.fetchData();
    await couponController.fetchCoupons(context);
    print('📦 3rd page country: $_country');
    if (token != null) {
      firstName = await StorageServices.instance.read('firstName');
      contact = await StorageServices.instance.read('contact');
      contactCode = await StorageServices.instance.read('contactCode');
      email = await StorageServices.instance.read(
        'emailId',
      );
    }
    setState(() {}); // to trigger rebuild once _country is loaded
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBgPrimary1,
      body: SafeArea(
        child: Padding(
            padding: const EdgeInsets.only(top: 12.0, left: 12.0, right: 12.0, bottom: 70),
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
                  CouponScreen(),
                  SizedBox(
                    height: 16,
                  ),
                  TravelerDetailsForm(),

                ],
              ),
            )),
      ),
      bottomSheet: BottomPaymentBar(),
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
                  width: 96,
                  height: 66,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Image.asset(
                      'assets/images/inventory_car.png',
                      width: 96,
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
            leading: GestureDetector(
              onTap: (){
                GoRouter.of(context).pop();
              },
                child: const Icon(Icons.arrow_back, size: 20)),
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
                // GestureDetector(
                //     onTap: () {},
                //     child: Icon(Icons.edit,
                //         size: 16, color: AppColors.mainButtonBg)),
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

  final CabBookingController cabBookingController =
      Get.put(CabBookingController());

  @override
  void initState() {
    super.initState();
    loadInitialData();
  }

  Future<void> loadInitialData() async {
    _country = await StorageServices.instance.read('country');

    final rawIndiaExtras = cabBookingController
            .indiaData.value?.inventory?.carTypes?.extrasIdArray ??
        [];
    final rawGlobalExtras =
        cabBookingController.globalData.value?.vehicleDetails?.extraArray ?? [];

    setState(() {
      indiaExtras = rawIndiaExtras.map((e) {
        return SelectableExtra(
          id: e.id ?? '',
          label: e.name ?? '',
          price: e.price?.daily ?? 0,
        );
      }).toList();

      globalExtras = rawGlobalExtras.map((e) {
        return SelectableExtra(
          id: e.id ?? '',
          label: e.name ?? '',
          price: e.price?.daily ?? 0,
        );
      }).toList();

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
    final title = "Choose Extras";

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
            Text(title,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            if (extras.isEmpty)
              const Text("No extras available",
                  style: TextStyle(color: Colors.grey, fontSize: 14))
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
                              extras[index].isSelected = val;

                              // Store selected IDs in controller
                              cabBookingController.toggleExtraId(item.id, val);

                              // Existing logic
                              cabBookingController.toggleExtraFacility(
                                item.label,
                                item.price.toDouble(),
                                val,
                              );
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.label,
                            style: const TextStyle(
                                fontSize: 14, color: Colors.black87),
                          ),
                        ),
                        Text(
                          _country?.toLowerCase() == 'india'
                              ? '₹ ${item.price.toStringAsFixed(0)}'
                              : 'USD ${item.price.toStringAsFixed(0)}',
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 4),
                        const Padding(
                          padding: EdgeInsets.only(right: 8.0),
                          child: Text(
                            'per day',
                            style:
                                TextStyle(fontSize: 12, color: Colors.black54),
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
  final ProfileController profileController = Get.put(ProfileController());
  final TextEditingController mobileController = TextEditingController();
  PhoneNumber number = PhoneNumber(isoCode: 'IN');
  String? _country;
  String? token;
  String? firstName;
  String? email;
  String? contact;
  String? contactCode;

  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController contactController = TextEditingController();
  final TextEditingController sourceController = TextEditingController();
  final TextEditingController destinationController = TextEditingController();
  final BookingRideController bookingRideController =
      Get.put(BookingRideController());

  @override
  void initState() {
    super.initState();
    loadInitialData();
  }

  Future<void> loadInitialData() async {
    _country = await StorageServices.instance.read('country');
    token = await StorageServices.instance.read('token');

    await profileController.fetchData();
    print('📦 3rd page country: $_country');
      firstName = profileController.profileResponse.value?.result?.firstName??'';
      contact = profileController.profileResponse.value?.result?.contact.toString()??'';
      contactCode = profileController.profileResponse.value?.result?.contactCode??'';
      email = profileController.profileResponse.value?.result?.emailID??'';

      firstNameController.text = firstName ?? '';
      emailController.text = email ?? '';
      contactController.text = contact ?? '';
      sourceController.text = bookingRideController.prefilled.value;
      destinationController.text = bookingRideController.prefilledDrop.value;

    print('First Name: $firstName');
    print('Contact: $contact');
    print('Contact Code: $contactCode');
    print('Email: $email');

    setState(() {}); // to trigger rebuild once _country is loaded
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      margin: EdgeInsets.only(bottom: 40),
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
            _buildTextField(
                hint: "Enter full name", controller: firstNameController),

            /// Email
            _buildTextField(
                hint: "Enter email id", controller: emailController),

            /// Phone
            Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey.shade300,
                    width: 1.0,
                  ),
                ),
              ),
              child: InternationalPhoneNumberInput(
                selectorConfig: const SelectorConfig(
                  selectorType: PhoneInputSelectorType.BOTTOM_SHEET,
                  useBottomSheetSafeArea: true,
                  showFlags: true,
                ),
                ignoreBlank: false,
                autoValidateMode: AutovalidateMode.disabled,
                selectorTextStyle: const TextStyle(color: Colors.black),
                initialValue: number,
                textFieldController: contactController,
                formatInput: false,
                keyboardType:
                    const TextInputType.numberWithOptions(signed: true),
                validator: (_) => null,
                maxLength: 10,
                inputDecoration: const InputDecoration(
                  hintText: "Enter Mobile Number",
                  hintStyle: TextStyle(color: Colors.black45),
                  counterText: "",
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 0, vertical: 14),
                  border: InputBorder.none,
                ),
                onInputChanged: (PhoneNumber value) async {
                  contact = value.phoneNumber
                          ?.replaceFirst(value.dialCode ?? '', '') ??
                      '';
                  contactCode = value.dialCode?.replaceAll('+', '');

                  await StorageServices.instance.save('contact', contact ?? '');
                  await StorageServices.instance
                      .save('contactCode', contactCode ?? '');

                  print("📱 Contact updated (no country code): $contact");
                  print("📞 Dial Code updated: $contactCode");

                  setState(() {});
                },
              ),
            ),

            /// Pickup

            SizedBox(
              height: 8,
            ),
            _buildTextField(
                hint: "Enter Pickup Address",
                tag: "",
                controller: sourceController),

            /// Drop
            _buildTextField(
                hint: "Enter Dropping Address",
                tag: "",
                controller: destinationController),

            SizedBox(
              height: 40,
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
      {required String hint,
      required TextEditingController controller,
      String? tag}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller,
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
            onChanged: (value) async {
              if (controller == firstNameController) {
                firstName = value;
                await StorageServices.instance.save('firstName', value);
                print("📝 First Name updated: $value");
              } else if (controller == emailController) {
                email = value;
                await StorageServices.instance.save('emailId', value);
                print("📧 Email updated: $value");
              } else if (controller == sourceController) {
                bookingRideController.prefilled.value = value;
                await StorageServices.instance.save('pickupAddress', value);
                print("📍 Pickup Address updated: $value");
              } else if (controller == destinationController) {
                bookingRideController.prefilledDrop.value = value;
                await StorageServices.instance.save('dropAddress', value);
                print("🏁 Drop Address updated: $value");
              }

              setState(() {}); // Trigger rebuild if needed
            },
          ),
        ],
      ),
    );
  }

  // Widget _buildPhoneField() {
  //   return Padding(
  //     padding: const EdgeInsets.only(bottom: 16.0),
  //     child: Row(
  //       children: [
  //         Text(
  //           "+91",
  //           style: TextStyle(fontWeight: FontWeight.w600),
  //         ),
  //         const SizedBox(width: 12),
  //         Expanded(
  //           child: TextField(
  //             keyboardType: TextInputType.phone,
  //             decoration: InputDecoration(
  //               hintText: "Enter mobile number",
  //               hintStyle: TextStyle(color: Colors.black45),
  //               enabledBorder: UnderlineInputBorder(
  //                 borderSide: BorderSide(color: Colors.grey.shade300),
  //               ),
  //               focusedBorder: UnderlineInputBorder(
  //                 borderSide: BorderSide(color: Colors.black54),
  //               ),
  //               contentPadding: EdgeInsets.symmetric(vertical: 4),
  //             ),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }
}

class SelectableExtra {
  final String id;
  final String label;
  final num price;
  bool isSelected;

  SelectableExtra({
    required this.id,
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

// coupon ui
class CouponScreen extends StatefulWidget {
  const CouponScreen({super.key});

  @override
  State<CouponScreen> createState() => _CouponScreenState();
}

class _CouponScreenState extends State<CouponScreen> {
  String? selectedCouponCode;
  final TextEditingController couponController = TextEditingController();
  final CouponController fetchCouponController = Get.put(CouponController());
  final ApplyCouponController applyCouponController =
      Get.put(ApplyCouponController());

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0.5,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Available Coupons",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 220,
              child: Scrollbar(
                thickness: 2,
                thumbVisibility: true,
                radius: const Radius.circular(4),
                trackVisibility: false,
                interactive: true,
                scrollbarOrientation: ScrollbarOrientation.right,
                child: ListView.builder(
                  itemCount: fetchCouponController.coupons.length,
                  itemBuilder: (context, index) {
                    final coupon = fetchCouponController.coupons[index];
                    return _buildCouponCard(coupon);
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Have a coupon code?",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: couponController,
                    decoration: InputDecoration(
                      hintText: "Enter Coupon Code",
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    final inputCode = couponController.text.trim();
                    if (inputCode.isNotEmpty) {
                      setState(() {
                        selectedCouponCode = inputCode;
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade500,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text("Apply"),
                )
              ],
            ),
            if (selectedCouponCode != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  children: [
                    Icon(Icons.discount, color: Colors.green, size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Coupon "$selectedCouponCode" applied',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.green),
                      ),
                    ),
                    Chip(
                      label: const Text(
                        'Remove',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      // avatar: const Icon(
                      //   Icons.close,
                      //   size: 16,
                      //   color: Colors.redAccent,
                      // ),
                      backgroundColor: Colors.redAccent.withOpacity(0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                            color: Colors.redAccent.withOpacity(0.5)),
                      ),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 2, vertical: 0),
                      deleteIcon: null,
                      deleteIconColor: Colors.redAccent,
                      onDeleted: () {
                        setState(() {
                          selectedCouponCode = null;
                          couponController.clear();
                          applyCouponController.isCouponApplied.value = false;
                        });
                      },
                    )
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCouponCard(CouponData coupon) {
    final ApplyCouponController applyCouponController =
        Get.put(ApplyCouponController());
    final BookingRideController bookingRideController =
        Get.put(BookingRideController());
    final CabBookingController cabBookingController =
        Get.put(CabBookingController());
    final SearchCabInventoryController searchCabInventoryController =
        Get.put(SearchCabInventoryController());
    final isSelected = selectedCouponCode == coupon.codeName;
    return GestureDetector(
      onTap: () async {
        final token = await StorageServices.instance.read('token');
        final Map<String, dynamic> requestData = {
          "userID": null,
          "couponID": coupon.id,
          "totalAmount": 1200,
          "sourceLocation": bookingRideController.prefilled.value,
          "destinationLocation": bookingRideController.prefilledDrop.value,
          "serviceType": null,
          "bankName": null,
          "userType": "CUSTOMER",
          "bookingDateTime":
              await StorageServices.instance.read('userDateTime'),
          "appliedCoupon": token != null ? 1 : 0,
          "payNow": cabBookingController.actualFare,
          "tripType": searchCabInventoryController
              .indiaData.value?.result?.tripType?.currentTripCode,
          "vehicleType":
              cabBookingController.indiaData.value?.inventory?.carTypes?.type ??
                  ''
        };
        setState(() {
          if (isSelected && coupon.couponIsActive == true) {
            selectedCouponCode = null;
            couponController.clear();
          } else {
            selectedCouponCode = coupon.codeName;
            couponController.text = coupon.codeName ?? "";

            applyCouponController.applyCoupon(
                requestData: requestData, context: context);
          }
        });
      },
      child: Opacity(
        opacity: coupon.couponIsActive == true ? 1 : 0.4,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.grey.shade100 : Colors.grey.shade100,
            border: Border.all(
              color: isSelected ? AppColors.mainButtonBg : Colors.grey.shade300,
              width: 1.3,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                isSelected
                    ? Icons.check_circle_rounded
                    : Icons.local_offer_outlined,
                color: isSelected ? AppColors.mainButtonBg : Colors.black54,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      coupon.codeDescription ?? '',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Text(
                    //   coupon.description,
                    //   style: const TextStyle(fontSize: 13),
                    // ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                          color: isSelected
                              ? AppColors.mainButtonBg
                              : Colors.grey.shade400,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        coupon.codeName ?? '',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                          color: isSelected
                              ? AppColors.mainButtonBg
                              : Colors.black87,
                        ),
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      )

    );
  }
}

class BottomPaymentBar extends StatefulWidget {
  @override
  _BottomPaymentBarState createState() => _BottomPaymentBarState();
}

class _BottomPaymentBarState extends State<BottomPaymentBar> {
  final CabBookingController cabBookingController = Get.find(); // ✅ FIXED
  int selectedOption = 0;
  String? _country;
  final IndiaPaymentController indiaPaymentController =
      Get.put(IndiaPaymentController());
  final GlobalPaymentController globalPaymentController =
  Get.put(GlobalPaymentController());
  String? token;
  String? firstName;
  String? email;
  String? contact;
  String? contactCode;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    loadInitialData();

  } // 0 = Part Pay, 1 = Full Pay

  Future<void> loadInitialData() async {
    _country = await StorageServices.instance.read('country');

    cabBookingController.country = _country;
    token = await StorageServices.instance.read('token');
    print('📦 3rd page country: $_country');


    firstName = await StorageServices.instance.read('firstName');
    contact = await StorageServices.instance.read('contact');
    contactCode = await StorageServices.instance.read('contactCode');
    email = await StorageServices.instance.read('emailId');

    setState(() {}); // to trigger rebuild once _country is loaded
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Obx(
                () =>  Row(
                  children: [
                    _country?.toLowerCase().trim() == 'india' ?  _buildRadioOption(
                      index: 0,
                      title: 'Part Pay',
                      amount: _country?.toLowerCase() == 'india'
                          ? '₹ ${cabBookingController.partFare.toStringAsFixed(0)}'
                          : 'USD ${cabBookingController.partFare.toStringAsFixed(0)}',
                    ) : SizedBox(),
                    VerticalDivider(width: 1, color: Colors.grey.shade300),
                    _buildRadioOption(
                      index: 1,
                      title: 'Full Pay',
                      amount: _country?.toLowerCase() == 'india'
                          ? '₹ ${cabBookingController.totalFare.toStringAsFixed(0)}'
                          : 'USD ${cabBookingController.totalFare.toStringAsFixed(0)}',
                      showInfoIcon: true,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
              width: 120,
              height: 54,
              child: MainButton(
                  text: 'Pay Now',
                  onPressed:
                  // _country?.toLowerCase() == 'india' ?
                      () async {

                        showRazorpaySkeletonLoader(context);
                    print(
                        'yash amountToBeCollected ids : ${double.parse(cabBookingController.amountTobeCollected.toStringAsFixed(2))}');
                    print(
                        'yash fare details : ${cabBookingController.indiaData.value?.inventory?.carTypes?.fareDetails?.toJson()}');
                    final timeZone =
                        await StorageServices.instance.read('timeZone');
                    final sourceTitle =
                        await StorageServices.instance.read('sourceTitle');
                    final sourcePlaceId =
                        await StorageServices.instance.read('sourcePlaceId');
                    final sourceCity =
                        await StorageServices.instance.read('sourceCity');
                    final sourceState =
                        await StorageServices.instance.read('sourceState');
                    final sourceCountry =
                        await StorageServices.instance.read('country');
                    final sourceLat =
                        await StorageServices.instance.read('sourceLat');
                    final sourceLng =
                        await StorageServices.instance.read('sourceLng');
                    // source type and terms
                    final typesJson =
                        await StorageServices.instance.read('sourceTypes');
                    final List<String> sourceTypes =
                        typesJson != null && typesJson.isNotEmpty
                            ? List<String>.from(jsonDecode(typesJson))
                            : [];

                    final termsJson =
                        await StorageServices.instance.read('sourceTerms');
                    final List<Map<String, dynamic>> sourceTerms = termsJson !=
                                null &&
                            termsJson.isNotEmpty
                        ? List<Map<String, dynamic>>.from(jsonDecode(termsJson))
                        : [];

                    //destination type and terms
                    final destinationPlaceId = await StorageServices.instance
                        .read('destinationPlaceId');
                    final destinationTitle =
                        await StorageServices.instance.read('destinationTitle');
                    final destinationCity =
                        await StorageServices.instance.read('destinationCity');
                    final destinationState =
                        await StorageServices.instance.read('destinationState');
                    final destinationCountry = await StorageServices.instance
                        .read('destinationCountry');

                    final destinationTypesJson =
                        await StorageServices.instance.read('destinationTypes');
                    final destinationTermsJson =
                        await StorageServices.instance.read('destinationTerms');

// Decode JSON strings to actual List or Map types (if applicable)
                    final List<String> destinationType = destinationTypesJson !=
                                null &&
                            destinationTypesJson.isNotEmpty
                        ? List<String>.from(jsonDecode(destinationTypesJson))
                        : [];
                    final List<Map<String, dynamic>> destinationTerms =
                        destinationTermsJson != null &&
                                destinationTermsJson.isNotEmpty
                            ? List<Map<String, dynamic>>.from(
                                jsonDecode(destinationTermsJson))
                            : [];
                    final destinationLat =
                        await StorageServices.instance.read('destinationLat');
                    final destinationLng =
                        await StorageServices.instance.read('destinationLng');

                    final Map<String, dynamic> requestData = {
                      "firstName":
                          await StorageServices.instance.read('firstName'),
                      "contactCode":
                          await StorageServices.instance.read('contactCode'),
                      "contact": await StorageServices.instance.read('contact'),
                      "countryName": _country,
                      "userType": "CUSTOMER",
                      "gender": 'MALE',
                      "emailID": await StorageServices.instance.read('emailId')
                    };
                    final Map<String, dynamic> provisionalRequestData = {
                      "reservation": {
                        "flightNumber": "",
                        "remarks": "",
                        "gst_number": "",
                        "payment_gateway_used": 1,
                        "countryName": _country,
                        "search_id": "",
                        "partnername": "wti",
                        "start_time": cabBookingController
                            .indiaData.value?.tripType?.pickUpDateTime
                            ?.toIso8601String(),
                        "end_time": cabBookingController
                            .indiaData.value?.tripType?.dropDateTime
                            ?.toIso8601String(),
                        "platform_fee": 0,
                        "booking_gst": 0,
                        "one_way_distance": cabBookingController
                            .indiaData.value?.inventory?.distanceBooked
                            ?.toInt(),
                        "distance": cabBookingController
                            .indiaData.value?.inventory?.distanceBooked
                            ?.toInt(),
                        "package": await StorageServices.instance.read('currentTripCode') == '4' ? cabBookingController.indiaData.value?.inventory?.carTypes?.packageId??'' : null,
                        "flags": [],
                        "base_km": cabBookingController
                            .indiaData.value?.inventory?.carTypes?.baseKm
                            ?.toInt(),
                        "vehicle_details": {
                          "sku_id": cabBookingController.indiaData.value
                                  ?.inventory?.carTypes?.skuId ??
                              '',
                          "fleet_id": cabBookingController.indiaData.value
                                  ?.inventory?.carTypes?.fleetId ??
                              '',
                          "type": cabBookingController
                                  .indiaData.value?.inventory?.carTypes?.type ??
                              '',
                          "subcategory": cabBookingController.indiaData.value
                                  ?.inventory?.carTypes?.subcategory ??
                              '',
                          "combustion_type": cabBookingController.indiaData
                                  .value?.inventory?.carTypes?.combustionType ??
                              '',
                          "model": cabBookingController.indiaData.value
                                  ?.inventory?.carTypes?.model ??
                              '',
                          "carrier": cabBookingController.indiaData.value
                                  ?.inventory?.carTypes?.carrier ??
                              false,
                          "make_year_type": cabBookingController.indiaData.value
                                  ?.inventory?.carTypes?.makeYearType ??
                              '',
                          "make_year": ""
                        },
                        "source": {
                          "sourceTitle": sourceTitle,
                          "sourcePlaceId": sourcePlaceId,
                          "sourceCity": sourceCity,
                          "sourceState": sourceState,
                          "sourceCountry": sourceCountry,
                          "sourceType": sourceTypes,
                          "sourceLat": sourceLat,
                          "sourceLng": sourceLng,
                          "terms": sourceTerms
                        },
                        "destination": {
                          "destinationTitle": destinationTitle,
                          "destinationPlaceId": destinationPlaceId,
                          "destinationCity": destinationCity,
                          "destinationState": destinationState,
                          "destinationCountry": destinationCountry,
                          "destinationType": destinationType,
                          "destinationLat": destinationLat,
                          "destinationLng": destinationLng,
                          "terms": destinationTerms
                        },
                        "stopovers": [],
                        "trip_type_details": {
                          "basic_trip_type": cabBookingController
                                  .indiaData
                                  .value
                                  ?.tripType
                                  ?.tripTypeDetails
                                  ?.basicTripType ??
                              '',
                          "trip_type": "ONE_WAY",
                          cabBookingController.indiaData.value?.tripType
                                      ?.tripTypeDetails?.airportType !=
                                  null
                              ? "airport_type"
                              : cabBookingController.indiaData.value?.tripType
                                      ?.tripTypeDetails?.basicTripType ??
                                  '': null
                        },
                        "paid": false,
                        "extrasSelected":
                            cabBookingController.selectedExtrasIds,
                        "total_fare": cabBookingController.totalFare,
                        "amount_to_be_collected": double.parse(
                            cabBookingController.amountTobeCollected
                                .toStringAsFixed(2)),
                        "cancelled_by": null,
                        "cancellation_reason": null,
                        "canceltime": null,
                        "couponCodeUsed": null,
                        "offerUsed": null,
                        "userType": "CUSTOMER",
                        "timezone":
                            await StorageServices.instance.read('timeZone'),
                        "guest_id": null
                      },
                      "order": {"currency": "INR", "amount": selectedOption == 0 ? cabBookingController.partFare : cabBookingController.totalFare, //(part payment or full paymenmt)
                      },
                      "receiptData": {
                        "countryName": "india",
                        "baseCurrency": "INR",
                        "currency": {"currencyName": "INR", "currencyRate": 1},
                        "addon_charges":
                            cabBookingController.extraFacilityCharges,
                        "isOffer": false,
                        "fare_details": {
                          "actual_fare": cabBookingController.actualFare,
                          "seller_discount": 0,
                          "per_km_charge": cabBookingController
                                  .indiaData
                                  .value
                                  ?.inventory
                                  ?.carTypes
                                  ?.fareDetails
                                  ?.perKmCharge ??
                              0,
                          "per_km_extra_charge": cabBookingController
                                  .indiaData
                                  .value
                                  ?.inventory
                                  ?.carTypes
                                  ?.fareDetails
                                  ?.perKmExtraCharge ??
                              0,
                          "amount_paid":
                              selectedOption == 0 ? cabBookingController.partFare : cabBookingController.totalFare, //(part payment or full paymenmt)
                          "total_driver_charges": cabBookingController
                                  .indiaData
                                  .value
                                  ?.inventory
                                  ?.carTypes
                                  ?.fareDetails
                                  ?.totalDriverCharges ??
                              0,
                          "base_fare": cabBookingController
                                  .indiaData
                                  .value
                                  ?.inventory
                                  ?.carTypes
                                  ?.fareDetails
                                  ?.baseFare ??
                              0,
                          "total_fare": cabBookingController.totalFare, //(full payment)
                          "total_tax": 5,
                          "extra_time_fare": cabBookingController
                              .indiaData
                              .value
                              ?.inventory
                              ?.carTypes
                              ?.fareDetails
                              ?.extraTimeFare
                              ?.toJson(),
                          "extra_charges": cabBookingController.indiaData.value
                              ?.inventory?.carTypes?.fareDetails?.extraCharges
                              ?.toJson(),
                          "amount_to_be_collected": double.parse(
                              cabBookingController.amountTobeCollected
                                  .toStringAsFixed(2))
                        },
                        // "fare_details": cabBookingController.indiaData.value?.inventory?.carTypes?.fareDetails?.toJson(),

                        "paymentType": selectedOption == 1 ? "FULL" : "PART"
                      }
                    };
                    GoRouter.of(context).pop();
                    await indiaPaymentController.verifySignup(
                        requestData: requestData,
                        provisionalRequestData: provisionalRequestData,
                        context: context);
                  }
//                       : () async{
//                     print(
//                         'yash amountToBeCollected ids : ${double.parse(cabBookingController.amountTobeCollected.toStringAsFixed(2))}');
//                     print(
//                         'yash fare details : ${cabBookingController.indiaData.value?.inventory?.carTypes?.fareDetails?.toJson()}');
//                     final timeZone =
//                     await StorageServices.instance.read('timeZone');
//                     final sourceTitle =
//                     await StorageServices.instance.read('sourceTitle');
//                     final sourcePlaceId =
//                     await StorageServices.instance.read('sourcePlaceId');
//                     final sourceCity =
//                     await StorageServices.instance.read('sourceCity');
//                     final sourceState =
//                     await StorageServices.instance.read('sourceState');
//                     final sourceCountry =
//                     await StorageServices.instance.read('country');
//                     final sourceLat =
//                     await StorageServices.instance.read('sourceLat');
//                     final sourceLng =
//                     await StorageServices.instance.read('sourceLng');
//                     // source type and terms
//                     final typesJson =
//                     await StorageServices.instance.read('sourceTypes');
//                     final List<String> sourceTypes =
//                     typesJson != null && typesJson.isNotEmpty
//                         ? List<String>.from(jsonDecode(typesJson))
//                         : [];
//
//                     final termsJson =
//                     await StorageServices.instance.read('sourceTerms');
//                     final List<Map<String, dynamic>> sourceTerms = termsJson !=
//                         null &&
//                         termsJson.isNotEmpty
//                         ? List<Map<String, dynamic>>.from(jsonDecode(termsJson))
//                         : [];
//
//                     //destination type and terms
//                     final destinationPlaceId = await StorageServices.instance
//                         .read('destinationPlaceId');
//                     final destinationTitle =
//                     await StorageServices.instance.read('destinationTitle');
//                     final destinationCity =
//                     await StorageServices.instance.read('destinationCity');
//                     final destinationState =
//                     await StorageServices.instance.read('destinationState');
//                     final destinationCountry = await StorageServices.instance
//                         .read('destinationCountry');
//
//                     final destinationTypesJson =
//                     await StorageServices.instance.read('destinationTypes');
//                     final destinationTermsJson =
//                     await StorageServices.instance.read('destinationTerms');
//
// // Decode JSON strings to actual List or Map types (if applicable)
//                     final List<String> destinationType = destinationTypesJson !=
//                         null &&
//                         destinationTypesJson.isNotEmpty
//                         ? List<String>.from(jsonDecode(destinationTypesJson))
//                         : [];
//                     final List<Map<String, dynamic>> destinationTerms =
//                     destinationTermsJson != null &&
//                         destinationTermsJson.isNotEmpty
//                         ? List<Map<String, dynamic>>.from(
//                         jsonDecode(destinationTermsJson))
//                         : [];
//                     final destinationLat =
//                     await StorageServices.instance.read('destinationLat');
//                     final destinationLng =
//                     await StorageServices.instance.read('destinationLng');
//
//                     final Map<String, dynamic> requestData = {
//                       "firstName": "Yash Khare",
//                       "contactCode": "91",
//                       "contact": 9179419377,
//                       "countryName": "India",
//                       "userType": "CUSTOMER",
//                       "gender": "MALE",
//                       "emailID": "yash.khare@aaveg.com"
//                     };
//                     final Map<String, dynamic> provisionalRequestData = {
//                       "receiptData": {
//                         "countryName": "LONDON",
//                         "currency": {
//                           "currencyName": "INR",
//                           "currencyRate": 85.765
//                         },
//                         "baseCurrency": "USD",
//                         "addon_charges": 0,
//                         "freeWaitingTime": 15,
//                         "waitingInterval": 15,
//                         "normalWaitingCharge": 10,
//                         "airportWaitingChargeSlab": [],
//                         "congestion_charges": 0,
//                         "extra_global_charge": 0,
//                         "fare_details": {
//                           "actual_fare": 101,
//                           "seller_discount": 0,
//                           "base_fare": 101,
//                           "total_driver_charges": 0,
//                           "state_tax": 0,
//                           "toll_charges": 0,
//                           "night_charges": 0,
//                           "holiday_charges": 0,
//                           "total_tax": 0,
//                           "amount_paid": 0,
//                           "amount_to_be_collected": 0,
//                           "total_fare": 101,
//                           "per_km_charge": 0.09900990099009901,
//                           "extra_time_fare": {
//                             "rate": 10,
//                             "applicable_time": 15
//                           },
//                           "extra_charges": {}
//                         }
//                       },
//                       "reservation": {
//                         "flightNumber": "",
//                         "remarks": "",
//                         "payment_gateway_used": 0,
//                         "countryName": "LONDON",
//                         "partnername": "wti",
//                         "start_time": "2125-07-21T19:00:00.000Z",
//                         "end_time": "2125-07-21T19:21:00.000Z",
//                         "platform_fee": 0,
//                         "booking_gst": 0,
//                         "one_way_distance": 5,
//                         "distance": 0,
//                         "package": "",
//                         "flags": [
//                           "B2C"
//                         ],
//                         "base_km": 10,
//                         "vehicle_details": {
//                           "fleet_id": "67ff3e76282e5219a791276a",
//                           "sku_id": null,
//                           "type": "sedan",
//                           "subcategory": null,
//                           "combustion_type": "petrol",
//                           "model": "sedan",
//                           "carrier": null,
//                           "make_year_type": null,
//                           "make_year": "",
//                           "title": "Toyota prius or similar"
//                         },
//                         "source": {
//                           "address": "London, UK",
//                           "latitude": 51.5072178,
//                           "longitude": -0.1275862,
//                           "city": "London",
//                           "place_id": "ChIJdd4hrwug2EcRmSrV3Vo6llI",
//                           "types": [
//                             "political",
//                             "geocode",
//                             "locality"
//                           ],
//                           "state": "England",
//                           "country": "United Kingdom"
//                         },
//                         "destination": {
//                           "address": "Islington, London, UK",
//                           "latitude": 51.538621,
//                           "longitude": -0.1028346,
//                           "city": "Islington",
//                           "place_id": "ChIJbYmzrW4bdkgRrKWuY-3_qFo",
//                           "types": [
//                             "political",
//                             "sublocality",
//                             "geocode",
//                             "sublocality_level_1"
//                           ],
//                           "state": "England",
//                           "country": "United Kingdom"
//                         },
//                         "stopovers": [],
//                         "trip_type_details": {
//                           "basic_trip_type": "LOCAL",
//                           "trip_type": "ONE_WAY",
//                           "airport_type": "NONE"
//                         },
//                         "paid": false,
//                         "passenger": "6746bc63d602cf82adf329c3",
//                         "extrasSelected": [],
//                         "total_fare": 101,
//                         "amount_to_be_collected": 0,
//                         "cancelled_by": null,
//                         "cancellation_reason": null,
//                         "canceltime": null,
//                         "couponCodeUsed": null,
//                         "offerUsed": null,
//                         "stripe_cust_id": "cus_Si64rruaBXtZsi",
//                         "timezone": "Europe/London",
//                         "userType": "CUSTOMER",
//                         "guest_id": null
//                       }
//                     };
//                     final Map<String, dynamic> checkoutRequestData = {
//                       "amount": 8662.265,
//                       "currency": "INR",
//                       "order_reference_number": "ORD1753025551261",
//                       "userID": "6746bc63d602cf82adf329c3",
//                       "carType": "sedan",
//                       "description": "sedan",
//                       "userType": "CUSTOMER",
//                       "customerId": "cus_Se9xiBiseIzwCl"
//                     };
//
//                     GoRouter.of(context).pop();
//                     await globalPaymentController.verifySignup(requestData: requestData, provisionalRequestData: provisionalRequestData, checkoutRequestData: checkoutRequestData, context: context);
//                   }
                  )

          )
        ],
      ),
    );
  }

  Widget _buildRadioOption({
    required int index,
    required String title,
    required String amount,
    bool showInfoIcon = false,
  }) {
    final isSelected = selectedOption == index;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            selectedOption = index;
          });
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 18,
              color: isSelected ? Colors.blue.shade700 : Colors.grey,
            ),
            const SizedBox(width: 6),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (showInfoIcon) ...[
                      const SizedBox(width: 4),
                      Icon(Icons.info_outline, size: 14, color: Colors.grey),
                    ],
                  ],
                ),
                Text(
                  amount,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
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


void showRazorpaySkeletonLoader(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false, // disables tapping outside to dismiss
    builder: (BuildContext context) {
      return WillPopScope(
        onWillPop: () async => false, // disables back button
        child: Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const CircularProgressIndicator(),
                const SizedBox(width: 16),
                Expanded(
                  child: Text('Payment Processing...', style: CommonFonts.bodyText3,),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
