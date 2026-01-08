import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Thư viện để chặn nhập chữ/số
import 'package:image_picker/image_picker.dart'; // Thư viện chọn ảnh
import 'package:file_picker/file_picker.dart'; // Thư viện chọn file
import '../../services/user_service.dart';

class CreateEventPage extends StatefulWidget {
  const CreateEventPage({super.key});

  @override
  State<CreateEventPage> createState() => _CreateEventPageState();
}

class _CreateEventPageState extends State<CreateEventPage> {
  // --- BIẾN TRẠNG THÁI ---
  bool _isPaid = false; // Mặc định là Miễn phí

  // --- CONTROLLERS (Quản lý nhập liệu) ---
  final _nameController = TextEditingController();
  final _topicController = TextEditingController();
  final _descController = TextEditingController();
  final _locationController = TextEditingController();
  final _priceController = TextEditingController();

  // Liên hệ
  final _contactNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _formLinkController = TextEditingController();

  // --- BIẾN LƯU TRỮ FILE/ẢNH ---
  XFile? _selectedImage;
  PlatformFile? _selectedFile;

  // --- BIẾN NGÀY GIỜ ---
  String _selectedDate = "";
  String _startTime = "";
  String _endTime = "";

  @override
  void initState() {
    super.initState();
    // Tự động điền thông tin người dùng nếu có
    _contactNameController.text = UserData.name ?? "";
    _emailController.text = UserData.email ?? "";
    _phoneController.text = UserData.phone ?? "";
  }

  // --- HÀM KIỂM TRA LINK HỢP LỆ ---
  bool _isValidUrl(String url) {
    return Uri.tryParse(url)?.hasAbsolutePath ?? false;
  }

  // --- HÀM VALIDATE (Kiểm tra nhập liệu) ---
  bool _validateInputs() {
    // 1. Kiểm tra rỗng các trường bắt buộc
    if (_nameController.text.isEmpty ||
        _topicController.text.isEmpty ||
        _descController.text.isEmpty ||
        _locationController.text.isEmpty ||
        _selectedDate.isEmpty ||
        _startTime.isEmpty ||
        _endTime.isEmpty ||
        _contactNameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _formLinkController.text.isEmpty) {
      _showSnackBar("Vui lòng điền đầy đủ thông tin bắt buộc (*)", Colors.red);
      return false;
    }

    // 2. Kiểm tra tiền vé (nếu chọn Có phí)
    if (_isPaid && _priceController.text.isEmpty) {
      _showSnackBar("Vui lòng nhập giá vé", Colors.red);
      return false;
    }

    // 3. Kiểm tra số điện thoại (10-11 số)
    String phone = _phoneController.text.trim();
    if (phone.length < 10 || phone.length > 11) {
      _showSnackBar(
        "Số điện thoại không hợp lệ (phải từ 10-11 số)",
        Colors.orange,
      );
      return false;
    }

    // 4. Kiểm tra Link Form đăng ký
    if (!_isValidUrl(_formLinkController.text.trim())) {
      _showSnackBar(
        "Link form không hợp lệ (Phải có http:// hoặc https://)",
        Colors.orange,
      );
      return false;
    }

    return true;
  }

