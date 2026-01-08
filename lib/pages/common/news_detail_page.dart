import 'package:flutter/material.dart';
import '../../data/mock_data.dart';
import 'quizz_page.dart'; // Import trang làm bài Quiz

class NewsDetailPage extends StatelessWidget {
  final NewsItem item;

  const NewsDetailPage({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Header đỏ
      appBar: AppBar(
        backgroundColor: const Color(0xFFB71C1C),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          item.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
      ),

      body: Container(
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF3DDDD), Colors.white],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.network(
                  item.image,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) =>
                      Container(height: 200, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                item.title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s.\n\nIt is a long established fact that a reader will be distracted by the readable content of a page when looking at its layout.\n\nLorem Ipsum is simply dummy text of the printing and typesetting industry.",
                style: TextStyle(
                  fontSize: 16,
                  height: 1.6,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 40),

              // --- SỬA Ở ĐÂY: LINK QUIZ CHỮ ĐỎ NHƯ THIẾT KẾ ---
              if (item.question.isNotEmpty) // Chỉ hiện nếu bài báo có câu hỏi
                InkWell(
                  onTap: () {
                    // Chuyển sang màn hình QuizPage (Thiết kế Image 2)
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => QuizPage(
                          articleTitle: item.title,
                          questions: item
                              .question, // Truyền danh sách câu hỏi của bài này qua
                        ),
                      ),
                    );
                  },
                  child: const Text(
                    "Quiz tích điểm",
                    style: TextStyle(
                      color: Color(0xFFD32F2F), // Màu đỏ
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline, // Gạch chân
                      fontSize: 16,
                    ),
                  ),
                )
              else
                const Text(
                  "Bài viết này không có Quiz.",
                  style: TextStyle(color: Colors.grey),
                ),

              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }
}
