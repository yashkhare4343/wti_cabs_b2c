import 'package:flutter/material.dart';

/// Modern pulse/skeleton loader for corporate screens
/// Uses pulse animation instead of shimmer effect
class CorporateShimmer extends StatefulWidget {
  final bool showAppBar;
  final Widget? customAppBar;
  final bool isDetailsPage;

  const CorporateShimmer({
    super.key,
    this.showAppBar = true,
    this.customAppBar,
    this.isDetailsPage = false,
  });

  @override
  State<CorporateShimmer> createState() => _CorporateShimmerState();
}

class _CorporateShimmerState extends State<CorporateShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
    
    _animation = Tween<double>(begin: 0.5, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.customAppBar != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        appBar: widget.customAppBar as PreferredSizeWidget?,
        body: SafeArea(
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return widget.isDetailsPage 
                  ? _buildDetailsLoader(context, _animation.value) 
                  : _buildHomeLoader(context, _animation.value);
            },
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return widget.isDetailsPage 
                ? _buildDetailsLoader(context, _animation.value) 
                : _buildHomeLoader(context, _animation.value);
          },
        ),
      ),
    );
  }

  Widget _buildHomeLoader(BuildContext context, double opacity) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Banner Section
          Container(
            height: 300,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo and Home button row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildPulseContainer(
                        height: 50,
                        width: 190,
                        borderRadius: 12,
                        opacity: opacity,
                      ),
                      _buildPulseContainer(
                        height: 40,
                        width: 90,
                        borderRadius: 22,
                        opacity: opacity,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Search bar
                  _buildPulseContainer(
                    height: 56,
                    width: double.infinity,
                    borderRadius: 30,
                    opacity: opacity,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          // Branch selector tile
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Container(
              height: 72,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                child: Row(
                  children: [
                    _buildPulseContainer(
                      width: 36,
                      height: 36,
                      borderRadius: 18,
                      opacity: opacity,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildPulseContainer(
                            height: 16,
                            width: 140,
                            borderRadius: 8,
                            opacity: opacity,
                          ),
                          const SizedBox(height: 10),
                          _buildPulseContainer(
                            height: 14,
                            width: 170,
                            borderRadius: 8,
                            opacity: opacity,
                          ),
                        ],
                      ),
                    ),
                    _buildPulseContainer(
                      width: 20,
                      height: 20,
                      borderRadius: 6,
                      opacity: opacity,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          // Services section header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildPulseContainer(
              height: 22,
              width: 120,
              borderRadius: 8,
              opacity: opacity,
            ),
          ),
          const SizedBox(height: 20),
          // Services grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _buildServiceCard(opacity)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildServiceCard(opacity)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildServiceCard(opacity)),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(child: _buildServiceCard(opacity)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildServiceCard(opacity)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildServiceCard(opacity)),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(child: _buildServiceCard(opacity)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildServiceCard(opacity)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildDetailsLoader(BuildContext context, double opacity) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main Booking Card
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPulseContainer(
                        width: 70,
                        height: 54,
                        borderRadius: 12,
                        opacity: opacity,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildPulseContainer(
                              height: 20,
                              width: 160,
                              borderRadius: 8,
                              opacity: opacity,
                            ),
                            const SizedBox(height: 12),
                            _buildPulseContainer(
                              height: 16,
                              width: 120,
                              borderRadius: 8,
                              opacity: opacity,
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildPulseContainer(
                            width: 20,
                            height: 20,
                            borderRadius: 10,
                            opacity: opacity,
                          ),
                          const SizedBox(width: 8),
                          _buildPulseContainer(
                            height: 16,
                            width: 80,
                            borderRadius: 8,
                            opacity: opacity,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  // Divider
                  Container(
                    height: 1,
                    width: double.infinity,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 24),
                  // Route visualization
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          _buildPulseContainer(
                            width: 16,
                            height: 16,
                            borderRadius: 8,
                            opacity: opacity,
                          ),
                          Container(
                            width: 3,
                            height: 50,
                            color: Colors.grey[300],
                            margin: const EdgeInsets.symmetric(vertical: 6),
                          ),
                          _buildPulseContainer(
                            width: 16,
                            height: 16,
                            borderRadius: 8,
                            opacity: opacity,
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildPulseContainer(
                              height: 18,
                              width: double.infinity,
                              borderRadius: 8,
                              opacity: opacity,
                            ),
                            const SizedBox(height: 8),
                            _buildPulseContainer(
                              height: 16,
                              width: 240,
                              borderRadius: 8,
                              opacity: opacity,
                            ),
                            const SizedBox(height: 24),
                            _buildPulseContainer(
                              height: 18,
                              width: double.infinity,
                              borderRadius: 8,
                              opacity: opacity,
                            ),
                            const SizedBox(height: 8),
                            _buildPulseContainer(
                              height: 16,
                              width: 220,
                              borderRadius: 8,
                              opacity: opacity,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  // Divider
                  Container(
                    height: 1,
                    width: double.infinity,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 24),
                  // Booking ID and date
                  _buildPulseContainer(
                    height: 15,
                    width: 200,
                    borderRadius: 8,
                    opacity: opacity,
                  ),
                  const SizedBox(height: 12),
                  _buildPulseContainer(
                    height: 15,
                    width: 170,
                    borderRadius: 8,
                    opacity: opacity,
                  ),
                  const SizedBox(height: 28),
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: _buildPulseContainer(
                          height: 44,
                          borderRadius: 12,
                          opacity: opacity,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _buildPulseContainer(
                          height: 44,
                          borderRadius: 12,
                          opacity: opacity,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Need Help section
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Row(
                children: [
                  _buildPulseContainer(
                    width: 28,
                    height: 28,
                    borderRadius: 14,
                    opacity: opacity,
                  ),
                  const SizedBox(width: 16),
                  _buildPulseContainer(
                    height: 18,
                    width: 120,
                    borderRadius: 8,
                    opacity: opacity,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildServiceCard(double opacity) {
    return Container(
      height: 130,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildPulseContainer(
              height: 70,
              width: double.infinity,
              borderRadius: 12,
              opacity: opacity,
            ),
            const SizedBox(height: 12),
            _buildPulseContainer(
              height: 14,
              width: 70,
              borderRadius: 8,
              opacity: opacity,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPulseContainer({
    required double height,
    double? width,
    required double borderRadius,
    required double opacity,
  }) {
    // Create a smooth pulse effect by interpolating opacity
    final pulseOpacity = 0.5 + (opacity * 0.4);
    
    return Container(
      height: height,
      width: width ?? double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[300]!.withOpacity(pulseOpacity),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}
