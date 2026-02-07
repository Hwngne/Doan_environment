import 'package:flutter/material.dart';
import '../../services/user_service.dart';
import '../../services/earn_service.dart'; 
import '../common/news_detail_page.dart'; 
import 'waste_lookup_page.dart';
import '../../components/banner_slider.dart';
import '../common/earn_points_page.dart';
import '../common/notification_page.dart';

class StudentHome extends StatefulWidget {
  const StudentHome({super.key});

  @override
  State<StudentHome> createState() => _StudentHomeState();
}

class _StudentHomeState extends State<StudentHome> {
  // Biến lưu danh sách bài báo từ API
  List<dynamic> _homeArticles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  // Hàm khởi tạo dữ liệu
  Future<void> _initData() async {
    await UserService.fetchUserInfo();

    // 2. Lấy danh sách bài báo
    final res = await EarnService.getArticles();

    print("LOG API ARTICLES: $res");
    print("LOG LIST RAW: ${res['articles']}");

    if (mounted) {
      setState(() {
        // Lọc bài báo hiển thị cho Home
        List all = res['articles'] ?? [];
        _homeArticles = all
            .where((item) => (item['displayType']) == 'home')
            .toList();
        print("LOG FILTERED: ${_homeArticles.length}");
        _isLoading = false;
      });
    }
  }

  // Hàm refresh khi quay lại từ trang khác
  void _refreshData() {
    _initData();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double screenHeight = size.height;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // HEADER ĐỎ
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.bottomCenter,
              children: [
                Container(
                  height: screenHeight * 0.32,
                  padding: EdgeInsets.fromLTRB(20, screenHeight * 0.08, 20, 80),
                  decoration: const BoxDecoration(
                    color: Color(0xFFB71C1C),
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(35),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // AVATAR (Dữ liệu thật từ UserData)
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          image: DecorationImage(
                            image: NetworkImage(
                              UserData.avatar ?? 'https://i.pravatar.cc/300',
                            ),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // TÊN & ROLE
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "Chào, ${UserData.name ?? 'Bạn'}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              UserData.role ?? 'Student',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // NÚT THÔNG BÁO
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (c) => const NotificationPage(),
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Stack(
                            children: const [
                              Icon(
                                Icons.notifications_outlined,
                                color: Colors.white,
                                size: 24,
                              ),
                              Positioned(
                                right: 0,
                                top: 0,
                                child: CircleAvatar(
                                  radius: 4,
                                  backgroundColor: Colors.redAccent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // THẺ ĐIỂM NỔI
                Positioned(
                  bottom: -30,
                  left: 20,
                  right: 20,
                  child: GestureDetector(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (c) => const EarnPointsPage(),
                        ),
                      );
                      _refreshData(); // Refresh điểm khi quay về
                    },
                    child: Container(
                      height: 80,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A237E),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 15,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  "Điểm tích lũy",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "${UserData.points ?? 0}",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Text(
                                      "💎",
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: Colors.white24,
                          ),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  "Hạng thành viên",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  "${UserData.rank ?? 0}",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: screenHeight * 0.08),

            // NỘI DUNG DƯỚI
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  SizedBox(
                    height: screenHeight * 0.2,
                    child: const BannerSlider(),
                  ),
                  const SizedBox(height: 35),

                  // Nút Tra Cứu
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (c) => const WasteLookupPage(),
                      ),
                    ),
                    child: Container(
                      width: double.infinity,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.search,
                            color: Color(0xFF1A237E),
                            size: 28,
                          ),
                          SizedBox(width: 10),
                          Text(
                            "Tra cứu Trạm thu gom rác",
                            style: TextStyle(
                              color: Color(0xFF1A237E),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // DANH SÁCH BÀI BÁO (Data Thật)
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (_homeArticles.isEmpty)
                    const Text(
                      "Chưa có tin tức mới",
                      style: TextStyle(color: Colors.grey),
                    )
                  else
                    ..._homeArticles.map(
                      (item) => GestureDetector(
                        onTap: () async {
                          // Xử lý ID
                          String articleId = item['_id'] is Map
                              ? item['_id']['\$oid']
                              : item['_id'].toString();
                          // Xử lý Quiz ID (nếu có)
                          String? quizId;
                          if (item['quiz'] != null) {
                            quizId = item['quiz'] is Map
                                ? item['quiz']['\$oid']
                                : item['quiz'].toString();
                          }

                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => NewsDetailPage(
                                id: articleId,
                                title: item['title'],
                                content: item['content'] ?? "",
                                imageUrl: item['thumbnail'] ?? "",
                                displayType: "home", // Type HOME
                                quizId: quizId,
                              ),
                            ),
                          );
                          _refreshData();
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 15),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: const [
                              BoxShadow(color: Colors.black12, blurRadius: 5),
                            ],
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  item['thumbnail'] ?? "",
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) => Container(
                                    width: 80,
                                    height: 80,
                                    color: Colors.grey[300],
                                    child: const Icon(
                                      Icons.broken_image,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['title'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      "Tin tức & Sự kiện",
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
