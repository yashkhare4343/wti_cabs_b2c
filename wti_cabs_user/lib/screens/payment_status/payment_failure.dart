import 'package:flutter/material.dart';
import 'dart:async';

import 'package:wti_cabs_user/common_widget/buttons/main_button.dart';

class PaymentFailurePage extends StatefulWidget {


  @override
  State<PaymentFailurePage> createState() => _PaymentFailurePageState();
}

class _PaymentFailurePageState extends State<PaymentFailurePage> {
  @override
  void initState() {
    super.initState();
  }

  void _navigateBack() {
      Navigator.pop(context); // Default back navigation
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red[50],
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cancel, color: Colors.red, size: 100),
              const SizedBox(height: 20),
              const Text(
                "Booking Creation Failed",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text("Please try again."),
              const SizedBox(height: 30),
              SizedBox(
                width: 220,
                height: 60,
                child: MainButton(text: 'Continue', onPressed: _navigateBack)
              ),
            ],
          ),
        ),
      ),
    );
  }
}
