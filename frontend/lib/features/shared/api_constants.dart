import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';

class ApiConstants {
  static late String baseUrl;

  static Future<void> initialize() async {
    if (kReleaseMode) {
      baseUrl = 'https://titangym-mangement-application-production.up.railway.app';
      return;
    }

    const String realDeviceIp = 'http://192.168.1.8:8000';

    if (kIsWeb) {
      baseUrl = 'http://localhost:8000';
      return;
    }

    final deviceInfo = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      final isEmulator = !androidInfo.isPhysicalDevice;
      baseUrl = isEmulator
          ? 'http://10.0.2.2:8000'  //Android emulator
          : realDeviceIp;            //Real Android device
      return;
    }

    if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      final isSimulator = !iosInfo.isPhysicalDevice;
      baseUrl = isSimulator
          ? 'http://localhost:8000'  // iOS simulator
          : realDeviceIp;            // Real iPhone
      return;
    }

    baseUrl = 'http://localhost:8000';
  }
}