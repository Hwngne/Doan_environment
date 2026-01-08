import 'package:flutter/material.dart';
import '../../components/mobile_layout.dart';
import '../../components/club_layout.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import 'change_password_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isObscure = true;

  void _handleLogin() async {
    // A. Kiểm tra nhập liệu
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Vui lòng nhập Email và Mật khẩu"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // B. Hiện loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(child: CircularProgressIndicator()),
    );

    // C. GỌI API
    final result = await AuthService.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    // D. Tắt loading
    if (!mounted) return;
    Navigator.pop(context); // Đóng dialog loading

    // E. Kiểm tra kết quả
    if (result['success'] == true) {
      final String rawRole = result['role'] ?? "student";
      final String role = rawRole.toLowerCase();
      print("🔍 DEBUG FINAL CHECK: Name='${UserData.name}', Role='${UserData.role}'");

      bool isFirstLogin = result['isFirstLogin'] ?? false;

      if (isFirstLogin) {
        // 👉 TRƯỜNG HỢP 1: Lần đầu đăng nhập -> Sang trang Đổi mật khẩu
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ChangePasswordPage()),
        );
      } else {
        if (role == 'club') {
          print("✅ Role is CLUB -> Navigate to ClubLayout");
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const ClubLayout()),
          );
        } else if (role == 'student') {
          // Chỉ vào đây khi role CHÍNH XÁC là 'student'
          print("✅ Role is STUDENT -> Navigate to MobileLayout");
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MobileLayout()),
          );
        } else {
          print(
            " Role không hợp lệ hoặc chưa được cấp quyền trên Mobile: '$role'",
          );

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Lỗi quyền hạn: Role '$role' không được hỗ trợ trên App.",
              ),
              backgroundColor: Colors.redAccent,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } else {
      // Đăng nhập thất bại (Sai pass, user không tồn tại...)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? "Đăng nhập thất bại!"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5FA),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. HEADER CONG MÀU ĐỎ (Giữ nguyên)
            Stack(
              alignment: Alignment.bottomCenter,
              children: [
                ClipPath(
                  clipper: BottomCurveClipper(),
                  child: Container(
                    height: 280,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFFD32F2F), Color(0xFFB71C1C)],
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.eco, size: 80, color: Colors.white),
                          SizedBox(height: 10),
                          Text(
                            "ECO LIFE",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 40),

            // 2. FORM ĐĂNG NHẬP
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Đăng nhập",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C2C54),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Vui lòng đăng nhập để tiếp tục",
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 30),

                  _buildTextField(
                    controller: _emailController,
                    icon: Icons.person_outline,
                    hint: "Email hoặc MSSV",
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    controller: _passwordController,
                    icon: Icons.lock_outline,
                    hint: "Mật khẩu",
                    isPassword: true,
                  ),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        // Có thể làm chức năng quên mật khẩu sau
                      },
                      child: const Text(
                        "Quên mật khẩu?",
                        style: TextStyle(
                          color: Color(0xFFB71C1C),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // NÚT ĐĂNG NHẬP
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2C2C54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 5,
                      ),
                      child: const Text(
                        "ĐĂNG NHẬP",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  // 👇 3. ĐÃ XÓA PHẦN NÚT "ĐĂNG KÝ NGAY" Ở DƯỚI NÀY
                  // Vì User do Admin cấp, không cho tự đăng ký nữa.
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // WIDGET TEXT FIELD (Giữ nguyên logic Mắt thần của bạn)
  Widget _buildTextField({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    bool isPassword = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(
              0.1,
            ), // Sửa lại withOpacity cho tương thích bản cũ nếu cần
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? _isObscure : false,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: const Color(0xFF2C2C54)),
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400]),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 15,
          ),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _isObscure ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _isObscure = !_isObscure;
                    });
                  },
                )
              : null,
        ),
      ),
    );
  }
}

// Custom Clipper (Giữ nguyên)
class BottomCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 50);
    var firstControlPoint = Offset(size.width / 2, size.height);
    var firstEndPoint = Offset(size.width, size.height - 50);
    path.quadraticBezierTo(
      firstControlPoint.dx,
      firstControlPoint.dy,
      firstEndPoint.dx,
      firstEndPoint.dy,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
