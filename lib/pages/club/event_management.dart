import 'package:flutter/material.dart';
import 'event_detail_page.dart'; // Sẽ tạo ở bước 3

class EventManagementPage extends StatefulWidget {
  const EventManagementPage({super.key});

  @override
  State<EventManagementPage> createState() => _EventManagementPageState();
}

class _EventManagementPageState extends State<EventManagementPage> {
  // Dữ liệu giả mô phỏng danh sách sự kiện
  final List<Map<String, dynamic>> _events = [
    {
      "title": "TÁC HẠI CỦA RÁC THẢI NHỰA",
      "status": "Chờ duyệt",
      "price": "Miễn phí",
      "promotion": "Chờ duyệt",
      "author": "Nguyễn Hoàng Gia Vĩ",
      "date": "16/10/2025",
    },
    {
      "title": "TÁI CHẾ 2025",
      "status": "Chấp nhận",
      "price": "Miễn phí",
      "promotion": "Đã duyệt",
      "author": "Trần Văn A",
      "date": "20/11/2025",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFB71C1C),
        title: const Text(
          "Quản lý sự kiện",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // 1. HEADER THỐNG KÊ (Màu xanh than)
          Container(
            padding: const EdgeInsets.all(20),
            color: const Color(0xFF1A237E), // Xanh than đậm
            child: Row(
              children: [
                const Icon(Icons.event_note, color: Colors.white, size: 30),
                const SizedBox(width: 10),
                const Text(
                  "Sự kiện",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  "${_events.length}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // 2. BỘ LỌC NGÀY (Date Range)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(15),
            child: Column(
              children: [
                _buildDateRow("Từ ngày", "12/10/2025"),
                const SizedBox(height: 10),
                _buildDateRow("Đến ngày", "12/11/2025"),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            child: Row(
              children: [
                // Radio button giả (Icon)
                Icon(
                  Icons.radio_button_checked,
                  color: Colors.red[900],
                  size: 16,
                ),
                const SizedBox(width: 5),
                const Text(
                  "Hiển thị tất cả sự kiện",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ],
            ),
          ),

          // 3. DANH SÁCH SỰ KIỆN
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              itemCount: _events.length,
              itemBuilder: (context, index) {
                return _buildEventCard(_events[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateRow(String label, String date) {
    return Row(
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(width: 15),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(date),
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    return GestureDetector(
      onTap: () {
        // Chuyển sang trang chi tiết
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventDetailPage(eventData: event),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(15),
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
        ),
        child: Column(
          children: [
            _buildInfoRow("Tên sự kiện", event['title'], isBold: true),
            _buildInfoRow(
              "Trạng thái",
              event['status'],
              color: event['status'] == "Chấp nhận"
                  ? Colors.green
                  : Colors.orange,
            ),
            _buildInfoRow("Giá vé", event['price']),
            _buildInfoRow("Quảng bá", event['promotion'], color: Colors.orange),
            _buildInfoRow("Người phụ trách", event['author']),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    bool isBold = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value, // Giới hạn độ dài text nếu cần
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                color: color ?? Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
