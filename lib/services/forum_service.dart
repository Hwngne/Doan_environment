import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'user_service.dart';
import 'auth_service.dart';

// --- MODEL FORUM POST ---
class ForumPost {
  final String id;
  final String authorId;
  final String authorName;
  final String authorAvatar;
  final String time;
  final DateTime? timestamp;
  final String tagName;
  final String content;
  int likes;
  int comments;
  bool isLiked;
  final String? image;
  final String? topic;
  final String? category;
  final double? price;
  final String? attachmentName;
  final String? attachmentUrl;
  final String? eventDate;
  final String? eventTime;
  final String? eventLocation;
  List<dynamic>? commentsList;

  ForumPost({
    required this.id,
    required this.authorId,
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
    this.commentsList = const [],
  });
}

class ForumService {
  // ⚠️ Đổi IP backend nếu cần
  static const String baseUrl = "http://localhost:5000/api/posts";
  static const String configUrl = "http://localhost:5000/api/config";
  static const String serverUrl = "http://localhost:5000";

  // --- 1. LẤY DANH SÁCH BÀI VIẾT ---
  static Future<List<ForumPost>> fetchPosts() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl?email=${UserData.email}'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) {
          String? imageUrl;
          if (json['image'] != null && json['image'].toString().isNotEmpty) {
            if (json['image'].toString().startsWith('http')) {
              imageUrl = json['image'];
            } else {
              imageUrl = "$serverUrl${json['image']}";
            }
          }

