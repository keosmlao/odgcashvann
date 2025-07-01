// main.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui'; // Required for DartPluginRegistrant.ensureInitialized()

import 'package:battery_plus/battery_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

// Assuming these are in your project structure:
import 'package:odgcashvan/login/login.dart';
import 'package:odgcashvan/utility/my_constant.dart';

// Entry point for the Flutter application
Future<void> main() async {
  // Ensure that Flutter's widget binding is initialized. This is required
  // before using any Flutter plugins.
  WidgetsFlutterBinding.ensureInitialized();

  // Request necessary permissions from the user.
  await _requestPermissions();

  // Initialize Firebase for the application.
  await Firebase.initializeApp();

  // Initialize the background service.
  await initializeService();

  // Configure Firebase Messaging for foreground messages.
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  FirebaseMessaging.onMessage.listen((message) {
    // Log incoming foreground messages.
    print("📩 Foreground message: ${message.notification?.title}");
  });

  // Set up Firebase Messaging to handle background messages.
  // This function must be a top-level function.
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Set preferred device orientations to portrait mode.
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).then((_) {
    // Run the main application widget.
    runApp(const MyApp());
  });
}

// Top-level function for handling Firebase background messages.
// This function needs to be marked with @pragma('vm:entry-point')
// to ensure it's discoverable by the Flutter engine for background execution.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase within the background isolate. This is crucial
  // because the background handler runs in its own isolate.
  await Firebase.initializeApp();
  // Log the received background message.
  print("📩 Background message: ${message.notification?.title}");
}

// Initializes and configures the Flutter background service.
Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  // Configure the background service for Android and iOS.
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      // The function that will be executed in the background.
      onStart: onStart,
      // Automatically start the service when the app launches.
      autoStart: true,
      // Automatically start the service when the device boots.
      autoStartOnBoot: true,
      // Ensure the service runs in foreground mode to prevent it from being killed by the OS.
      isForegroundMode: true,
      // ID for the notification channel used by the foreground service.
      // Make sure this channel is properly configured on the native Android side.
      notificationChannelId: 'gps_tracking',

      // ID for the foreground service notification.
      foregroundServiceNotificationId: 888,
    ),
    // iOS configuration (can be empty if not needed, or configured for iOS specifics).
    iosConfiguration: IosConfiguration(
      // If you need background fetch or other iOS background modes, configure them here.
      // Example:
      // onStart: onStart, // Use the same onStart for consistency if applicable
      // autoStart: true,
      // autoStartOnBoot: true,
    ),
  );

  // Start the background service.
  await service.startService();
}

// The entry point for the background service's isolate.
// This function needs to be a top-level function and marked as an entry point.
@pragma('vm:entry-point')
void onStart(ServiceInstance service) {
  // Ensure that platform plugins can be used in this background isolate.
  DartPluginRegistrant.ensureInitialized();

  // Cast the service instance to AndroidServiceInstance if running on Android
  // to access Android-specific foreground notification methods.
  if (service is AndroidServiceInstance) {
    // Set the information for the foreground notification.
    // This notification is required for Android foreground services.
    service.setForegroundNotificationInfo(
      title: "📍 GPS Tracking",
      content: "กำลังส่งตำแหน่งทุก 5 วินาที...",
    );
  }

  // Set up a periodic timer to send GPS data every 5 seconds.
  Timer.periodic(const Duration(seconds: 5), (timer) async {
    final battery = Battery();
    final deviceInfo = DeviceInfoPlugin();

    try {
      // Get Android device information.
      final androidInfo = await deviceInfo.androidInfo;
      // Note: androidInfo.id provides the Android ID, not the IMEI.
      // It's a unique device identifier, but not the phone's hardware IMEI.
      final deviceAndroidId = androidInfo.id; // Renamed from 'imei' for clarity

      // Check if location services are enabled on the device.
      if (!await Geolocator.isLocationServiceEnabled()) {
        print("❌ Location services disabled.");
        return; // Exit if location services are not enabled.
      }

      // Check location permission status.
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        // If permissions are denied, log an error and return.
        // It's generally not recommended to request permissions from a background isolate
        // as it might not be able to show a UI prompt effectively.
        // Rely on the foreground app to request necessary permissions.
        print(
          "❌ Location permissions denied in background. Cannot get position.",
        );
        return;
      }

      // Get the current device position with high accuracy.
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Get the current battery level.
      final batteryLevel = await battery.batteryLevel;

      // Get or create a persistent UUID for the device.
      final uuid = await getOrCreateUUID();

      // Prepare the data payload to be sent.
      final data = {
        'lat': position.latitude,
        'lng': position.longitude,
        'timestamp': position.timestamp?.toIso8601String(),
        'device_id': uuid, // Use the generated UUID
        'device_model': androidInfo.model, // Device model for identification
        'imei': androidInfo.id, // Use Android ID as a unique identifier
        'android_id':
            deviceAndroidId, // Use the Android ID for additional identification
        'battery_level': batteryLevel,
      };

      // Send the GPS data to your server via HTTP POST.
      await http.post(
        Uri.parse('${MyConstant().domain}/savegps'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      // Log the sent data.
      print("📡 Sent: $data");
    } catch (e) {
      // Catch and log any errors that occur during background processing.
      print("❌ Error in background service: $e");
    }
  });
}

// Retrieves a stored UUID or generates a new one if not found.
Future<String> getOrCreateUUID() async {
  final prefs = await SharedPreferences.getInstance();
  String? deviceId = prefs.getString('device_uuid');
  if (deviceId == null) {
    deviceId = const Uuid().v4(); // Generate a new UUID.
    await prefs.setString('device_uuid', deviceId); // Store the new UUID.
  }
  return deviceId;
}

// Requests all necessary permissions for the app.
Future<void> _requestPermissions() async {
  // Request multiple permissions concurrently.
  await [
    Permission.locationAlways, // Required for background location access.
    Permission.locationWhenInUse, // Required for foreground location access.
    Permission.notification, // Recommended for showing notifications.
    Permission
        .ignoreBatteryOptimizations, // Recommended for continuous background tasks.
  ].request();

  // After initial requests, check location permission specifically.
  final permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied ||
      permission == LocationPermission.deniedForever) {
    // If permission is still denied, request it again.
    // This provides a second chance for the user to grant permission.
    await Geolocator.requestPermission();
  }
}

// The root widget for your Flutter application.
class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Define the theme for the application.
      theme: ThemeData(
        fontFamily: 'NotoSansLao', // Custom font.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true, // Enable Material 3 design.
      ),
      // Set the home screen of the application to the Login widget.
      home: const Login(),
    );
  }
}
