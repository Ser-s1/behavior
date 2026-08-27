import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

// استيراد الودجت الموحدة

class HistoryPage extends StatefulWidget {
  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<dynamic> historyLogs = [];
  double totalSessionAverage = 0.0;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    fetchHistory();
    // تحديث السجل كل 3 ثواني
    timer = Timer.periodic(Duration(seconds: 3), (t) => fetchHistory());
  }

  fetchHistory() async {
    try {
      var response = await http.get(Uri.parse('http://127.0.0.1:5000/history'));
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        
        double sum = 0;
        if (data.isNotEmpty) {
          for (var log in data) {
            sum += (log['overall'] ?? 0).toDouble();
          }
          totalSessionAverage = sum / data.length;
        }

        setState(() {
          historyLogs = data;
        });
      }
    } catch (e) {
      print("خطأ في الاتصال بسجل الأحداث");
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("سجل المراقبة الأمنية", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w300, color: Colors.white)),
        SizedBox(height: 20),
        
        // بطاقة تلخيص التطابق الكلي
        _buildSummaryHeader(),
        
        SizedBox(height: 40),
        Text("الأحداث الأخيرة", style: TextStyle(color: Colors.white70, fontSize: 20)),
        SizedBox(height: 15),

        // قائمة السجلات
        historyLogs.isEmpty 
          ? _buildEmptyState()
          : ListView.builder(
              shrinkWrap: true, 
              physics: NeverScrollableScrollPhysics(),
              itemCount: historyLogs.length,
              itemBuilder: (context, index) => _buildLogCard(historyLogs[index]),
            ),
      ],
    );
  }

  // --- مكونات الصفحة ---

  Widget _buildSummaryHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF00B2D4), Color(0xFF005F9E)]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Color(0xFF00B2D4).withOpacity(0.4), blurRadius: 15, offset: Offset(0, 5))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("متوسط التطابق الكلي للجلسة", style: TextStyle(color: Colors.white70, fontSize: 18)),
              SizedBox(height: 5),
              Text("${totalSessionAverage.toStringAsFixed(1)}%", style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
            ],
          ),
          Icon(Icons.verified_user_outlined, size: 60, color: Colors.white38),
        ],
      ),
    );
  }

  Widget _buildLogCard(dynamic log) {
    String severity = log['severity'];
    Color color = _getSeverityColor(severity);

    return Container(
      margin: EdgeInsets.only(bottom: 15),
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: Color(0xFF252538),
        borderRadius: BorderRadius.circular(15),
        border: Border(left: BorderSide(color: color, width: 5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(_getSeverityIcon(severity), color: color, size: 28),
              SizedBox(width: 15),
              Text(log['time'], style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          Row(
            children: [
              _miniStat("الماوس", "${log['mouse']}%", Colors.blueAccent),
              SizedBox(width: 20),
              _miniStat("الكيبورد", "${log['keyboard']}%", Colors.purpleAccent),
            ],
          ),
          // الـ Badge الخاص بالحالة
          Container(
            padding: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
            child: Text(severity, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
          )
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: Colors.white54, fontSize: 12)),
        Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(child: Padding(
      padding: const EdgeInsets.all(40.0),
      child: Text("لا توجد سجلات حالياً. قم بتشغيل 'Live Monitor' لتبدأ المراقبة.", style: TextStyle(color: Colors.white54, fontSize: 16)),
    ));
  }

  // دوال مساعدة للألوان والأيقونات
  Color _getSeverityColor(String severity) {
    if (severity == "عادية") return Colors.greenAccent;
    if (severity == "متوسطة") return Colors.orangeAccent;
    return Colors.redAccent;
  }

  IconData _getSeverityIcon(String severity) {
    if (severity == "عادية") return Icons.check_circle;
    if (severity == "متوسطة") return Icons.warning;
    return Icons.dangerous;
  }
}