          return ForumPost(
            id: json['_id'],
            authorId: json['author'] != null && json['author'] is Map
                ? json['author']['_id'] ?? ""
                : "",
            authorName: _getAuthorName(json['author']),
            authorAvatar: json['author'] != null
                ? json['author']['avatar'] ?? UserData.avatar
                : UserData.avatar,
            time: _formatTime(json['createdAt']),
            timestamp: DateTime.tryParse(json['createdAt'] ?? ""),
            tagName: json['type'] ?? "Thảo luận",
            content: json['content'] ?? "",
            image: imageUrl,
            likes: (json['likes'] as List).length,
            comments: json['commentCount'] ?? (json['comments'] as List).length,
            commentsList: json['comments'] ?? [],
            isLiked: json['isLiked'] ?? false,
            topic: json['topic'],
            category: json['category'],
            price: json['price'] != null
                ? double.tryParse(json['price'].toString())
                : null,
            attachmentUrl: json['attachment'],
            attachmentName: json['attachmentName'],
            eventDate: json['date'] ?? json['eventDate'],
            eventTime: json['eventTime'],
            eventLocation: json['eventLocation'],
          );
        }).toList();
      }
      return [];
    } catch (e) {
      print("Lỗi mạng Forum: $e");
      return [];
    }
  }

  // --- 2. LIKE BÀI VIẾT ---
  static Future<bool> toggleLike(String postId) async {
    try {
      final token = await AuthService.getToken();
      final response = await http.put(
        Uri.parse('$baseUrl/$postId/like'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'email': UserData.email}),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print("Lỗi Like: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Lỗi Like (Exception): $e");
      return false;
    }
  }

  // --- 3. TẠO BÀI VIẾT (MULTIPART) ---
  static Future<bool> createPost(
    String type,
    String title,
    String content,
    XFile? imageFile,
    PlatformFile? attachFile, {
    String? topic,
    String? category,
    double? price,
    int? quantity,
    String? phone,
  }) async {
    try {
      final token = await AuthService.getToken();
      var request = http.MultipartRequest('POST', Uri.parse(baseUrl));

      request.headers['Authorization'] = 'Bearer $token';
      request.fields['email'] = UserData.email ?? "";
      request.fields['type'] = type;
      request.fields['title'] = title;
      request.fields['content'] = content;

      if (topic != null) request.fields['topic'] = topic;
      if (category != null) request.fields['category'] = category;
      if (price != null) request.fields['price'] = price.toString();
      if (quantity != null) request.fields['quantity'] = quantity.toString();
      if (phone != null) request.fields['phone'] = phone;

      if (imageFile != null) {
        final bytes = await imageFile.readAsBytes();
        request.files.add(
          http.MultipartFile.fromBytes(
            'image',
            bytes,
            filename: imageFile.name,
          ),
        );
      }

      if (attachFile != null) {
        if (attachFile.bytes != null) {
          request.files.add(
            http.MultipartFile.fromBytes(
              'attachment',
              attachFile.bytes!,
              filename: attachFile.name,
            ),
          );
        } else if (attachFile.path != null) {
          request.files.add(
            await http.MultipartFile.fromPath('attachment', attachFile.path!),
          );
        }
        request.fields['attachmentName'] = attachFile.name;
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print("Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print("❌ Lỗi KẾT NỐI (Exception): $e");
      return false;
    }
  }

  static Future<List<String>> fetchConfigList(String type) async {
    try {
      final response = await http.get(
        Uri.parse('$configUrl?type=$type'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => item['name'].toString()).toList();
      }
      return [];
    } catch (e) {
      print("Lỗi lấy config ($type): $e");
      return [];
    }
  }

  static String _formatTime(String? dateString) {
    if (dateString == null) return "Vừa xong";
    try {
      final date = DateTime.parse(dateString);
      final diff = DateTime.now().difference(date);
      if (diff.inMinutes < 1) return "Vừa xong";
      if (diff.inMinutes < 60) return "${diff.inMinutes} phút trước";
      if (diff.inHours < 24) return "${diff.inHours} giờ trước";
      return "${date.day}/${date.month}";
    } catch (e) {
      return "Vừa xong";
    }
  }

  // --- HÀM XỬ LÝ TÊN TÁC GIẢ ---
  static String _getAuthorName(dynamic authorJson) {
    if (authorJson == null) return "Ẩn danh";
    try {
      if (authorJson['club_info'] != null && authorJson['club_info'] is Map) {
        final clubInfo = authorJson['club_info'];
        if (clubInfo['club_name'] != null &&
            clubInfo['club_name'].toString().isNotEmpty) {
          return clubInfo['club_name'].toString();
        }
      }
      if (authorJson['student_name'] != null &&
          authorJson['student_name'].toString().isNotEmpty) {
        return authorJson['student_name'].toString();
      }
      if (authorJson['name'] != null &&
          authorJson['name'].toString().isNotEmpty) {
        return authorJson['name'].toString();
      }
    } catch (e) {
      print("Lỗi đọc tên: $e");
    }
    return authorJson['email'] ?? "Người dùng Eco";
  }

  // --- 4. GỬI COMMENT ---
  static Future<List<dynamic>?> sendComment(
    String postId,
    String content,
    XFile? imageFile,
  ) async {
    try {
      final token = await AuthService.getToken();

      // Kiểm tra Email trước khi gửi
      if (UserData.email == null || UserData.email!.isEmpty) {
        print("❌ LỖI: UserData.email đang bị rỗng!");
        return null;
      }

      // TRƯỜNG HỢP 1: CÓ ẢNH -> Dùng Multipart
      if (imageFile != null) {
        var request = http.MultipartRequest(
          'POST',
          Uri.parse('$baseUrl/$postId/comment'),
        );
        request.headers['Authorization'] = 'Bearer $token';

        // 🔥 QUAN TRỌNG: Gán fields (Text) TRƯỚC
        request.fields['email'] = UserData.email!;
        request.fields['content'] = content;

        // 🔥 Gán files (Ảnh) SAU
        final bytes = await imageFile.readAsBytes();
        request.files.add(
          http.MultipartFile.fromBytes(
            'image',
            bytes,
            filename: imageFile.name,
          ),
        );

        print(
          "📤 Đang gửi Comment Multipart: Email=${UserData.email}, Content=$content, Image=${imageFile.name}",
        );

        var streamedResponse = await request.send();
        var response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 201) {
          final data = jsonDecode(response.body);
          return data['comments'];
        } else {
          print("❌ Lỗi comment (Multipart): ${response.body}");
          return null;
        }
      }
      // TRƯỜNG HỢP 2: KHÔNG CÓ ẢNH -> Dùng JSON (Chuẩn, không lỗi)
      else {
        final response = await http.post(
          Uri.parse('$baseUrl/$postId/comment'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({'email': UserData.email, 'content': content}),
        );

        if (response.statusCode == 201) {
          final data = jsonDecode(response.body);
          return data['comments'];
        } else {
          print("Lỗi comment (JSON): ${response.body}");
          return null;
        }
      }
    } catch (e) {
      print("Lỗi kết nối comment: $e");
      return null;
    }
  }

  // --- 6. LIKE BÌNH LUẬN ---
  static Future<List<dynamic>?> toggleLikeComment(
    String postId,
    String commentId,
  ) async {
    try {
      final token = await AuthService.getToken();
      final response = await http.put(
        Uri.parse('$baseUrl/$postId/comment/$commentId/like'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'email': UserData.email}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['likes'];
      }
      return null;
    } catch (e) {
      print("Lỗi Like Comment: $e");
      return null;
    }
  }

  // --- 7. XÓA BÌNH LUẬN ---
  static Future<List<dynamic>?> deleteComment(
    String postId,
    String commentId,
  ) async {
    try {
      final token = await AuthService.getToken();
      final request = http.Request(
        'DELETE',
        Uri.parse('$baseUrl/$postId/comment/$commentId'),
      );
      request.headers.addAll({
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      });
      request.body = jsonEncode({'email': UserData.email});

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['comments'];
      }
      return null;
    } catch (e) {
      print("Lỗi xóa comment: $e");
      return null;
    }
  }

  // --- 8. SỬA BÌNH LUẬN ---
  static Future<bool> editComment(
    String postId,
    String commentId,
    String newContent,
  ) async {
    try {
      final token = await AuthService.getToken();
      final response = await http.put(
        Uri.parse('$baseUrl/$postId/comment/$commentId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'email': UserData.email, 'content': newContent}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Lỗi sửa comment: $e");
      return false;
    }
  }

  // --- 9. GỬI TRẢ LỜI (REPLY) ---
  static Future<List<dynamic>?> sendReply(
    String postId,
    String commentId,
    String content,
    XFile? imageFile,
  ) async {
    try {
      final token = await AuthService.getToken();

      if (UserData.email == null || UserData.email!.isEmpty) {
        print("❌ LỖI: UserData.email đang bị rỗng!");
        return null;
      }

      // TRƯỜNG HỢP 1: CÓ ẢNH -> Multipart
      if (imageFile != null) {
        var request = http.MultipartRequest(
          'POST',
          Uri.parse('$baseUrl/$postId/comment/$commentId/reply'),
        );
        request.headers['Authorization'] = 'Bearer $token';

        // 🔥 QUAN TRỌNG: Fields TRƯỚC
        request.fields['email'] = UserData.email!;
        request.fields['content'] = content;

        // 🔥 Files SAU
        final bytes = await imageFile.readAsBytes();
        request.files.add(
          http.MultipartFile.fromBytes(
            'image',
            bytes,
            filename: imageFile.name,
          ),
        );
        var streamedResponse = await request.send();
        var response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 201) {
          final data = jsonDecode(response.body);
          return data['replies'];
        } else {
          return null;
        }
      }
      // TRƯỜNG HỢP 2: KHÔNG CÓ ẢNH -> JSON
      else {
        final response = await http.post(
          Uri.parse('$baseUrl/$postId/comment/$commentId/reply'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({'email': UserData.email, 'content': content}),
        );

        if (response.statusCode == 201) {
          final data = jsonDecode(response.body);
          return data['replies'];
        } else {
          return null;
        }
      }
    } catch (e) {
      print("Lỗi reply: $e");
      return null;
    }
  }

  // --- 10. LIKE REPLY ---
  static Future<List<dynamic>?> toggleLikeReply(
    String postId,
    String commentId,
    String replyId,
  ) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return null;

      final response = await http.put(
        Uri.parse('$baseUrl/$postId/comment/$commentId/reply/$replyId/like'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'email': UserData.email}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['likes'];
      }
      return null;
    } catch (e) {
      print("Lỗi Like Reply: $e");
      return null;
    }
  }

  // --- 11. XÓA REPLY ---
  static Future<List<dynamic>?> deleteReply(
    String postId,
    String commentId,
    String replyId,
  ) async {
    try {
      final token = await AuthService.getToken();
      final request = http.Request(
        'DELETE',
        Uri.parse('$baseUrl/$postId/comment/$commentId/reply/$replyId'),
      );
      request.headers.addAll({
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      });
      request.body = jsonEncode({'email': UserData.email});

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['replies'];
      }
      return null;
    } catch (e) {
      print("Lỗi xóa reply: $e");
      return null;
    }
  }

  // --- 12. SỬA REPLY ---
  static Future<bool> editReply(
    String postId,
    String commentId,
    String replyId,
    String newContent,
  ) async {
    try {
      final token = await AuthService.getToken();
      final response = await http.put(
        Uri.parse('$baseUrl/$postId/comment/$commentId/reply/$replyId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'email': UserData.email, 'content': newContent}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print("Lỗi sửa reply: $e");
      return false;
    }
  }

  // --- 13. XÓA BÀI VIẾT ---
  static Future<bool> deletePost(String postId) async {
    try {
      final token = await AuthService.getToken();

      final request = http.Request('DELETE', Uri.parse('$baseUrl/$postId'));
      request.headers.addAll({
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      });
      request.body = jsonEncode({'email': UserData.email});

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return true;
      } else {
        print("Lỗi xóa bài: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Lỗi kết nối xóa bài: $e");
      return false;
    }
  }
}
