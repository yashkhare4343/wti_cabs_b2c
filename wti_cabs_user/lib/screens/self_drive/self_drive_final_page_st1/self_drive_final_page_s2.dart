import 'dart:io';

import 'package:another_flushbar/flushbar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:shimmer/shimmer.dart';
import 'package:wti_cabs_user/core/controller/self_drive/self_drive_booking_details/self_drive_booking_details_controller.dart';
import 'package:wti_cabs_user/core/controller/self_drive/service_hub/service_hub_controller.dart';
import 'package:wti_cabs_user/core/route_management/app_routes.dart';
import 'package:wti_cabs_user/screens/self_drive/self_drive_all_inventory/self_drive_all_inventory.dart';
import 'package:wti_cabs_user/screens/self_drive/self_drive_popular_location/self_drive_most_popular_location.dart';

import '../../../core/controller/cab_booking/cab_booking_controller.dart';
import '../../../core/controller/profile_controller/profile_controller.dart';
import '../../../core/controller/self_drive/file_upload_controller/file_upload_controller.dart';
import '../../../core/controller/self_drive/google_lat_lng_controller/google_lat_lng_controller.dart';
import '../../../core/controller/self_drive/search_inventory_sd_controller/search_inventory_sd_controller.dart';
import '../../../core/controller/self_drive/self_drive_stripe_payment/sd_create_stripe_payment.dart';
import '../../../core/controller/self_drive/self_drive_upload_file_controller/self_drive_upload_file_controller.dart';
import '../../../core/services/storage_services.dart';
import '../../../utility/constants/colors/app_colors.dart';
import '../../booking_details_final/booking_details_final.dart';
import '../self_drive_popular_location/self_drive_return_popular_location.dart';

class SelfDriveFinalPageS2 extends StatefulWidget {
  final String? vehicleId;
  final bool? isHomePage;
  final bool? fromReturnMapPage;
  final bool? fromPaymentFailurePage;
  const SelfDriveFinalPageS2({super.key, this.vehicleId, this.isHomePage, this.fromReturnMapPage, this.fromPaymentFailurePage});

  @override
  State<SelfDriveFinalPageS2> createState() => _SelfDriveFinalPageS2State();
}

