// frontend/lib/main.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// !!! هام: تأكد من أن هذا الرابط هو الرابط الصحيح لخدمتك على Render
const String API_BASE_URL = 'https://flutter-render-project-bf7z.onrender.com';

void main( ) {
  runApp(const MyApp());
}

// --- نموذج البيانات ---
class Message {
  int id;
  String text;

  Message({required this.id, required this.text});

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(id: json['id'], text: json['text']);
  }
}

// --- طبقة خدمة الـ API (لتنظيم الكود) ---
class ApiService {
  // جلب
  Future<List<Message>> fetchMessages() async {
    final response = await http.get(Uri.parse('$API_BASE_URL/messages' ));
    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
      return data.map((json) => Message.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load messages');
    }
  }

  // إضافة
  Future<Message> createMessage(String text) async {
    final response = await http.post(
      Uri.parse('$API_BASE_URL/messages' ),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({'text': text}),
    );
    if (response.statusCode == 201) {
      return Message.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Failed to create message.');
    }
  }

  // تعديل
  Future<void> updateMessage(int id, String text) async {
    final response = await http.put(
      Uri.parse('$API_BASE_URL/messages/$id' ),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({'text': text}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update message.');
    }
  }

  // حذف
  Future<void> deleteMessage(int id) async {
    final response = await http.delete(Uri.parse('$API_BASE_URL/messages/$id' ));
    if (response.statusCode != 204) {
      throw Exception('Failed to delete message.');
    }
  }
}

// --- واجهة المستخدم ---
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter CRUD',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        fontFamily: 'Tajawal',
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      debugShowCheckedModeBanner: false,
      home: const MessagesScreen(),
    );
  }
}

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<Message>> _messagesFuture;

  @override
  void initState() {
    super.initState();
    _refreshMessages();
  }

  void _refreshMessages() {
    setState(() {
      _messagesFuture = _apiService.fetchMessages();
    });
  }

  void _showMessageDialog({Message? message}) {
    final textController = TextEditingController(text: message?.text ?? '');
    final isUpdating = message != null;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isUpdating ? 'تعديل الرسالة' : 'إضافة رسالة جديدة'),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'اكتب رسالتك هنا'),
        ),
        actions: [
          TextButton(
            child: const Text('إلغاء'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: Text(isUpdating ? 'حفظ التعديل' : 'إضافة'),
            onPressed: () {
              final text = textController.text;
              if (text.isNotEmpty) {
                _handleApiCall(
                  isUpdating
                      ? _apiService.updateMessage(message.id, text)
                      : _apiService.createMessage(text),
                );
                Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
    );
  }

  void _handleApiCall(Future<dynamic> apiCall) async {
    try {
      await apiCall;
      _refreshMessages();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('قائمة الرسائل (CRUD)'),
      ),
      body: FutureBuilder<List<Message>>(
        future: _messagesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('خطأ: ${snapshot.error}'));
          } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            final messages = snapshot.data!;
            return ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                return Dismissible(
                  key: Key(message.id.toString()),
                  direction: DismissDirection.startToEnd,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (direction) {
                    _handleApiCall(_apiService.deleteMessage(message.id));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('تم حذف "${message.text}"')),
                    );
                  },
                  child: Card(
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: ListTile(
                      title: Text(message.text),
                      onLongPress: () => _showMessageDialog(message: message),
                    ),
                  ),
                );
              },
            );
          } else {
            return const Center(child: Text('لا توجد رسائل. قم بإضافة واحدة!'));
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showMessageDialog(),
        tooltip: 'إضافة رسالة',
        child: const Icon(Icons.add),
      ),
    );
  }
}
