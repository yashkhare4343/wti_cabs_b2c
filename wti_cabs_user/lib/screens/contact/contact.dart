import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:flutter/material.dart';

class Contact extends StatelessWidget {
  // Static values as per your image
  final DateTime dateTime = DateTime(2025, 8, 8, 10, 0);

  Contact({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Custom formatted values for the card display
    final String day = '08';
    final String month = 'Aug';
    final String year = '2025';
    final String time = '10:00 AM';

    return Column(
      children: [
        SizedBox(
          height: 90,
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Icon(
                  Icons.calendar_today_outlined,
                  color: Colors.grey.shade700,
                  size: 27,
                ),
              ),
              const SizedBox(width: 14),
              // Text block
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TRIP START',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                      fontSize: 13,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      // "Fri 08 Aug"

                      Text(
                        day,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        ' $month ',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        year,
                        style: const TextStyle(
                          fontWeight: FontWeight.normal,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    time,
                    style: TextStyle(
                      color: Colors.grey.shade800,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Usage:
// Place Contact() anywhere in your UI

// Usage Example:
// Contact(dateTime: DateTime(2025, 8, 8, 10, 0)),
