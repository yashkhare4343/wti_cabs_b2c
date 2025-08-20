import 'dart:io';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';

class CacheHelper {
  /// Clear Flutter's temp directory (system cache)
  static Future<void> clearTempDir() async {
    try {
      final tempDir = await getTemporaryDirectory();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
        print("✅ Temp directory cleared");
      }
    } catch (e) {
      print("❌ Failed to clear temp dir: $e");
    }
  }

  /// Clear flutter_cache_manager files (e.g. images, downloads)
  static Future<void> clearFileCache() async {
    try {
      await DefaultCacheManager().emptyCache();
      print("✅ CacheManager cleared");
    } catch (e) {
      print("❌ Failed to clear file cache: $e");
    }
  }

  /// Run both
  static Future<void> clearAllCache() async {
    await clearTempDir();
    await clearFileCache();
  }
}
