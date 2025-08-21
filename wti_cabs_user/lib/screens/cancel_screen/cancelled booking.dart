import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CancelledBookingScreen extends StatelessWidget {
  final Map<String, dynamic> booking;

  const CancelledBookingScreen({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Booking Cancelled")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.cancel, color: Colors.red, size: 80),
            const SizedBox(height: 16),
            Text("Booking ID: ${booking["id"]}",
                style:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("Reason: ${booking["reason"] ?? "Not provided"}",
                style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                GoRouter.of(context).pop(); // go back to booking list
              },
              child: const Text("Back to Bookings"),
            ),
          ],
        ),
      ),
    );
  }
}
