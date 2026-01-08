import 'package:flutter/material.dart';
import '../../data/mock_data.dart'
    hide UserData; // Để lấy thông tin User hiện tại
import '../../services/auth_service.dart';
import '../../services/user_service.dart';

class RankPage extends StatefulWidget {
  const RankPage({super.key});

  @override
  State<RankPage> createState() => _RankPageState();
}

class _RankPageState extends State<RankPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _displayList = [];

  // Dữ liệu giả lập (Backup)
  final List<Map<String, dynamic>> _mockBackupData = [
    {
      "name": "Trần Minh Tâm",
      "points": 9800,
      "avatar": "https://i.pravatar.cc/150?u=1",
    },
    {
      "name": "Lê Bảo Châu",
      "points": 8500,
      "avatar": "https://i.pravatar.cc/150?u=2",
    },
    {
      "name": "Phạm Văn Đức",
      "points": 7200,
      "avatar": "https://i.pravatar.cc/150?u=3",
    },
    {
      "name": "Nguyễn Thị Mai",
      "points": 6500,
      "avatar": "https://i.pravatar.cc/150?u=4",
    },
    {
      "name": "Hoàng Quốc Việt",
      "points": 6000,
      "avatar": "https://i.pravatar.cc/150?u=5",
    },
    {
      "name": "Vũ Thu Hà",
      "points": 5500,
      "avatar": "https://i.pravatar.cc/150?u=6",
    },
    {
      "name": "Đặng Ngọc Ánh",
      "points": 5000,
      "avatar": "https://i.pravatar.cc/150?u=7",
    },
    {
      "name": "Bùi Tiến Dũng",
      "points": 4500,
      "avatar": "https://i.pravatar.cc/150?u=8",
    },
    {
      "name": "Đỗ Mỹ Linh",
      "points": 4200,
      "avatar": "https://i.pravatar.cc/150?u=9",
    },
    {
      "name": "Ngô Kiến Huy",
      "points": 3800,
      "avatar": "https://i.pravatar.cc/150?u=10",
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // --- HÀM LOAD DỮ LIỆU (CÓ FIX LỖI HIỂN THỊ 0 ĐIỂM) ---
  Future<void> _loadData() async {
    List<dynamic> serverData = await AuthService.fetchLeaderboard();
    List<Map<String, dynamic>> combinedList = [];

    // 1. Map dữ liệu server
    for (var user in serverData) {
      int score =
          (user['totalScore'] != null &&
              int.parse(user['totalScore'].toString()) > 0)
          ? int.parse(user['totalScore'].toString())
          : int.parse((user['points'] ?? 0).toString());

      combinedList.add({
        "name": user['name'] ?? "Unknown",
        "points": score,
        "avatar": user['avatar'] ?? "https://i.pravatar.cc/150",
      });
    }

    // 2. Bù Mock Data nếu thiếu
    if (combinedList.length < 10) {
      int itemsNeeded = 10 - combinedList.length;
      for (int i = 0; i < itemsNeeded; i++) {
        if (i < _mockBackupData.length) {
          combinedList.add(_mockBackupData[i]);
        }
      }
    }

    // 3. Gán Rank và ĐỒNG BỘ ĐIỂM CỦA TÔI
    bool foundMe = false;
    for (int i = 0; i < combinedList.length; i++) {
      combinedList[i]['rank'] = i + 1;

      // 👇 NẾU LÀ TÔI: Ép điểm hiển thị phải giống UserData.points (để không bị hiện số 0)
      if (combinedList[i]['name'] == UserData.name) {
        UserData.rank = i + 1;

        // --- FIX LỖI 1: Cập nhật điểm trong list bằng điểm thật trong máy ---
        combinedList[i]['points'] = UserData.points;
        // ------------------------------------------------------------------

        foundMe = true;
      }
    }

    if (!foundMe) {
      UserData.rank = 125;
    }

    if (mounted) {
      setState(() {
        _displayList = combinedList;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFB71C1C)),
        ),
      );
    }

    final top1 = _displayList[0];
    final top2 = _displayList[1];
    final top3 = _displayList[2];
    final restOfList = _displayList.sublist(3);

    return Scaffold(
      body: Stack(
        children: [
          // 1. BACKGROUND
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFB71C1C), Color(0xFFFCE4EC), Colors.white],
                stops: [0.0, 0.4, 1.0],
              ),
            ),
          ),

          // 2. NỘI DUNG
          Column(
            children: [
              // Header
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundImage: NetworkImage(
                          UserData.avatar ?? "https://i.pravatar.cc/150",
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Chào, ${UserData.name}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const Text(
                            "Sinh viên",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(
                          Icons.notifications,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Top 3 Podium
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildPodiumItem(top2, 2, 90, const Color(0xFFC0C0C0)),
                    _buildPodiumItem(top1, 1, 110, const Color(0xFFFFD700)),
                    _buildPodiumItem(top3, 3, 90, const Color(0xFFCD7F32)),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // List còn lại
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                  ),
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 20, bottom: 100),
                    itemCount: restOfList.length,
                    itemBuilder: (context, index) {
                      return _buildRankItem(restOfList[index]);
                    },
                  ),
                ),
              ),
            ],
          ),

          // 3. THANH HẠNG CỦA TÔI (ĐÃ SỬA GIAO DIỆN)
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              decoration: BoxDecoration(
                color: const Color(0xFF536DFE),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Text(
                    "Hạng ", // Giữ chữ Hạng ở label nếu muốn, hoặc bỏ tùy ý
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  Text(
                    "${UserData.rank}", // --- FIX LỖI 2: Chỉ hiện số (VD: 3) ---
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18, // Cho số to lên một chút
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    "Điểm tích lũy: ",
                    style: TextStyle(color: Colors.white70),
                  ),
                  Text(
                    "${UserData.points}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET PODIUM (GIỮ NGUYÊN) ---
  Widget _buildPodiumItem(
    Map<String, dynamic> user,
    int rank,
    double avatarSize,
    Color color,
  ) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (rank == 1)
            const Icon(Icons.emoji_events, color: Colors.yellow, size: 30),
          const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 3),
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 10),
              ],
            ),
            child: CircleAvatar(
              radius: avatarSize / 3,
              backgroundImage: NetworkImage(user['avatar']),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            height: rank == 1 ? 140 : (rank == 2 ? 110 : 90),
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(15),
              ),
              border: Border.all(color: color.withValues(alpha: 0.5)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "$rank",
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w900,
                    fontSize: 30,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  user['name'],
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                Text(
                  "${user['points']}",
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET LIST ITEM (GIỮ NGUYÊN) ---
  Widget _buildRankItem(Map<String, dynamic> user) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9C4).withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text(
              "${user['rank']}",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ),
          CircleAvatar(
            radius: 20,
            backgroundImage: NetworkImage(user['avatar']),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              user['name'],
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Color(0xFF333333),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                "Điểm tích lũy",
                style: TextStyle(fontSize: 10, color: Colors.grey),
              ),
              Text(
                "${user['points']}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFFB71C1C),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
