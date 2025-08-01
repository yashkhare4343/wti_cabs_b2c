import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class CustomDrawerSheet extends StatelessWidget {
  const CustomDrawerSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width * 0.8;

    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: width,
          // height: double.infinity,
          margin: const EdgeInsets.only(top: 16),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(34),
              bottomRight: Radius.circular(20),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SvgPicture.asset(
                      'assets/images/wti_logo.svg',
                      height: 17,
                      width: 47,
                    ),
                    // InkWell(
                    //   splashColor: Colors.transparent,
                    //   onTap: () {
                    //     Navigator.pop(context);
                    //   },
                    //   child: Container(
                    //     decoration: BoxDecoration(
                    //       color: Color(0xFFE6EAF9),
                    //       borderRadius: BorderRadius.circular(4),
                    //     ),
                    //     padding: EdgeInsets.all(6.0),
                    //     child: Icon(
                    //       Icons.arrow_back,
                    //       size: 16,
                    //       color: Color(0xFF192653),
                    //     ),
                    //   ),
                    // ),
                  ],
                ),
                SizedBox(
                  height: 12,
                ),
                const Divider(),
                SizedBox(
                  height: 22,
                ),
                /// Drawer Items
                _buildDrawerItem(
                  icon: SvgPicture.asset(
                    'assets/images/india_logo.svg',
                    height: 16,
                    width: 24,
                  ),
                  title: 'Country',
                  subtitle: 'India',
                  onTap: () {},
                ),
                _buildDrawerItem(
                  icon: SvgPicture.asset(
                    'assets/images/payments.svg',
                    height: 20,
                    width: 20,
                  ),
                  title: 'Currency',
                  subtitle: 'Select Currency',
                  onTap: () {},
                ),
                _buildDrawerItem(
                  icon: SvgPicture.asset(
                    'assets/images/refer.svg',
                    height: 20,
                    width: 20,
                  ),
                  title: 'Refer & Earn',
                  subtitle: 'Driving Licence, Passport, ID etc.',
                  onTap: () {},
                ),
                _buildDrawerItem(
                  icon: SvgPicture.asset(
                    'assets/images/language.svg',
                    height: 20,
                    width: 20,
                  ),
                  title: 'Language',
                  subtitle: 'English',
                  onTap: () {},
                ),
                _buildDrawerItem(
                  icon: SvgPicture.asset(
                    'assets/images/docs.svg',
                    height: 20,
                    width: 20,
                  ),
                  title: 'Documents',
                  subtitle: 'Driving Licence, Passport, ID etc.',
                  onTap: () {},
                ),
                _buildDrawerItem(
                  icon: SvgPicture.asset(
                    'assets/images/legal.svg',
                    height: 20,
                    width: 20,
                  ),
                  title: 'Legal',
                  subtitle: 'Privacy Policy, Terms & Conditions',
                  onTap: () {},
                ),
                _buildDrawerItem(
                  icon: SvgPicture.asset(
                    'assets/images/logout.svg',
                    height: 20,
                    width: 20,
                  ),
                  title: 'Sign Out',
                  subtitle: 'Driving Licence, Passport, ID etc.',
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required Widget icon, // Accepts any widget now
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Color(0xFFE2E2E2), // Change as needed
            width: 1,
          ),

        ),
        child: Row(
          children: [
            SizedBox(
                width: 24, height: 24, child: icon), // Consistent icon size
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: Color(0xFF3F3F3F)),
                  ),
                  SizedBox(
                    height: 4,
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF929292),
                      fontWeight: FontWeight.w500,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 12,
              color: Color(0xFF919191),
            ),
          ],
        ),
      ),
    );
  }
}
