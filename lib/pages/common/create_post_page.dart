import 'dart:io'; // Để xử lý File
import 'package:file_picker/file_picker.dart'; // <--- MỚI: Thư viện chọn tệp
import 'package:flutter/foundation.dart'; // Để check kIsWeb
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart'; // Thư viện ảnh
import 'package:http/http.dart' as http; // Gọi API upload
import '../../data/mock_data.dart';

class CreatePostPage extends StatefulWidget {
  final String postType;

  const CreatePostPage({super.key, required this.postType});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  // --- CONTROLLERS ---
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  // --- DATA ---
  String? _selectedTopic;
  final List<String> _topics = [
    "Mẹo sống xanh",
    "Tin tức môi trường",
    "Hỏi đáp",
    "Góc thảo luận",
  ];

  String? _selectedCategory;
  final List<String> _categories = [
    "Đồ tái chế",
    "Đồ Handmade",
    "Nguyên liệu thô",
    "Dụng cụ làm vườn",
    "Sách báo cũ",
    "Khác",
  ];

  String _productType = "Miễn phí";

  // --- UPLOAD LOGIC ---
  bool _isUploading = false; // Trạng thái đang upload

  // 1. ẢNH
  XFile? _pickedImage;
  String? _uploadedImageUrl;

  // 2. FILE ĐÍNH KÈM (MỚI)
  PlatformFile? _pickedFile; // <--- MỚI: Biến lưu file đã chọn
  String? _uploadedFileUrl; // <--- MỚI: Biến lưu link file sau khi upload

