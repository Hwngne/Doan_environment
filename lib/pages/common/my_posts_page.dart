import 'package:flutter/material.dart';
import '../../data/mock_data.dart';
import '../../components/app_background.dart';

class MyPostsPage extends StatefulWidget {
  const MyPostsPage({super.key});

  @override
  State<MyPostsPage> createState() => _MyPostsPageState();
}

class _MyPostsPageState extends State<MyPostsPage> {
  // Biến quản lý bộ lọc
  String _selectedCategory = "All";

  // Biến lưu ngày đã chọn
  DateTime? _fromDate;
  DateTime? _toDate;

  final TextEditingController _fromDateController = TextEditingController();
  final TextEditingController _toDateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Mặc định lọc năm 2025
    _fromDate = DateTime(2025, 1, 1);
    _toDate = DateTime.now();
    _fromDateController.text = "1/1/2025";
    _toDateController.text =
        "${_toDate!.day}/${_toDate!.month}/${_toDate!.year}";
  }

  @override
  Widget build(BuildContext context) {
    // LOGIC LỌC DỮ LIỆU
    final myPosts = forumPosts.where((post) {
      // 1. Check tác giả
      final bool isAuthor = post.authorName == UserData.name;

      // 2. Check Loại bài
      final bool matchesCategory =
          _selectedCategory == "All" ||
          (_selectedCategory == "Kiến thức" && post.topic == "Kiến thức") ||
          (_selectedCategory == "Sản phẩm" &&
              post.topic ==
                  "Sản phẩm"); // Lưu ý: logic này check theo topic chung

      // 3. Check Ngày
      bool matchesDate = true;
      if (_fromDate != null) {
        matchesDate =
            matchesDate &&
            !post.timestamp.isBefore(
              _fromDate!.copyWith(hour: 0, minute: 0, second: 0),
            );
      }
      if (_toDate != null) {
        matchesDate =
            matchesDate &&
            !post.timestamp.isAfter(
              _toDate!.copyWith(hour: 23, minute: 59, second: 59),
            );
      }

      return isAuthor && matchesCategory && matchesDate;
    }).toList();

    return Scaffold(
      body: AppBackground(
        child: Column(
          children: [
            // HEADER ĐỎ
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
                        "Bài đăng của tôi",
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
                    // THẺ THỐNG KÊ
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 25,
                        horizontal: 30,
                      ),
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
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: const [
                              Icon(
                                Icons.local_library,
                                color: Colors.white,
                                size: 28,
                              ),
                              SizedBox(width: 15),
                              Text(
                                "Bài đăng",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            "${myPosts.length}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),

                    // BỘ CHỌN NGÀY
                    _buildDateFilterRow("Từ ngày", _fromDateController, true),
                    const SizedBox(height: 15),
                    _buildDateFilterRow("Đến ngày", _toDateController, false),

                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Text(
                          "Loại bài đăng",
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(width: 15),
                        _buildFilterButton("Kiến thức", Colors.lightBlue),
                        const SizedBox(width: 10),
                        _buildFilterButton("Sản phẩm", Colors.teal),
                      ],
                    ),

                    const SizedBox(height: 15),

                    // --- SỬA NÚT "HIỂN THỊ TẤT CẢ" ---
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCategory = "All";
                          // Reset ngày về mặc định nếu muốn, hoặc giữ nguyên
                        });
                      },
                      child: Row(
                        children: [
                          // Thay đổi màu và icon dựa trên trạng thái chọn
                          Icon(
                            _selectedCategory == "All"
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            size: 24,
                            color: _selectedCategory == "All"
                                ? const Color(0xFFB71C1C)
                                : Colors.grey,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            "Hiển thị tất cả bài viết",
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: _selectedCategory == "All"
                                  ? Colors.black
                                  : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                    const Divider(thickness: 1, color: Colors.black12),
                    const SizedBox(height: 10),

                    // LIST BÀI VIẾT
                    myPosts.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.only(top: 50),
                              child: Text(
                                "Không tìm thấy bài đăng nào.",
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: myPosts.length,
                            itemBuilder: (context, index) =>
                                _buildPostItem(myPosts[index]),
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

  // --- SỬA LỖI CĂN CHỈNH TEXT NGÀY ---
  Widget _buildDateFilterRow(
    String label,
    TextEditingController controller,
    bool isFromDate,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () => _selectDate(context, controller, isFromDate),
            child: Container(
              height: 45,
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
              ), // Padding cho container
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.black12),
              ),
              child: TextField(
                controller: controller,
                enabled: false,
                textAlignVertical:
                    TextAlignVertical.center, // <--- Căn giữa theo chiều dọc
                style: const TextStyle(color: Colors.black),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true, // Giúp text field gọn hơn
                  contentPadding:
                      EdgeInsets.zero, // Xóa padding mặc định của input
                  suffixIcon: Icon(
                    Icons.calendar_today,
                    size: 18,
                    color: Colors.grey,
                  ),
                  // Căn chỉnh icon cho khớp
                  suffixIconConstraints: BoxConstraints(
                    minWidth: 24,
                    minHeight: 24,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate(
    BuildContext context,
    TextEditingController controller,
    bool isFromDate,
  ) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isFromDate
          ? (_fromDate ?? DateTime.now())
          : (_toDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFB71C1C),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isFromDate) {
          _fromDate = picked;
        } else {
          _toDate = picked;
        }
        controller.text = "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  Widget _buildFilterButton(String label, Color color) {
    bool isSelected = _selectedCategory == label;
    return InkWell(
      onTap: () {
        setState(() => _selectedCategory = isSelected ? "All" : label);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black54,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  // --- SỬA BÀI VIẾT NỔI BẬT HƠN ---
  Widget _buildPostItem(ForumPost item) {
    Color tagColor = item.topic == "Kiến thức" ? Colors.lightBlue : Colors.teal;

    // Kiểm tra topic để gán màu tag (nếu null thì mặc định xám)
    if (item.topic == "Sản phẩm") tagColor = Colors.teal;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        // --- TẠO HIỆU ỨNG NỔI BẬT ---
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.15,
            ), // Màu bóng đậm hơn chút
            blurRadius: 15, // Bóng lan rộng hơn
            offset: const Offset(0, 8), // Bóng đổ xuống dưới nhiều hơn
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage(item.authorAvatar),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.authorName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: tagColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      item.topic ?? "Chung",
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                item.time,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(item.content, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 10),
          if (item.image != null && item.image!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.network(
                item.image!,
                width: double.infinity,
                height: 180,
                fit: BoxFit.cover,
              ),
            ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.favorite_border, size: 20, color: Colors.grey),
              const SizedBox(width: 5),
              Text("${item.likes}", style: const TextStyle(color: Colors.grey)),
              const SizedBox(width: 20),
              const Icon(
                Icons.chat_bubble_outline,
                size: 20,
                color: Colors.grey,
              ),
              const SizedBox(width: 5),
              Text(
                "${item.comments}",
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
