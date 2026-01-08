//import 'dart:convert';
//import 'package:http/http.dart' as http;

// ==========================================
// 1. CLASS USERDATA (KHO DỮ LIỆU TOÀN CỤC)
// ==========================================
// Đây là nơi lưu trữ dữ liệu sau khi xử lý xong (dù là từ API hay Mock)
// Các trang FE (Profile, Home) sẽ lấy dữ liệu từ đây để hiển thị
class UserData {
  static String? token;
  static String? role; // Quan trọng: dùng để phân luồng 'student' hay 'club'
  static String? email;
  static String? name;
  static String? avatar;
  static String? studentId;
  static String? phone;
  static String? gender;
  static String? dateOfBirth;
  static List<String> attendanceHistory = [];

  // Điểm số
  static int? points;
  static int? totalScore;
  static int? rank;

  // Hàm xóa dữ liệu khi đăng xuất
  static void clear() {
    token = null;
    role = null;
    email = null;
    name = null;
    avatar = null;
    points = null;
    studentId = null;
    phone = null;
    gender = null;
    dateOfBirth = null;
    totalScore = null;
  }
}

// ==========================================
// 2. CLASS USERSERVICE (XỬ LÝ LOGIC)
// ==========================================
class UserService {
  // Hàm cập nhật Profile
  // Logic: Giữ nguyên cách bạn đang làm (Giả lập hoặc gọi API thật tùy bạn đã cài đặt)
  // Nhưng quan trọng: Phải cập nhật ngược lại vào class UserData ở trên
  Future<bool> updateUserProfile(
    String name,
    String dob,
    String gender,
    String phone,
  ) async {
    try {
      // 1. Giả lập độ trễ (như code cũ của bạn)
      await Future.delayed(const Duration(seconds: 2));
      print("Processing Update Profile: $name, $dob, $gender, $phone");

      // --- NẾU BẠN ĐANG DÙNG API THÌ BỎ COMMENT PHẦN NÀY ---
      /*
      final url = Uri.parse('YOUR_API_URL/profile');
      final response = await http.put(url, body: {...});
      if (response.statusCode != 200) return false;
      */
      // -----------------------------------------------------

      // 2. CẬP NHẬT DỮ LIỆU VÀO KHO (QUAN TRỌNG)
      // Dù là lưu xuống DB hay không, ta phải cập nhật vào UserData
      // để màn hình ProfilePage hiển thị thông tin mới ngay lập tức.
      UserData.name = name;
      UserData.dateOfBirth = dob;
      UserData.gender = gender;
      UserData.phone = phone;

      // 3. Trả về thành công
      return true;
    } catch (e) {
      print("Lỗi update: $e");
      return false;
    }
  }

  // Các hàm khác của Sinh viên (Đăng bài, Xếp hạng...)
  // Bạn giữ nguyên logic cũ của bạn ở đây.
}
