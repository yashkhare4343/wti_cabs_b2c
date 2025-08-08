import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:wti_cabs_user/common_widget/buttons/main_button.dart';
import 'package:wti_cabs_user/common_widget/loader/custom_loader.dart';
import 'package:wti_cabs_user/core/controller/profile_controller/update_profile_controller.dart';
import 'package:wti_cabs_user/utility/constants/colors/app_colors.dart';

import '../../common_widget/loader/popup_loader.dart';
import '../../core/controller/profile_controller/profile_controller.dart';
import '../../core/services/storage_services.dart';

class Profile extends StatefulWidget {
   Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();

  bool isActive = false;

}

void _showLoader(String message, BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false, // Prevent closing by tapping outside
    builder: (_) {
      return Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SpinKitFadingCircle(
                  color: Colors.deepPurple,
                  size: 48.0,
                ),
                SizedBox(height: 16),
                Text(message,
                    style: TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ),
      );
    },
  );

  // Fake delay to simulate loading
  Future.delayed(const Duration(seconds: 3), () {
    Navigator.pop(context); // Close loader
  });

}
void _successLoader(String message, BuildContext outerContext) {
  showDialog(
    context: outerContext,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      // Start delayed closure using outerContext
      Future.delayed(const Duration(seconds: 1), () {
        if (Navigator.of(dialogContext).canPop()) {
          Navigator.of(dialogContext).pop(); // Close dialog
        }

        if (Navigator.of(outerContext).canPop()) {
          Navigator.of(outerContext).pop(); // Navigate back
        }
      });

      return Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 48),
                SizedBox(height: 16),
                Text(message, style: TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ),
      );
    },
  );
}

bool isEdit = true;
String ? selectedGender;

class _ProfileState extends State<Profile> {
  final ProfileController profileController = Get.put(ProfileController());
  final UpdateProfileController updateProfileController = Get.put(UpdateProfileController());
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneNoController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController countryController = TextEditingController();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    profileController.fetchData();
  }

  @override
  Widget build(BuildContext context) {
    firstNameController.text = profileController.profileResponse.value?.result?.firstName??'';
    emailController.text = profileController.profileResponse.value?.result?.emailID??'';
    countryController.text = profileController.profileResponse.value?.result?.countryName??'';
    phoneNoController.text = profileController.profileResponse.value?.result?.contact.toString()??'';
    return Scaffold(
      backgroundColor: AppColors.scaffoldBgPrimary2,
      appBar: AppBar(
        backgroundColor: AppColors.scaffoldBgPrimary2,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Color(0xFF192653),
            size: 20,
          ),
          onPressed: () {
            GoRouter.of(context).pop();
            setState(() {
              isEdit = false;
            });
          },
        ),
        centerTitle: true,
        title: const Text(
          "Profile",
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child:Obx((){
          if(profileController.isLoading==true){
            return PopupLoader(message: 'Loading...');
          }
         return Stack(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 28),
                  padding: const EdgeInsets.only(top: 20, bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      SizedBox(height: 32,),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding:  EdgeInsets.only(left: 16.0, bottom: isEdit != true ? 12 : 2),
                          child: Text(
                            "General Details",
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.black
                            ),
                          ),
                        ),
                      ),
                      Container(padding: EdgeInsets.only(left: 16, right: 16,),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text('Fields marked with * are mandatory', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: Color(0xFF6D6D6D)),),
                          ],
                        ),
                      ),
                      SizedBox(height: 16,),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            EditableTextField(label: "Full name *", value: profileController.profileResponse.value?.result?.firstName??'', controller: firstNameController,),
                            const SizedBox(height: 12),
                            EditableTextField(label: "Email ID *", value: profileController.profileResponse.value?.result?.emailID??'', controller: emailController,) ,
                            const SizedBox(height: 12) ,
                            EditableTextField(label: "Mobile No *", value: "${profileController.profileResponse.value?.result?.contactCode} ${profileController.profileResponse.value?.result?.contact}", controller: phoneNoController,),
                            const SizedBox(height: 12) ,
                            Row(
                              children: [
                                Expanded(
                                  child:
                                  EditableTextField(label: "City", value: "", controller: cityController,),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child:
                                  EditableTextField(label: "State", value: "",),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            EditableTextField(label: "Nationality", value: profileController.profileResponse.value?.result?.countryName??'',controller: countryController, readOnly: isEdit == false ? true : false,),
                            SizedBox(height: 20,),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  elevation: 0,
                                  backgroundColor: const Color(0xFF000088),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 13),
                                ),
                                onPressed: () async{
                                  // Close loader
                                  _showLoader('Loading..', context);
                                  final Map<String, dynamic> requestData = {
                                    "firstName":
                                    firstNameController.text.trim(),
                                    "contact":
                                    phoneNoController.text.trim()??'0000000000',
                                    "contactCode": "91",
                                    "countryName": "India",
                                    "gender": selectedGender,
                                    "emailID": emailController.text.trim()
                                  };
                                  await updateProfileController.updateProfile(requestData: requestData, context: context).then((value){
                                    _successLoader('Profile Updated Successfully', context);
                                  });

                                  // / GoRouter.of(context).pop();
                                },
                                child: const Text(
                                  "Save Details",
                                  style: TextStyle(
                                      color: Color(0xFFFFFFFF),
                                      fontWeight: FontWeight.w400,
                                      fontSize: 16
                                  ),
                                ),
                              ) ,
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      children: [
                        Container(
                          padding: EdgeInsets.only(bottom: 16),
                          child: CircleAvatar(
                              radius: 40,
                              child: Image.asset('assets/images/profile_pic.png', width: 80, height: 80,)
                          ),
                        ),
                        isEdit == true ?  Positioned(
                          bottom: 5,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 28,
                            width: 28,
                            padding: EdgeInsets.all(4.0),
                            decoration: BoxDecoration(
                              color: Color(0xFF002CC0),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey.shade300, width: 2),
                            ),
                            child: Icon(Icons.camera_alt, color: Colors.white, size: 16,),
                          ),
                        ) : SizedBox(),


                      ],
                    ),
                  ],
                ),
              ),

            ],
          );
        })

        ,
      ),
    );
  }
}


