import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:get_it/get_it.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:wti_cabs_user/core/api/api_services.dart';
import 'package:wti_cabs_user/core/controller/booking_ride_controller.dart';
import 'package:wti_cabs_user/screens/map_picker/map_picker.dart';
import 'package:wti_cabs_user/utility/constants/strings/string_constants.dart';

import 'config/enviornment_config.dart';
import 'core/controller/banner/banner_controller.dart';
import 'core/controller/choose_drop/choose_drop_controller.dart';
import 'core/controller/choose_pickup/choose_pickup_controller.dart';
import 'core/controller/drop_location_controller/drop_location_controller.dart';
import 'core/controller/popular_destination/popular_destination.dart';
import 'core/controller/usp_controller/usp_controller.dart';
import 'core/route_management/app_page.dart';
import 'core/services/cache_services.dart';
import 'core/services/storage_services.dart';
import 'firebase_options.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:location/location.dart' as location;
import 'package:geocoding/geocoding.dart' as geocoding;
import 'dart:convert'; // for jsonEncode
import 'package:google_maps_flutter/google_maps_flutter.dart';

final FlutterLocalNotificationsPlugin _localNotificationsPlugin = FlutterLocalNotificationsPlugin();
const AndroidNotificationChannel _channel = AndroidNotificationChannel(
  'high_importance_channel', // Must match AndroidManifest
  'High Importance Notifications',
  importance: Importance.high,
);

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Corrected: GetIt instance accessed via getter, NOT as a method call
final GetIt getIt = GetIt.instance;

/// Background message handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('🔄 Background message received: ${message.messageId}');
}

void serviceLocator() {
  // Register your services here
  getIt.registerSingleton<ApiService>(ApiService());
}

Future<bool> requestLocationPermission() async {
  LocationPermission permission;

  // Check current permission status
  permission = await Geolocator.checkPermission();

  if (permission == LocationPermission.denied) {
    // Request permission
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      // Permission denied
      print("Location permission denied");
      return false;
    }
  }

  if (permission == LocationPermission.deniedForever) {
    // Permissions are denied forever
    print("Location permission denied forever. Open settings.");
    return false;
  }

  // Permission granted
  print("Location permission granted");
  return true;
}


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('🟢 Starting main');

  try {
    print('🌱 Loading .env');
    await dotenv.load(fileName: ".env");

    print('🔥 Initializing Firebase');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    print('📦 Initializing StorageServices');
    await StorageServices.instance.init();
    // await CacheHelper.clearAllCache();

    print('🔧 Registering services');
    serviceLocator();

    print('📨 Configuring background FCM handler');
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    print('⚙️ Setting EnvironmentConfig');
    EnvironmentConfig.setEnvironment(EnvironmentType.dev);

    print('🚕 Registering controllers');
    Get.put(BookingRideController());
    Get.put(PlaceSearchController());
    Get.lazyPut<DropPlaceSearchController>(() => DropPlaceSearchController());
    Get.lazyPut<DestinationLocationController>(() => DestinationLocationController());

    print('🌍 Initializing Time Zones');
    tz.initializeTimeZones();

    print('💳 Setting Stripe key');
    Stripe.publishableKey = 'pk_test_51QwGPYICDiJ5BoSQa8eKsWdvifkn4LOeuBoTTMx4ES6SCI2iDMWY4p74wOCc8bFLuJQwU37DMbmIA3ACuZDhReuO00dxg0qfsS';
    await Stripe.instance.applySettings();

    print('📥 Initializing FlutterDownloader');
    await FlutterDownloader.initialize(debug: true, ignoreSsl: true);
    bool locationGranted = await requestLocationPermission();
    if (locationGranted) {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      print("🌍 Current location: ${position.latitude}, ${position.longitude}");
    } else {
      print("⚠️ Location permission not granted. You may need to request it later.");
    }
    print('🏁 Running App');
    runApp(const MyApp());
  } catch (e, stack) {
    print('❌ Caught exception in main: $e');
    print('🪵 StackTrace:\n$stack');
  }
}



// Example usage
void checkAndGetLocation() async {
  bool granted = await requestLocationPermission();
  if (granted) {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    print("Current location: ${position.latitude}, ${position.longitude}");
  } else {
    // Show a dialog to open app settings if needed
  }
}


