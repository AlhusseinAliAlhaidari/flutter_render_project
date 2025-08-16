// frontend/lib/main.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main( ) {
  runApp(const MyApp());
}

// نموذج بسيط لتمثيل بيانات الرسالة
class Message {
  final int id;
  final String text;

  Message({required this.id, required this.text});

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      text: json['text'],
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter & Render',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Tajawal', // يمكنك إضافة خط عربي جميل
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
  // متغير لتخزين حالة جلب البيانات (تحميل، نجاح، خطأ)
  late Future<List<Message>> futureMessages;

  @override
  void initState() {
    super.initState();
    // بدء عملية جلب البيانات عند تشغيل الشاشة
    futureMessages = fetchMessages();
  }

 // frontend/lib/main.dart

Future<List<Message>> fetchMessages() async {
  const apiUrl = 'https://flutter-render-project-bf7z.onrender.com/messages';
  print('جاري طلب البيانات من: $apiUrl' ); // للتحقق من أن الرابط صحيح

  try {
    final response = await http.get(Uri.parse(apiUrl ));

    if (response.statusCode == 200) {
      print('تم استلام استجابة ناجحة!');
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      List<dynamic> messageList = data['messages'];
      return messageList.map((json) => Message.fromJson(json)).toList();
    } else {
      // إذا فشل الطلب، ارمِ استثناءً مع رمز الحالة
      print('فشل الطلب. رمز الحالة: ${response.statusCode}');
      print('محتوى الاستجابة: ${response.body}');
      throw Exception('فشل في تحميل الرسائل. رمز الحالة: ${response.statusCode}');
    }
  } catch (e) {
    // لالتقاط أي أخطاء أخرى (مثل مشاكل الشبكة)
    print('حدث خطأ أثناء محاولة الاتصال بالـ API: $e');
    throw Exception('فشل في الاتصال بالـ API.');
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('رسائل من Render API'),
      ),
      body: Center(
        // استخدام FutureBuilder لعرض واجهة مختلفة بناءً على حالة الطلب
        child: FutureBuilder<List<Message>>(
          future: futureMessages,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              // عرض مؤشر تحميل أثناء انتظار البيانات
              return const CircularProgressIndicator();
            } else if (snapshot.hasError) {
              // عرض رسالة خطأ في حال فشل الطلب
              return Text('خطأ: ${snapshot.error}');
            } else if (snapshot.hasData) {
              // عرض قائمة الرسائل عند وصول البيانات بنجاح
              return ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  return Card(
                    margin: const EdgeInsets.all(8.0),
                    child: ListTile(
                      leading: CircleAvatar(child: Text(snapshot.data![index].id.toString())),
                      title: Text(snapshot.data![index].text),
                    ),
                  );
                },
              );
            }
            // حالة افتراضية
            return const Text('لا توجد بيانات لعرضها');
          },
        ),
      ),
    );
  }
}
