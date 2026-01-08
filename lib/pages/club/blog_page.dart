import 'package:flutter/material.dart';
import '../../services/user_service.dart';
import '../../services/forum_service.dart';
import '../../data/mock_data.dart' hide UserData, ForumPost;

class BlogPage extends StatefulWidget {
  const BlogPage({super.key});

  @override
  State<BlogPage> createState() => _BlogPageState();
}

class _BlogPageState extends State<BlogPage> {
  List<ForumPost> _myPosts = [];
  bool _isLoading = true;
  String _selectedFilter = "All"; // All, Kiến thức, Sản phẩm, Sự kiện

  @override
  void initState() {
    super.initState();
    _loadMyPosts();
  }

  // Lấy bài viết và lọc chỉ lấy bài của CLB mình
  Future<void> _loadMyPosts() async {
    setState(() => _isLoading = true);
    // Gọi API lấy tất cả bài viết
    List<ForumPost> allPosts = await ForumService.fetchPosts();

    // Lọc: Chỉ lấy bài nào có authorName trùng với tên CLB đang đăng nhập
    // (Hoặc lọc theo email nếu backend hỗ trợ)
    List<ForumPost> myPosts = allPosts.where((post) {
      return post.authorName == UserData.name;
    }).toList();

    if (mounted) {
      setState(() {
        _myPosts = myPosts;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Logic lọc bài viết
    final displayPosts = _myPosts.where((post) {
      if (_selectedFilter == "All") return true;
      return post.tagName == _selectedFilter;
    }).toList();

    return Scaffold(
      // AppBar giữ nguyên màu đỏ
      appBar: AppBar(
        backgroundColor: const Color(0xFFB71C1C),
        centerTitle: true,
        title: Text(
          (UserData.name ?? "CLB").toUpperCase(),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {}, // Xử lý back nếu cần
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz, color: Colors.white),
            onPressed: () {},
          ),
        ],
        elevation: 0,
      ),
      body: Column(
        children: [
          // 1. HEADER PROFILE (Đỏ -> Hồng nhạt)
          Container(
            padding: const EdgeInsets.only(bottom: 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFB71C1C), // Đỏ đậm
                  Color(
                    0xFFF3DDDD,
                  ), // 👇 Chuyển sang màu Hồng nhạt (để khớp với body)
                ],
                stops: [0.0, 0.4],
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 10),
                // Avatar
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: NetworkImage(
                      UserData.avatar ?? "https://i.pravatar.cc/300",
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Tên & Role
                Text(
                  UserData.name ?? "Thế Hệ Xanh",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C2C54),
                  ),
                ),
                const Text(
                  "Câu Lạc Bộ",
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),

                const SizedBox(height: 20),

                // Filter Tabs
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildFilterButton("Kiến thức", Colors.blue),
                      const SizedBox(width: 10),
                      _buildFilterButton("Sản phẩm", const Color(0xFF009688)),
                      const SizedBox(width: 10),
                      _buildFilterButton("Sự kiện", Colors.orange),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 2. DANH SÁCH BÀI VIẾT (Nền Gradient chuẩn)
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  stops: [0.0, 0.54, 1.0],
                  colors: [
                    Color(0xFFF3DDDD), // Hồng nhạt
                    Color(0xFFFFFFFF), // Trắng
                    Color(0xFFE5EFFF), // Xanh nhạt
                  ],
                ),
              ),
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFB71C1C),
                      ),
                    )
                  : displayPosts.isEmpty
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.post_add, size: 60, color: Colors.grey[400]),
                        const SizedBox(height: 10),
                        Text(
                          "Chưa có bài viết ${_selectedFilter != 'All' ? 'thuộc mục $_selectedFilter' : ''}",
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 10,
                      ),
                      itemCount: displayPosts.length,
                      itemBuilder: (context, index) {
                        return _buildPostItem(displayPosts[index]);
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET NÚT LỌC (Filter Button) ---
  Widget _buildFilterButton(String label, Color color) {
    bool isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          // Nếu đang chọn rồi thì bỏ chọn (về All), ngược lại thì chọn
          _selectedFilter = isSelected ? "All" : label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? color
              : color.withOpacity(0.1), // Chọn thì đậm, không thì nhạt
          borderRadius: BorderRadius.circular(25),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : color, // Chữ trắng hoặc màu theo theme
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // --- WIDGET BÀI VIẾT (Style riêng cho Blog) ---
  Widget _buildPostItem(ForumPost post) {
    Color tagColor = Colors.grey;
    if (post.tagName == "Kiến thức") tagColor = Colors.blue;
    if (post.tagName == "Sản phẩm") tagColor = const Color(0xFF009688);
    if (post.tagName == "Sự kiện") tagColor = Colors.orange;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.white),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header bài viết nhỏ
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundImage: NetworkImage(post.authorAvatar),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        post.authorName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        post.time,
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ),
                  // Tag nằm ngay dưới tên
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: tagColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "CLB",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(width: 1, height: 10, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          post.tagName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Tiêu đề/Nội dung
          Text(
            post.content, // Nếu có Title riêng thì dùng title, ở đây dùng content tạm
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 15, height: 1.4),
          ),

          // Ảnh bài viết (Nếu có)
          if (post.image != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  post.image!,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => Container(
                    height: 180,
                    color: Colors.grey[200],
                    child: const Icon(Icons.broken_image),
                  ),
                ),
              ),
            ),

          // Thanh tương tác (Like/Comment)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              children: [
                Icon(
                  post.isLiked ? Icons.favorite : Icons.favorite_border,
                  size: 20,
                  color: post.isLiked ? Colors.red : Colors.grey,
                ),
                const SizedBox(width: 5),
                Text("${post.likes}"),
                const SizedBox(width: 20),
                const Icon(
                  Icons.chat_bubble_outline,
                  size: 20,
                  color: Colors.grey,
                ),
                const SizedBox(width: 5),
                Text("${post.comments}"),

                const Spacer(),
                const Icon(
                  Icons.share,
                  size: 20,
                  color: Colors.grey,
                ), // Nút share giả
              ],
            ),
          ),
        ],
      ),
    );
  }
}
