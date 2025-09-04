// lib/controllers/pdf_download_controller.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../api/api_services.dart';

class PdfDownloadController extends GetxController {
  var isDownloading = false.obs;

  Future<void> _ensurePermissions() async {
    if (Platform.isAndroid) {
      if (await Permission.storage.isDenied) {
        await Permission.storage.request();
      }
    }
  }

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

  Future<void> downloadChauffeurEInvoice({
    required BuildContext context,
    required String objectId,
  }) async {
    final endpoint = "chaufferReservation/pdfGeneratorEInvoice/$objectId/CUSTOMER";
    print(
        '🔽 [PdfDownloadController] Starting downloadChauffeurEInvoice for objectId: $objectId | Endpoint: $endpoint');

    try {
      await _ensurePermissions(); // ✅ ask storage permission on Android <= 12

      Directory? dir;
      if (Platform.isAndroid) {
        if (await Directory("/storage/emulated/0/Download").exists()) {
          dir = Directory("/storage/emulated/0/Download");
        } else {
          dir = await getExternalStorageDirectory();
        }
      } else {
        dir = await getApplicationDocumentsDirectory();
      }

      final filePath = "${dir!.path}/e_invoice_$objectId.pdf";
      print('📂 Saving E-Invoice file to: $filePath');

      // Assuming you already have ApiService.downloadPdfFromGetApi(filePath) updated to handle saving
      await ApiService().downloadPdfFromGetApi(
        context: context,
        endpoint: endpoint,
        fileName: filePath, // ✅ Pass full path instead of just fileName
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
      print('✅ E-Invoice PDF downloaded successfully for objectId: $objectId');
    } catch (e) {
      print(
          '❌ Error in downloadChauffeurEInvoice for objectId: $objectId | Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to download E-Invoice'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }
}