class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String? _fcmToken = 'Fetching...';
  String address = '';
  final PopularDestinationController popularDestinationController =
  Get.put(PopularDestinationController());
  final UspController uspController = Get.put(UspController());
  final BannerController bannerController = Get.put(BannerController());


  @override
  void initState() {
    super.initState();
    initFCM();
    homeApiLoading();
  }

  void homeApiLoading() async{
  await popularDestinationController.fetchPopularDestinations();
   await uspController.fetchUsps();
   await bannerController.fetchImages();

    fetchCurrentLocationAndAddress();
  }

  Future<void> fetchCurrentLocationAndAddress() async {
    location.Location loc = location.Location();

    bool serviceEnabled = await loc.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await loc.requestService();
      if (!serviceEnabled) return;
    }

    location.PermissionStatus permissionGranted = await loc.hasPermission();
    if (permissionGranted == location.PermissionStatus.denied) {
      permissionGranted = await loc.requestPermission();
      if (permissionGranted != location.PermissionStatus.granted) return;
    }

    final locData = await loc.getLocation();
    if (locData.latitude != null && locData.longitude != null) {
      final LatLng latLng = LatLng(locData.latitude!, locData.longitude!);
      await _getAddressAndPrefillFromLatLng(latLng);
    }
  }

  Future<void> _getAddressAndPrefillFromLatLng(LatLng latLng) async {
    try {
      // 1. Reverse geocode to get human-readable address
      final placemarks = await geocoding.placemarkFromCoordinates(
        latLng.latitude,
        latLng.longitude,
      );
      print('yash current lat/lng is ${latLng.latitude},${latLng.longitude}');

      if (placemarks.isEmpty) {
        setState(() => address = 'Address not found');
        return;
      }

      final place = placemarks.first;
      final components = <String>[
        place.name ?? '',
        place.street ?? '',
        place.subLocality ?? '',
        place.locality ?? '',
        place.administrativeArea ?? '',
        place.postalCode ?? '',
        place.country ?? '',
      ];
      final fullAddress = components.where((s) => s.trim().isNotEmpty).join(', ');

      // 2. Show address on UI immediately
      setState(() => address = fullAddress);

      // 3. Try searching the place (may fail or return empty)
      await placeSearchController.searchPlaces(fullAddress, context);

      if (placeSearchController.suggestions.isEmpty) {
        print("No search suggestions found for $fullAddress");
        return; // stop here – do not prefill controllers/storage
      }

      final suggestion = placeSearchController.suggestions.first;

      // 4. Update booking controller ONLY if valid suggestion exists
      bookingRideController.prefilled.value = fullAddress;
      placeSearchController.placeId.value = suggestion.placeId;

      // 5. Fire-and-forget details/storage update
      Future.microtask(() async {
        try {
          await placeSearchController.getLatLngDetails(suggestion.placeId, context);

          StorageServices.instance.save('sourcePlaceId', suggestion.placeId);
          StorageServices.instance.save('sourceTitle', suggestion.primaryText);
          StorageServices.instance.save('sourceCity', suggestion.city);
          StorageServices.instance.save('sourceState', suggestion.state);
          StorageServices.instance.save('sourceCountry', suggestion.country);

          if (suggestion.types.isNotEmpty) {
            StorageServices.instance.save(
              'sourceTypes',
              jsonEncode(suggestion.types),
            );
          }

          if (suggestion.terms.isNotEmpty) {
            StorageServices.instance.save(
              'sourceTerms',
              jsonEncode(suggestion.terms),
            );
          }

          sourceController.setPlace(
            placeId: suggestion.placeId,
            title: suggestion.primaryText,
            city: suggestion.city,
            state: suggestion.state,
            country: suggestion.country,
            types: suggestion.types,
            terms: suggestion.terms,
          );

          print('akash country: ${suggestion.country}');
          print('Current location address saved: $fullAddress');
        } catch (err) {
          print('Background save failed: $err');
        }
      });
    } catch (e) {
      print('Error fetching location/address: $e');
      setState(() => address = 'Error fetching address');
    }
  }

  Future<void> initFCM() async {
    // Request permissions
    NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    print('🛂 User permission status: ${settings.authorizationStatus}');

    // Skip APNs handling on iOS simulator
    if (Platform.isIOS && !Platform.environment.containsKey('SIMULATOR_DEVICE_NAME')) {
      String? apnsToken;
      do {
        apnsToken = await FirebaseMessaging.instance.getAPNSToken();
        await Future.delayed(const Duration(milliseconds: 500));
      } while (apnsToken == null);
      print('📲 APNs Token: $apnsToken');
    } else {
      print('ℹ️ Skipping APNs token setup (non-iOS or Simulator)');
    }

    // Get FCM token
    String? token = await FirebaseMessaging.instance.getToken();
    print("🔑 FCM Token: $token");

    setState(() {
      _fcmToken = token;
    });

    // Local notifications
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _localNotificationsPlugin.initialize(initSettings);

    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // Foreground message handling
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📩 Foreground message received!');
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        _localNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _channel.id,
              _channel.name,
              icon: '@mipmap/ic_launcher',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
        );
      }
    });

    // Background open
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('📲 App opened from background notification: ${message.data}');
    });

    // Terminated open
    RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      print('🚀 App launched from terminated notification: ${initialMessage.data}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerDelegate: AppPages.router.routerDelegate,
      routeInformationParser: AppPages.router.routeInformationParser,
      routeInformationProvider: AppPages.router.routeInformationProvider,
      title: StringConstants.title,
    );
  }
}
