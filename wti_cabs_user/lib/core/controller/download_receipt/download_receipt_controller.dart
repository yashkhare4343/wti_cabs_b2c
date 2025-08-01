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
    isDownloading.value = true;

    try {
      final dir = await getApplicationDocumentsDirectory();
      final filePath = "${dir.path}/receipt_$objectId.pdf";

      await ApiService().downloadPdfWithHttp(
        endpoint: 'chaufferReservation/pdfGeneratorGlobalNormalUser',
        body: {"objectID": objectId},
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Basic aGFyc2g6MTIz',
        },
        filePath: filePath,

      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF downloaded successfully.'),
          backgroundColor: Colors.green,
        ),
      );
      await OpenFile.open(filePath); // Optional: open file after download
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please wait for Booking Complete'),
          backgroundColor: Colors.redAccent,
        ),
      );    } finally {
      isDownloading.value = false;
    }
  }

  Future<void> downloadChauffeurEInvoice({
    required BuildContext context,
    required String objectId,
  }) async {
    final endpoint = "chaufferReservation/pdfGeneratorEInvoice/$objectId/CUs";

    await ApiService().downloadPdfFromGetApi(
      context: context,
      endpoint: endpoint,
      fileName: "receipt_$objectId.pdf",
      headers: {
        'Authorization': 'Basic aGFyc2g6MTIz',
      },
    );
    print('yash download invoice id : $objectId');
  }
}
