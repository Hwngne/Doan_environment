import 'package:flutter/material.dart';
import '../../data/mock_data.dart';
import '../../components/app_background.dart';

class TransactionHistoryPage extends StatefulWidget {
  const TransactionHistoryPage({super.key});

  @override
  State<TransactionHistoryPage> createState() => _TransactionHistoryPageState();
}

class _TransactionHistoryPageState extends State<TransactionHistoryPage> {
  // Biến bộ lọc
  String _selectedRole = "All"; // All, Bên mua, Bên bán, Đổi quà
  DateTime? _fromDate;
  DateTime? _toDate;

  final TextEditingController _fromDateController = TextEditingController();
  final TextEditingController _toDateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Mặc định lọc từ đầu năm đến hiện tại
    _fromDate = DateTime(2025, 1, 1);
    _toDate = DateTime.now();

    _fromDateController.text = "1/1/2025";
    _toDateController.text =
        "${_toDate!.day}/${_toDate!.month}/${_toDate!.year}";
  }

  // Hàm chọn ngày (Tái sử dụng logic chuẩn từ MyPostsPage)
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

  @override
  Widget build(BuildContext context) {
    // LOGIC LỌC DỮ LIỆU
    final filteredList = transactionHistory.where((item) {
      // 1. Lọc theo Vai trò
      bool matchRole = _selectedRole == "All" || item.role == _selectedRole;

      // 2. Lọc theo Ngày
      bool matchDate = true;
      if (_fromDate != null) {
        matchDate =
            matchDate &&
            !item.date.isBefore(
              _fromDate!.copyWith(hour: 0, minute: 0, second: 0),
            );
      }
      if (_toDate != null) {
        matchDate =
            matchDate &&
            !item.date.isAfter(
              _toDate!.copyWith(hour: 23, minute: 59, second: 59),
            );
      }

      return matchRole && matchDate;
    }).toList();

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
                        "Lịch sử giao dịch",
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
                    // 1. THẺ THỐNG KÊ (Xanh đen)
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
                                Icons.history,
                                color: Colors.white,
                                size: 30,
                              ),
                              SizedBox(width: 15),
                              Text(
                                "Giao dịch",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            "${filteredList.length}",
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

                    // 2. BỘ LỌC NGÀY
                    _buildDateInput("Từ ngày", _fromDateController, true),
                    const SizedBox(height: 15),
                    _buildDateInput("Đến ngày", _toDateController, false),

                    const SizedBox(height: 20),

                    // 3. BỘ LỌC LOẠI GIAO DỊCH
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          const Text(
                            "Loại giao dịch",
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(width: 15),
                          _buildFilterChip(
                            "Bên mua",
                            Colors.red[100]!,
                            Colors.red[900]!,
                          ),
                          const SizedBox(width: 10),
                          _buildFilterChip(
                            "Bên bán",
                            Colors.blue[100]!,
                            Colors.blue[900]!,
                          ),
                          const SizedBox(width: 10),
                          _buildFilterChip(
                            "Đổi quà",
                            Colors.orange[100]!,
                            Colors.orange[900]!,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 15),

                    // Nút "Hiển thị tất cả"
                    GestureDetector(
                      onTap: () => setState(() => _selectedRole = "All"),
                      child: Row(
                        children: [
                          Icon(
                            _selectedRole == "All"
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            size: 24,
                            color: _selectedRole == "All"
                                ? const Color(0xFFB71C1C)
                                : Colors.grey,
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            "Hiển thị tất cả giao dịch",
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                    const Divider(thickness: 1, color: Colors.black12),
                    const SizedBox(height: 10),

                    // 4. DANH SÁCH GIAO DỊCH
                    filteredList.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.only(top: 50),
                              child: Text(
                                "Chưa có giao dịch nào.",
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: filteredList.length,
                            itemBuilder: (context, index) =>
                                _buildTransactionCard(filteredList[index]),
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

  // --- Widget ô chọn ngày ---
  Widget _buildDateInput(
    String label,
    TextEditingController controller,
    bool isFrom,
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
            onTap: () => _selectDate(context, controller, isFrom),
            child: Container(
              height: 45,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.black12),
              ),
              child: TextField(
                controller: controller,
                enabled: false,
                textAlignVertical: TextAlignVertical.center,
                style: const TextStyle(color: Colors.black),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  suffixIcon: Icon(
                    Icons.calendar_today,
                    size: 18,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- Widget nút lọc ---
  Widget _buildFilterChip(String label, Color bg, Color text) {
    bool isSelected = _selectedRole == label;
    return InkWell(
      onTap: () => setState(() => _selectedRole = isSelected ? "All" : label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? bg : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? Border.all(color: text.withValues(alpha: 0.5))
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? text : Colors.black54,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  // --- Widget Thẻ Giao Dịch (Thiết kế giống ảnh) ---
  Widget _buildTransactionCard(TransactionItem item) {
    // Xác định màu trạng thái
    Color statusColor = Colors.green;
    String statusText = "Đã hoàn thành";

    if (item.status == TransactionStatus.pending) {
      statusColor = Colors.red;
      statusText = "Chưa trao đổi/bán"; // Giống ảnh mẫu
    } else if (item.status == TransactionStatus.cancelled) {
      statusColor = Colors.grey;
      statusText = "Đã hủy";
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFFCE4EC), // Màu nền hồng phấn nhạt như thiết kế
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildRowInfo("Mã giao dịch", item.id),
          const SizedBox(height: 10),
          _buildRowInfo("Tên món", item.itemName), // Thêm dòng này cho rõ nghĩa
          const SizedBox(height: 10),
          _buildRowInfo("Trạng thái", statusText, valueColor: statusColor),
          const SizedBox(height: 10),
          _buildRowInfo("Vai trò", item.role),
          const SizedBox(height: 10),
          _buildRowInfo("Giá tiền", item.price),
        ],
      ),
    );
  }

  // Helper tạo dòng thông tin trong ô trắng
  Widget _buildRowInfo(String label, String value, {Color? valueColor}) {
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white, // Nền trắng cho ô input giả
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: valueColor ?? Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }
}
