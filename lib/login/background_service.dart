import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:odgcashvan/utility/my_constant.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> initializeService() async {
  final service = FlutterBackgroundService();
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
      notificationChannelId: 'my_foreground',
      initialNotificationTitle: 'ກຳລັງຕິດຕາມຕຳແໜ່ງ',
      initialNotificationContent: 'ກຳລັງສົ່ງຂໍ້ມູນ GPS ທຸກ 5 ວິນາທີ',
    ),
    iosConfiguration: IosConfiguration(),
  );
  await service.startService();
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();

  final battery = Battery();
  final prefs = await SharedPreferences.getInstance();
  final deviceInfo = DeviceInfoPlugin();
  final androidInfo = await deviceInfo.androidInfo;
  final imei = androidInfo.id;
  // final imei = androidInfo.id;
  final deviceId = androidInfo.device; // ✅ เพิ่มตรงนี้
  Timer.periodic(const Duration(seconds: 5), (timer) async {
    if (service is AndroidServiceInstance &&
        await service.isForegroundService()) {
      service.setForegroundNotificationInfo(
        title: 'ກຳລັງສົ່ງຂໍ້ມູນ GPS',
        content: DateTime.now().toIso8601String(),
      );
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final batteryLevel = await battery.batteryLevel;
      final connectivity = await Connectivity().checkConnectivity();
      final isOnline = connectivity != ConnectivityResult.none;

      final data = {
        'imei': imei,
        'timestamp': DateTime.now().toIso8601String(),
        'lat': position.latitude,
        'lng': position.longitude,
        'battery': batteryLevel,
        'device_id': deviceId,
        'network': isOnline ? 'online' : 'offline',
      };

      if (isOnline) {
        // Send current data
        final response = await http.post(
          Uri.parse(MyConstant().domain + '/savegps'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(data),
        );

        // If successful, send cached too
        if (response.statusCode == 200) {
          final cached = prefs.getStringList('offline_gps') ?? [];
          for (final item in cached) {
            await http.post(
              Uri.parse(MyConstant().domain + '/savegps'),
              headers: {'Content-Type': 'application/json'},
              body: item,
            );
          }
          await prefs.remove('offline_gps');
        } else {
          await _saveOffline(data, prefs);
        }
      } else {
        await _saveOffline(data, prefs);
      }
    } catch (e) {
      debugPrint('GPS error: $e');
    }
  });
}

Future<void> _saveOffline(
  Map<String, dynamic> data,
  SharedPreferences prefs,
) async {
  List<String> offline = prefs.getStringList('offline_gps') ?? [];
  offline.add(jsonEncode(data));
  await prefs.setStringList('offline_gps', offline);
}
