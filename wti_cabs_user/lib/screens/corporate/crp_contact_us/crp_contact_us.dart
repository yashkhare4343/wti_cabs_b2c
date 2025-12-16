import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wti_cabs_user/core/route_management/app_routes.dart';
import 'package:wti_cabs_user/utility/constants/colors/app_colors.dart';
import '../../../common_widget/loader/shimmer/corporate_shimmer.dart';

class CrpContactUs extends StatefulWidget {
  const CrpContactUs({super.key});

  @override
  State<CrpContactUs> createState() => _CrpContactUsState();
}

class _CrpContactUsState extends State<CrpContactUs> {
  bool _showShimmer = true;

  @override
  void initState() {
    super.initState();
    // Show shimmer for 0.5 seconds
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _showShimmer = false;
        });
      }
    });
  }

  void _launchPhone(String number) async {
    final Uri uri = Uri(scheme: "tel", path: number);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _launchEmail(String email) async {
    final Uri uri = Uri(scheme: "mailto", path: email);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _launchWebsite(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showShimmer) {
      return const CorporateShimmer();
    }

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) {
          context.go(AppRoutes.cprBottomNav);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBgPrimary1,
        appBar: AppBar(
          title: const Text(
            "Contact Us",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
              fontFamily: 'Montserrat',
            ),
          ),
          centerTitle: false,
          elevation: 0.3,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          automaticallyImplyLeading: false,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionCard(
                title: "Address",
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _CircleIcon(
                      icon: Icons.apartment_rounded,
                      color: Colors.black87,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        "3rd Floor, D21, Corporate Park, Sector-21, Dwarka, New Delhi - 110077",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                          height: 1.4,
                          fontFamily: 'Montserrat',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: "Support",
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoRow(
                      icon: Icons.mail_outline_rounded,
                      label: "bookings@wti.co.in",
                      onTap: () => _launchEmail("bookings@wti.co.in"),
                    ),
                    const SizedBox(height: 12),
                    _InfoRow(
                      icon: Icons.call,
                      label: "9250057902",
                      onTap: () => _launchPhone("9250057902"),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: "Social Links",
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoRow(
                      icon: Icons.facebook,
                      label: "Facebook",
                      onTap: () => _launchWebsite("https://www.facebook.com/search/top?q=wti%20cabs"),
                    ),
                    const SizedBox(height: 12),
                    _InfoRow(
                      icon: Icons.linked_camera, // closest to LinkedIn
                      label: "LinkedIn",
                      onTap: () => _launchWebsite("https://www.linkedin.com/search/results/all/?keywords=wticabs&origin=GLOBAL_SEARCH_HEADER&sid=jYo"),
                    ),
                    // const SizedBox(height: 12),
                    // _InfoRow(
                    //   icon: Icons.alternate_email, // closest to Twitter/X
                    //   label: "Twitter",
                    //   onTap: () => _launchWebsite("https://twitter.com"),
                    // ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: Colors.white,
      elevation: 0.8,
      shadowColor: Colors.black.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
                fontFamily: 'Montserrat',
              ),
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final row = Row(
      children: [
        _CircleIcon(icon: icon, color: const Color(0xFF1C274C)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black87,
              fontFamily: 'Montserrat',
            ),
          ),
        ),
      ],
    );

    if (onTap == null) return row;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: row,
      ),
    );
  }
}

class _CircleIcon extends StatelessWidget {
  const _CircleIcon({
    required this.icon,
    required this.color,
  });

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        size: 20,
        color: color,
      ),
    );
  }
}
