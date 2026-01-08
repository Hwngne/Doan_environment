import 'dart:convert';
import 'package:http/http.dart' as http;
import 'user_service.dart'; // Import UserData thật

// --- 1. MODEL FORUM POST (Định nghĩa ngay tại đây để dễ quản lý) ---
class ForumPost {
  final String id;
  final String authorName;
  final String authorAvatar;
  final String time;
  final DateTime? timestamp;
  final String tagName; // "Kiến thức", "Sản phẩm", "Sự kiện"
  final String content;
  int likes;
  int comments;
  bool isLiked;
  final String? image;

  // Các trường bổ sung cho Sản phẩm/Kiến thức
  final String? topic;
  final String? category;
  final double? price;
  final String? attachmentName;
  final String? attachmentUrl;

  // 👇 MỚI THÊM: Các trường cho SỰ KIỆN
  final String? eventDate; // Ví dụ: "16/10/2025"
  final String? eventTime; // Ví dụ: "08:00 - 11:30"
  final String? eventLocation; // Ví dụ: "Phòng F.09.10"

  ForumPost({
    required this.id,
    required this.authorName,
    required this.authorAvatar,
    required this.time,
    this.timestamp,
    required this.tagName,
    required this.content,
    required this.likes,
    required this.comments,
    this.isLiked = false,
    this.image,
    this.topic,
    this.category,
    this.price,
    this.attachmentName,
    this.attachmentUrl,
    this.eventDate,
    this.eventTime,
    this.eventLocation,
  });
}

// --- 2. FORUM SERVICE ---
class ForumService {
  // ⚠️ Đổi IP nếu chạy máy thật
  static const String baseUrl = "http://localhost:5000/api/posts";
  static const String serverUrl = "http://localhost:5000";

  // --- LẤY DANH SÁCH BÀI VIẾT ---
  static Future<List<ForumPost>> fetchPosts() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl?email=${UserData.email}'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        return data.map((json) {
          // Xử lý link ảnh
          String? imageUrl;
          if (json['image'] != null && json['image'].toString().isNotEmpty) {
            if (json['image'].toString().startsWith('http')) {
              imageUrl = json['image'];
            } else {
              imageUrl = "$serverUrl${json['image']}";
            }
          }

          // Map từ JSON -> ForumPost
          return ForumPost(
            id: json['_id'],
            authorName: json['author']['name'] ?? "Ẩn danh",
            authorAvatar: json['author']['avatar'] ?? UserData.avatar,
            time: _formatTime(json['createdAt']),
            timestamp: DateTime.tryParse(json['createdAt']),
            tagName:
                json['type'], // Backend lưu 'type', Frontend gọi là 'tagName'
            content: json['content'],
            image: imageUrl,
            likes: (json['likes'] as List).length,
            comments: (json['comments'] as List).length,
            isLiked: json['isLiked'] ?? false,

            // Các trường phụ
            topic: json['topic'],
            category: json['category'],
            price: json['price'] != null
                ? double.parse(json['price'].toString())
                : null,
            attachmentUrl: json['attachment'],
            attachmentName: json['attachmentName'],

            // 👇 ĐỌC DỮ LIỆU SỰ KIỆN TỪ SERVER
            eventDate: json['eventDate'],
            eventTime: json['eventTime'],
            eventLocation: json['eventLocation'],
          );
        }).toList();
      } else {
        print("Lỗi tải bài viết: ${response.body}");
        return [];
      }
    } catch (e) {
      print("Lỗi mạng Forum: $e");
      return [];
    }
  }

  // --- THÍCH / BỎ THÍCH ---
  static Future<bool> toggleLike(String postId) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/$postId/like'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': UserData.email}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // --- ĐĂNG BÀI VIẾT MỚI ---
  static Future<bool> createPost(ForumPost post) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': UserData.email,
          'type': post.tagName,
          'title': post.content.split('\n')[0],
          'content': post.content,
          'image': post.image,

          // Các trường optional
          'topic': post.topic,
          'category': post.category,
          'price': post.price,
          'attachment': post.attachmentUrl,
          'attachmentName': post.attachmentName,

          // 👇 GỬI DỮ LIỆU SỰ KIỆN LÊN SERVER
          'eventDate': post.eventDate,
          'eventTime': post.eventTime,
          'eventLocation': post.eventLocation,
        }),
      );

      return response.statusCode == 201;
    } catch (e) {
      print("Lỗi mạng khi đăng bài: $e");
      return false;
    }
  }

  // Hàm format thời gian
  static String _formatTime(String? dateString) {
    if (dateString == null) return "Vừa xong";
    final date = DateTime.parse(dateString);
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return "Vừa xong";
    if (diff.inMinutes < 60) return "${diff.inMinutes} phút trước";
    if (diff.inHours < 24) return "${diff.inHours} giờ trước";
    return "${date.day}/${date.month}";
  }
}
