from flask import Flask, jsonify, request
from flask_cors import CORS
import threading
import time
import os
import json
import math

# استدعاء ملفات البصمة السلوكية
from mouse_biometrics import MouseAuthenticator
from keyboard_biometrics import KeyboardAuthenticator

app = Flask(__name__)
CORS(app)  # السماح لتطبيق الفلتر بالاتصال بهذا الخادم

# تهيئة أنظمة المصادقة
mouse_auth = MouseAuthenticator()
kb_auth = KeyboardAuthenticator()

# متغيرات الحالة المشتركة
status_data = {
    "mouse_perc": 0.0,
    "kb_perc": 0.0,
    "overall": 0.0,
    "status_msg": "في انتظار البدء...",
    "is_monitoring": False,
    "is_collecting": False
}

# الذاكرة الحية والمؤقتة للرسوم البيانية (اثناء المراقبة)
live_mouse_history = [0] * 20
live_kb_history = [0] * 20

# مصفوفة حفظ سجل الأحداث (لصفحة السجل)
session_history_logs = []

def normalize_percentage(val):
    """دالة مساعدة لضمان بقاء النسبة بدقة متناهية بين 0 و 100"""
    try:
        return round(max(0.0, min(100.0, float(val))), 2)
    except (ValueError, TypeError):
        return 0.0

def monitoring_loop():
    """حلقة المراقبة المستمرة تعمل في مسار (Thread) منفصل"""
    global status_data, live_mouse_history, live_kb_history, session_history_logs

    while status_data["is_monitoring"]:
        mouse_auth.start_recording()
        kb_auth.start_recording()

        # الانتظار لمدة 4 ثواني
        for _ in range(40):
            if not status_data["is_monitoring"]:
                break
            time.sleep(0.1)

        # الخروج فوراً إذا تم إيقاف المراقبة
        if not status_data["is_monitoring"]:
            break

        # 🌟 التحقق من وجود نشاط فعلي (مطابق تماماً لملف main.py)
        mouse_active = len(mouse_auth.current_session_data) > 2
        kb_active = len(kb_auth.current_session_data) > 2

        mouse_auth.stop_recording(save_to_file=False)
        kb_auth.stop_recording(save_to_file=False)

        # فحص البصمة بناءً على حد أمان 70% كما في main.py
        m_safe, raw_m_p = mouse_auth.verify_current_session(threshold=70.0)
        k_safe, raw_k_p = kb_auth.verify_current_session(threshold=70.0)

        m_perc = normalize_percentage(raw_m_p) if mouse_active else 0.0
        k_perc = normalize_percentage(raw_k_p) if kb_active else 0.0

        overall_match = 0.0
        status_msg = ""
        severity = "عادية"

        # 🌟 تطبيق منطق main.py بالملي للحالة والنسبة الإجمالية
        if not mouse_active and not kb_active:
            status_msg = "💤 وضع السكون (لا يوجد استخدام)"
            overall_match = 0.0
            severity = "-"

        elif mouse_active and not kb_active:
            state = "✅ (آمن)" if m_safe else "🚨 (شاذ)"
            status_msg = f"🖱️ الماوس فقط | الحالة: {state}"
            overall_match = m_perc
            severity = "عادية" if m_safe else "حرجة"

        elif kb_active and not mouse_active:
            state = "✅ (آمن)" if k_safe else "🚨 (شاذ)"
            status_msg = f"⌨️ الكيبورد فقط | الحالة: {state}"
            overall_match = k_perc
            severity = "عادية" if k_safe else "حرجة"

        else:
            best_perc = max(m_perc, k_perc)
            worst_perc = min(m_perc, k_perc)
            best_device = "الماوس" if m_perc >= k_perc else "الكيبورد"
            worst_device = "الكيبورد" if best_device == "الماوس" else "الماوس"

            overall_match = best_perc
            state = "✅ (آمن)" if overall_match >= 70.0 else "🚨 (شاذ)"
            status_msg = f"🔄 دمج | الاعتماد على {best_device} {state}"
            severity = "عادية" if overall_match >= 70.0 else "حرجة"

            # تحذير إذا كان أحد الأجهزة شاذاً جداً
            if worst_perc > 0 and worst_perc < 50.0:
                status_msg += f" | ⚠️ [خطر: بصمة {worst_device} شاذة]"
                if severity == "عادية":
                    severity = "متوسطة" # تحذير متوسط لأن الاعتماد الأساسي كان آمناً

        # تحديث الحالة لواجهة الفلاتر
        status_data["mouse_perc"] = m_perc
        status_data["kb_perc"] = k_perc
        status_data["overall"] = overall_match
        status_data["status_msg"] = status_msg

        # تحديث الذاكرة الحية للرسوم البيانية
        live_mouse_history.append(m_perc)
        live_kb_history.append(k_perc)
        if len(live_mouse_history) > 20: live_mouse_history.pop(0)
        if len(live_kb_history) > 20: live_kb_history.pop(0)

        # 🌟 تسجيل الأحداث في السجل (فقط إذا كان هناك نشاط فعلي)
        if mouse_active or kb_active:
            log_entry = {
                "time": time.strftime("%H:%M:%S"),
                "mouse": m_perc,
                "keyboard": k_perc,
                "overall": overall_match,
                "severity": severity
            }
            session_history_logs.insert(0, log_entry)

            if len(session_history_logs) > 100:
                session_history_logs.pop()


