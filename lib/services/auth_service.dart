import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'user_service.dart';
import '../data/mock_data.dart' hide UserData;

class AuthService {
  // ⚠️ Đổi IP máy tính của bạn ở đây
  static const String baseUrl = "http://localhost:5000/api/users";

  // --- 2. ĐĂNG NHẬP (LOGIC GIỮ NGUYÊN) ---
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      print("📡 SERVER RESPONSE: ${response.body}"); // Debug xem API trả về gì

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();

        // 1. Xử lý linh hoạt (Giữ nguyên logic của bạn)
        // Tìm xem dữ liệu user nằm ở 'data' hay 'data['user']'
        Map<String, dynamic> userObj = (data['user'] != null)
            ? data['user']
            : data;

        // Lấy các biến quan trọng ra trước (Giữ nguyên logic của bạn)
        String token = data['token'] ?? "";
        String role = userObj['role'] ?? "student";
        String name = userObj['name'] ?? "User"; // Lấy từ userObj chuẩn hơn
        String userEmail = userObj['email'] ?? email;
        String avatar = userObj['avatar'] ?? "";

        // 2. Lưu session vào máy (ĐÃ SỬA: Dùng biến đã lấy ở trên thay vì data['...'])
        await prefs.setString('user_token', token);
        await prefs.setBool('is_logged_in', true);
        await prefs.setString('user_email', userEmail);
        await prefs.setString('user_name', name);
        await prefs.setString('user_role', role);
        if (avatar.isNotEmpty) {
          await prefs.setString('user_avatar', avatar);
        }

        // 3. Cập nhật UserData (ĐÃ SỬA: Dùng userObj để đảm bảo không bị null)
        UserData.name = name; // ✅ Sửa: Dùng biến name đã check null ở trên
        UserData.email = userEmail; // ✅ Sửa
        UserData.role = role; // ✅ Sửa
        UserData.avatar = avatar.isNotEmpty
            ? avatar
            : "https://i.pravatar.cc/300";

        UserData.rank = userObj['rank'] ?? 1; // ✅ Sửa: Dùng userObj

        if (userObj['attendanceHistory'] != null) {
          // ✅ Sửa: Dùng userObj
          UserData.attendanceHistory = List<String>.from(
            userObj['attendanceHistory'],
          );
        } else {
          UserData.attendanceHistory = [];
        }

        // --- 4. XỬ LÝ ĐỒNG BỘ ĐIỂM (ĐÃ SỬA: Dùng userObj) ---
        int serverPoints = (userObj['points'] != null)
            ? int.parse(userObj['points'].toString())
            : 0;

        int localPoints = prefs.getInt('points_$userEmail') ?? 0;

        // So sánh:
        if (localPoints > serverPoints) {
          UserData.points = localPoints;
          int diff = localPoints - serverPoints;
          if (diff > 0) {
            print("⚠️ Lệch điểm. Đang bù $diff điểm lên Server...");
            _sendPointsToBackend(diff);
          }
        } else {
          UserData.points = serverPoints;
          await prefs.setInt('points_$userEmail', serverPoints);
        }

        print("💾 ĐÃ LƯU RAM: Name=${UserData.name}, Role=${UserData.role}");

