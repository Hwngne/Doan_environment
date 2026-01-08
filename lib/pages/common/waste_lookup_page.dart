import 'package:flutter/material.dart';
import '../../data/mock_data.dart'; // Import dữ liệu

class WasteLookupPage extends StatefulWidget {
  const WasteLookupPage({super.key});

  @override
  State<WasteLookupPage> createState() => _WasteLookupPageState();
}

class _WasteLookupPageState extends State<WasteLookupPage> {
  // Biến lưu lựa chọn của người dùng
  String? _selectedType;
  String? _selectedArea;

  // Danh sách kết quả tìm kiếm (Ban đầu hiển thị tất cả)
  List<WasteStation> _foundStations = stationData;

  // Hàm lọc dữ liệu khi bấm nút Tìm
  void _runFilter() {
    setState(() {
      _foundStations = stationData.where((station) {
        // Nếu chưa chọn gì (null) thì coi như đúng
        bool matchType = _selectedType == null || station.type == _selectedType;
        bool matchArea = _selectedArea == null || station.area == _selectedArea;
        return matchType && matchArea;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // Nền xám nhẹ
      appBar: AppBar(
        backgroundColor: const Color(0xFFB71C1C),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Tra cứu Trạm thu gom",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- KHUNG TÌM KIẾM  ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 10),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Bộ lọc tìm kiếm",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A237E),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // 1. Dropdown Loại rác
                  _buildDropdownLabel("Loại rác tiếp nhận"),
                  DropdownButtonFormField<String>(
                    value: _selectedType,
                    isExpanded: true, // Để chữ dài tự xuống dòng
                    hint: const Text("Chọn loại rác..."),
                    decoration: _inputDecoration(),
                    items: wasteTypesList.map((String type) {
                      return DropdownMenuItem<String>(
                        value: type,
                        child: Text(
                          type,
                          style: const TextStyle(fontSize: 13),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedType = val),
                  ),

                  const SizedBox(height: 15),

                  // 2. Dropdown Khu vực
                  _buildDropdownLabel("Khu vực"),
                  DropdownButtonFormField<String>(
                    value: _selectedArea,
                    hint: const Text("Chọn khu vực..."),
                    decoration: _inputDecoration(),
                    items: areaList.map((String area) {
                      return DropdownMenuItem<String>(
                        value: area,
                        child: Text(area, style: const TextStyle(fontSize: 14)),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedArea = val),
                  ),

                  const SizedBox(height: 25),

                  // Nút Tìm kiếm & Nút Xóa lọc
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _selectedType = null;
                              _selectedArea = null;
                              _runFilter();
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[200],
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                          child: const Text("Xóa lọc"),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _runFilter,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(
                              0xFF1A237E,
                            ), // Xanh đậm
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            "Tìm kiếm",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // --- KẾT QUẢ TÌM KIẾM ---
            Text(
              "Kết quả tìm thấy (${_foundStations.length})",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),

            // Danh sách hiển thị
            _foundStations.isEmpty
                ? const Padding(
                    padding: EdgeInsets.only(top: 30),
                    child: Center(
                      child: Text(
                        "Không tìm thấy trạm nào!",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true, // Để nằm trong SingleChildScrollView
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _foundStations.length,
                    itemBuilder: (context, index) {
                      final station = _foundStations[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 15),
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border(
                            left: BorderSide(
                              color: _getStationColor(station.type),
                              width: 5,
                            ),
                          ),
                          boxShadow: const [
                            BoxShadow(color: Colors.black12, blurRadius: 5),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              station.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const Divider(height: 20),
                            _rowInfo(Icons.delete_outline, station.type),
                            const SizedBox(height: 5),
                            _rowInfo(
                              Icons.location_on_outlined,
                              "${station.area} - ${station.address}",
                            ),
                            const SizedBox(height: 5),
                            _rowInfo(Icons.phone, station.contact),
                          ],
                        ),
                      );
                    },
                  ),

            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  // --- Các Widget phụ trợ cho code gọn ---

  Widget _buildDropdownLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
    );
  }

  Widget _rowInfo(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, color: Colors.black87),
          ),
        ),
      ],
    );
  }

  // Đổi màu viền trái theo loại rác cho đẹp
  Color _getStationColor(String type) {
    if (type.contains("nhựa")) return Colors.blue;
    if (type.contains("Giấy")) return Colors.orange;
    if (type.contains("thực phẩm")) return Colors.green;
    return Colors.grey;
  }
}