  // Hàm định dạng tiền tệ
  String formatCurrency(String value) {
    if (value.isEmpty) return "0";
    double? num = double.tryParse(value);
    if (num == null) return value;
    return num.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  // --- 1. CHỌN ẢNH TỪ MÁY ---
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _pickedImage = image;
        });
      }
    } catch (e) {
      print("Lỗi chọn ảnh: $e");
    }
  }

  // --- 2. CHỌN FILE TÀI LIỆU (MỚI) ---
  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        // Cho phép các định dạng văn phòng phổ biến
        allowedExtensions: [
          'pdf',
          'doc',
          'docx',
          'xls',
          'xlsx',
          'ppt',
          'pptx',
          'zip',
          'rar',
          'txt',
        ],
      );

      if (result != null) {
        setState(() {
          _pickedFile = result.files.first; // Lấy file đầu tiên
        });
      }
    } catch (e) {
      print("Lỗi chọn file: $e");
    }
  }

  // --- 3. HÀM UPLOAD CHUNG (Sửa lại để dùng cho cả Ảnh và File) ---
  Future<String?> _uploadFileGeneric(List<int> bytes, String fileName) async {
    // URL của Backend
    String uploadUrl = 'http://localhost:5000/api/upload';

    try {
      var request = http.MultipartRequest('POST', Uri.parse(uploadUrl));

      request.files.add(
        http.MultipartFile.fromBytes(
          'image', // Backend đang đón key là 'image', ta cứ giữ nguyên
          bytes,
          filename: fileName,
        ),
      );

      var res = await request.send();

      if (res.statusCode == 200) {
        var responseString = await res.stream.bytesToString();
        // Server trả về đường dẫn tương đối (vd: /uploads/abc.pdf)
        // Ta cần nối thêm host vào
        return 'http://localhost:5000$responseString';
      } else {
        print("Upload thất bại: ${res.statusCode}");
        return null;
      }
    } catch (e) {
      print("Lỗi upload: $e");
      return null;
    }
  }

  // --- VALIDATION ---
  bool _validateInputs() {
    if (_titleController.text.trim().isEmpty ||
        _contentController.text.trim().isEmpty) {
      _showError("Bạn chưa điền tiêu đề hoặc nội dung!");
      return false;
    }
    if (widget.postType == "Kiến thức" && _selectedTopic == null) {
      _showError("Vui lòng chọn chủ đề!");
      return false;
    }
    if (widget.postType == "Sản phẩm") {
      if (_selectedCategory == null) {
        _showError("Vui lòng chọn loại sản phẩm!");
        return false;
      }
      if (_quantityController.text.trim().isEmpty) {
        _showError("Vui lòng nhập số lượng!");
        return false;
      }
      if (_productType == "Có phí" &&
          (_priceController.text.isEmpty || _phoneController.text.isEmpty)) {
        _showError("Vui lòng nhập giá và số điện thoại!");
        return false;
      }
    }
    return true;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  // --- 3. GIAO DIỆN XEM TRƯỚC (HIỆN ĐẠI HÓA) ---
  void _showPreviewDialog() {
    if (!_validateInputs()) return;

    // Logic hiển thị ảnh preview (Giữ nguyên)
    ImageProvider previewImage;
    if (_pickedImage != null) {
      if (kIsWeb) {
        previewImage = NetworkImage(_pickedImage!.path);
      } else {
        previewImage = FileImage(File(_pickedImage!.path));
      }
    } else {
      previewImage = NetworkImage(
        widget.postType == "Kiến thức"
            ? "https://img.freepik.com/free-vector/garbage-sorting-concept-illustration_114360-5238.jpg"
            : "https://i.pinimg.com/736x/e8/35/66/e83566735e2632280d28589710080614.jpg",
      );
    }

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(15),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header Dialog
                Padding(
                  padding: const EdgeInsets.all(15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Xem trước bài đăng",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // BODY CỦA CARD
                SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Ảnh Cover
                      Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          image: DecorationImage(
                            image: previewImage,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.all(15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (widget.postType == "Sản phẩm")
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _productType == "Miễn phí"
                                          ? Colors.green
                                          : Colors.red,
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Text(
                                      _productType == "Miễn phí"
                                          ? "MIỄN PHÍ"
                                          : "${formatCurrency(_priceController.text)} đ",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Text(
                                      _selectedCategory ?? "Sản phẩm",
                                      style: TextStyle(
                                        color: Colors.grey[800],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                            const SizedBox(height: 10),
                            Text(
                              _titleController.text,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _contentController.text,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.black87,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 15),

                            // <--- MỚI: HIỂN THỊ FILE TRONG PREVIEW (NẾU CÓ)
                            if (_pickedFile != null)
                              Container(
                                padding: const EdgeInsets.all(10),
                                margin: const EdgeInsets.only(bottom: 15),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.blue.shade200,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.attach_file,
                                      color: Colors.blue,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        "Đính kèm: ${_pickedFile!.name}",
                                        style: const TextStyle(
                                          color: Colors.blue,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 13,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 12,
                                  backgroundImage: NetworkImage(
                                    UserData.avatar,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  UserData.name,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1),

                // Nút Đăng
                Padding(
                  padding: const EdgeInsets.all(15),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context); // Tắt preview
                        _handlePost(); // Gọi hàm đăng thật
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A237E),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        "Đăng ngay",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- HÀM TẠO DỮ LIỆU ---
  ForumPost _createPostData() {
    double? postPrice;
    if (widget.postType == "Sản phẩm") {
      postPrice = _productType == "Miễn phí"
          ? 0
          : double.tryParse(_priceController.text) ?? 0;
    }

    String finalImage =
        _uploadedImageUrl ??
        (widget.postType == "Kiến thức"
            ? "https://img.freepik.com/free-vector/garbage-sorting-concept-illustration_114360-5238.jpg"
            : "https://i.pinimg.com/736x/e8/35/66/e83566735e2632280d28589710080614.jpg");

    return ForumPost(
      id: "", // ID sẽ do Backend cấp sau
      authorName: UserData.name,
      authorAvatar: UserData.avatar,
      time: "Vừa xong",
      timestamp: DateTime.now(),
      tagName: widget.postType,
      topic: _selectedTopic,
      category: _selectedCategory,
      price: postPrice,
      content: widget.postType == "Kiến thức"
          ? "${_titleController.text}\n\n${_contentController.text}"
          : "📦 ${_titleController.text}\n"
                "🏷️ Loại: $_selectedCategory\n"
                "🔢 Số lượng: ${_quantityController.text}\n"
                "${_productType == "Miễn phí" ? "🎁 Miễn phí" : "💵 ${_priceController.text} đ"}\n"
                "----------------\n"
                "📝 ${_contentController.text}\n"
                "📞 Liên hệ: ${_phoneController.text}",
      image: finalImage,

      // <--- MỚI: TRUYỀN THÔNG TIN FILE VÀO
      attachmentUrl: _uploadedFileUrl,
      attachmentName: _pickedFile?.name,

      likes: 0,
      comments: 0,
      isLiked: false,
    );
  }

  // --- XỬ LÝ ĐĂNG BÀI (ĐÃ CẬP NHẬT UPLOAD FILE) ---
  Future<void> _handlePost() async {
    if (_validateInputs()) {
      setState(() => _isUploading = true);

      // 1. UPLOAD ẢNH (NẾU CÓ)
      if (_pickedImage != null && _uploadedImageUrl == null) {
        var bytes = await _pickedImage!.readAsBytes();
        _uploadedImageUrl = await _uploadFileGeneric(bytes, _pickedImage!.name);

        if (_uploadedImageUrl == null) {
          _showError("Lỗi upload ảnh! Đang dùng ảnh mặc định.");
        }
      }

      // 2. UPLOAD FILE ĐÍNH KÈM (NẾU CÓ) <--- MỚI
      if (_pickedFile != null && _uploadedFileUrl == null) {
        // Đọc bytes của file
        List<int>? fileBytes;

        if (kIsWeb) {
          fileBytes = _pickedFile!.bytes; // Web có sẵn bytes
        } else if (_pickedFile!.path != null) {
          fileBytes = File(
            _pickedFile!.path!,
          ).readAsBytesSync(); // Mobile đọc từ path
        }

        if (fileBytes != null) {
          _uploadedFileUrl = await _uploadFileGeneric(
            fileBytes,
            _pickedFile!.name,
          );
        } else {
          _showError("Không thể đọc file đính kèm!");
        }
      }

      setState(() => _isUploading = false);

      // 3. Đóng gói và trả về
      final newPost = _createPostData();
      Navigator.pop(context, newPost);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Đã đăng bài thành công!")));
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isKnowledge = widget.postType == "Kiến thức";
    Color tagColor = isKnowledge ? Colors.blue : const Color(0xFF009688);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFB71C1C),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Bài viết mới",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Stack(
        // Bọc Stack để hiển thị Loading
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.white, Color(0xFFFCE4EC), Color(0xFFE3F2FD)],
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User Info
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundImage: NetworkImage(UserData.avatar),
                      ),
                      const SizedBox(width: 15),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            UserData.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF1A237E),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: tagColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              widget.postType,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),

                  if (isKnowledge)
                    _buildKnowledgeForm()
                  else
                    _buildProductForm(),

                  const SizedBox(height: 20),

                  // --- VÙNG HIỂN THỊ ẢNH ---
                  if (_pickedImage != null)
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: kIsWeb
                              ? Image.network(
                                  _pickedImage!.path,
                                  height: 200,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                )
                              : Image.file(
                                  File(_pickedImage!.path),
                                  height: 200,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                        ),
                        Positioned(
                          top: 10,
                          right: 10,
                          child: GestureDetector(
                            onTap: () => setState(() => _pickedImage = null),
                            child: const CircleAvatar(
                              backgroundColor: Colors.red,
                              radius: 15,
                              child: Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                  // --- VÙNG HIỂN THỊ FILE ĐÍNH KÈM (MỚI) ---
                  if (_pickedFile != null)
                    Container(
                      margin: const EdgeInsets.only(top: 15),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.blue.shade200),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 2,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.attach_file,
                            color: Colors.blue,
                            size: 24,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _pickedFile!.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                                Text(
                                  "${(_pickedFile!.size / 1024).toStringAsFixed(1)} KB",
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () => setState(() => _pickedFile = null),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 30),

                  // Buttons
                  Row(
                    children: [
                      _buildMediaButton(
                        Icons.image_outlined,
                        "Thư viện",
                        const Color(0xFFFFF0F0),
                        onTap: _pickImage,
                      ),
                      const SizedBox(width: 15),
                      // <--- MỚI: KÍCH HOẠT NÚT ĐÍNH KÈM
                      _buildMediaButton(
                        Icons.attach_file,
                        "Đính kèm",
                        const Color(0xFFF0F4FF),
                        onTap: _pickFile,
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _showPreviewDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[300],
                            foregroundColor: Colors.black87,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: const Text(
                            "Xem trước",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _handlePost,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[300],
                            foregroundColor: const Color(0xFF1A237E),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: const Text(
                            "Đăng",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),

          // MÀN HÌNH LOADING KHI UPLOAD
          if (_isUploading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 10),
                    Text(
                      "Đang tải dữ liệu lên...",
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // --- CÁC WIDGET CON (GIỮ NGUYÊN) ---
  Widget _buildMediaButton(
    IconData icon,
    String label,
    Color bgColor, {
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(15),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 2,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: const Color(0xFF1A237E), size: 28),
              const SizedBox(height: 5),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A237E),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKnowledgeForm() {
    return Column(
      children: [
        _buildDropdownField(
          hint: "Chủ đề bài viết",
          value: _selectedTopic,
          items: _topics,
          onChanged: (val) => setState(() => _selectedTopic = val),
        ),
        const SizedBox(height: 15),
        _buildInputField(
          controller: _titleController,
          hint: "Tiêu đề bài viết",
        ),
        const SizedBox(height: 15),
        _buildInputField(
          controller: _contentController,
          hint: "Bạn đang nghĩ gì?",
          maxLines: 8,
          height: 200,
        ),
      ],
    );
  }

  Widget _buildProductForm() {
    return Column(
      children: [
        Row(
          children: [
            const SizedBox(
              width: 100,
              child: Text(
                "Loại sản phẩm",
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            Expanded(
              child: _buildDropdownField(
                hint: "Chọn loại...",
                value: _selectedCategory,
                items: _categories,
                onChanged: (val) => setState(() => _selectedCategory = val),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            const SizedBox(
              width: 100,
              child: Text(
                "Tên sản phẩm",
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            Expanded(
              child: _buildInputField(
                controller: _titleController,
                hint: "VD: Chậu hoa tái chế",
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            const SizedBox(
              width: 100,
              child: Text(
                "Số lượng",
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            Expanded(
              child: _buildInputField(
                controller: _quantityController,
                hint: "VD: 01",
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(
              width: 100,
              child: Padding(
                padding: EdgeInsets.only(top: 15),
                child: Text(
                  "Mô tả",
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ),
            Expanded(
              child: _buildInputField(
                controller: _contentController,
                hint: "Mô tả chi tiết...",
                maxLines: 4,
                height: 120,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            const SizedBox(
              width: 100,
              child: Text(
                "Hình thức",
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            _buildChoiceChip("Miễn phí", Colors.grey[200]!, Colors.black54),
            const SizedBox(width: 10),
            _buildChoiceChip("Có phí", Colors.red[50]!, Colors.red),
          ],
        ),
        if (_productType == "Có phí") ...[
          const SizedBox(height: 20),
          Row(
            children: [
              const SizedBox(
                width: 100,
                child: Text(
                  "Giá tiền",
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              Expanded(
                child: _buildInputField(
                  controller: _priceController,
                  hint: "VD: 100000",
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(12),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              const SizedBox(
                width: 100,
                child: Text(
                  "SĐT liên lạc",
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              Expanded(
                child: _buildInputField(
                  controller: _phoneController,
                  hint: "Nhập số điện thoại",
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildDropdownField({
    required String hint,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1)),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(
            hint,
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
          ),
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down),
          items: items
              .map(
                (String item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(item, style: const TextStyle(fontSize: 14)),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildChoiceChip(String label, Color bgColor, Color activeColor) {
    bool isSelected = _productType == label;
    Color finalBgColor = isSelected ? activeColor : bgColor;
    if (label == "Miễn phí" && isSelected) finalBgColor = Colors.green;
    return GestureDetector(
      onTap: () => setState(() => _productType = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: finalBgColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black54,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    double? height,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1)),
        ],
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 15,
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