class _SelfDriveFinalPageS2State extends State<SelfDriveFinalPageS2> {
  final FetchSdBookingDetailsController fetchSdBookingDetailsController = Get.put(FetchSdBookingDetailsController());
  final SdCreateStripePaymentController sdCreateStripePaymentController = Get.put(SdCreateStripePaymentController());
  final FileUploadValidController fileUploadValidController = Get.find<FileUploadValidController>();
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  void showFareBreakdownSheet(BuildContext context,
      FetchSdBookingDetailsController controller) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Obx(() {
          final selectedType =
              controller.getAllBookingData.value?.result?.tarrifSelected;

          // Pick index based on selection
          int index = 0;
          if (selectedType == 'Daily') {
            index = 0;
          } else if (selectedType == 'Weekly') {
            index = 1;
          } else if (selectedType == 'Monthly') {
            index = 2;
          }

          final selectedTariff =
          controller.getAllBookingData.value?.result?.tarrifs?[index];
          final fareDetails = selectedTariff?.fareDetails;

          if (fareDetails == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text("No fare details available"),
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                Text(
                  "$selectedType Fare Breakdown",
                  style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                _fareRow("Base fare", "AED ${fareDetails.baseFare ?? 0}"),
                _fareRow("Delivery Charge", "AED ${fareDetails.delivery_charges ?? 0}"),
                _fareRow("Collection Charge", "AED ${fareDetails.collection_charges ?? 0}"),
                _fareRow("Deposite Free Rides", "AED ${fareDetails.deposit_free_ride ?? 0}"),
                _fareRow("Tax", "AED ${fareDetails.tax ?? 0}"),



                const Divider(height: 24, thickness: 1),

                _fareRow(
                  "Grand Total",
                  "AED ${fareDetails.grandTotal ?? 0}",
                  isTotal: true,
                ),

                const SizedBox(height: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Close",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  Widget _fareRow(String title, String amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchSdBookingDetailsController.isSameLocation.value = widget.fromReturnMapPage== true? false : true;
    });
    return Scaffold(
      backgroundColor: AppColors.scaffoldBgPrimary1,
      body: SafeArea(child: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  InkWell(
                    onTap:(){
                      GoRouter.of(context).pop();
                    },
                    child: CircleAvatar(
                      backgroundColor: Colors.white,
                      radius: 16,
                      child: Icon(Icons.arrow_back, color: Colors.black, size: 22),
                    ),
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width*0.8,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                          child: Text(
                            'Step 2 of 2',
                            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Text(
                'Book your car',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BookYourCarScreen(vehicleId: widget.vehicleId??'', isHomePage: widget.isHomePage??false,),
            ),
            CarRentalCard(vehicleId: widget.vehicleId??'', isHomePage: widget.isHomePage??false),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TravelerDetailsForm(
                formKey: cabBookingController.formKey,
                fromPaymentFailurePage: widget.fromPaymentFailurePage,
              ),
            ),
            UploadDocumentsScreen()
          ],
        ),
      )),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              offset: const Offset(0, -3),
              blurRadius: 10,
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Price Container
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children:  [
                    Text(
                      "Total Fare | ",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(width: 4),
                    Obx(() {
                      if (fetchSdBookingDetailsController.getAllBookingData
                          .value?.result?.tarrifSelected ==
                          'Daily'){
                        return Text(
                          "AED ${fetchSdBookingDetailsController.getAllBookingData.value?.result?.tarrifs?.first.fareDetails?.grandTotal}", // Bind dynamically
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        );
                      }
                      else if (fetchSdBookingDetailsController.getAllBookingData
                          .value?.result?.tarrifSelected ==
                          'Weekly'){
                        return Text(
                          "AED ${fetchSdBookingDetailsController.getAllBookingData.value?.result?.tarrifs?[1].fareDetails?.grandTotal}", // Bind dynamically
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        );
                      }
                      else if (fetchSdBookingDetailsController.getAllBookingData
                          .value?.result?.tarrifSelected ==
                          'Monthly'){
                        return Text(
                          "AED ${fetchSdBookingDetailsController.getAllBookingData.value?.result?.tarrifs?[2].fareDetails?.grandTotal}", // Bind dynamically
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        );
                      }
                      return Text(
                        "AED ${fetchSdBookingDetailsController.getAllBookingData.value?.result?.tarrifs?.first.fareDetails?.grandTotal}", // Bind dynamically
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      );
                    }),                  ],
                ),
              ),
              InkWell(
                splashColor: Colors.transparent,
                onTap: (){
                  showFareBreakdownSheet(context, fetchSdBookingDetailsController);
                },
                  child: Icon(Icons.info_outline, size: 20, color: Colors.grey,)),

              // Continue Button
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    final isValid = fileUploadValidController.validateUploads(0);

                    if (isValid) {

                      sdCreateStripePaymentController.createUser(context: context);
                      // Proceed with submission logic
                    } else {
                      Flushbar(
                        flushbarPosition: FlushbarPosition.TOP, // ✅ Show at top
                        margin: const EdgeInsets.all(12),
                        borderRadius: BorderRadius.circular(12),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 3),
                        icon: Icon(Icons.error, color: Colors.white,),
                        messageText: const Text(
                          "Please upload documents to continue",
                          style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                      ).show(context);                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0.3,
                    shadowColor: Colors.redAccent.withOpacity(0.4),
                  ),
                  child: const Text(
                    "Continue",
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
    );
  }
}

class BookYourCarScreen extends StatefulWidget {
  final String vehicleId;
  final bool isHomePage;
  const BookYourCarScreen({Key? key, required this.vehicleId, required this.isHomePage}) : super(key: key);

  @override
  State<BookYourCarScreen> createState() => _BookYourCarScreenState();
}

