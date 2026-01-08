import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import '../../data/mock_data.dart';
import '../../components/app_background.dart';
import '../../services/auth_service.dart';

class EarnPointsPage extends StatefulWidget {
  const EarnPointsPage({super.key});

  @override
  State<EarnPointsPage> createState() => _EarnPointsPageState();
}

class _EarnPointsPageState extends State<EarnPointsPage> {
  final int _maxArticles = 3;
  final int _maxQuizzes = 5;

  // --- DỮ LIỆU CÂU HỎI (GIỮ NGUYÊN) ---
  final List<Map<String, dynamic>> _questionBank = [
    {
      "q": "Rác thải nhựa mất bao lâu để phân hủy?",
      "options": ["10 năm", "100 năm", "450 - 1000 năm", "Vĩnh viễn"],
      "answer": 2,
    },
    {
      "q": "3R trong bảo vệ môi trường là gì?",
      "options": [
        "Run, Read, Rest",
        "Reduce, Reuse, Recycle",
        "Red, Rose, Rice",
        "Không có ý nghĩa gì",
      ],
      "answer": 1,
    },
    {
      "q": "Giờ Trái Đất diễn ra vào tháng mấy?",
      "options": ["Tháng 1", "Tháng 3", "Tháng 6", "Tháng 12"],
      "answer": 1,
    },
    {
      "q": "Loại rác nào sau đây CÓ THỂ tái chế?",
      "options": [
        "Tã giấy đã dùng",
        "Vỏ hộp sữa giấy",
        "Khăn giấy ướt",
        "Gốm sứ vỡ",
      ],
      "answer": 1,
    },
    {
      "q": "Pin cũ nên xử lý như thế nào?",
      "options": [
        "Vứt vào thùng rác thường",
        "Chôn xuống đất",
        "Đốt đi",
        "Đưa đến điểm thu gom chuyên dụng",
      ],
      "answer": 3,
    },
  ];

  // --- HÀM HỖ TRỢ NGÀY THÁNG (MỚI) ---

