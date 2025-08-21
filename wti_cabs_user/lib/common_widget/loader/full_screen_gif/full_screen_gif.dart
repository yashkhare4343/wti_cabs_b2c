import 'package:flutter/material.dart';
import 'package:wti_cabs_user/common_widget/loader/popup_loader.dart';

class FullScreenGifLoader extends StatefulWidget {
  const FullScreenGifLoader({Key? key}) : super(key: key);

  @override
  State<FullScreenGifLoader> createState() => _FullScreenGifLoaderState();
}

class _FullScreenGifLoaderState extends State<FullScreenGifLoader> {
  // final List<Map<String, dynamic>> usps = [
  //   {"icon": Icons.directions_car_rounded, "text": "Comfortable rides"},
  //   {"icon": Icons.access_time_rounded, "text": "On-time guarantee"},
  //   {"icon": Icons.attach_money_rounded, "text": "Best price assured"},
  // ];
  //
  // int currentIndex = 0;
  //
  // @override
  // void initState() {
  //   super.initState();
  //   _startUspRotation();
  // }
  //
  // void _startUspRotation() {
  //   Future.delayed(const Duration(seconds: 2), () {
  //     if (mounted) {
  //       setState(() {
  //         currentIndex = (currentIndex + 1) % usps.length;
  //       });
  //       _startUspRotation();
  //     }
  //   });
  // }

  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     backgroundColor: const Color(0xFFF7F7F7), // subtle grey bg like MMT
  //     body: Center(
  //       child: PopupLoader(message: 'Search Inventeries'),
  //     ),
  //   );
  // }
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: RideWithUsAvatar(
            imageUrl:
            "https://play-lh.googleusercontent.com/aOe2OpZYo3hFu7EzQzkWDr6GobXQxW53JUrRsiIZx5mlz2VwAUQGLrPR3_BlYQbwzw",
            radius: 30,
          ),
        ),
      ),
    );
  }
}

class RideWithUsAvatar extends StatelessWidget {
  final String imageUrl;
  final double radius;
  const RideWithUsAvatar({
    super.key,
    required this.imageUrl,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        RippleCircleAvatar(imageUrl: imageUrl, radius: radius),
        const SizedBox(height: 30),
        const Text(
          "Ride with us",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}

class RippleCircleAvatar extends StatefulWidget {
  final String imageUrl;
  final double radius;
  const RippleCircleAvatar({
    super.key,
    required this.imageUrl,
    required this.radius,
  });
  @override
  State<RippleCircleAvatar> createState() => _RippleCircleAvatarState();
}

class _RippleCircleAvatarState extends State<RippleCircleAvatar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildRipples() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        return CustomPaint(
          size: Size.square(widget.radius * 2.8),
          painter: RipplePainter(
            animationValue: _controller.value,
            color: Colors.blue,
            circleSize: widget.radius,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final avatar = ClipOval(
      child: Image.network(
        widget.imageUrl,
        width: widget.radius * 2,
        height: widget.radius * 2,
        fit: BoxFit.cover,
      ),
    );
    return SizedBox(
      width: widget.radius * 2.8,
      height: widget.radius * 2.8,
      child: Stack(
        alignment: Alignment.center,
        children: [_buildRipples(), avatar],
      ),
    );
  }
}

class RipplePainter extends CustomPainter {
  final double animationValue;
  final Color color;
  final double circleSize;
  RipplePainter({
    required this.animationValue,
    required this.color,
    required this.circleSize,
  });
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    for (int i = 0; i < 2; i++) {
      final progress = (animationValue + i * 0.5) % 1.0;
      final scale = 1.0 + progress * 1.4;
      final opacity = (1 - progress).clamp(0, 1).toDouble();
      final paint = Paint()
        ..color = color.withOpacity(0.18 * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawCircle(center, circleSize * scale, paint);
    }
  }

  @override
  bool shouldRepaint(covariant RipplePainter oldDelegate) {
    return animationValue != oldDelegate.animationValue;
  }
}