        return {
          'success': true,
          'isFirstLogin': data['isFirstLogin'] ?? false,
          'role': role, // Trả về role chuẩn để Login Page điều hướng
        };
      }
      return {'success': false, 'message': 'Sai tài khoản hoặc mật khẩu'};
    } catch (e) {
      print("Lỗi Login: $e");
      return {'success': false, 'message': 'Lỗi kết nối'};
    }
  }

  static Future<Map<String, dynamic>> changePassword(String newPassword) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/change-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': UserData.email, 'newPassword': newPassword}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message'] ?? 'Thành công'};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Lỗi không xác định',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  // --- 3. AUTO LOGIN ---
  static Future<bool> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('is_logged_in')) return false;

    final String? name = prefs.getString('user_name');
    final String? email = prefs.getString('user_email');
    final String? role = prefs.getString('user_role');
    final String? avatar = prefs.getString('user_avatar');

    if (name != null && email != null) {
      UserData.name = name;
      UserData.email = email;
      UserData.role = role ?? "Sinh viên";
      UserData.avatar = avatar ?? "https://i.pravatar.cc/300";
      int savedPoints = prefs.getInt('points_$email') ?? 0;
      UserData.points = savedPoints;
      // Logic xếp hạng đơn giản
      if (savedPoints > 500) {
        UserData.rank = 3; // Hạng Vàng
      } else if (savedPoints > 100) {
        UserData.rank = 2; // Hạng Bạc
      } else {
        UserData.rank = 1; // Hạng Đồng
      }

      return true;
    }
    return false;
  }

  // --- 4. ĐĂNG XUẤT ---
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_token');
    await prefs.remove('is_logged_in');
    UserData.name = "Khách";
    UserData.email = "";
    UserData.points = 0;
  }

  // --- 4. HÀM DÙNG CHO GAME (Săn điểm, Quiz...) ---
  static Future<void> saveUserPoints(int addedPoints) async {
    UserData.points =
        (UserData.points ?? 0) + addedPoints; // Fix lỗi null safety
    final prefs = await SharedPreferences.getInstance();
    if (UserData.email != null && UserData.email!.isNotEmpty) {
      await prefs.setInt('points_${UserData.email}', UserData.points ?? 0);
    }
    await _sendPointsToBackend(addedPoints);
  }

  // --- 5. HÀM GỬI SERVER (PRIVATE) ---
  // Hàm này chỉ gửi API, không cộng thêm vào RAM UserData.points
  static Future<void> _sendPointsToBackend(int addedPoints) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/update-points'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': UserData.email, 'pointsAdded': addedPoints}),
      );

      if (response.statusCode == 200) {
        print("✅ Đã cộng thêm $addedPoints điểm lên Server");
      } else {
        print("❌ Lỗi Server trả về: ${response.body}");
      }
    } catch (e) {
      print("❌ Lỗi mạng: $e");
    }
  }

  static Future<List<dynamic>> fetchLeaderboard() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/leaderboard'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print("Lỗi lấy BXH: $e");
    }
    return [];
  }

  // --- . CẬP NHẬT HỒ SƠ ---
  static Future<bool> updateProfile({
    required String gender,
    required String phone,
    required String dateOfBirth,
    required String avatar,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/profile'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': UserData.email,
          // Không gửi name vì SV không được sửa tên
          'gender': gender,
          'phone': phone,
          'dateOfBirth': dateOfBirth,
          'avatar': avatar,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();

        // 1. Cập nhật RAM
        UserData.gender = data['gender'];
        UserData.phone = data['phone'] ?? "";
        UserData.dateOfBirth = data['dateOfBirth'] ?? "";
        UserData.avatar = data['avatar'];

        // 2. Cập nhật Local Storage
        await prefs.setString('user_gender', UserData.gender ?? "");
        await prefs.setString('user_phone', UserData.phone ?? "");
        await prefs.setString('user_dob', UserData.dateOfBirth ?? "");
        await prefs.setString('user_avatar', UserData.avatar ?? "");

        return true;
      }
      return false;
    } catch (e) {
      print("❌ Lỗi mạng: $e");
      return false;
    }
  }

  // --- HÀM CỘNG ĐIỂM MỚI ---
  static Future<bool> addPoints(int points) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/add-points'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': UserData.email, 'points': points}),
      );
      print("STATUS CODE: ${response.statusCode}");
      print("RESPONSE BODY: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Cập nhật lại UserData toàn cục ngay lập tức
        UserData.points = data['newPoints'];
        UserData.rank = data['newRank'];
        return true;
      }
      return false;
    } catch (e) {
      print("Lỗi cộng điểm: $e");
      return false;
    }
  }

  static Future<bool> dailyCheckIn() async {
    try {
      final now = DateTime.now();
      final dateStr =
          "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      final response = await http.post(
        Uri.parse('$baseUrl/checkin'), // Route mà chúng ta vừa tạo ở Backend
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': UserData.email, 'date': dateStr}),
      );
      print("STATUS: ${response.statusCode}");
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        UserData.points = data['newPoints'];
        List<dynamic> history = data['attendanceHistory'];
        UserData.attendanceHistory = history.cast<String>().toList();
        return true;
      }
      // TRƯỜNG HỢP 2: ĐÃ ĐIỂM DANH (400) -> VẪN CẬP NHẬT UI
      else if (response.statusCode == 400 &&
          data['attendanceHistory'] != null) {
        // Cập nhật lại lịch sử để UI hiện màu xanh
        List<dynamic> history = data['attendanceHistory'];
        UserData.attendanceHistory = history.cast<String>().toList();

        // Vẫn trả về false để bên UI biết là không được cộng điểm thêm
        return false;
      }

      return false;
    } catch (e) {
      print("Lỗi checkin: $e");
      return false;
    }
  }
}
