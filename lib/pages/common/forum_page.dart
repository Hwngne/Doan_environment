import 'package:flutter/material.dart';
import '../../components/banner_slider.dart';
import 'create_post_page.dart';
import '../common/chat_list_page.dart';
import '../common/chat_detail_page.dart';
import '../../services/forum_service.dart';
import '../../services/user_service.dart';
import 'package:url_launcher/url_launcher.dart';
import '../club/create_event_page.dart';

class ForumPage extends StatefulWidget {
  const ForumPage({super.key});

  @override
  State<ForumPage> createState() => _ForumPageState();
}

class _ForumPageState extends State<ForumPage> {
  // --- BIẾN DỮ LIỆU ---
  List<ForumPost> _posts = [];
  bool _isLoading = true;

  // --- BIẾN LỌC ---
  String _filterCategory = "All";
  String? _filterTopic;
  String? _filterProductType;
  RangeValues _filterPriceRange = const RangeValues(0, 1000000);
  String? _filterEventType;
  String? _filterEventStatus;

  // --- DANH SÁCH DỮ LIỆU ---
  final List<String> _knowledgeTopics = [
    "Mẹo sống xanh",
    "Tin tức môi trường",
    "Hỏi đáp",
    "Góc thảo luận",
  ];
  final List<String> _productCategories = [
    "Đồ tái chế",
    "Đồ Handmade",
    "Nguyên liệu thô",
    "Dụng cụ làm vườn",
    "Khác",
  ];
  final List<String> _eventCategories = [
    "Hoạt động tình nguyện",
    "Workshop/Hội thảo",
    "Thu gom rác",
    "Cuộc thi",
    "Khác",
  ];
  final List<String> _eventStatuses = [
    "Sắp diễn ra",
    "Đang diễn ra",
    "Đã kết thúc",
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Hàm lấy dữ liệu từ Server
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    List<ForumPost> fetchedPosts = await ForumService.fetchPosts();
    if (mounted) {
      setState(() {
        _posts = fetchedPosts;
        _isLoading = false;
      });
    }
  }

  String _getShortName(String fullName) {
    List<String> words = fullName.trim().split(" ");
    if (words.length > 2) {
      return "${words[words.length - 2]} ${words[words.length - 1]}";
    } else {
      return fullName;
    }
  }

  String formatCurrency(double amount) {
    return amount.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  void _toggleLike(int index) async {
    final String postId = _posts[index].id;
    setState(() {
      _posts[index].isLiked = !_posts[index].isLiked;
      _posts[index].isLiked ? _posts[index].likes++ : _posts[index].likes--;
    });
    bool success = await ForumService.toggleLike(postId);
    if (!success) {
      if (mounted) {
        setState(() {
          _posts[index].isLiked = !_posts[index].isLiked;
          _posts[index].isLiked ? _posts[index].likes++ : _posts[index].likes--;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Lỗi kết nối! Không thể like.")),
        );
      }
    }
  }

  void _showCommentSheet(BuildContext context, int postIndex) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Tính năng bình luận (Coming soon)")),
    );
  }

