// lib/controllers/pdf_download_controller.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:wti_cabs_user/core/api/self_drive_api_services.dart';

import '../../api/api_services.dart';

class PdfDownloadController extends GetxController {
  var isDownloading = false.obs;

  Future<Directory> _getPdfDirectory() async {
    // App-scoped directory (no storage/media permissions needed).
    final Directory baseDir = Platform.isAndroid
        ? (await getExternalStorageDirectory() ??
            await getApplicationDocumentsDirectory())
        : await getApplicationDocumentsDirectory();

    final pdfDir = Directory('${baseDir.path}/pdf');
    if (!await pdfDir.exists()) {
      await pdfDir.create(recursive: true);
    }
    return pdfDir;
  }



  Future<void> downloadReceiptPdf(String objectId, BuildContext context) async {
    print(
        '🔽 [PdfDownloadController] Starting downloadReceiptPdf for objectId: $objectId');
    isDownloading.value = true;

    try {
      final dir = await _getPdfDirectory();

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
    print('🔽 [PdfDownloadController] Starting download for $objectId');
    print('🔗 Endpoint: $endpoint');

    try {
      final dir = await _getPdfDirectory();

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

  // cab invoice
  Future<void> downloadChauffeurEInvoiceCab({
    required BuildContext context,
    required String objectId,
  }) async {
    final endpoint = "chaufferReservation/pdfGeneratorEInvoice/$objectId/CUSTOMER";
    print('🔽 [PdfDownloadController] Starting download for $objectId');
    print('🔗 Endpoint: $endpoint');

    try {
      final dir = await _getPdfDirectory();

      final filePath = "${dir!.path}/e_invoice_$objectId.pdf";
      print('📂 Target save path: $filePath');

      await ApiService().downloadPdfFromGetApiCab(
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