class CustomDropdownField extends StatefulWidget {
  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  const CustomDropdownField({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  State<CustomDropdownField> createState() => _CustomDropdownFieldState();
}

class _CustomDropdownFieldState extends State<CustomDropdownField> {
  late String selectedValue;
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
    _focusNode = FocusNode();
    _focusNode.addListener(() => setState(() {}));
    selectedValue = widget.value;

  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _showBottomSheet() {
    showModalBottomSheet(
      backgroundColor: Colors.white,
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  "Select ${widget.label}",
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: widget.options.length,
                    separatorBuilder: (_, __) =>
                        Divider(color: Colors.grey.shade200, height: 1),
                    itemBuilder: (context, index) {
                      final option = widget.options[index];
                      return ListTile(
                        title: Text(option),
                        onTap: () {
                          setState(() => selectedValue = option);
                          widget.onChanged(option);
                          _controller.text = selectedValue;
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    final bool isFocused = _focusNode.hasFocus;

    return GestureDetector(
      onTap: _showBottomSheet,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        decoration: BoxDecoration(
          border: Border.all(
            color: isFocused ? Colors.blue : const Color(0xFFE2E2E2),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(8),
          color: const Color(0xFFF7F7F7),
        ),
        child: TextFormField(
          controller: _controller,
          focusNode: _focusNode,
          readOnly: true,
          onTap: (){
            _showBottomSheet();
          },
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
          decoration: InputDecoration(
            suffixIcon: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Icon(Icons.arrow_drop_down_outlined, size: 24,),
            ),
            label: ((isFocused)) ? Transform.translate(
                offset: Offset(0, 4.0),
                child: Text(widget.label)) : Container(
                padding: EdgeInsets.symmetric(vertical: (_controller.text.isNotEmpty)? 8 : 0),
                margin: EdgeInsets.only(bottom: (_controller.text.isNotEmpty)? 8 : 0),
                child: Text(widget.label)),
            labelStyle: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isFocused ? Colors.blue : const Color(0xFF7D7D7D),
            ),
            floatingLabelBehavior: FloatingLabelBehavior.auto,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),

          ),
        ),
      ),
    );
  }
}



class EditableTextField extends StatefulWidget {
  final String label;
  final String value;
  final bool? readOnly;
  final VoidCallback? onTap;
  final TextEditingController? controller;

  const EditableTextField({
    super.key,
    required this.label,
    required this.value,
    this.readOnly,
    this.onTap,
    this.controller,
  });

  @override
  State<EditableTextField> createState() => _EditableTextFieldState();
}

class _EditableTextFieldState extends State<EditableTextField> {
  late FocusNode _focusNode;
  late TextEditingController _controller;
  bool _isExternalController = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()..addListener(() => setState(() {}));

    _isExternalController = widget.controller != null;
    _controller = widget.controller ?? TextEditingController(text: widget.value);
  }

  @override
  void dispose() {
    _focusNode.dispose();
    if (!_isExternalController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isFocused = _focusNode.hasFocus;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      decoration: BoxDecoration(
        border: Border.all(
          color: isFocused ? Colors.blue : const Color(0xFFE2E2E2),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(8),
        color: const Color(0xFFF7F7F7),
      ),
      child: TextFormField(
        controller: _controller,
        focusNode: _focusNode,
        readOnly: widget.readOnly?? false,
        onTap: widget.onTap,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.black,
        ),
        decoration: InputDecoration(
          label: isFocused
              ? Transform.translate(
            offset: const Offset(0, 8.0),
            child: Text(widget.label),
          )
              : Padding(
            padding: EdgeInsets.only(top: _controller.text.isNotEmpty ? 8 : 0),
            child: Text(widget.label),
          ),
          labelStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: isFocused ? Colors.blue : const Color(0xFF7D7D7D),
          ),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
        ),
      ),
    );
  }
}

Widget buildShimmer() {
  return Padding(
    padding: const EdgeInsets.only(bottom: 16.0),
    child: Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        child: Padding(
          padding:
          const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                width: 96,
                height: 66,
                color: Colors.white,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 16,
                      width: double.infinity,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 14,
                      width: 80,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(height: 12, width: 40, color: Colors.white),
                        const SizedBox(width: 8),
                        Container(height: 12, width: 40, color: Colors.white),
                        const SizedBox(width: 8),
                        Container(height: 12, width: 60, color: Colors.white),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(width: 16, height: 16, color: Colors.white),
            ],
          ),
        ),
      ),
    ),
  );
}
