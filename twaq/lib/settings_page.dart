import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

// استيراد الودجت الموحدة
import 'package:twaq/custom_widgets.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // المتغيرات الأساسية
  bool isMonitoringEnabled = false; 
  bool enableNegativeNotifications = true;
  
  Timer? _notificationTimer;

  @override
  void initState() {
    super.initState();
    // 1. جلب الحالة الحالية للمراقبة من السيرفر عند فتح الصفحة
    _fetchInitialState();
    // 2. تشغيل مؤقت الفحص الدوري
    _setupNotificationTimer();
  }

  // دالة لجلب حالة المراقبة من السيرفر
  Future<void> _fetchInitialState() async {
    try {
      var response = await http.get(Uri.parse('http://127.0.0.1:5000/status'));
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        if (mounted) {
          setState(() {
            isMonitoringEnabled = data['is_monitoring'] ?? false;
          });
        }
      }
    } catch (e) {
      print("خطأ في جلب حالة الإعدادات: $e");
    }
  }

  // دالة لإرسال أمر التفعيل/التعطيل للسيرفر
  Future<void> _toggleMonitoring(bool value) async {
    // تحديث الواجهة فوراً لاستجابة أسرع
    setState(() => isMonitoringEnabled = value); 
    
    try {
      var response = await http.post(Uri.parse('http://127.0.0.1:5000/monitor/toggle'));
      if (response.statusCode != 200) {
        throw Exception("فشل في تحديث الحالة");
      }
    } catch (e) {
      // التراجع عن التحديث في حال فشل الاتصال بالسيرفر
      if (mounted) {
        setState(() => isMonitoringEnabled = !value);
        _showSnackBar("فشل الاتصال بالخادم!", Colors.redAccent);
      }
    }
  }

  // إعداد المؤقت الذي يفحص كل دقيقة
  void _setupNotificationTimer() {
    _notificationTimer?.cancel(); // إيقاف أي مؤقت سابق
    
    if (enableNegativeNotifications) {
      // الفحص كل 60 ثانية
      _notificationTimer = Timer.periodic(Duration(minutes: 1), (timer) {
        _checkSecurityStatus();
      });
    }
  }

  // دالة فحص الحالة الأمنية وإصدار الإنذار
  Future<void> _checkSecurityStatus() async {
    if (!isMonitoringEnabled) return; // لا تفحص إذا كانت المراقبة متوقفة

    try {
      var response = await http.get(Uri.parse('http://127.0.0.1:5000/status'));
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        double mouseMatch = data['mouse_perc']?.toDouble() ?? 0.0;
        double keyboardMatch = data['kb_perc']?.toDouble() ?? 0.0;
        double overallTrust = (mouseMatch + keyboardMatch) / 2;

        // إذا كانت نسبة الثقة أقل من 50% يتم إطلاق تحذير
        if (overallTrust < 50.0 && data['is_monitoring'] == true) {
          _showSnackBar(
            "تحذير أمني: تم اكتشاف سلوك شاذ! مستوى التطابق انخفض إلى ${overallTrust.toStringAsFixed(1)}%", 
            Colors.redAccent
          );
        }
      }
    } catch (e) {
      print("خطأ في فحص الحالة الأمنية الدورية: $e");
    }
  }

  // دالة مساعدة لعرض الإشعارات
  void _showSnackBar(String message, Color bgColor) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.white),
            SizedBox(width: 10),
            Expanded(child: Text(message, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          ],
        ),
        backgroundColor: bgColor,
        duration: Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  void dispose() {
    _notificationTimer?.cancel(); // إيقاف المؤقت عند الخروج من الصفحة
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "إعدادات النظام وتفضيلات الأمان", 
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.w300, color: Colors.white)
        ),
        SizedBox(height: 30),

        // قسم الإعدادات الموحد
        SettingsSection(
          title: "إعدادات المراقبة والإشعارات",
          icon: Icons.security,
          color: Colors.blueAccent,
          children: [
            _buildSwitchSetting(
              title: "تشغيل المراقبة",
              subtitle: "تفعيل نظام تحليل السلوك في الخلفية (يتزامن مع السيرفر)",
              value: isMonitoringEnabled,
              onChanged: (val) => _toggleMonitoring(val), // تم ربطها بالخلفية
            ),
            Divider(color: Colors.white10, height: 1),
            _buildSwitchSetting(
              title: "إشعارات النتائج السلبية (كل دقيقة)",
              subtitle: "إظهار تنبيه في حال اكتشاف سلوك شاذ أثناء الفحص الدوري",
              value: enableNegativeNotifications,
              onChanged: (val) {
                setState(() => enableNegativeNotifications = val);
                _setupNotificationTimer(); // إعادة تشغيل أو إيقاف المؤقت بناءً على الخيار
              },
            ),
          ],
        ),
      ],
    );
  }

  // دالة مساعدة لإنشاء أزرار التفعيل (Switch)
  Widget _buildSwitchSetting({required String title, required String subtitle, required bool value, required void Function(bool) onChanged}) {
    return SwitchListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      title: Text(title, style: TextStyle(color: Colors.white, fontSize: 16)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.white54, fontSize: 13)),
      value: value,
      activeColor: Colors.blueAccent,
      onChanged: onChanged,
    );
  }
}