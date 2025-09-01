// lib/controllers/pdf_download_controller.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

import '../../api/api_services.dart';

class PdfDownloadController extends GetxController {
  var isDownloading = false.obs;

  Future<void> downloadReceiptPdf(String objectId, BuildContext context) async {
    print('🔽 [PdfDownloadController] Starting downloadReceiptPdf for objectId: $objectId');
    isDownloading.value = true;

    try {
      final dir = await getApplicationDocumentsDirectory();
      final filePath = "${dir.path}/receipt_$objectId.pdf";
      print('📂 Saving file to: $filePath');

      await ApiService().downloadPdfWithHttp(
        endpoint: 'chaufferReservation/pdfGeneratorGlobalNormalUser',
        body: {"objectID": objectId},
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Basic aGFyc2g6MTIz',
        },
        filePath: filePath,
      );
      print('✅ PDF downloaded successfully for objectId: $objectId');


      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF downloaded successfully.'),
          backgroundColor: Colors.green,
        ),
      );

      final result = await OpenFile.open(filePath); // Optional: open file after download
      print('📖 OpenFile result: ${result.message}');
    } catch (e) {
      print('❌ Error in downloadReceiptPdf for objectId: $objectId | Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please wait for Booking Complete'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      isDownloading.value = false;
      print('ℹ️ downloadReceiptPdf completed for objectId: $objectId | isDownloading reset to false');
    }
  }

  Future<void> downloadChauffeurEInvoice({
    required BuildContext context,
    required String objectId,
  }) async {
    final endpoint = "chaufferReservation/pdfGeneratorEInvoice/$objectId/CUSTOMER";
    print('🔽 [PdfDownloadController] Starting downloadChauffeurEInvoice for objectId: $objectId | Endpoint: $endpoint');

    try {
      await ApiService().downloadPdfFromGetApi(
        context: context,
        endpoint: endpoint,
        fileName: "receipt_$objectId.pdf",
        headers: {
          'Authorization': 'Basic aGFyc2g6MTIz',
        },
      );
      print('✅ E-Invoice PDF downloaded successfully for objectId: $objectId');
      print('✅ url eInvoice: $endpoint');
    } catch (e) {
      print('❌ Error in downloadChauffeurEInvoice for objectId: $objectId | Error: $e');
    }
  }
}