  // 1. Chuyển đổi DateTime sang chuỗi "YYYY-MM-DD" để so sánh với Backend
  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  // 2. Tìm ngày Thứ 2 của tuần hiện tại
  DateTime _getMondayOfWeek(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  // --- HÀM XỬ LÝ ĐIỂM DANH (ĐÃ SỬA LOGIC) ---
  void _handleCheckIn() async {
    String todayStr = _formatDate(DateTime.now());

    // 1. Kiểm tra Client
    if (UserData.attendanceHistory.contains(todayStr)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Hôm nay bạn đã điểm danh rồi!")),
      );
      return;
    }

    // 2. Gọi API
    bool success = await AuthService.dailyCheckIn();

    // 3. Cập nhật UI (Dù thành công hay thất bại do đã điểm danh,
    // thì AuthService cũng đã cập nhật UserData.attendanceHistory rồi)
    setState(() {
      // Hàm này sẽ vẽ lại UI, nếu UserData có ngày hôm nay -> Nó sẽ tự xanh
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Điểm danh thành công! +5 điểm"),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      // Kiểm tra lại lần nữa, nếu trong list đã có ngày hôm nay rồi thì báo "Đã điểm danh" thay vì "Lỗi"
      if (UserData.attendanceHistory.contains(todayStr)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Dữ liệu đã được cập nhật! (Bạn đã điểm danh trước đó)",
            ),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Lỗi kết nối!"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 10,
                bottom: 20,
                left: 10,
                right: 20,
              ),
              color: const Color(0xFFB71C1C),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        "Săn điểm tích lũy",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPointCard(),
                    const SizedBox(height: 25),
                    const Text(
                      "Điểm danh tuần này",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),

                    // --- UI ĐIỂM DANH MỚI ---
                    _buildAttendanceSection(),

                    const SizedBox(height: 25),
                    const Text(
                      "Nhiệm vụ kiếm điểm",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),

                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                      childAspectRatio: 1.1,
                      children: [
                        _buildTaskCard(
                          title: "Đọc báo xanh",
                          subtitle:
                              "(${UserData.articlesReadToday}/$_maxArticles) bài",
                          points: "+10 điểm",
                          icon: Icons.article_outlined,
                          color: Colors.blue,
                          bgColor: Colors.blue.shade50,
                          onTap: () => _handleReadingTask(),
                          isLocked: UserData.articlesReadToday >= _maxArticles,
                        ),
                        _buildTaskCard(
                          title: "Thử tài Quiz",
                          subtitle:
                              "(${UserData.quizzesDoneToday}/$_maxQuizzes) câu",
                          points: "+20 điểm",
                          icon: Icons.quiz_outlined,
                          color: Colors.purple,
                          bgColor: Colors.purple.shade50,
                          onTap: () => _handleQuizTask(),
                          isLocked: UserData.quizzesDoneToday >= _maxQuizzes,
                        ),
                        _buildTaskCard(
                          title: "Xem video",
                          subtitle: "Không được tắt",
                          points: "+15 điểm",
                          icon: Icons.play_circle_outline,
                          color: Colors.red,
                          bgColor: Colors.red.shade50,
                          onTap: () => _handleVideoTask(),
                        ),
                        _buildTaskCard(
                          title: "Vòng quay",
                          subtitle: UserData.hasSpunWheelToday
                              ? "Đã quay hôm nay"
                              : "Thử vận may",
                          points: "Ngẫu nhiên",
                          icon: Icons.donut_large,
                          color: Colors.orange,
                          bgColor: Colors.orange.shade50,
                          onTap: () => _openLuckyWheelGame(),
                          isLocked: UserData.hasSpunWheelToday,
                        ),
                      ],
                    ),
                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- UI ĐIỂM DANH (ĐÃ SỬA ĐỂ KHỚP NGÀY THỰC TẾ) ---
  Widget _buildAttendanceSection() {
    DateTime now = DateTime.now();
    DateTime monday = _getMondayOfWeek(now); // Lấy ngày thứ 2 đầu tuần
    String todayStr = _formatDate(now);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(7, (i) {
        // Tính ngày cho từng ô (Thứ 2 -> CN)
        DateTime dayDate = monday.add(Duration(days: i));
        String dateStr = _formatDate(dayDate); // VD: "2023-11-01"

        // Kiểm tra xem ngày này có trong danh sách đã lưu không
        bool isChecked = UserData.attendanceHistory.contains(dateStr);

        // Kiểm tra có phải hôm nay không
        bool isToday = (dateStr == todayStr);

        String dayLabel = (i == 6) ? "CN" : "T${i + 2}";

        return GestureDetector(
          // Chỉ cho phép bấm nếu là Hôm nay và Chưa tích
          onTap: () => isToday && !isChecked ? _handleCheckIn() : null,
          child: CircleAvatar(
            backgroundColor: isChecked
                ? Colors.green
                : (isToday ? Colors.orange : Colors.grey[200]),
            radius: 18,
            child: isChecked
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : (isToday
                      ? const Icon(
                          Icons.touch_app,
                          size: 16,
                          color: Colors.white,
                        )
                      : Text(
                          dayLabel,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.black54,
                          ),
                        )),
          ),
        );
      }),
    );
  }

  // --- CÁC HÀM XỬ LÝ NHIỆM VỤ KHÁC (GIỮ NGUYÊN) ---

  void _handleReadingTask() {
    if (UserData.articlesReadToday >= _maxArticles) return;
    showModalBottomSheet(
      context: context,
      builder: (c) => Container(
        padding: const EdgeInsets.all(20),
        height: 250,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Chọn bài báo",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 10),
            ListTile(
              leading: const Icon(Icons.eco, color: Colors.green),
              title: const Text("Lợi ích của việc phân loại rác"),
              subtitle: const Text("3 phút đọc"),
              onTap: () {
                Navigator.pop(context);
                _showReadingSimulation("Lợi ích của phân loại rác");
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showReadingSimulation(String title) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => _ReadingDialog(
        title: title,
        onCompleted: () async {
          // Gửi điểm đọc báo
          bool success = await AuthService.addPoints(10); // Dùng addPoints cũ
          if (success) {
            setState(() {
              UserData.articlesReadToday++;
            });
            _showSuccessDialog("Đọc báo", 10);
          }
        },
      ),
    );
  }

  void _handleQuizTask() {
    if (UserData.quizzesDoneToday >= _maxQuizzes) return;
    var q = _questionBank[Random().nextInt(_questionBank.length)];
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        title: const Text("Câu hỏi"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(q['q'], style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 15),
            ...List.generate(
              4,
              (i) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      if (i == q['answer']) {
                        bool success = await AuthService.addPoints(20);
                        if (success) {
                          setState(() {
                            UserData.quizzesDoneToday++;
                          });
                          _showSuccessDialog("Quiz", 20);
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Sai rồi!"),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    child: Text(q['options'][i]),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleVideoTask() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => _VideoTimerDialog(
        onCompleted: () async {
          bool success = await AuthService.addPoints(15);
          if (success) {
            setState(() {});
            _showSuccessDialog("Xem video", 15);
          }
        },
      ),
    );
  }

  void _openLuckyWheelGame() {
    if (UserData.hasSpunWheelToday) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return _LuckyWheelDialog(
          onSpinCompleted: (points) async {
            bool success = await AuthService.addPoints(points);
            if (success) {
              setState(() {
                UserData.hasSpunWheelToday = true;
              });
              _showSuccessDialog("Vòng quay may mắn", points);
            }
          },
        );
      },
    );
  }

  void _showSuccessDialog(String task, int points) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 60),
              const SizedBox(height: 10),
              const Text(
                "Chúc mừng!",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              const SizedBox(height: 5),
              Text("Hoàn thành: $task"),
              const SizedBox(height: 10),
              Text(
                "+$points điểm",
                style: const TextStyle(
                  color: Colors.orange,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB71C1C),
                ),
                child: const Text(
                  "NHẬN ĐIỂM",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPointCard() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C54),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text("Điểm hiện tại", style: TextStyle(color: Colors.white70)),
              SizedBox(height: 5),
              Text(
                "Ví Eco",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Text(
            "${UserData.points} 💎", // Tự động lấy số điểm mới nhất
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard({
    required String title,
    required String subtitle,
    required String points,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
    bool isLocked = false,
  }) {
    return GestureDetector(
      onTap: isLocked ? null : onTap,
      child: Opacity(
        opacity: isLocked ? 0.5 : 1.0,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: isLocked ? Colors.grey[200] : bgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isLocked ? Icons.lock : icon,
                  color: isLocked ? Colors.grey : color,
                  size: 30,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                style: TextStyle(color: Colors.grey[600], fontSize: 10),
              ),
              const SizedBox(height: 5),
              Text(
                points,
                style: TextStyle(
                  color: isLocked ? Colors.grey : color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- CÁC DIALOG GIỮ NGUYÊN NHƯ CŨ ---
class _LuckyWheelDialog extends StatefulWidget {
  final Function(int) onSpinCompleted;
  const _LuckyWheelDialog({required this.onSpinCompleted});
  @override
  State<_LuckyWheelDialog> createState() => _LuckyWheelDialogState();
}

class _LuckyWheelDialogState extends State<_LuckyWheelDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  final Random _random = Random();
  final List<int> _rewards = [5, 10, 20, 50, 100, 0];
  final List<Color> _colors = [
    Colors.green.shade400,
    Colors.orange.shade400,
    Colors.purple.shade400,
    Colors.red.shade400,
    Colors.amber.shade400,
    Colors.grey.shade400,
  ];
  bool _isSpinning = false;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.decelerate);
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _isSpinning = false);
        _calculateReward();
      }
    });
  }

  void _spin() {
    if (_isSpinning) return;
    setState(() => _isSpinning = true);
    double targetAngle = (5 * 2 * pi) + (_random.nextDouble() * 2 * pi);
    _animation = Tween<double>(begin: 0, end: targetAngle).animate(
      CurvedAnimation(parent: _controller, curve: Curves.fastOutSlowIn),
    );
    _controller.forward(from: 0);
  }

  void _calculateReward() {
    double finalAngle = _animation.value % (2 * pi);
    int index = ((2 * pi - finalAngle) / ((2 * pi) / 6)).floor() % 6;
    Future.delayed(const Duration(milliseconds: 500), () {
      Navigator.pop(context);
      widget.onSpinCompleted(_rewards[index]);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(10),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 320,
            height: 320,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: Colors.amber, width: 5),
            ),
          ),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) => Transform.rotate(
              angle: _animation.value,
              child: Container(
                width: 300,
                height: 300,
                decoration: const BoxDecoration(shape: BoxShape.circle),
                child: CustomPaint(
                  painter: _WheelPainter(rewards: _rewards, colors: _colors),
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            child: Transform.translate(
              offset: const Offset(0, 5),
              child: const Icon(
                Icons.arrow_drop_down,
                size: 50,
                color: Colors.black,
              ),
            ),
          ),
          GestureDetector(
            onTap: _spin,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFB71C1C), width: 4),
              ),
              child: Center(
                child: _isSpinning
                    ? const CircularProgressIndicator(color: Color(0xFFB71C1C))
                    : const Text(
                        "QUAY",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFB71C1C),
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WheelPainter extends CustomPainter {
  final List<int> rewards;
  final List<Color> colors;
  _WheelPainter({required this.rewards, required this.colors});
  @override
  void paint(Canvas canvas, Size size) {
    double anglePerSegment = (2 * pi) / rewards.length;
    Offset center = Offset(size.width / 2, size.height / 2);
    double radius = size.width / 2;
    for (int i = 0; i < rewards.length; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        i * anglePerSegment - (pi / 2),
        anglePerSegment,
        true,
        Paint()..color = colors[i],
      );
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        i * anglePerSegment - (pi / 2),
        anglePerSegment,
        true,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      final tp = TextPainter(
        text: TextSpan(
          text: "${rewards[i] == 0 ? 'Lucky' : rewards[i]}",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      double angle = (i * anglePerSegment - (pi / 2)) + (anglePerSegment / 2);
      tp.paint(
        canvas,
        Offset(
          center.dx + (radius * 0.7) * cos(angle) - tp.width / 2,
          center.dy + (radius * 0.7) * sin(angle) - tp.height / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ReadingDialog extends StatefulWidget {
  final String title;
  final VoidCallback onCompleted;
  const _ReadingDialog({required this.title, required this.onCompleted});
  @override
  State<_ReadingDialog> createState() => _ReadingDialogState();
}

class _ReadingDialogState extends State<_ReadingDialog> {
  int _sec = 5;
  late Timer _t;
  bool _ok = false;
  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_sec > 0) {
        setState(() => _sec--);
      } else {
        setState(() => _ok = true);
        _t.cancel();
      }
    });
  }

  @override
  void dispose() {
    _t.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    title: Text(widget.title),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text("Vui lòng đọc bài viết..."),
        const SizedBox(height: 20),
        _ok
            ? const Icon(Icons.verified, color: Colors.green, size: 50)
            : CircularProgressIndicator(value: 1 - (_sec / 5)),
        const SizedBox(height: 10),
        Text(_ok ? "Hoàn thành!" : "Còn $_sec giây"),
      ],
    ),
    actions: [
      TextButton(
        onPressed: _ok
            ? () {
                Navigator.pop(context);
                widget.onCompleted();
              }
            : null,
        child: Text(
          "NHẬN ĐIỂM",
          style: TextStyle(color: _ok ? Colors.green : Colors.grey),
        ),
      ),
    ],
  );
}

class _VideoTimerDialog extends StatefulWidget {
  final VoidCallback onCompleted;
  const _VideoTimerDialog({required this.onCompleted});
  @override
  State<_VideoTimerDialog> createState() => _VideoDialogState();
}

class _VideoDialogState extends State<_VideoTimerDialog> {
  int _sec = 5;
  late Timer _t;
  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_sec > 0) {
        setState(() => _sec--);
      } else {
        _t.cancel();
        Navigator.pop(context);
        widget.onCompleted();
      }
    });
  }

  @override
  void dispose() {
    _t.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: Colors.black,
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.play_circle_fill, color: Colors.white, size: 50),
        const SizedBox(height: 20),
        Text("Quảng cáo $_sec s", style: const TextStyle(color: Colors.white)),
      ],
    ),
  );
}
