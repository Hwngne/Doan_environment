import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import '../../data/mock_data.dart';
import '../../components/app_background.dart';
import '../../services/auth_service.dart';
import '../../services/earn_service.dart';
import '../common/quizz_page.dart';
import '../common/news_detail_page.dart';
import '../common/video_watch_page.dart';

class EarnPointsPage extends StatefulWidget {
  const EarnPointsPage({super.key});

  @override
  State<EarnPointsPage> createState() => _EarnPointsPageState();
}

class _EarnPointsPageState extends State<EarnPointsPage> {
  int _displayArticlePoints = 10;
  int _displayQuizPoints = 20;
  final int _maxArticles = 3;
  final int _maxQuizzes = 3;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  // --- HÀM ĐỒNG BỘ DỮ LIỆU ---
  Future<void> _fetchUserData() async {
    final data = await AuthService.fetchUserInfo();
    final articleRes = await EarnService.getArticles();
    final quizRes = await EarnService.getQuizzes();
    final videoRes = await EarnService.getVideos();

    if (mounted) {
      setState(() {
        if (data != null) {
          if (data['points'] != null) {
            UserData.points = int.tryParse(data['points'].toString()) ?? 0;
          }
          if (data['attendanceHistory'] != null) {
            UserData.attendanceHistory = List<String>.from(
              data['attendanceHistory'],
            );
          }
          UserData.hasSpunWheelToday = data['hasSpunToday'] ?? false;
        }

        UserData.articlesReadToday = articleRes['readToday'] ?? 0;
        UserData.quizzesDoneToday = quizRes['doneToday'] ?? 0;
        UserData.videosWatchedToday = videoRes['doneToday'] ?? 0;

        List aList = articleRes['articles'] ?? [];
        if (aList.isNotEmpty) {
          _displayArticlePoints = aList[0]['bonusPoints'] ?? 10;
        }

        List qList = quizRes['quizzes'] ?? [];
        if (qList.isNotEmpty) {
          _displayQuizPoints = qList[0]['max_points'] ?? 20;
        }

        _isLoading = false;
      });
    }
  }

  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  DateTime _getMondayOfWeek(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  // --- 1. XỬ LÝ ĐIỂM DANH (Giữ nguyên) ---
  void _handleCheckIn() async {
    String todayStr = _formatDate(DateTime.now());

    if (UserData.attendanceHistory.contains(todayStr)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Hôm nay bạn đã điểm danh rồi!")),
      );
      return;
    }
    final result = await AuthService.dailyCheckIn();
    bool success = result != null && result['success'] == true;

    if (success) {
      UserData.attendanceHistory.add(todayStr);

      UserData.points += 5;

      if (mounted) {
        setState(() {});
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Điểm danh thành công! +5 điểm"),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      if (UserData.attendanceHistory.contains(todayStr)) {
        UserData.attendanceHistory.add(todayStr);
        if (mounted) setState(() {});

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Bạn đã điểm danh trước đó."),
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

  // --- 2. XỬ LÝ ĐỌC BÁO (TÍCH HỢP NEWS DETAIL PAGE) ---
  void _handleReadingTask() async {
    // 1. Loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(child: CircularProgressIndicator()),
    );

    // 2. Gọi API
    Map<String, dynamic> result = await EarnService.getArticles();
    List<dynamic> articles = (result['articles'] is List)
        ? List<dynamic>.from(
            result['articles'],
          ).where((item) => item['displayType'] == 'hunt').toList()
        : <dynamic>[];
    int readToday = result['readToday'] ?? 0;

    if (mounted) {
      Navigator.pop(context); // Tắt loading
      setState(() {
        UserData.articlesReadToday = readToday;
      });
    }

    if (articles.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Chưa có bài báo nào mới!")));
      return;
    }

    // 3. Hiển thị danh sách
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (c) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Tin tức môi trường",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              const SizedBox(height: 15),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  itemCount: articles.length,
                  separatorBuilder: (c, i) => const Divider(),
                  itemBuilder: (context, index) {
                    final article = articles[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          article['thumbnail'] ??
                              'https://via.placeholder.com/150',
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => const Icon(
                            Icons.article,
                            color: Colors.green,
                            size: 40,
                          ),
                        ),
                      ),
                      title: Text(
                        article['title'],
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        // Hiển thị điểm theo config Global
                        "Đọc ngay • +$_displayArticlePoints điểm",
                        style: const TextStyle(color: Colors.green),
                      ),
                      onTap: () {
                        Navigator.pop(context); // Đóng BottomSheet

                        // Xử lý ID an toàn
                        String articleId = article['_id'] is Map
                            ? article['_id']['\$oid']
                            : article['_id'].toString();

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => NewsDetailPage(
                              id: articleId,
                              title: article['title'],
                              content: article['content'] ?? "",
                              imageUrl: article['thumbnail'] ?? "",

                              displayType: "hunt",
                              readingTime: 15,
                              bonusPoints: _displayArticlePoints,
                            ),
                          ),
                        ).then((_) {
                          _fetchUserData();
                        });
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- 3. XỬ LÝ QUIZ ---
  void _handleQuizTask() async {
    if (UserData.quizzesDoneToday >= _maxQuizzes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Bạn đã hoàn thành đủ 3 bộ đề hôm nay!")),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(child: CircularProgressIndicator()),
    );

    Map<String, dynamic> result = await EarnService.getQuizzes();
    List<dynamic> quizzes = result['quizzes'] ?? [];
    int doneToday = result['doneToday'] ?? 0;

    Navigator.pop(context);

    if (mounted) {
      setState(() {
        UserData.quizzesDoneToday = doneToday;
      });
    }

    if (quizzes.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Chưa có bộ đề nào mới!")));
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (c) => Container(
        padding: const EdgeInsets.all(20),
        height: 500,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Chọn bộ đề thi",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
                Text(
                  "Đã làm: $doneToday/$_maxQuizzes",
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Expanded(
              child: ListView.separated(
                itemCount: quizzes.length,
                separatorBuilder: (c, i) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final quiz = quizzes[index];
                  List qs = quiz['questions'] ?? [];

                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.purple.shade100,
                        child: const Icon(
                          Icons.help_outline,
                          color: Colors.purple,
                        ),
                      ),
                      title: Text(
                        quiz['title'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        "${qs.length} câu hỏi • +${quiz['max_points'] ?? 20} điểm",
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey,
                      ),
                      onTap: () {
                        Navigator.pop(context);

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => QuizPage(quizData: quiz),
                          ),
                        ).then((_) {
                          _fetchUserData();
                        });
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 4. XỬ LÝ VIDEO  ---
  void _handleVideoTask() async {
    if (UserData.videosWatchedToday >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Hôm nay bạn đã xem đủ 3 video rồi!")),
      );
      return;
    }
    // 2. Hiện Loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(child: CircularProgressIndicator()),
    );

    Map<String, dynamic> result = await EarnService.getVideos();
    if (mounted) Navigator.pop(context);
    List<dynamic> videos = result['videos'] ?? [];
    int doneToday = result['doneToday'] ?? 0;

    if (mounted) {
      setState(() {
        UserData.videosWatchedToday = doneToday;
      });
    }

    if (doneToday >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Hôm nay bạn đã xem đủ 3 video! Hãy quay lại ngày mai.",
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (videos.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Chưa có video nào mới!")));
      return;
    }

    // 3. HIỂN THỊ DANH SÁCH VIDEO (BOTTOM SHEET)
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (c) => Container(
        height: MediaQuery.of(context).size.height * 0.75, // Cao 75% màn hình
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Color(0xFFF5F5FA),
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thanh gạch ngang nhỏ trang trí
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              "Thư viện Video xanh",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: Color(0xFF2D3142),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              "Xem hết video để nhận thưởng ngay",
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 20),

            // DANH SÁCH
            Expanded(
              child: ListView.separated(
                itemCount: videos.length,
                separatorBuilder: (c, i) => const SizedBox(height: 15),
                itemBuilder: (context, index) {
                  final video = videos[index];

                  // Map dữ liệu an toàn từ JSON
                  String title = video['title'] ?? "Video không tiêu đề";
                  String thumb = video['thumbnailUrl'] ?? "";
                  String url = video['videoUrl'] ?? "";
                  int bonus = video['bonusPoints'] ?? 15;
                  int views = video['views'] ?? 0;

                  return GestureDetector(
                    onTap: () async {
                      Navigator.pop(context);

                      String videoId = video['_id'] is Map
                          ? video['_id']['\$oid']
                          : video['_id'].toString();

                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => VideoWatchPage(
                            videoId: videoId,
                            videoUrl: url,
                            title: title,
                            bonusPoints: bonus,
                          ),
                        ),
                      );

                      if (result == true && mounted) {
                        setState(() {
                          UserData.points += bonus;
                          UserData.videosWatchedToday++;
                        });
                        _fetchUserData();
                        _showRewardDialog(bonus, "Thưởng xem video");
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Thumbnail Image
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(15),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Image.network(
                                  thumb,
                                  height: 180,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) => Container(
                                    height: 180,
                                    color: Colors.grey[300],
                                    child: const Icon(
                                      Icons.videocam_off,
                                      color: Colors.grey,
                                      size: 40,
                                    ),
                                  ),
                                ),
                                // Nút Play overlay
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.6),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.play_arrow,
                                    color: Colors.white,
                                    size: 30,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Thông tin bên dưới
                          Padding(
                            padding: const EdgeInsets.all(15),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    height: 1.3,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.stars,
                                            size: 14,
                                            color: Colors.orange,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            "+$bonus điểm",
                                            style: const TextStyle(
                                              color: Colors.orange,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Spacer(),
                                    Icon(
                                      Icons.remove_red_eye,
                                      size: 14,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      "$views lượt xem",
                                      style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 5. XỬ LÝ VÒNG QUAY (GIỮ NGUYÊN) ---
  void _openLuckyWheelGame() {
    if (UserData.hasSpunWheelToday) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Hôm nay bạn đã thử vận may rồi!")),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return _LuckyWheelDialog(
          onSpinCompleted: (points) async {
            bool success = await EarnService.saveSpinResult(points);

            if (success && mounted) {
              setState(() {
                UserData.hasSpunWheelToday = true;
                UserData.points += points;
              });
              _showSuccessDialog("Vòng quay may mắn", points);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Lỗi kết nối, vui lòng thử lại!")),
              );
            }
          },
        );
      },
    );
  }

  // --- UI DIALOG THÔNG BÁO ---
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

  void _showRewardDialog(int points, String title) {
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
              Text(
                title, // Ví dụ: "Xem video xong"
                style: const TextStyle(color: Colors.grey),
              ),
              Text(
                "+$points",
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C2C54),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Tắt Dialog
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB71C1C),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 10,
                  ),
                ),
                child: const Text(
                  "Nhận",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: Column(
          children: [
            // HEADER
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
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
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
                                points: "+$_displayArticlePoints điểm",
                                icon: Icons.article_outlined,
                                color: Colors.blue,
                                bgColor: Colors.blue.shade50,
                                onTap: () => _handleReadingTask(),
                                isLocked:
                                    UserData.articlesReadToday >= _maxArticles,
                              ),
                              _buildTaskCard(
                                title: "Thử tài Quiz",
                                subtitle:
                                    "(${UserData.quizzesDoneToday}/$_maxQuizzes) câu",
                                points: "+$_displayQuizPoints điểm",
                                icon: Icons.quiz_outlined,
                                color: Colors.purple,
                                bgColor: Colors.purple.shade50,
                                onTap: () => _handleQuizTask(),
                                isLocked:
                                    UserData.quizzesDoneToday >= _maxQuizzes,
                              ),
                              _buildTaskCard(
                                title: "Xem video",
                                subtitle:
                                    "(${UserData.videosWatchedToday}/3) video",
                                points: "+15 điểm", // Hoặc "Ngẫu nhiên"
                                icon: Icons.play_circle_outline,
                                color: Colors.red,
                                bgColor: Colors.red.shade50,
                                onTap: () => _handleVideoTask(),
                                // Khóa nút nếu đã xem đủ 3
                                isLocked: UserData.videosWatchedToday >= 3,
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

  // --- UI COMPONENTS GIỮ NGUYÊN ---
  Widget _buildAttendanceSection() {
    DateTime now = DateTime.now();
    DateTime monday = _getMondayOfWeek(now);
    String todayStr = _formatDate(now);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(7, (i) {
        DateTime dayDate = monday.add(Duration(days: i));
        String dateStr = _formatDate(dayDate);
        bool isChecked = UserData.attendanceHistory.contains(dateStr);
        bool isToday = (dateStr == todayStr);
        String dayLabel = (i == 6) ? "CN" : "T${i + 2}";

        return GestureDetector(
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
            "${UserData.points} 💎",
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
