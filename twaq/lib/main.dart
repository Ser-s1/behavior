import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:io';

// استيراد الملفات الأخرى
import 'package:twaq/analytics_page.dart';
import 'package:twaq/history_page.dart';
import 'package:twaq/settings_page.dart';
// استيراد ملف الودجت الموحدة الذي أنشأناه
import 'package:twaq/custom_widgets.dart';

void main() {
  runApp(AdvancedBiometricApp());
}

class AdvancedBiometricApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Color(0xFF1B1E2B), 
      ),
      home: ProfessionalDashboard(),
    );
  }
}

class ProfessionalDashboard extends StatefulWidget {
  @override
  _ProfessionalDashboardState createState() => _ProfessionalDashboardState();
}

class _ProfessionalDashboardState extends State<ProfessionalDashboard> {
  double mouseMatch = 0.0;
  double keyboardMatch = 0.0;
  double overallTrust = 0.0;
  String statusMessage = "جاري الاتصال بالنظام...";
  bool isMonitoring = false;
  Timer? timer;

  int selectedPageIndex = 0; 

  @override
  void initState() {
    super.initState();
    // 🌟 التحديث كل 4 ثواني ليتزامن مع الخادم
    timer = Timer.periodic(Duration(seconds: 4), (t) => fetchStatusFromPython());
  }

  fetchStatusFromPython() async {
    try {
      var response = await http.get(Uri.parse('http://127.0.0.1:5000/status'));
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        setState(() {
          // جلب الأرقام الدقيقة والجاهزة من البايثون مباشرة
          mouseMatch = data['mouse_perc']?.toDouble() ?? 0.0;
          keyboardMatch = data['kb_perc']?.toDouble() ?? 0.0;
          overallTrust = data['overall']?.toDouble() ?? 0.0; // النسبة الإجمالية تأتي مجهزة بشروطك
          statusMessage = data['status_msg'] ?? "متصل";
          isMonitoring = data['is_monitoring'] ?? false;
        });
      }
    } catch (e) {
      setState(() => statusMessage = "فقدان الاتصال بالخادم الأمني!");
    }
  }

  sendCommand(String endpoint) async {
    try {
      await http.post(Uri.parse('http://127.0.0.1:5000/$endpoint'));
      // 🌟 جلب الحالة فوراً بعد الضغط على أي زر لتحديث الواجهة في نفس اللحظة!
      fetchStatusFromPython();
    } catch (e) {
      print("خطأ في الاتصال: $e");
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // 1. القائمة الجانبية (Sidebar)
          Container(
            width: 80,
            color: Color(0xFF212435),
            child: Column(
              children: [
                SizedBox(height: 40),
                Icon(Icons.shield, color: Colors.blue, size: 35),
                SizedBox(height: 50),
                
                SideMenuItem(
                  icon: Icons.dashboard, 
                  isActive: selectedPageIndex == 0, 
                  onTap: () => setState(() => selectedPageIndex = 0)
                ),
                SideMenuItem(
                  icon: Icons.analytics_outlined, 
                  isActive: selectedPageIndex == 1, 
                  onTap: () => setState(() => selectedPageIndex = 1)
                ),
                SideMenuItem(
                  icon: Icons.history, 
                  isActive: selectedPageIndex == 2, 
                  onTap: () => setState(() => selectedPageIndex = 2)
                ),
                SideMenuItem(
                  icon: Icons.settings, 
                  isActive: selectedPageIndex == 3, 
                  onTap: () => setState(() => selectedPageIndex = 3)
                ),
                SideMenuItem(
                  icon: Icons.logout, 
                  isActive: false, 
                  onTap: () => exit(0)
                ),
              ],
            ),
          ),

          // 2. المساحة الرئيسية
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(30.0),
                child: _buildCurrentPage(),
              ),
            ),
          ),
        ],
      ),
    );
  }
  // دالة بسيطة لاختيار الصفحة لعرض كود أنظف
  Widget _buildCurrentPage() {
    switch (selectedPageIndex) {
      case 0: return _buildMainDashboard();
      case 1: return AnalyticsPage();
      case 2: return HistoryPage();
      case 3: return SettingsPage();
      default: return _buildMainDashboard();
    }
  }

  Widget _buildMainDashboard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Overview", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w300, color: Colors.white)),
            Text(statusMessage, style: TextStyle(color: isMonitoring ? Colors.green : Colors.orange, fontSize: 16)),
          ],
        ),
        SizedBox(height: 20),
        
        Container(
          height: 150, width: double.infinity,
          child: CustomPaint(painter: WavyGraphPainter()),
        ),
        SizedBox(height: 40),
        
        // استخدام CircularMetricCard لعرض النسب
        Row(
          children: [
            Expanded(child: CircularMetricCard(title: "Mouse behavior", value: mouseMatch, unit: "Match", color: Color(0xFFF54133), icon: Icons.mouse)),
            SizedBox(width: 20),
            Expanded(child: CircularMetricCard(title: "Keyboard style", value: keyboardMatch, unit: "Match", color: Color(0xFF8D7BF3), icon: Icons.keyboard)),
            SizedBox(width: 20),
            Expanded(child: CircularMetricCard(title: "System Trust", value: overallTrust, unit: "Secure", color: Color(0xFF00B2D4), icon: Icons.security)),
          ],
        ),
        SizedBox(height: 50),
        
        Text("System Controls", style: TextStyle(color: Colors.white60, fontSize: 18)),
        SizedBox(height: 20),
        
        // استخدام ActionButton من ملف الودجت الموحدة
        Wrap(
          spacing: 15, runSpacing: 15,
          children: [
            ActionButton(label: "Start Collection", color: Colors.blue, icon: Icons.play_arrow, onPressed: () => sendCommand('collect/start')),
            ActionButton(label: "Stop & Save", color: Colors.redAccent, icon: Icons.stop, onPressed: () => sendCommand('collect/stop')),
            ActionButton(label: "AI Training", color: Colors.deepPurple, icon: Icons.psychology, onPressed: () => sendCommand('train')),
            ActionButton(
              label: isMonitoring ? "Stop Monitor" : "Live Monitor", 
              color: isMonitoring ? Colors.orange : Colors.green, 
              icon: isMonitoring ? Icons.pause : Icons.visibility, 
              onPressed: () => sendCommand('monitor/toggle')
            ),
          ],
        )
      ],
    );
  }
} // 🌟 هنا يتم إغلاق كلاس _ProfessionalDashboardState