class _BookYourCarScreenState extends State<BookYourCarScreen> {
  final FetchSdBookingDetailsController fetchSdBookingDetailsController =
  Get.put(FetchSdBookingDetailsController());
  int _currentIndex = 0;
  bool _showOverlayText = true; // Track if text box should be visible

  @override
  void initState() {
    super.initState();
    fetchSdBookingDetailsController.fetchBookingDetails(
        widget.vehicleId, widget.isHomePage);
  }

  @override
  Widget build(BuildContext context) {
    final images = fetchSdBookingDetailsController
        .getAllBookingData.value?.result?.vehicleId?.images ??
        [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                    bottom: Radius.circular(20),
                  ),
                  child: CarouselSlider.builder(
                    itemCount: images.length,
                    itemBuilder: (context, imgIndex, realIndex) {
                      final img = images[imgIndex];
                      return SizedBox(
                        width: double.infinity,
                        height: 350,
                        child: CachedNetworkImage(
                          imageUrl: img ?? '',
                          fit: BoxFit.contain,
                          alignment: Alignment.center,
                          useOldImageOnUrlChange: true,
                          memCacheHeight: 320,
                          memCacheWidth: 550,
                          placeholder: (context, url) => Shimmer.fromColors(
                            baseColor: Colors.grey.shade300,
                            highlightColor: Colors.grey.shade100,
                            child: Container(
                              width: double.infinity,
                              height: 320,
                              color: Colors.grey,
                            ),
                          ),
                          errorWidget: (context, url, error) =>
                          const Icon(Icons.error, size: 50),
                        ),
                      );
                    },
                    options: CarouselOptions(
                      height: 320,
                      viewportFraction: 1.0,
                      enableInfiniteScroll: true,
                      autoPlay: true,
                      autoPlayInterval: const Duration(seconds: 4),
                      autoPlayAnimationDuration:
                      const Duration(milliseconds: 800),
                      onPageChanged: (imgIndex, reason) {
                        setState(() {
                          _currentIndex = imgIndex;
                        });
                      },
                    ),
                  ),
                ),
                // Show overlay text only from 2nd slide and if not dismissed
                if (_currentIndex >= 1 && _showOverlayText)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.black87.withOpacity(0.7),
                        borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(20)),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Expanded(
                            child: Text(
                              "We’ll try to provide the model you chose, but the car may vary in make, model, or color within the same category",
                              style:
                              TextStyle(color: Colors.white, fontSize: 11),
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _showOverlayText = false; // dismiss text
                              });
                            },
                            child: Icon(Icons.close,
                                color: Colors.white.withOpacity(0.75), size: 24),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class CarRentalCard extends StatefulWidget {
  final String vehicleId;
  final bool isHomePage;
  const CarRentalCard({super.key, required this.vehicleId, required this.isHomePage});

  @override
  State<CarRentalCard> createState() => _CarRentalCardState();
}

class _CarRentalCardState extends State<CarRentalCard> {
  final FetchSdBookingDetailsController fetchSdBookingDetailsController = Get.put(FetchSdBookingDetailsController());

  @override
  void initState() {
    super.initState();
    fetchSdBookingDetailsController.fetchBookingDetails(widget.vehicleId, widget.isHomePage);
  }

