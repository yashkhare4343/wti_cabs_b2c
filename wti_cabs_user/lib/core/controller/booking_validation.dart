import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BookingValidation extends GetxController {
  final RxString pickup = ''.obs;
  final RxString drop = ''.obs;

  bool get hasSourceError => pickup.value.trim().isEmpty;
  bool get hasDestinationError => drop.value.trim().isEmpty;
  bool get samePlace => pickup.value.trim() == drop.value.trim() && pickup.value.isNotEmpty;
  bool get isPlaceMissing => pickup.value.trim().isEmpty || drop.value.trim().isEmpty;
  bool get canProceed => !hasSourceError && !hasDestinationError && !samePlace;
}

class BookingScreen extends StatefulWidget {
  const BookingScreen({Key? key}) : super(key: key);

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final BookingValidation controller = Get.put(BookingValidation());

  final TextEditingController pickupController = TextEditingController();
  final TextEditingController dropController = TextEditingController();

  void showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Book a Ride")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Obx(() {
          final samePlace = controller.samePlace;
          final hasSourceError = controller.hasSourceError;
          final hasDestinationError = controller.hasDestinationError;
          final isPlaceMissing = controller.isPlaceMissing;
          final canProceed = controller.canProceed;

          return Column(
            children: [
              TextField(
                controller: pickupController,
                decoration: const InputDecoration(labelText: 'Pickup Location'),
                onChanged: (val) => controller.pickup.value = val,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: dropController,
                decoration: const InputDecoration(labelText: 'Drop Location'),
                onChanged: (val) => controller.drop.value = val,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: canProceed ? Colors.blue : Colors.grey,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                ),
                onPressed: () {
                  if (!canProceed) {
                    if (samePlace) {
                      showErrorSnackbar("Pickup and drop cannot be the same location.");
                    } else if (hasSourceError) {
                      showErrorSnackbar("Invalid pickup location.");
                    } else if (hasDestinationError) {
                      showErrorSnackbar("Invalid drop location.");
                    } else if (isPlaceMissing) {
                      showErrorSnackbar("Please select both pickup and drop locations.");
                    } else {
                      showErrorSnackbar("Selected drop location is not available.");
                    }
                  } else {
                    // ✅ Proceed with valid data
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Searching available rides..."),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    // TODO: Trigger search logic or navigation
                  }
                },
                child: Text(
                  "Search Now",
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