  // Helper hiện thông báo
  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  // --- HÀM CHỌN ẢNH ---
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = image;
      });
    }
  }

  // --- HÀM CHỌN FILE ---
  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      setState(() {
        _selectedFile = result.files.first;
      });
    }
  }

  // --- HÀM CHỌN NGÀY ---
  Future<void> _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: const Color(0xFFB71C1C),
            colorScheme: const ColorScheme.light(primary: Color(0xFFB71C1C)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  // --- HÀM CHỌN GIỜ ---
  Future<void> _pickTime(bool isStart) async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        String formattedTime =
            "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
        if (isStart) {
          _startTime = formattedTime;
        } else {
          _endTime = formattedTime;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double headerHeight = size.height * 0.25;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          "Sự kiện mới",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: Stack(
        children: [
          // 1. HEADER NỀN ĐỎ
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: headerHeight,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFB71C1C), // Đỏ đậm
                    Color(0xFFD32F2F), // Đỏ tươi
                  ],
                ),
              ),
            ),
          ),

          // 2. FORM NHẬP LIỆU (NỀN GRADIENT HỒNG-TRẮNG-XANH)
          SafeArea(
            bottom: false,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              margin: const EdgeInsets.only(top: 60),
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 20),
                child: Container(
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
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Header Info CLB
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 25,
                              backgroundImage: NetworkImage(
                                UserData.avatar ?? "https://i.pravatar.cc/300",
                              ),
                            ),
                            const SizedBox(width: 15),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  UserData.name ?? "Câu Lạc Bộ",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.green),
                                  ),
                                  child: const Text(
                                    "CLB | Sự kiện",
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // NỘI DUNG FORM
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionTitle("Thông tin sự kiện"),
                            const SizedBox(height: 15),

                            _buildLabel("Tên sự kiện", isRequired: true),
                            _buildTextField(
                              hint: "TÁC HẠI CỦA RÁC THẢI...",
                              controller: _nameController,
                            ),

                            _buildLabel("Chủ đề", isRequired: true),
                            _buildTextField(
                              hint: "Tái chế và phân loại",
                              controller: _topicController,
                            ),

                            _buildLabel("Mô tả sự kiện", isRequired: true),
                            _buildTextField(
                              hint: "Nhập mô tả chi tiết...",
                              controller: _descController,
                              maxLines: 4,
                            ),

                            _buildLabel("Hình thức", isRequired: true),
                            const SizedBox(height: 8),
                            // Toggle Button
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Row(
                                children: [
                                  _buildToggleButton("Miễn phí", !_isPaid),
                                  _buildToggleButton("Có phí", _isPaid),
                                ],
                              ),
                            ),

                            // Hiển thị ô nhập tiền nếu chọn Có phí
                            if (_isPaid) ...[
                              const SizedBox(height: 15),
                              _buildLabel("Tiền vé", isRequired: true),
                              _buildTextField(
                                hint: "100.000",
                                controller: _priceController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ], // Chỉ cho nhập số
                                suffixText: "VND",
                              ),
                            ],

                            const SizedBox(height: 15),
                            _buildLabel("Địa điểm", isRequired: true),
                            _buildTextField(
                              hint: "CS3.F.09.10",
                              controller: _locationController,
                            ),

                            _buildLabel("Ngày tổ chức", isRequired: true),
                            GestureDetector(
                              onTap: _pickDate,
                              child: _buildTextField(
                                hint: _selectedDate.isEmpty
                                    ? "dd/mm/yyyy"
                                    : _selectedDate,
                                enabled: false,
                                icon: Icons.calendar_today,
                              ),
                            ),

                            _buildLabel("Thời gian", isRequired: true),
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => _pickTime(true),
                                    child: _buildTextField(
                                      hint: _startTime.isEmpty
                                          ? "--:--"
                                          : _startTime,
                                      enabled: false,
                                      icon: Icons.access_time_filled,
                                      iconColor: const Color(0xFF1A237E),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  "-",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => _pickTime(false),
                                    child: _buildTextField(
                                      hint: _endTime.isEmpty
                                          ? "--:--"
                                          : _endTime,
                                      enabled: false,
                                      icon: Icons.access_time_filled,
                                      iconColor: const Color(0xFF1A237E),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 30),
                            const Divider(),
                            const SizedBox(height: 10),

                            _buildSectionTitle("Thông tin liên hệ"),
                            const SizedBox(height: 15),

                            _buildLabel("Người phụ trách", isRequired: true),
                            _buildTextField(
                              hint: "Họ tên",
                              controller: _contactNameController,
                            ),

                            _buildLabel("Email", isRequired: true),
                            _buildTextField(
                              hint: "email@domain.com",
                              controller: _emailController,
                            ),

                            _buildLabel("Sđt", isRequired: true),
                            _buildTextField(
                              hint: "Số điện thoại",
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(
                                  11,
                                ), // Max 11 số
                              ],
                            ),

                            _buildLabel("Form đăng ký", isRequired: true),
                            _buildTextField(
                              hint: "https://example.com/form",
                              controller: _formLinkController,
                              keyboardType: TextInputType.url, // Bàn phím URL
                            ),

                            const SizedBox(height: 30),
                            const Divider(),
                            const SizedBox(height: 10),

                            _buildSectionTitle("Thông tin bổ sung"),
                            const SizedBox(height: 15),

                            Row(
                              children: [
                                Expanded(
                                  child: _buildUploadButton(
                                    icon: Icons.image_outlined,
                                    label: _selectedImage != null
                                        ? "Đã chọn ảnh"
                                        : "Thư viện",
                                    onTap: _pickImage,
                                    isSelected: _selectedImage != null,
                                  ),
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: _buildUploadButton(
                                    icon: Icons.attach_file,
                                    label: _selectedFile != null
                                        ? _selectedFile!.name
                                        : "Đính kèm",
                                    onTap: _pickFile,
                                    isSelected: _selectedFile != null,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 40),

                            // BUTTON ACTION
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      if (_validateInputs()) {
                                        _showPreviewDialog();
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: Colors.black,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 15,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      elevation: 2,
                                    ),
                                    child: const Text(
                                      "Xem trước",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      if (_validateInputs()) {
                                        _showSuccessDialog();
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFFFF0F0),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 15,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      elevation: 2,
                                      side: const BorderSide(
                                        color: Color(0xFFB71C1C),
                                        width: 1,
                                      ),
                                    ),
                                    child: const Text(
                                      "Gửi yêu cầu",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFB71C1C),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 50),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- CÁC WIDGET CON (UI Components) ---

  // Tiêu đề phần
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF2C2C54),
      ),
    );
  }

  // Nhãn (Label)
  Widget _buildLabel(String label, {bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 10),
      child: RichText(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            color: Color(0xFF2C2C54),
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          children: [
            if (isRequired)
              const TextSpan(
                text: " *",
                style: TextStyle(color: Colors.red),
              ),
          ],
        ),
      ),
    );
  }

  // Ô nhập liệu (Text Field)
  Widget _buildTextField({
    required String hint,
    TextEditingController? controller,
    int maxLines = 1,
    bool enabled = true,
    IconData? icon,
    Color? iconColor,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? suffixText,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        enabled: enabled,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 15,
          ),
          suffixIcon: icon != null
              ? Icon(icon, color: iconColor ?? Colors.grey)
              : null,
          suffixText: suffixText,
          suffixStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }

  // Nút chuyển đổi (Toggle)
  Widget _buildToggleButton(String text, bool isSelected) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _isPaid = (text == "Có phí");
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFE3F2FD) : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                color: isSelected ? const Color(0xFF1565C0) : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Nút tải lên (Upload)
  Widget _buildUploadButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: isSelected ? Colors.red[50] : const Color(0xFFFFF0F0),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFFFFCDD2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFFB71C1C)),
            const SizedBox(height: 5),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF2C2C54),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- POPUP XEM TRƯỚC (Preview Dialog) ---
  void _showPreviewDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Popup
              Padding(
                padding: const EdgeInsets.all(15),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: NetworkImage(UserData.avatar ?? ""),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          UserData.name ?? "CLB",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            "CLB",
                            style: TextStyle(fontSize: 10, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      _selectedDate,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),

              // Nội dung xem trước
              Container(
                color: const Color(0xFFFFF5F5), // Nền hồng nhạt
                padding: const EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _nameController.text.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C2C54),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Ảnh (Placeholder hoặc ảnh thật)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: _selectedImage != null
                          ? Image.file(
                              File(_selectedImage!.path),
                              height: 150,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            )
                          : Image.network(
                              "https://picsum.photos/400/200",
                              height: 150,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                    ),

                    const SizedBox(height: 10),
                    Text(
                      _descController.text,
                      style: TextStyle(color: Colors.grey[700], fontSize: 13),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 15),

                    const Text(
                      "Thông tin sự kiện",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 5),
                    _buildPreviewInfo(
                      "Thời gian:",
                      "$_startTime - $_endTime, ngày $_selectedDate",
                    ),
                    _buildPreviewInfo("Địa điểm:", _locationController.text),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Text(
                          "Giá vé: ",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          _isPaid
                              ? "${_priceController.text} VND/người"
                              : "Miễn phí",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Đăng ký:",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _formLinkController.text,
                      style: const TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),

              // Buttons Footer
              Padding(
                padding: const EdgeInsets.all(15),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          "Hủy",
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context); // Đóng preview
                          _showSuccessDialog(); // Hiện success
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: const Color(0xFFB71C1C),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          "Gửi yêu cầu",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- POPUP THÀNH CÔNG (Success Dialog) ---
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(15),
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 20),
              const Text(
                "Gửi yêu cầu thành công",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C2C54),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Vui lòng đợi phản hồi từ nhà trường",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 25),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context); // Đóng popup
                        Navigator.pop(context); // Về trang chủ
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB71C1C),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        "Về trang chủ",
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // Logic chuyển sang trang Quản lý sự kiện sau này
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB71C1C),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        "Quản lý Sự kiện",
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper cho Preview Info
  Widget _buildPreviewInfo(String label, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "• $label ",
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Expanded(
            child: Text(
              content,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
