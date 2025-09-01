import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import '../../../utility/currency/currency_utils.dart';
import '../../api/api_services.dart';

class Currency {
  final String code;
  final String symbol;
  final String name;

  Currency({required this.code, required this.symbol, required this.name});

  factory Currency.fromMap(Map<String, String> map) {
    return Currency(
      code: map["code"] ?? "",
      symbol: map["symbol"] ?? "",
      name: map["name"] ?? "",
    );
  }

  Map<String, String> toMap() {
    return {"code": code, "symbol": symbol, "name": name};
  }
}

class CurrencyController extends GetxController {
  static const _currencyKey = "selected_currency";

  var selectedCurrency = Currency(code: "INR", symbol: "₹", name: "Indian Rupee").obs;
  var fromCurrency = Currency(code: "INR", symbol: "₹", name: "Indian Rupee").obs;
  RxString country = 'india'.obs;
  RxBool isInIndiaLocation = false.obs; // ✅ cache location result
  Rx<Currency> baseCurrency = Currency(code: "INR", symbol: "₹", name: "Indian Rupee").obs;
  RxDouble convertedRate = 1.0.obs;

  late final List<Currency> availableCurrencies =
  CurrencyUtils.currencies.map((e) => Currency.fromMap(e)).toList();

  final ApiService _apiService = ApiService();
  var isLoading = false.obs;


  @override
  void onInit() {
    super.onInit();
    _loadCurrency();
    detectLocationOnce();
  }

  Future<void> changeCurrency(Currency currency) async {
    selectedCurrency.value = currency;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currencyKey, currency.code);
  }

  Future<void> _loadCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    String? code = prefs.getString(_currencyKey);

    if (code != null) {
      selectedCurrency.value = availableCurrencies.firstWhere(
            (c) => c.code == code,
        orElse: () => availableCurrencies.first,
      );
    } else {
      await _setCurrencyFromLocation();
    }
  }

  Future<void> _setCurrencyFromLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      List<Placemark> placemarks =
      await placemarkFromCoordinates(position.latitude, position.longitude);

      country.value =
      placemarks.isNotEmpty ? placemarks.first.country ?? "India" : "India";

      selectedCurrency.value = country.value.toLowerCase() == "india"
          ? availableCurrencies.firstWhere((c) {
            return c.code == "INR";
          })
          : availableCurrencies.firstWhere(
            (c) => c.code == "USD",
        orElse: () => availableCurrencies.first,
      );



      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_currencyKey, selectedCurrency.value.code);
    } catch (e) {
      print("⚠️ Error getting location: $e");
      selectedCurrency.value =
          availableCurrencies.firstWhere((c) => c.code == "INR");
    }
  }


  Future<void> detectLocationOnce() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      List<Placemark> placemarks =
      await placemarkFromCoordinates(position.latitude, position.longitude);

      String countryName =
      placemarks.isNotEmpty ? placemarks.first.country ?? "" : "";
      country.value = countryName;

      isInIndiaLocation.value = countryName.toLowerCase() == "india";
      print("🌍 Detected location country: $countryName (isInIndia: ${isInIndiaLocation.value})");
    } catch (e) {
      print("⚠️ Error detecting location: $e");
      isInIndiaLocation.value = false;
    }
  }


  void setBaseCurrency({
    required bool isIndiaInventory,
    required bool isInIndiaLocation,
  }) async {
    // Apply your mapping rules
    if (isInIndiaLocation && isIndiaInventory) {
      baseCurrency.value = Currency(code: "INR", symbol: "₹", name: "Indian Rupee");
    } else if (isInIndiaLocation && !isIndiaInventory) {
      baseCurrency.value = Currency(code: "USD", symbol: "\$", name: "US Dollar");
    } else if (!isInIndiaLocation && isIndiaInventory) {
      baseCurrency.value = Currency(code: "INR", symbol: "₹", name: "Indian Rupee");
    } else {
      baseCurrency.value = Currency(code: "USD", symbol: "\$", name: "US Dollar");
    }

    // 🔹 Check if user has already selected a currency
    final prefs = await SharedPreferences.getInstance();
    final userSelectedCode = prefs.getString(_currencyKey);

    if (userSelectedCode == null) {
      // No manual selection → fall back to system base
      selectedCurrency.value = baseCurrency.value;
      await prefs.setString(_currencyKey, baseCurrency.value.code);
    }

    fromCurrency.value = baseCurrency.value;

    print("✅ Base currency set to ${baseCurrency.value.code} (${baseCurrency.value.symbol}) "
        "| isIndiaLocation=$isInIndiaLocation | isIndiaInventory=$isIndiaInventory");
  }




  /// ---------------- Conversion ----------------
  /// Converts any amount by multiplying it with API conversion rate.
  Future<double> convertPrice(double amount) async {
    final from = fromCurrency.value.code;
    final to = selectedCurrency.value.code;

    print("🔄 Converting price...");
    print("➡️ From: $from  ➡️ To: $to  | Amount: $amount");

    if (from == to) {
      convertedRate.value = 1.0;          // ✅ reset to 1
      print("⚡ Same currency ($from), no conversion needed.");
      return amount; // no conversion needed
    }

    try {
      isLoading.value = true; // 🔥 start loader

      final url = "currency/currencyConversion/$to?baseCurrency=$from";
      print("🌐 API Request URL: $url");

      final response = await _apiService.getRequestCurrency(url);
      print("✅ API Response: $response");

      if (response["currencyConverted"] == true) {
        double rate = (response["data"] as num).toDouble();
        convertedRate.value = rate; // ✅ keep rate in observable

        print("💱 Conversion rate: $rate | Converted Amount: ${amount * rate}");

        return amount * rate; // multiply price by conversion rate
      }

      print("⚠️ Conversion not applied, returning original amount: $amount");
      convertedRate.value = 1.0;

      return amount; // fallback
    } catch (e, s) {
      print("❌ Conversion API failed: $e");
      print("📌 Stacktrace: $s");

      return amount;
    } finally {
      isLoading.value = false; // ✅ stop loader
    }
  }

  /// Helper to get formatted price string
  String formatPrice(double price) =>
      "${selectedCurrency.value.symbol} ${price.toStringAsFixed(2)}";

  /// Allows setting fromCurrency dynamically
  void setFromCurrency(String code) {
    final found = availableCurrencies.firstWhere(
          (c) => c.code == code,
      orElse: () => Currency(code: code, symbol: code, name: code),
    );
    fromCurrency.value = found;
  }
}

