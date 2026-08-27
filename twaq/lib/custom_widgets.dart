import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

// --- 1. بطاقات الإحصائيات (Stat Cards) ---

/// البطاقة الدائرية الكبيرة المستخدمة في الصفحة الرئيسية
class CircularMetricCard extends StatelessWidget {
  final String title;
  final double value;
  final String unit;
  final Color color;
  final IconData icon;

  const CircularMetricCard({
    required this.title,
    required this.value,
    required this.unit,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 20, offset: Offset(0, 10))],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 100, height: 100,
                child: CircularProgressIndicator(
                  value: value / 100,
                  strokeWidth: 12,
                  color: Colors.white,
                  backgroundColor: Colors.white24,
                ),
              ),
              Column(
                children: [
                  Text("${value.toInt()}", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                  Text(unit, style: TextStyle(fontSize: 12, color: Colors.white70)),
                ],
              )
            ],
          ),
          SizedBox(height: 30),
          Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w400, color: Colors.white)),
          SizedBox(height: 5),
          Icon(icon, color: Colors.white54, size: 20),
        ],
      ),
    );
  }
}

/// بطاقة الإحصائيات الأفقية المستخدمة في صفحة التحليلات
class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final IconData icon;
  final Color iconColor;

  const StatCard({
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFF212435),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(color: iconColor.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: Colors.white54, fontSize: 14)),
                SizedBox(height: 5),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(value, style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    SizedBox(width: 5),
                    Flexible(child: Text(unit, style: TextStyle(color: Colors.white38, fontSize: 12), overflow: TextOverflow.ellipsis)),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

// --- 2. أزرار التحكم (Control Elements) ---

class SideMenuItem extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const SideMenuItem({required this.icon, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Icon(icon, color: isActive ? Colors.white : Colors.white24, size: 28),
      ),
    );
  }
}

class ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onPressed;

  const ActionButton({required this.label, required this.color, required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white10,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(color: color.withOpacity(0.5)),
      ),
    );
  }
}

// --- 3. الرسوم البيانية (Charts) ---

class CustomLineChart extends StatelessWidget {
  final List<FlSpot> spots;
  final Color lineColor;
  final List<Color> gradientColors;

  const CustomLineChart({required this.spots, required this.lineColor, required this.gradientColors});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      padding: EdgeInsets.only(right: 20, left: 10, top: 20, bottom: 10),
      decoration: BoxDecoration(color: Color(0xFF252538), borderRadius: BorderRadius.circular(20)),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) => Text(value.toInt().toString(), style: TextStyle(color: Colors.white54, fontSize: 10)),
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: lineColor,
              barWidth: 3,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(colors: gradientColors, begin: Alignment.topCenter, end: Alignment.bottomCenter),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- 4. إعدادات النظام (Settings Widgets) ---

class SettingsSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<Widget> children;

  const SettingsSection({required this.title, required this.icon, required this.color, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 24),
            SizedBox(width: 10),
            Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        SizedBox(height: 15),
        Container(
          decoration: BoxDecoration(
            color: Color(0xFF252538),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}