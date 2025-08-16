// frontend/lib/main.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart'; // لاستخدامها في تنسيق الأرقام والتواريخ

// !!! هام: تأكد من أن هذا الرابط هو الرابط الصحيح لخدمتك على Render
const String API_BASE_URL = 'https://flutter-render-project-bf7z.onrender.com';

void main( ) {
  runApp(const MyApp());
}

// --- نماذج البيانات ---
enum TransactionType { income, expense }

class Transaction {
  final int id;
  final String description;
  final double amount;
  final TransactionType type;
  final DateTime date;

  Transaction({
    required this.id,
    required this.description,
    required this.amount,
    required this.type,
    required this.date,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      description: json['description'],
      amount: json['amount'].toDouble(),
      type: json['type'] == 'income' ? TransactionType.income : TransactionType.expense,
      date: DateTime.parse(json['date']),
    );
  }
}

class AccountSummary {
  final double totalIncome;
  final double totalExpense;
  final double balance;

  AccountSummary({
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
  });

  factory AccountSummary.fromJson(Map<String, dynamic> json) {
    return AccountSummary(
      totalIncome: json['total_income'].toDouble(),
      totalExpense: json['total_expense'].toDouble(),
      balance: json['balance'].toDouble(),
    );
  }
}

// --- طبقة خدمة الـ API ---
class ApiService {
  Future<List<Transaction>> fetchTransactions() async {
    final response = await http.get(Uri.parse('$API_BASE_URL/transactions' ));
    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
      return data.map((json) => Transaction.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load transactions');
    }
  }

  Future<AccountSummary> fetchSummary() async {
    final response = await http.get(Uri.parse('$API_BASE_URL/summary' ));
    if (response.statusCode == 200) {
      return AccountSummary.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Failed to load summary');
    }
  }

  Future<void> createTransaction(String description, double amount, TransactionType type) async {
    final response = await http.post(
      Uri.parse('$API_BASE_URL/transactions' ),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({
        'description': description,
        'amount': amount,
        'type': type == TransactionType.income ? 'income' : 'expense',
      }),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to create transaction.');
    }
  }

  Future<void> deleteTransaction(int id) async {
    final response = await http.delete(Uri.parse('$API_BASE_URL/transactions/$id' ));
    if (response.statusCode != 204) {
      throw Exception('Failed to delete transaction.');
    }
  }
}

// --- واجهة المستخدم ---
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'برنامج المحاسبة',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        fontFamily: 'Tajawal',
        scaffoldBackgroundColor: const Color(0xFFF4F6F8),
      ),
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  Future<List<dynamic>>? _dataFuture;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    setState(() {
      // جلب الملخص والحركات في طلب واحد متزامن
      _dataFuture = Future.wait([
        _apiService.fetchSummary(),
        _apiService.fetchTransactions(),
      ]);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة التحكم المالية'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
          ),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('خطأ في تحميل البيانات: ${snapshot.error}'));
          }
          if (snapshot.hasData) {
            final summary = snapshot.data![0] as AccountSummary;
            final transactions = snapshot.data![1] as List<Transaction>;

            return Column(
              children: [
                SummaryCard(summary: summary),
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('أحدث الحركات', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: transactions.isEmpty
                      ? const Center(child: Text('لا توجد حركات مسجلة.'))
                      : TransactionList(
                          transactions: transactions,
                          onDelete: (id) async {
                            try {
                              await _apiService.deleteTransaction(id);
                              _refreshData();
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل الحذف: $e')));
                            }
                          },
                        ),
                ),
              ],
            );
          }
          return const Center(child: Text('لا توجد بيانات'));
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTransactionDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddTransactionDialog() {
    final descriptionController = TextEditingController();
    final amountController = TextEditingController();
    TransactionType type = TransactionType.expense; // القيمة الافتراضية

    showDialog(
      context: context,
      builder: (context) {
        // استخدام StatefulWidgetBuilder للسماح بتحديث الحالة داخل مربع الحوار
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('إضافة حركة جديدة'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: descriptionController, decoration: const InputDecoration(labelText: 'الوصف')),
                    TextField(controller: amountController, decoration: const InputDecoration(labelText: 'المبلغ'), keyboardType: TextInputType.number),
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('النوع:'),
                          Radio<TransactionType>(
                            value: TransactionType.expense,
                            groupValue: type,
                            onChanged: (value) => setState(() => type = value!),
                          ),
                          const Text('مصروف'),
                          Radio<TransactionType>(
                            value: TransactionType.income,
                            groupValue: type,
                            onChanged: (value) => setState(() => type = value!),
                          ),
                          const Text('إيراد'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('إلغاء')),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      final description = descriptionController.text;
                      final amount = double.tryParse(amountController.text);
                      if (description.isNotEmpty && amount != null && amount > 0) {
                        await _apiService.createTransaction(description, amount, type);
                        Navigator.of(context).pop();
                        _refreshData();
                      } else {
                        // يمكنك إظهار رسالة خطأ هنا
                      }
                    } catch (e) {
                      // معالجة الخطأ
                    }
                  },
                  child: const Text('إضافة'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// --- الويدجتس المساعدة ---

class SummaryCard extends StatelessWidget {
  final AccountSummary summary;
  const SummaryCard({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'ar_SA', symbol: 'ر.س');
    return Card(
      margin: const EdgeInsets.all(8.0),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('الرصيد الحالي', style: Theme.of(context).textTheme.titleMedium),
            Text(
              currencyFormat.format(summary.balance),
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: summary.balance >= 0 ? Colors.green : Colors.red),
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InfoColumn(title: 'إجمالي الإيرادات', value: currencyFormat.format(summary.totalIncome), color: Colors.green),
                InfoColumn(title: 'إجمالي المصروفات', value: currencyFormat.format(summary.totalExpense), color: Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class InfoColumn extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  const InfoColumn({super.key, required this.title, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}

class TransactionList extends StatelessWidget {
  final List<Transaction> transactions;
  final Function(int) onDelete;
  const TransactionList({super.key, required this.transactions, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'ar_SA', symbol: 'ر.س');
    final dateFormat = DateFormat('yMMMd', 'ar_SA');

    return ListView.builder(
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final trans = transactions[index];
        final isIncome = trans.type == TransactionType.income;
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isIncome ? Colors.green.shade100 : Colors.red.shade100,
              child: Icon(isIncome ? Icons.arrow_downward : Icons.arrow_upward, color: isIncome ? Colors.green : Colors.red, size: 20),
            ),
            title: Text(trans.description),
            subtitle: Text(dateFormat.format(trans.date)),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isIncome ? '+' : '-'} ${currencyFormat.format(trans.amount)}',
                  style: TextStyle(fontWeight: FontWeight.bold, color: isIncome ? Colors.green : Colors.red),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 20),
                  onPressed: () => onDelete(trans.id),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