  String formatToDayMonth(String inputDate) {
    try {
      DateTime date = DateFormat("dd/MM/yyyy").parse(inputDate);
      return DateFormat("dd MMM").format(date);
    } catch (e) {
      return inputDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.directions_car, size: 20, color: Color(0xFF000000),),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Obx(() => Text(
                      fetchSdBookingDetailsController.getAllBookingData.value?.result?.vehicleId?.modelName ?? '',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    )),
                  ],
                ),
              )
            ],
          ),
          const Divider(),
          Obx(() {
            return Row(
              children: [
                Icon(Icons.calendar_today_outlined, size: 18),
                SizedBox(width: 8),
                if(fetchSdBookingDetailsController.getAllBookingData.value?.result?.tarrifSelected == 'Daily')  Expanded(
                  child: Text(
                    '${formatToDayMonth(fetchSdBookingDetailsController.getAllBookingData.value?.result?.tarrifs?[0].pickup?.date ?? '')} ${fetchSdBookingDetailsController.getAllBookingData.value?.result?.tarrifs?[0].pickup?.time} - ${formatToDayMonth(fetchSdBookingDetailsController.getAllBookingData.value?.result?.tarrifs?[0].drop?.date ?? '')} ${fetchSdBookingDetailsController.getAllBookingData.value?.result?.tarrifs?[0].drop?.time}',
                    style: TextStyle(fontSize: 15),
                  ),
                ),
                if(fetchSdBookingDetailsController.getAllBookingData.value?.result?.tarrifSelected == 'Weekly')  Expanded(
                  child: Text(
                    '${formatToDayMonth(fetchSdBookingDetailsController.getAllBookingData.value?.result?.tarrifs?[1].pickup?.date ?? '')} ${fetchSdBookingDetailsController.getAllBookingData.value?.result?.tarrifs?[1].pickup?.time} - ${formatToDayMonth(fetchSdBookingDetailsController.getAllBookingData.value?.result?.tarrifs?[1].drop?.date ?? '')} ${fetchSdBookingDetailsController.getAllBookingData.value?.result?.tarrifs?[1].drop?.time}',
                    style: TextStyle(fontSize: 15),
                  ),
                ),
                if(fetchSdBookingDetailsController.getAllBookingData.value?.result?.tarrifSelected == 'Monthly')  Expanded(
                  child: Text(
                    '${formatToDayMonth(fetchSdBookingDetailsController.getAllBookingData.value?.result?.tarrifs?[2].pickup?.date ?? '')} ${fetchSdBookingDetailsController.getAllBookingData.value?.result?.tarrifs?[2].pickup?.time} - ${formatToDayMonth(fetchSdBookingDetailsController.getAllBookingData.value?.result?.tarrifs?[2].drop?.date ?? '')} ${fetchSdBookingDetailsController.getAllBookingData.value?.result?.tarrifs?[2].drop?.time}',
                    style: TextStyle(fontSize: 15),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class TravelerDetailsForm extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final bool ? fromPaymentFailurePage;

  const TravelerDetailsForm(
      {super.key, required this.formKey, this.fromPaymentFailurePage}); // ✅ Accept form key from parent
  @override
  _TravelerDetailsFormState createState() => _TravelerDetailsFormState();
}

class _TravelerDetailsFormState extends State<TravelerDetailsForm> {
  String selectedTitle = 'Mr.';
  final List<String> titles = ['Mr.', 'Ms.', 'Mrs.'];
  final ProfileController profileController = Get.put(ProfileController());
  final SdCreateStripePaymentController sdCreateStripePaymentController =
  Get.put(SdCreateStripePaymentController());
  PhoneNumber number = PhoneNumber(isoCode: 'IN');
  String? _country;
  String? token;
  String? firstName;
  String? email;
  String? contact;
  String? contactCode;

  // final TextEditingController firstNameController = TextEditingController();
  // final TextEditingController emailController = TextEditingController();
  // final TextEditingController contactController = TextEditingController();

  bool isGstSelected = false;
  String? tripCode;

  @override
  void initState() {
    super.initState();
    loadInitialData();
    getCurrentTripCode();
  }

  void getCurrentTripCode() async {
    tripCode = await StorageServices.instance.read('currentTripCode');
    setState(() {});
    print('yash trip code : $tripCode');
  }

  Future<void> loadInitialData() async {
    _country = await StorageServices.instance.read('country');
    token = await StorageServices.instance.read('token');

    await profileController.fetchData();
    print('📦 3rd page country: $_country');


    if(widget.fromPaymentFailurePage==true){
      firstName = await StorageServices.instance.read('firstName') ?? '';
      contact = await StorageServices.instance.read('contact') ?? '';
      email = await StorageServices.instance.read('emailId') ?? '';
    }
    else if(widget.fromPaymentFailurePage == null && await StorageServices.instance.read('token')==null){
      firstName = await StorageServices.instance.read('firstName') ?? '';
      contact = await StorageServices.instance.read('contact') ?? '';
      email = await StorageServices.instance.read('emailId') ?? '';
    }
    else{
      firstName =
          profileController.profileResponse.value?.result?.firstName ?? '';
      contact =
          profileController.profileResponse.value?.result?.contact.toString() ??
              '';
      contactCode =
          profileController.profileResponse.value?.result?.contactCode ?? '';
      email = profileController.profileResponse.value?.result?.emailID ?? '';

    }




    //fromPaymentFailurePagefromPaymentFailurePage logic yahi se karna hai.
    //
    sdCreateStripePaymentController.firstNameController.text = firstName ?? '';
    sdCreateStripePaymentController.emailController.text = email ?? '';
    sdCreateStripePaymentController.contactController.text = contact ?? '';

    print('First Name: $firstName');
    print('Contact: $contact');
    print('Contact Code: $contactCode');
    print('Email: $email');

    WidgetsBinding.instance.addPostFrameCallback((_) {

      final selfDriveBookingController = Get.find<FetchSdBookingDetailsController>();
      Future.delayed(Duration(milliseconds: 100), () {
        // small delay to let TextEditingControllers update in the tree
        selfDriveBookingController.validateForm();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      // ✅ Wrap form
      key: widget.formKey,
      autovalidateMode: AutovalidateMode.disabled, // ✅ show on change

      child: Card(
        color: Colors.white,
        margin: EdgeInsets.only(bottom: 20),
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
              /// Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Travelers Details",
                      style:
                      TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                ],
              ),
              SizedBox(height: 8),

              /// Title Chips
              Row(
                children: titles.map((title) {
                  final isSelected = selectedTitle == title;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(title),
                      selected: isSelected,
                      selectedColor: AppColors.mainButtonBg,
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(
                        fontSize: 10,
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                        side: BorderSide(color: AppColors.mainButtonBg),
                      ),
                      showCheckmark: false,
                      onSelected: (_) => setState(() => selectedTitle = title),
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: 8),

              /// Fields
              _buildTextField(
                label: 'Full Name',
                hint: "Enter full name",
                controller: sdCreateStripePaymentController.firstNameController,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return "Full name is required";
                  }
                  return null;
                },
              ),

              _buildTextField(
                label: 'Email',
                hint: "Enter email id",
                controller: sdCreateStripePaymentController.emailController,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return "Email is required";
                  }
                  final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                  return !regex.hasMatch(v.trim())
                      ? "Enter a valid email"
                      : null;
                },
              ),

              /// Phone
              Text(
                'Mobile no',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black38,
                ),
              ),
              const SizedBox(height: 4),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Small label above the field

                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.grey.shade300, width: 1),
                    ),
                    padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                    child: Row(
                      children: [
                        const SizedBox(
                            width: 6), // spacing between icon and field

                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: InternationalPhoneNumberInput(
                              selectorConfig: const SelectorConfig(
                                selectorType:
                                PhoneInputSelectorType.BOTTOM_SHEET,
                                useBottomSheetSafeArea: true,
                                showFlags: true,
                              ),
                              selectorTextStyle: const TextStyle(
                                // ✅ smaller selector text
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                              initialValue: number,
                              textFieldController: sdCreateStripePaymentController.contactController,
                              textStyle: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                              onFieldSubmitted: (value) {
                                cabBookingController.validateForm();
                                WidgetsBinding.instance
                                    .addPostFrameCallback((_) {
                                  Form.of(context).validate();
                                });
                              },
                              keyboardType:
                              const TextInputType.numberWithOptions(
                                  signed: true),
                              maxLength: 10,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return "Mobile number is required";
                                }
                                if (value.length != 10 ||
                                    !RegExp(r'^[0-9]+$').hasMatch(value)) {
                                  return "Enter valid 10-digit mobile number";
                                }
                                // trigger validation manually

                                return null;
                              },
                              inputDecoration: const InputDecoration(
                                hintText: "ENTER MOBILE NUMBER",
                                hintStyle: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black54,
                                ),
                                counterText: "",
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding:
                                EdgeInsets.symmetric(vertical: 10),
                              ),
                              formatInput: false,
                              onInputChanged: (PhoneNumber value) async {
                                cabBookingController.validateForm();
                                contact = (value.phoneNumber
                                    ?.replaceAll(' ', '')
                                    .replaceFirst(
                                    value.dialCode ?? '', '')) ??
                                    '';
                                sdCreateStripePaymentController.contactCode = value.dialCode?.replaceAll('+', '');
                                contactCode =
                                    value.dialCode?.replaceAll('+', '');

                                await StorageServices.instance
                                    .save('contactCode', contactCode ?? '');
                                await StorageServices.instance
                                    .save('contact', contact ?? '');
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              /// Submit Button
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      {required String label,
        required String hint,
        required TextEditingController controller,
        String? Function(String?)? validator,
        String? tag,
        bool? isReadOnly}) {
    final CabBookingController cabBookingController =
    Get.put(CabBookingController());
    final SdCreateStripePaymentController sdCreateStripePaymentController =
    Get.put(SdCreateStripePaymentController());
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Permanent label
          Text(
            label,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black38),
          ),
          const SizedBox(height: 4), // Small space between label and field
          TextFormField(
            controller: controller,
            readOnly: isReadOnly ?? false,
            style: const TextStyle(
              fontSize: 12, // smaller font
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
            decoration: InputDecoration(
              hintText: hint.toUpperCase(),
              hintStyle: const TextStyle(
                fontSize: 11.5, // smaller placeholder font
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
              filled: true,
              fillColor: Colors.grey.shade100,
              isDense: true, // makes height smaller
              contentPadding: const EdgeInsets.symmetric(
                vertical: 8, // reduced vertical padding
                horizontal: 10, // reduced horizontal padding
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius:
                BorderRadius.circular(6), // slightly smaller radius
                borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Colors.black54, width: 1.2),
              ),
            ),
            validator: validator,
            onChanged: (value) async {
              // 🔄 Your existing logic
              if (controller == sdCreateStripePaymentController.firstNameController) {
                firstName = value;
                await StorageServices.instance.save('firstName', value);
                print("📝 First Name updated: $value");
              } else if (controller == sdCreateStripePaymentController.emailController) {
                email = value;
                await StorageServices.instance.save('emailId', value);
                print("📧 Email updated: $value");
              }
              cabBookingController.validateForm();
              setState(() {});
            },
          ),
        ],
      ),
    );
  }
}



class UploadDocumentsScreen extends StatefulWidget {
  @override
  _UploadDocumentsScreenState createState() => _UploadDocumentsScreenState();
}

class _UploadDocumentsScreenState extends State<UploadDocumentsScreen> {
  final FileUploadValidController fileUploadValidController = Get.put(FileUploadValidController());
  int _selectedTab = 0;
  String? _eidFrontPath;
  String? _eidBackPath;
  String? _dlFrontPath;
  String? _dlBackPath;
  String? _passportPath;
  String? _touristPassportPath;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(String field) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        if (_selectedTab == 0) {
          switch (field) {
            case 'eidFront':
              _eidFrontPath = image.path;
              break;
            case 'eidBack':
              _eidBackPath = image.path;
              break;
            case 'dlFront':
              _dlFrontPath = image.path;
              break;
            case 'dlBack':
              _dlBackPath = image.path;
              break;
            case 'passport':
              _passportPath = image.path;
              break;
          }
        } else {
          _touristPassportPath = image.path;
        }
      });
      await fileUploadValidController.handleFileChange(field, image: image);
    }
  }

  Future<void> _removeImage(String field) async {
    setState(() {
      if (_selectedTab == 0) {
        switch (field) {
          case 'eidFront':
            _eidFrontPath = null;
            break;
          case 'eidBack':
            _eidBackPath = null;
            break;
          case 'dlFront':
            _dlFrontPath = null;
            break;
          case 'dlBack':
            _dlBackPath = null;
            break;
          case 'passport':
            _passportPath = null;
            break;
        }
      } else {
        _touristPassportPath = null;
      }
      fileUploadValidController.clearField(field);
    });
  }

  Widget _buildUploadField(String label, String? localPath, String field, IconData icon) {
    return Obx(() {
      final preview = fileUploadValidController.previews[field];
      final uploading = fileUploadValidController.uploadingField.value == field;
      final error = fileUploadValidController.errors[field] ?? "";

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 4.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: error.isNotEmpty ? Colors.red : Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Label
                Row(
                  children: [
                    Icon(icon, color: Colors.blue.shade700, size: 24),
                    SizedBox(width: 8),
                    Text(
                      '$label *',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),

                // Upload / Preview
                (preview == null || preview.isEmpty) && localPath == null
                    ? GestureDetector(
                  onTap: uploading ? null : () => _pickImage(field),
                  child: Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color:  Colors.blue.shade200,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.cloud_upload, size: 40, color: Colors.blue.shade400),
                        SizedBox(height: 8),
                        Text(
                          uploading ? "Uploading..." : "Tap to upload $label",
                          style: TextStyle(color: Colors.blue.shade600, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                )
                    : Column(
                  children: [
                    // Preview
                    GestureDetector(
                      onTap: () {
                        // TODO: full-screen preview
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: preview != null && preview.isNotEmpty
                            ? Image.network(preview,
                            height: 160, width: double.infinity, fit: BoxFit.contain)
                            : Image.file(File(localPath!),
                            height: 160, width: double.infinity, fit: BoxFit.contain),
                      ),
                    ),
                    SizedBox(height: 12),

                    // Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton.icon(
                          onPressed: uploading ? null : () => _pickImage(field),
                          icon: Icon(Icons.upload_file, size: 18, color: Colors.white),
                          label: Text('Change'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade600,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                        ),
                        TextButton(
                          onPressed: () => _removeImage(field),
                          child: Text('Remove', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  ],
                ),

                // Error
                if (error.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red, size: 16),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            error,
                            style: TextStyle(color: Colors.red, fontSize: 12),
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
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Document Type',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87),
          ),
          SizedBox(height: 8),
          Text(
            'Please select whether you are an Emirates Resident or a Tourist to upload the required documents.',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.5),
          ),
          SizedBox(height: 16),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment<int>(
                value: 0,
                label: Text('Emirates Resident', style: TextStyle(fontSize: 13)),
              ),
              ButtonSegment<int>(
                value: 1,
                label: Text('Tourist', style: TextStyle(fontSize: 13)),
              ),
            ],
            selected: {_selectedTab},
            onSelectionChanged: (Set<int> newSelection) {
              setState(() {
                _selectedTab = newSelection.first;
              });
            },
            showSelectedIcon: false,
          ),
          SizedBox(height: 16),
          if (_selectedTab == 0) ..._buildResidentSections() else ..._buildTouristSection(),
          SizedBox(height: 24),
        ],
      ),
    );
  }

  List<Widget> _buildResidentSections() {
    return [
      _sectionCard('Emirates ID', [
        _buildUploadField('Emirates ID Front', _eidFrontPath, 'eidFront', Icons.badge),
        _buildUploadField('Emirates ID Back', _eidBackPath, 'eidBack', Icons.badge),
      ]),
      SizedBox(height: 24),
      _sectionCard('Driving License', [
        _buildUploadField('Driving License Front', _dlFrontPath, 'dlFront', Icons.drive_eta),
        _buildUploadField('Driving License Back', _dlBackPath, 'dlBack', Icons.drive_eta),
      ]),
      SizedBox(height: 24),
      _sectionCard('Passport', [
        _buildUploadField('Passport', _passportPath, 'passport', Icons.book),
      ]),
    ];
  }

  List<Widget> _buildTouristSection() {
    return [
      _sectionCard('Passport', [
        _buildUploadField('Passport', _touristPassportPath, 'passport', Icons.book),
      ]),
    ];
  }

  Widget _sectionCard(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
        SizedBox(height: 12),
        Card(
          elevation: 0.3,
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(children: children),
          ),
        ),
      ],
    );
  }
}