// أبقينا الـ Painter هنا لأنه خاص بتصميم الخلفية في الصفحة الرئيسية فقط
class WavyGraphPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()..style = PaintingStyle.fill;
    paint.color = Color(0xFF8D7BF3).withOpacity(0.3);
    var path1 = Path();
    path1.moveTo(0, size.height * 0.8);
    path1.quadraticBezierTo(size.width * 0.2, size.height * 0.2, size.width * 0.4, size.height * 0.5);
    path1.quadraticBezierTo(size.width * 0.6, size.height * 0.9, size.width * 0.8, size.height * 0.3);
    path1.lineTo(size.width, size.height * 0.6);
    path1.lineTo(size.width, size.height);
    path1.lineTo(0, size.height);
    canvas.drawPath(path1, paint);

    paint.color = Color(0xFF00B2D4).withOpacity(0.4);
    var path2 = Path();
    path2.moveTo(0, size.height * 0.6);
    path2.quadraticBezierTo(size.width * 0.3, size.height * 0.9, size.width * 0.5, size.height * 0.4);
    path2.quadraticBezierTo(size.width * 0.8, size.height * 0.1, size.width, size.height * 0.5);
    path2.lineTo(size.width, size.height);
    path2.lineTo(0, size.height);
    canvas.drawPath(path2, paint);
  }
  
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}