  void _showPostTypeDialog() {
    final String role = (UserData.role ?? "student").toLowerCase();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Chọn loại bài viết",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                // Nút 1: Kiến thức
                _buildTypeButton(
                  label: "Kiến thức",
                  color: const Color(0xFFFCE4EC),
                  textColor: Colors.black,
                  onTap: () => _navigateToCreatePost("Kiến thức"),
                ),
                const SizedBox(height: 15),

                // Nút 2: Sản phẩm
                _buildTypeButton(
                  label: "Sản phẩm",
                  color: const Color(0xFFE3F2FD),
                  textColor: Colors.black,
                  onTap: () => _navigateToCreatePost("Sản phẩm"),
                ),

                // 👇 NÚT 3: SỰ KIỆN (CHỈ HIỆN KHI LÀ CLB)
                if (role == 'club') ...[
                  const SizedBox(height: 15),
                  _buildTypeButton(
                    label: "Sự kiện",
                    color: const Color(0xFFFFF3E0), // Màu cam nhạt
                    textColor: Colors.black,
                    onTap: _navigateToCreateEvent, // Hàm chuyển hướng mới
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _navigateToCreatePost(String type) async {
    Navigator.pop(context);
    final newPost = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CreatePostPage(postType: type)),
    );

    if (newPost != null && newPost is ForumPost) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Đang lưu bài viết...")));
      bool success = await ForumService.createPost(newPost);
      if (success) {
        await _loadData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Đăng bài thành công!"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Lỗi lưu bài viết"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _navigateToCreateEvent() {
    Navigator.pop(context); // Đóng Dialog chọn loại
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateEventPage()),
    );
  }

  // --- FILTER SHEET ---
  void _showFilterSheet() {
    String tempCategory = _filterCategory == "All"
        ? "Kiến thức"
        : _filterCategory;
    String? tempTopic = _filterTopic;
    String? tempProductType = _filterProductType;
    RangeValues tempPriceRange = _filterPriceRange;
    String? tempEventType = _filterEventType;
    String? tempEventStatus = _filterEventStatus;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text(
                      "Filter",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A237E),
                      ),
                    ),
                  ),
                  const Divider(height: 30),
                  const Text(
                    "Loại bài viết",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildChoiceChipInModal(
                        "Kiến thức",
                        Colors.blue,
                        tempCategory,
                        (val) => setModalState(() => tempCategory = val),
                      ),
                      _buildChoiceChipInModal(
                        "Sản phẩm",
                        const Color(0xFF009688),
                        tempCategory,
                        (val) => setModalState(() => tempCategory = val),
                      ),
                      _buildChoiceChipInModal(
                        "Sự kiện",
                        Colors.orange,
                        tempCategory,
                        (val) => setModalState(() => tempCategory = val),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  if (tempCategory == "Kiến thức") ...[
                    const Text(
                      "Chủ đề bài viết",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildDropdown(
                      tempTopic,
                      _knowledgeTopics,
                      "Tất cả chủ đề",
                      (val) => setModalState(() => tempTopic = val),
                    ),
                  ] else if (tempCategory == "Sản phẩm") ...[
                    const Text(
                      "Loại sản phẩm",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildDropdown(
                      tempProductType,
                      _productCategories,
                      "Tất cả sản phẩm",
                      (val) => setModalState(() => tempProductType = val),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Giá",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          "${formatCurrency(tempPriceRange.start)}đ - ${formatCurrency(tempPriceRange.end)}đ",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF009688),
                          ),
                        ),
                      ],
                    ),
                    RangeSlider(
                      values: tempPriceRange,
                      min: 0,
                      max: 1000000,
                      divisions: 20,
                      activeColor: const Color(0xFF009688),
                      inactiveColor: Colors.grey[200],
                      labels: RangeLabels(
                        formatCurrency(tempPriceRange.start),
                        formatCurrency(tempPriceRange.end),
                      ),
                      onChanged: (values) =>
                          setModalState(() => tempPriceRange = values),
                    ),
                  ] else if (tempCategory == "Sự kiện") ...[
                    const Text(
                      "Loại sự kiện",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildDropdown(
                      tempEventType,
                      _eventCategories,
                      "Tất cả sự kiện",
                      (val) => setModalState(() => tempEventType = val),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Trạng thái",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      children: _eventStatuses.map((status) {
                        bool isSelected = tempEventStatus == status;
                        return ChoiceChip(
                          label: Text(status),
                          selected: isSelected,
                          selectedColor: Colors.orange[100],
                          backgroundColor: Colors.grey[100],
                          labelStyle: TextStyle(
                            color: isSelected
                                ? Colors.orange[800]
                                : Colors.black87,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          onSelected: (selected) => setModalState(
                            () => tempEventStatus = selected ? status : null,
                          ),
                        );
                      }).toList(),
                    ),
                  ],

                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _filterCategory = tempCategory;
                          _filterTopic = tempTopic;
                          _filterProductType = tempProductType;
                          _filterPriceRange = tempPriceRange;
                          _filterEventType = tempEventType;
                          _filterEventStatus = tempEventStatus;
                        });
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      child: const Text(
                        "Lọc",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  if (_filterCategory != "All")
                    Center(
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            _filterCategory = "All";
                            _filterTopic = null;
                            _filterProductType = null;
                            _filterEventType = null;
                            _filterEventStatus = null;
                            _filterPriceRange = const RangeValues(0, 1000000);
                          });
                          Navigator.pop(context);
                        },
                        child: const Text(
                          "Xóa bộ lọc",
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  bool _checkEventStatus(ForumPost post, String statusFilter) {
    // 1. Nếu bài viết không có ngày tổ chức -> Bỏ qua hoặc coi như không khớp
    if (post.eventDate == null || post.eventDate!.isEmpty) return false;

    try {
      // 2. Chuyển đổi ngày từ String "dd/mm/yyyy" sang DateTime
      List<String> parts = post.eventDate!.split('/');
      if (parts.length != 3) return false;

      // Tạo đối tượng ngày của sự kiện (Giả sử kết thúc vào cuối ngày đó)
      DateTime eventDate = DateTime(
        int.parse(parts[2]), // Năm
        int.parse(parts[1]), // Tháng
        int.parse(parts[0]), // Ngày
        23,
        59,
        59, // Cuối ngày
      );

      DateTime now = DateTime.now();

      // 3. So sánh với hiện tại
      if (statusFilter == "Đã kết thúc") {
        return now.isAfter(eventDate); // Hiện tại > Ngày sự kiện
      } else if (statusFilter == "Sắp diễn ra") {
        return now.isBefore(eventDate); // Hiện tại < Ngày sự kiện
      } else if (statusFilter == "Đang diễn ra") {
        // Logic tương đối: Nếu là ngày hôm nay thì coi là đang diễn ra
        return now.year == eventDate.year &&
            now.month == eventDate.month &&
            now.day == eventDate.day;
      }
    } catch (e) {
      print("Lỗi parse ngày: $e");
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    // Logic lọc
    final displayPosts = _posts.where((post) {
      if (_filterCategory != "All" && post.tagName != _filterCategory)
        return false;
      if (_filterCategory == "Kiến thức" &&
          _filterTopic != null &&
          post.topic != _filterTopic)
        return false;
      if (_filterCategory == "Sản phẩm") {
        if (_filterProductType != null && post.category != _filterProductType)
          return false;
        if (post.price != null &&
            (post.price! < _filterPriceRange.start ||
                post.price! > _filterPriceRange.end))
          return false;
      }
      if (_filterCategory == "Sự kiện") {
        // Lọc loại sự kiện (Workshop, Tình nguyện...)
        if (_filterEventType != null && post.category != _filterEventType) {
          return false;
        }

        // 👇 MỚI THÊM: Lọc trạng thái (Sắp diễn ra/Đã kết thúc...)
        if (_filterEventStatus != null) {
          // Gọi hàm kiểm tra thời gian mình vừa viết ở trên
          if (!_checkEventStatus(post, _filterEventStatus!)) {
            return false;
          }
        }
      }

      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: Column(
          children: [
            // HEADER
            Container(
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
              color: const Color(0xFFB71C1C),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: NetworkImage(
                      UserData.avatar ?? 'https://i.pravatar.cc/300',
                    ),
                    backgroundColor: Colors.white,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Chào, ${_getShortName(UserData.name ?? "Bạn")}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          UserData.role ?? "Sinh viên",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.chat_bubble_outline,
                          color: Colors.white,
                          size: 24,
                        ),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ChatListPage(),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.search,
                          color: Colors.white,
                          size: 24,
                        ),
                        onPressed: _openSearch,
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.filter_alt_outlined,
                          color: Colors.white,
                          size: 24,
                        ),
                        onPressed: _showFilterSheet,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // BODY
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFB71C1C),
                      ),
                    )
                  : SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        children: [
                          const SizedBox(
                            height: 180,
                            width: double.infinity,
                            child: BannerSlider(),
                          ),
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 10),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 15,
                            ),
                            color: Colors.white,
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: _showPostTypeDialog,
                                  child: CircleAvatar(
                                    radius: 22,
                                    backgroundImage: NetworkImage(
                                      UserData.avatar ?? '',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: InkWell(
                                    onTap: _showPostTypeDialog,
                                    child: Container(
                                      height: 45,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(30),
                                        border: Border.all(
                                          color: Colors.grey[300]!,
                                        ),
                                      ),
                                      alignment: Alignment.centerLeft,
                                      child: const Text(
                                        "Bạn đang nghĩ gì?",
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_filterCategory != "All")
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Text(
                                "Đang lọc: $_filterCategory",
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          displayPosts.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 50),
                                  child: Column(
                                    children: const [
                                      Icon(
                                        Icons.search_off,
                                        size: 50,
                                        color: Colors.grey,
                                      ),
                                      SizedBox(height: 10),
                                      Text(
                                        "Không tìm thấy bài viết phù hợp",
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  padding: EdgeInsets.zero,
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: displayPosts.length,
                                  itemBuilder: (context, index) {
                                    return _buildPostItem(
                                      displayPosts[index],
                                      index,
                                    );
                                  },
                                ),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET HELPER ---
  Widget _buildDropdown(
    String? value,
    List<String> items,
    String hint,
    Function(String?) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint, style: const TextStyle(fontSize: 14)),
          isExpanded: true,
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildChoiceChipInModal(
    String label,
    Color color,
    String currentSelected,
    Function(String) onSelect,
  ) {
    bool isSelected = currentSelected == label;
    return GestureDetector(
      onTap: () => onSelect(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color, width: 1.5),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : color,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildTypeButton({
    required String label,
    required Color color,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildPostItem(ForumPost post, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundImage: NetworkImage(post.authorAvatar),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.authorName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      post.time,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: _getTagColor(post.tagName),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  post.tagName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(post.content),
          if (post.attachmentName != null && post.attachmentName!.isNotEmpty)
            InkWell(
              onTap: () async {
                if (post.attachmentUrl != null) {
                  final Uri url = Uri.parse(post.attachmentUrl!);
                  if (!await launchUrl(
                    url,
                    mode: LaunchMode.externalApplication,
                  )) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Không thể mở file này!")),
                    );
                  }
                }
              },
              child: Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.attach_file, size: 20, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post.attachmentName!,
                            style: const TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Text(
                            "Bấm để xem tài liệu",
                            style: TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.open_in_new, size: 16, color: Colors.blue),
                  ],
                ),
              ),
            ),
          if (post.image != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  post.image!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => Container(
                    height: 200,
                    color: Colors.grey[300],
                    child: const Center(
                      child: Icon(Icons.broken_image, color: Colors.grey),
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 10),
          Row(
            children: [
              IconButton(
                icon: Icon(
                  post.isLiked ? Icons.favorite : Icons.favorite_border,
                  color: post.isLiked ? Colors.red : Colors.grey,
                ),
                onPressed: () => _toggleLike(index),
              ),
              Text("${post.likes}"),
              const SizedBox(width: 20),
              IconButton(
                icon: const Icon(Icons.chat_bubble_outline),
                onPressed: () => _showCommentSheet(context, index),
              ),
              Text("${post.comments}"),
              const Spacer(),
              if (post.authorName != UserData.name)
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatDetailPage(
                          userName: post.authorName,
                          userImage: post.authorAvatar,
                          isOnline: true,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.message,
                    size: 16,
                    color: Colors.white,
                  ),
                  label: const Text(
                    "Nhắn tin",
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2C2C54),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getTagColor(String tag) {
    switch (tag) {
      case "Kiến thức":
        return Colors.blue;
      case "Sản phẩm":
        return const Color(0xFF009688);
      case "Sự kiện":
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  void _openSearch() {
    showSearch(context: context, delegate: UserSearchDelegate());
  }
}

class UserSearchDelegate extends SearchDelegate {
  final List<String> searchTerms = ["Nguyễn Ngọc Trâm", "Admin"];
  @override
  String? get searchFieldLabel => 'Tìm kiếm...';
  @override
  List<Widget>? buildActions(BuildContext context) => [
    IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
  ];
  @override
  Widget? buildLeading(BuildContext context) => IconButton(
    icon: const Icon(Icons.arrow_back),
    onPressed: () => close(context, null),
  );
  @override
  Widget buildResults(BuildContext context) => Container();
  @override
  Widget buildSuggestions(BuildContext context) => Container();
}
