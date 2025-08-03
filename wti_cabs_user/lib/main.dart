import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:get_it/get_it.dart';
import 'package:wti_cabs_user/core/api/api_services.dart';
import 'package:wti_cabs_user/core/controller/booking_ride_controller.dart';
import 'package:wti_cabs_user/utility/constants/strings/string_constants.dart';

import 'config/enviornment_config.dart';
import 'core/controller/choose_drop/choose_drop_controller.dart';
import 'core/controller/choose_pickup/choose_pickup_controller.dart';
import 'core/route_management/app_page.dart';
import 'core/services/storage_services.dart';
import 'firebase_options.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

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

    print('🌍 Initializing Time Zones');
    tz.initializeTimeZones();

    print('💳 Setting Stripe key');
    Stripe.publishableKey = 'pk_test_51QwGPYICDiJ5BoSQa8eKsWdvifkn4LOeuBoTTMx4ES6SCI2iDMWY4p74wOCc8bFLuJQwU37DMbmIA3ACuZDhReuO00dxg0qfsS';
    await Stripe.instance.applySettings();

    print('📥 Initializing FlutterDownloader');
    await FlutterDownloader.initialize(debug: true, ignoreSsl: true);

    print('🏁 Running App');
    runApp(const MyApp());
  } catch (e, stack) {
    print('❌ Caught exception in main: $e');
    print('🪵 StackTrace:\n$stack');
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String? _fcmToken = 'Fetching...';

  @override
  void initState() {
    super.initState();
    initFCM();
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