# ==========================================
# مسارات الـ API (Endpoints)
# ==========================================

@app.route('/status', methods=['GET'])
def get_status():
    """إرسال الحالة اللحظية للفلتر"""
    return jsonify(status_data)

@app.route('/collect/start', methods=['POST'])
def start_collect():
    """بدء جمع البيانات للتسجيل"""
    status_data["is_collecting"] = True
    mouse_auth.start_recording()
    kb_auth.start_recording()
    status_data["status_msg"] = "جاري جمع البيانات وتسجيلها في الخلفية..."
    return jsonify({"msg": "بدأ الجمع"})

@app.route('/collect/stop', methods=['POST'])
def stop_collect():
    """إيقاف جمع البيانات وحفظها في ملف JSON"""
    status_data["is_collecting"] = False
    mouse_auth.stop_recording(save_to_file=True)
    kb_auth.stop_recording(save_to_file=True)
    status_data["status_msg"] = "تم حفظ البيانات في الجيسون بنجاح."
    return jsonify({"msg": "تم الحفظ"})

@app.route('/train', methods=['POST'])
def train():
    """تدريب الذكاء الاصطناعي على البيانات المحفوظة"""
    status_data["status_msg"] = "جاري تدريب نماذج الذكاء الاصطناعي، يرجى الانتظار..."
    m_res = mouse_auth.train_model()[1]
    k_res = kb_auth.train_model()[1]
    status_data["status_msg"] = "تم التدريب بنجاح! النظام جاهز للمراقبة."
    return jsonify({"mouse": m_res, "kb": k_res})

@app.route('/monitor/toggle', methods=['POST'])
def toggle_monitor():
    """تشغيل أو إيقاف المراقبة الحية"""
    status_data["is_monitoring"] = not status_data["is_monitoring"]

    if status_data["is_monitoring"]:
        status_data["status_msg"] = "بدء تشغيل المراقبة..."
        threading.Thread(target=monitoring_loop, daemon=True).start()
    else:
        # تأكيد إيقاف المستشعرات
        mouse_auth.stop_recording(save_to_file=False)
        kb_auth.stop_recording(save_to_file=False)

        # تصفير كل شيء فوراً عند الإيقاف
        status_data["status_msg"] = "تم إيقاف المراقبة الحية."
        status_data["mouse_perc"] = 0.0
        status_data["kb_perc"] = 0.0
        status_data["overall"] = 0.0

    return jsonify({"monitoring": status_data["is_monitoring"]})

@app.route('/history', methods=['GET'])
def get_history():
    """إرسال سجل الأحداث الأمني لصفحة السجل"""
    return jsonify(session_history_logs)

@app.route('/analytics', methods=['GET'])
def get_analytics():
    """تحليل البيانات التاريخية المعقدة لصفحة التحليلات"""
    mouse_chart = []
    kb_chart = []
    stats = {
        "avg_mouse_speed": 0.0, "avg_angle": 0.0, "avg_typing_speed": 0.0, "avg_dwell_time": 0.0
    }

    if os.path.exists(mouse_auth.data_file):
        with open(mouse_auth.data_file, 'r', encoding='utf-8') as f:
            try:
                data = json.load(f)
                features = mouse_auth._extract_features(data)
                if features:
                    mouse_chart = [round(f[0], 2) for f in features]
                    if len(mouse_chart) > 50: mouse_chart = mouse_chart[-50:]
                    stats["avg_mouse_speed"] = round(sum(mouse_chart) / len(mouse_chart), 1)

                angles = []
                for i in range(2, len(data)):
                    p1, p2, p3 = data[i - 2], data[i - 1], data[i]
                    if p1['type'] == 'move' and p2['type'] == 'move' and p3['type'] == 'move':
                        v1x, v1y = p2['x'] - p1['x'], p2['y'] - p1['y']
                        v2x, v2y = p3['x'] - p2['x'], p3['y'] - p2['y']
                        mag1 = math.sqrt(v1x ** 2 + v1y ** 2)
                        mag2 = math.sqrt(v2x ** 2 + v2y ** 2)
                        if mag1 > 0 and mag2 > 0:
                            dot = v1x * v2x + v1y * v2y
                            cos_theta = max(min(dot / (mag1 * mag2), 1.0), -1.0)
                            angle = math.degrees(math.acos(cos_theta))
                            if angle > 1.0: angles.append(angle)
                if angles: stats["avg_angle"] = round(sum(angles) / len(angles), 1)
            except Exception as e:
                pass

    if os.path.exists(kb_auth.data_file):
        with open(kb_auth.data_file, 'r', encoding='utf-8') as f:
            try:
                data = json.load(f)
                features = kb_auth._extract_features(data)
                if features:
                    kb_chart = [round(f[2] * 12, 2) for f in features]
                    if len(kb_chart) > 50: kb_chart = kb_chart[-50:]
                    stats["avg_typing_speed"] = round(sum(kb_chart) / len(kb_chart), 1)
                    dwells = [f[0] for f in features if f[0] > 0]
                    if dwells: stats["avg_dwell_time"] = round(sum(dwells) / len(dwells), 3)
            except Exception as e:
                pass

    return jsonify({"mouse_chart": mouse_chart, "kb_chart": kb_chart, "stats": stats})

if __name__ == '__main__':
    app.run(port=5000, debug=False)