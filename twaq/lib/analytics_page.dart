import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

// استيراد الودجت الموحدة
import 'package:twaq/custom_widgets.dart';

class AnalyticsPage extends StatefulWidget {
  @override
  _AnalyticsPageState createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  String selectedUser = 'Admin (الحالي)';
  
  List<FlSpot> mouseSpots = [];
  List<FlSpot> kbSpots = [];
  
  double avgMouseSpeed = 0.0;
  double avgAngle = 0.0;
  double avgTypingSpeed = 0.0;
  double avgDwellTime = 0.0;

  Timer? timer;

  @override
  void initState() {
    super.initState();
    fetchChartData();
    timer = Timer.periodic(Duration(seconds: 10), (t) => fetchChartData());
  }

  fetchChartData() async {
    try {
      var response = await http.get(Uri.parse('http://127.0.0.1:5000/analytics'));
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        
        List<dynamic> mData = data['mouse_chart'] ?? [];
        List<dynamic> kData = data['kb_chart'] ?? [];
        var stats = data['stats'];
        
        setState(() {
          mouseSpots = mData.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.toDouble())).toList();
          kbSpots = kData.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.toDouble())).toList();
          
          avgMouseSpeed = stats['avg_mouse_speed']?.toDouble() ?? 0.0;
          avgAngle = stats['avg_angle']?.toDouble() ?? 0.0;
          avgTypingSpeed = stats['avg_typing_speed']?.toDouble() ?? 0.0;
          avgDwellTime = stats['avg_dwell_time']?.toDouble() ?? 0.0;
        });
      }
    } catch (e) {
      print("خطأ في الاتصال بالتحليلات");
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
        // العنوان والقائمة المنسدلة
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Historical Data", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w300, color: Colors.white)),
            _buildUserDropdown(),
          ],
        ),
        SizedBox(height: 30),

        // الرسوم البيانية باستخدام CustomLineChart الموحد
        Text("تاريخ سرعة الماوس", style: TextStyle(color: Colors.white70, fontSize: 18)),
        SizedBox(height: 15),
        CustomLineChart(
          spots: mouseSpots.isEmpty ? [FlSpot(0, 0)] : mouseSpots, 
          lineColor: Color(0xFFF54133), 
          gradientColors: [Color(0xFFF54133).withOpacity(0.5), Colors.transparent]
        ),

        SizedBox(height: 30),

        Text("تاريخ كثافة الكتابة", style: TextStyle(color: Colors.white70, fontSize: 18)),
        SizedBox(height: 15),
        CustomLineChart(
          spots: kbSpots.isEmpty ? [FlSpot(0, 0)] : kbSpots, 
          lineColor: Color(0xFF8D7BF3), 
          gradientColors: [Color(0xFF8D7BF3).withOpacity(0.5), Colors.transparent]
        ),

        SizedBox(height: 40),

        Text("المقاييس الحيوية للبصمة (Biometric Stats)", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w400, color: Colors.white)),
        SizedBox(height: 20),
        
        // شبكة البطاقات باستخدام StatCard الموحد
        Row(
          children: [
            Expanded(child: StatCard(title: "متوسط سرعة الماوس", value: "$avgMouseSpeed", unit: "بكسل / ثانية", icon: Icons.speed, iconColor: Colors.orangeAccent)),
            SizedBox(width: 15),
            Expanded(child: StatCard(title: "زاوية الانحناء", value: "$avgAngle°", unit: "درجة انحراف", icon: Icons.architecture, iconColor: Colors.redAccent)),
          ],
        ),
        SizedBox(height: 15),
        Row(
          children: [
            Expanded(child: StatCard(title: "سرعة الكتابة", value: "$avgTypingSpeed", unit: "نقرة / دقيقة", icon: Icons.keyboard_alt_outlined, iconColor: Colors.purpleAccent)),
            SizedBox(width: 15),
            Expanded(child: StatCard(title: "متوسط زمن الضغطة", value: "$avgDwellTime", unit: "ثانية", icon: Icons.timer, iconColor: Colors.blueAccent)),
          ],
        ),
        SizedBox(height: 20),
      ],
    );
  }

  // ودجت صغيرة خاصة بهذه الصفحة فقط (Dropdown)
  Widget _buildUserDropdown() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      decoration: BoxDecoration(color: Color(0xFF252538), borderRadius: BorderRadius.circular(10)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedUser,
          dropdownColor: Color(0xFF252538),
          style: TextStyle(color: Colors.white, fontSize: 16),
          icon: Icon(Icons.arrow_drop_down, color: Colors.blueAccent),
          items: ['Admin (الحالي)', 'User 1', 'Guest'].map((String value) => DropdownMenuItem<String>(value: value, child: Text(value))).toList(),
          onChanged: (newValue) => setState(() => selectedUser = newValue!),
        ),
      ),
    );
  }
}