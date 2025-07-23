import 'package:flutter/material.dart';
import 'dart:async';

import 'package:go_router/go_router.dart';
import 'package:wti_cabs_user/common_widget/buttons/main_button.dart';
import 'package:wti_cabs_user/utility/constants/colors/app_colors.dart';

class PaymentSuccessPage extends StatefulWidget {
  final VoidCallback? onContinue;

  const PaymentSuccessPage({super.key, this.onContinue});

  @override
  State<PaymentSuccessPage> createState() => _PaymentSuccessPageState();
}

class _PaymentSuccessPageState extends State<PaymentSuccessPage> {
  @override
  void initState() {
    super.initState();
    // Auto-navigate after 3 seconds
  }

  void _navigateNext() {
    GoRouter.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBgPrimary1,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 100),
              const SizedBox(height: 20),
              const Text(
                "Booking Created Successfully!",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text("Thank you for your payment."),
              const SizedBox(height: 30),
              SizedBox(
                width: 220,
                height: 60,
                child: MainButton(text: 'Continue', onPressed: (){

                }),
              )
            ],
          ),
        ),
      ),
    );
  }
}
