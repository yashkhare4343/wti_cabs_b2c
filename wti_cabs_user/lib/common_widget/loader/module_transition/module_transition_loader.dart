import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ModuleTransitionLoader extends StatelessWidget {
  const ModuleTransitionLoader({super.key});

  @override
  Widget build(BuildContext context) {
    // A simple container with a grey background to mimic content
    Widget _buildShimmerContainer({
      double height = 20.0,
      double width = double.infinity,
      double radius = 8.0,
    }) {
      return Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
        ),
      );
    }

    // A builder for individual shimmer items to reduce boilerplate
    Widget _buildShimmerItem({required Widget child}) {
      return Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: child,
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Custom App Bar Shimmer ---
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 50, 16, 16),
              child: Row(
                children: [
                  // Menu Icon / Drawer Placeholder
                  _buildShimmerItem(
                    child: _buildShimmerContainer(height: 30, width: 30, radius: 15),
                  ),
                  const Spacer(),
                  // Profile/Name Initial Placeholder
                  _buildShimmerItem(
                    child: _buildShimmerContainer(height: 30, width: 30, radius: 15),
                  ),
                ],
              ),
            ),

            // --- City Selection & Search Field Shimmer ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  // Current City Label
                  _buildShimmerItem(
                    child: _buildShimmerContainer(height: 18, width: 100, radius: 4),
                  ),
                  const SizedBox(height: 4),
                  // City Name Placeholder
                  _buildShimmerItem(
                    child: _buildShimmerContainer(height: 24, width: 150, radius: 4),
                  ),
                  const SizedBox(height: 20),
                  // Search Inventory Text
                  _buildShimmerItem(
                    child: _buildShimmerContainer(height: 20, width: 180, radius: 4),
                  ),
                  const SizedBox(height: 10),
                  // Search Bar Placeholder
                  _buildShimmerItem(
                    child: _buildShimmerContainer(height: 55, radius: 10),
                  ),
                ],
              ),
            ),

            // --- Date and Time Pickers Shimmer ---
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // From Date/Time Picker Placeholder
                  Expanded(
                    child: _buildShimmerItem(
                      child: _buildShimmerContainer(height: 70, radius: 10),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // To Date/Time Picker Placeholder
                  Expanded(
                    child: _buildShimmerItem(
                      child: _buildShimmerContainer(height: 70, radius: 10),
                    ),
                  ),
                ],
              ),
            ),

            // --- Main Button Shimmer ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: _buildShimmerItem(
                child: _buildShimmerContainer(height: 50, radius: 10),
              ),
            ),

            const SizedBox(height: 20),

            // --- Banner Carousel Shimmer ---
            SizedBox(
              height: 180, // Approximate height of a carousel
              child: _buildShimmerItem(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: _buildShimmerContainer(height: 180, radius: 12),
                ),
              ),
            ),

            // --- Section Header Shimmer (e.g., Top Rated Rides) ---
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _buildShimmerItem(
                child: _buildShimmerContainer(height: 22, width: 200, radius: 4),
              ),
            ),

            const SizedBox(height: 15),

            // --- Horizontal List Shimmer (e.g., Top Rated Rides) ---
            SizedBox(
              height: 180, // Approximate height of horizontal car cards
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 3, // Show a few placeholder cards
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: _buildShimmerItem(
                      child: _buildShimmerContainer(height: 180, width: 150, radius: 10),
                    ),
                  );
                },
              ),
            ),

            // --- Another Section Header Shimmer (e.g., Fleet Categories) ---
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _buildShimmerItem(
                child: _buildShimmerContainer(height: 22, width: 220, radius: 4),
              ),
            ),

            const SizedBox(height: 15),

            // --- Grid/Wrap Shimmer (e.g., Fleet Categories) ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: List.generate(4, (index) { // 4 grid items
                  return SizedBox(
                    width: (MediaQuery.of(context).size.width - 44) / 2, // 2 items per row
                    child: _buildShimmerItem(
                      child: _buildShimmerContainer(height: 120, radius: 10),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}