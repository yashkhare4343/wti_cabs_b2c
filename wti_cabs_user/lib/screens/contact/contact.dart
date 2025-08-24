import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../utility/constants/colors/app_colors.dart';

class Contact extends StatelessWidget {
  const Contact({super.key});

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
    return Scaffold(
      backgroundColor: AppColors.scaffoldBgPrimary1,
      appBar: AppBar(
        title: const Text(
          "Contact Us",
          style: TextStyle(
            fontSize: 16, // ⬅️ reduced
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        elevation: 0.5,
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16), // ⬅️ slightly less
        children: [
          const Text(
            "Get in Touch",
            style: TextStyle(
              fontSize: 18, // ⬅️ reduced
              fontWeight: FontWeight.w700,
              color: Colors.black87,
              letterSpacing: 0.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          const Text(
            "Our team is here to assist you with any queries related to reservations and services.",
            style: TextStyle(
              fontSize: 13, // ⬅️ reduced
              color: Colors.black54,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20), // ⬅️ less spacing

          // Contact Options
          _buildContactCard(
            context,
            icon: Icons.phone,
            title: "Call Us (Landline)",
            subtitle: "011-45434500",
            color: Colors.blue,
            onTap: () => _launchPhone("01145434500"),
          ),
          _buildContactCard(
            context,
            icon: Icons.phone_android,
            title: "Call Us (Mobile)",
            subtitle: "9250057902",
            color: Colors.teal,
            onTap: () => _launchPhone("9250057902"),
          ),
          _buildContactCard(
            context,
            icon: Icons.email_outlined,
            title: "Email Us",
            subtitle: "info@wti.co.in",
            color: Colors.redAccent,
            onTap: () => _launchEmail("info@wti.co.in"),
          ),
          _buildContactCard(
            context,
            icon: Icons.language_outlined,
            title: "Visit Our Website",
            subtitle: "www.wticabs.com",
            color: Colors.deepPurple,
            onTap: () => _launchWebsite("https://www.wticabs.com"),
          ),

          const SizedBox(height: 24), // ⬅️ reduced
          const Divider(thickness: 1, color: Colors.black12),

          const SizedBox(height: 16),
          const Text(
            "Company Information",
            style: TextStyle(
              fontSize: 14.5, // ⬅️ reduced
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            "Wise Travel India Ltd.",
            style: TextStyle(
              fontSize: 14, // ⬅️ reduced
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20), // ⬅️ tighter bottom
        ],
      ),
    );
  }
}

Widget _buildContactCard(
    BuildContext context, {
      required IconData icon,
      required String title,
      required String subtitle,
      required Color color,
      required VoidCallback onTap,
    }) {
  return Card(
    color: Colors.white,
    margin: const EdgeInsets.symmetric(vertical: 6), // ⬅️ less margin
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12), // ⬅️ slightly smaller radius
    ),
    elevation: 1,
    shadowColor: Colors.black12,
    child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6), // ⬅️ less padding
        child: ListTile(
          minVerticalPadding: 4, // ⬅️ tighter ListTile
          leading: CircleAvatar(
            radius: 22, // ⬅️ smaller avatar
            backgroundColor: color.withOpacity(0.12),
            child: Icon(icon, color: color, size: 20), // ⬅️ smaller icon
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14.5, // ⬅️ reduced
              color: Colors.black87,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 13, // ⬅️ reduced
            ),
          ),
          trailing: const Icon(
            Icons.chevron_right,
            color: Colors.grey,
            size: 18, // ⬅️ smaller trailing icon
          ),
        ),
      ),
    ),
  );
}
