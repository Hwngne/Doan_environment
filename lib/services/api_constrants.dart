import 'package:flutter/foundation.dart'; 
import 'dart:io'; 

class ApiConstants {
  // Hàm tự động chọn URL dựa trên thiết bị đang chạy
  static String get baseUrl {
    if (kIsWeb) {
      //  Nếu chạy trên Chrome/Web
      return "http://localhost:5000"; 
    } else if (Platform.isAndroid) {
      //  Nếu chạy trên Máy ảo Android (Emulator)
      return "http://10.0.2.2:5000";
    } else {
      // Nếu chạy trên iOS Simulator hoặc Máy thật (cần IP LAN)
      return "http://localhost:5000"; 
    }
  }
}