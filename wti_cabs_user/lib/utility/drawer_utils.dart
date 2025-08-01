import 'package:flutter/material.dart';
import 'package:wti_cabs_user/common_widget/drawer/custom_drawer.dart';

void showCustomDrawer(BuildContext context) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: "Drawer",
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (_, __, ___) => const CustomDrawerSheet(),
    transitionBuilder: (_, anim, __, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(-1, 0),
          end: Offset.zero,
        ).animate(anim),
        child: child,
      );
    },
  );
}
