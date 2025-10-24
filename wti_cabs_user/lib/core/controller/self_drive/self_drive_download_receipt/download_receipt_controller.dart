import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';
import '../../../api/self_drive_api_services.dart';

class SdPdfDownloadController extends GetxController {
  /// ✅ Ensure storage permission for Android (Android 13+ compatible)
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

  /// ✅ Reusable method to save PDF file
  Future<void> savePdfFile(Uint8List bytes, String filePath) async {
    try {
      final file = File(filePath);

      // Ensure parent directory exists
      if (!await file.parent.exists()) {
        await file.parent.create(recursive: true);
      }

      await file.writeAsBytes(bytes, flush: true);
      print('📂 PDF saved at: $filePath');
    } catch (e) {
      print('❌ Error saving PDF: $e');
      throw Exception('Failed to save PDF');
    }
  }

  /// ✅ Downloads PDF receipt using the GET API
  Future<void> downloadReceiptPdf({
    required BuildContext context,
    required String orderRefId,
  }) async {
    final endpoint = "pdf-receipt/generatePDFReceipt/$orderRefId";
    print('🔽 Starting downloadReceiptPdf for: $orderRefId | Endpoint: $endpoint');

    try {
      // ✅ Request permissions
      await _ensurePermissions();

      // ✅ Prefer visible Downloads folder on Android
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

      final fileName = "e_invoice_$orderRefId.pdf";
      final filePath = "${dir!.path}/$fileName";
      print('📂 Saving E-Invoice file to: $filePath');

      // ✅ Pass full file path here (fix)
      await SelfDriveApiService().downloadPdfFromGetApi(
        context: context,
        endpoint: endpoint,
        filePath: filePath, // ✅ FIXED: full absolute path instead of fileName
        headers: {
          'Authorization': 'Basic aGFyc2g6MTIz',
        },
      );

      // ✅ Confirm with user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('E-Invoice saved to ${dir.path}'),
          backgroundColor: Colors.green,
        ),
      );

      // ✅ Try to open file
      final result = await OpenFile.open(filePath);
      print('📖 OpenFile result: ${result.message}');
      print('✅ E-Invoice PDF downloaded successfully for orderRefId: $orderRefId');
    } catch (e) {
      print('❌ Error in downloadReceiptPdf for $orderRefId | Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to download E-Invoice'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }
}
