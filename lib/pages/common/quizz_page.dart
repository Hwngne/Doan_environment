import 'package:flutter/material.dart';
import '../../data/mock_data.dart';
import '../../services/auth_service.dart'; // <--- Import Service

class QuizPage extends StatefulWidget {
  final String articleTitle;
  final List<QuizQuestion> questions;

  const QuizPage({
    super.key,
    required this.articleTitle,
    required this.questions,
  });

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  int _currentIndex = 0;
  int _score = 0;
  int? _selectedAnswerIndex;
  bool _isAnswered = false;
  bool _isSaving = false; // Biến trạng thái đang lưu điểm

  void _answerQuestion(int index) {
    if (_isAnswered) return;

    setState(() {
      _selectedAnswerIndex = index;
      _isAnswered = true;
      if (index == widget.questions[_currentIndex].correctAnswerIndex) {
        _score++;
      }
    });

    Future.delayed(const Duration(seconds: 1), () {
      if (_currentIndex < widget.questions.length - 1) {
        setState(() {
          _currentIndex++;
          _selectedAnswerIndex = null;
          _isAnswered = false;
        });
      } else {
        _finishQuiz();
      }
    });
  }

  // --- LOGIC KẾT THÚC & CỘNG ĐIỂM THẬT ---
  Future<void> _finishQuiz() async {
    int passingScore = 3;

    if (_score >= passingScore) {
      // 1. Hiện dialog loading hoặc chờ xử lý
      setState(
        () => _isSaving = true,
      ); // (Optional: dùng để hiện loading nếu muốn)

      // 2. Gọi API cộng điểm thật (20 điểm)
      bool success = await AuthService.addPoints(20);

      // 3. Cập nhật thống kê cục bộ
      UserData.quizzesDoneToday++;

      if (success) {
        // Hiện popup chúc mừng
        if (mounted) _showRewardDialog();
      } else {
        // Lỗi mạng vẫn cho qua nhưng báo lỗi nhẹ (hoặc xử lý tùy ý)
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Lỗi kết nối! Điểm chưa được lưu.")),
          );
          _showRewardDialog(); // Vẫn hiện để không cụt hứng user
        }
      }
    } else {
      _showFailDialog();
    }
  }

  // DIALOG 1: NHẬN KIM CƯƠNG
  void _showRewardDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFF0F0), Colors.white],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.diamond, color: Colors.amber, size: 60),
              const SizedBox(height: 10),
              const Text(
                "Cộng điểm tích lũy",
                style: TextStyle(color: Colors.grey),
              ),
              const Text(
                "20",
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C2C54),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showSuccessResultDialog();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB71C1C),
                ),
                child: const Text(
                  "Tiếp tục",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // DIALOG 2: KẾT QUẢ THÀNH CÔNG
  void _showSuccessResultDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
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
                "Hoàn thành bài quiz",
                style: TextStyle(color: Colors.grey),
              ),
              Text(
                "$_score/${widget.questions.length}",
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C2C54),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Xuất sắc! Điểm đã được cộng vào ví.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.green),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB71C1C),
                ),
                child: const Text("OK", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // DIALOG 3: THẤT BẠI (Giữ nguyên)
  void _showFailDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cancel, color: Colors.red, size: 60),
              const SizedBox(height: 10),
              const Text(
                "Chưa đạt yêu cầu",
                style: TextStyle(color: Colors.grey),
              ),
              Text(
                "$_score/${widget.questions.length}",
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C2C54),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Bạn cần đúng ít nhất 3 câu để nhận điểm.\nHãy thử lại nhé!",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.redAccent),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2C2C54),
                ),
                child: const Text(
                  "Đóng",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  @override
  Widget build(BuildContext context) {
    final question = widget.questions[_currentIndex];
    // --- PHẦN GIAO DIỆN CHÍNH ---
    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFFF5F5FA),
          appBar: AppBar(
            backgroundColor: const Color(0xFFB71C1C),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              widget.articleTitle,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            centerTitle: true,
          ),
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Khung câu hỏi
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C2C54),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        "Câu hỏi ${_currentIndex + 1} / ${widget.questions.length}",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 15),
                      Text(
                        question.question,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // Danh sách đáp án
                ...List.generate(question.options.length, (index) {
                  Color bgColor = Colors.white;
                  Color borderColor = Colors.transparent;
                  Color textColor = Colors.black87;
                  Widget? icon;

                  if (_isAnswered) {
                    if (index == question.correctAnswerIndex) {
                      bgColor = Colors.green.shade50;
                      borderColor = Colors.green;
                      textColor = Colors.green;
                      icon = const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 20,
                      );
                    } else if (index == _selectedAnswerIndex) {
                      bgColor = Colors.red.shade50;
                      borderColor = Colors.red;
                      textColor = Colors.red;
                      icon = const Icon(
                        Icons.cancel,
                        color: Colors.red,
                        size: 20,
                      );
                    }
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 15),
                    child: GestureDetector(
                      onTap: () => _answerQuestion(index),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 15,
                          horizontal: 20,
                        ),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: borderColor == Colors.transparent
                                ? Colors.grey.shade300
                                : borderColor,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withValues(alpha: 0.1),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              question.options[index],
                              style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (icon != null) icon,
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        // Hiển thị lớp phủ loading khi đang lưu điểm
        if (_isSaving)
          Container(
            color: Colors.black.withValues(alpha: 0.5),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 15),
                  Text(
                    "Đang cộng điểm...",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
