import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart'; // Để dùng kIsWeb
import 'auth_service.dart'; // Import để lấy Token chuẩn

class GiftService {
  // Logic BaseURL thông minh (Web/Android)
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5000/api';
    } else {
      return 'http://10.0.2.2:5000/api';
    }
  }

  // 1. Lấy danh sách quà
  Future<List<dynamic>> fetchGifts() async {
    final url = Uri.parse('$baseUrl/gifts');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Lỗi tải dữ liệu');
      }
    } catch (e) {
      print('Lỗi fetchGifts: $e');
      return [];
    }
  }

  // 2. Đổi quà
  Future<Map<String, dynamic>> redeemGift(String giftId) async {
    final url = Uri.parse('$baseUrl/gifts/redeem');

    // Lấy Token từ AuthService
    final String? token = await AuthService.getToken();

    if (token == null || token.isEmpty) {
      return {
        'success': false,
        'message': 'Bạn chưa đăng nhập. Hãy đăng nhập lại!',
      };
    }

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // Gửi token
        },
        body: jsonEncode({'giftId': giftId}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Đổi quà thành công!',
          'data': data,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Đổi quà thất bại',
        };
      }
    } catch (e) {
      print('Lỗi redeemGift: $e');
      return {'success': false, 'message': 'Lỗi kết nối server'};
    }
  }

  // 3. Lấy lịch sử giao dịch (Hàm này UI TransactionHistoryPage đang gọi)
  Future<List<dynamic>> fetchHistory() async {
    final url = Uri.parse('$baseUrl/gifts/history');

    // Cần Token để biết lịch sử của ai
    final String? token = await AuthService.getToken();
    if (token == null) return [];

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token', // Bắt buộc có token
        },
      );

      if (response.statusCode == 200) {
        // Trả về danh sách gốc từ Server
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('Lỗi fetchHistory: $e');
    }
    return []; // Trả về rỗng nếu lỗi
  }
}
