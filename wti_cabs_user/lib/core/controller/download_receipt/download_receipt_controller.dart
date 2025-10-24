// lib/controllers/pdf_download_controller.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wti_cabs_user/core/api/self_drive_api_services.dart';

import '../../api/api_services.dart';

class PdfDownloadController extends GetxController {
  var isDownloading = false.obs;



  Future<void> downloadReceiptPdf(String objectId, BuildContext context) async {
    print(
        '🔽 [PdfDownloadController] Starting downloadReceiptPdf for objectId: $objectId');
    isDownloading.value = true;

    try {
      await _ensurePermissions(); // 🔑 Ask storage permission (for Android <=12)

      Directory? dir;
      if (Platform.isAndroid) {
        if (await Directory("/storage/emulated/0/Download").exists()) {
          dir = Directory(
              "/storage/emulated/0/Download"); // Public Downloads folder
        } else {
          dir =
          await getExternalStorageDirectory(); // App-specific storage (Android 11+)
        }
      } else {
        dir = await getApplicationDocumentsDirectory(); // iOS/macOS
      }

      final filePath = "${dir!.path}/receipt_$objectId.pdf";
      print('📂 Saving file to: $filePath');

      await ApiService().downloadPdfWithHttp(
        endpoint: 'chaufferReservation/printConfirmationChauffeur',
        body: {"objectID": objectId},
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Basic aGFyc2g6MTIz',
        },
        filePath: filePath,
      );

      print('✅ PDF downloaded successfully for objectId: $objectId');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF saved to ${dir.path}'),
          backgroundColor: Colors.green,
        ),
      );

      final result = await OpenFile.open(filePath);
      print('📖 OpenFile result: ${result.message}');
    } catch (e) {
      print(
          '❌ Error in downloadReceiptPdf for objectId: $objectId | Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please wait for Booking Complete'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      isDownloading.value = false;
      print(
          'ℹ️ downloadReceiptPdf completed for objectId: $objectId | isDownloading reset to false');
    }
  }

  Future<void> _ensurePermissions() async {
    if (!Platform.isAndroid) return;

    // Android 13+ → use these new permissions
    if (await Permission.photos.isDenied) {
      await Permission.photos.request();
    }

    if (await Permission.videos.isDenied) {
      await Permission.videos.request();
    }

    // Older Android (for writing to /storage/emulated/0/Download)
    if (await Permission.storage.isDenied) {
      await Permission.storage.request();
    }
  }

  Future<void> downloadChauffeurEInvoice({
    required BuildContext context,
    required String objectId,
  }) async {
    final endpoint = "chaufferReservation/pdfGeneratorEInvoice/$objectId/CUSTOMER";
    print('🔽 [PdfDownloadController] Starting download for $objectId');
    print('🔗 Endpoint: $endpoint');

    try {
      await _ensurePermissions();

      Directory? dir;
      if (Platform.isAndroid) {
        // ✅ Prefer Downloads folder
        if (await Directory("/storage/emulated/0/Download").exists()) {
          dir = Directory("/storage/emulated/0/Download");
        } else {
          dir = await getExternalStorageDirectory();
        }
      } else {
        dir = await getApplicationDocumentsDirectory();
      }

      final filePath = "${dir!.path}/e_invoice_$objectId.pdf";
      print('📂 Target save path: $filePath');

      await SelfDriveApiService().downloadPdfFromGetApi(
        context: context,
        endpoint: endpoint,
        filePath: filePath, // ✅ Correctly passing full path
        headers: {
          'Authorization': 'Basic aGFyc2g6MTIz',
        },
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('E-Invoice saved to ${dir.path}'),
          backgroundColor: Colors.green,
        ),
      );

      final result = await OpenFile.open(filePath);
      print('📖 OpenFile result: ${result.message}');
      print('✅ E-Invoice PDF downloaded successfully for $objectId');
    } catch (e) {
      print('❌ Error downloading E-Invoice for $objectId: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to download E-Invoice'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }
}
