import 'package:flutter/material.dart';
import '../../data/mock_data.dart';

class ChatDetailPage extends StatefulWidget {
  final String userName;
  final String userImage;
  final bool isOnline;

  const ChatDetailPage({
    super.key,
    required this.userName,
    required this.userImage,
    this.isOnline = false,
  });

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  // Tạo danh sách tin nhắn riêng cho trang này để thao tác (copy từ mockData)
  List<ChatMessage> messages = List.from(mockMessages);
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController =
      ScrollController(); // Để tự cuộn xuống cuối

  @override
  void initState() {
    super.initState();
    // Cuộn xuống cuối ngay khi mở
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _handleSendMessage() {
    if (_msgController.text.trim().isEmpty) return;

    String content = _msgController.text;

    // 1. HIỆN TIN NHẮN CỦA MÌNH NGAY LẬP TỨC (Realtime UI)
    setState(() {
      messages.add(
        ChatMessage(
          messageContent: content,
          messageType: "sender",
          timestamp: DateTime.now(),
        ),
      );
      _msgController.clear();
    });
    _scrollToBottom();

    // 2. GIẢ LẬP NGƯỜI KIA TRẢ LỜI (Fake Auto-reply)
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          messages.add(
            ChatMessage(
              messageContent:
                  "Ok nhé! Mình đã nhận được tin nhắn: \"$content\"", // Trả lời tự động
              messageType: "receiver",
              timestamp: DateTime.now(),
            ),
          );
        });
        _scrollToBottom();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // HEADER
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFB71C1C), // Màu đỏ chủ đạo
        flexibleSpace: SafeArea(
          child: Container(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                const SizedBox(width: 50), // Chừa chỗ cho nút Back
                CircleAvatar(
                  backgroundImage: NetworkImage(widget.userImage),
                  maxRadius: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.userName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        widget.isOnline ? "Đang hoạt động" : "Offline",
                        style: TextStyle(
                          color: widget.isOnline
                              ? Colors.greenAccent
                              : Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.settings, color: Colors.white70, size: 20),
              ],
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      body: Stack(
        children: [
          // DANH SÁCH TIN NHẮN
          Container(
            color: const Color(0xFFF5F5FA), // Nền chat hơi xám nhẹ
            padding: const EdgeInsets.only(
              bottom: 70,
            ), // Chừa chỗ cho thanh nhập liệu
            child: ListView.builder(
              controller: _scrollController,
              itemCount: messages.length,
              padding: const EdgeInsets.only(top: 10, bottom: 10),
              itemBuilder: (context, index) {
                return Container(
                  padding: const EdgeInsets.only(
                    left: 14,
                    right: 14,
                    top: 10,
                    bottom: 10,
                  ),
                  child: Align(
                    alignment: (messages[index].messageType == "receiver"
                        ? Alignment.topLeft
                        : Alignment.topRight),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        // Màu sắc: Người gửi (Xanh đen), Người nhận (Trắng/Xám)
                        color: (messages[index].messageType == "receiver"
                            ? Colors.white
                            : const Color(0xFF2C2C54)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withValues(alpha: 0.1),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        messages[index].messageContent,
                        style: TextStyle(
                          fontSize: 15,
                          color: messages[index].messageType == "receiver"
                              ? Colors.black87
                              : Colors.white,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // THANH NHẬP LIỆU (Ở DƯỚI CÙNG)
          Align(
            alignment: Alignment.bottomLeft,
            child: Container(
              padding: const EdgeInsets.only(left: 10, bottom: 10, top: 10),
              height: 70,
              width: double.infinity,
              color: Colors.white,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      height: 30,
                      width: 30,
                      decoration: BoxDecoration(
                        color: Colors.lightBlue,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: TextField(
                      controller: _msgController,
                      decoration: const InputDecoration(
                        hintText: "Nhập tin nhắn...",
                        hintStyle: TextStyle(color: Colors.black54),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  FloatingActionButton(
                    onPressed: _handleSendMessage,
                    backgroundColor: const Color(0xFFB71C1C),
                    elevation: 0,
                    mini: true, // Nút nhỏ gọn
                    child: const Icon(
                      Icons.send,
                      color: Colors.white,
                      size: 18,
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
}
