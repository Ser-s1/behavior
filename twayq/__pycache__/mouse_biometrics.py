import json
import time
import math
import os
import numpy as np  # سنستخدم numpy للحسابات الإحصائية المتقدمة
from pynput import mouse
from sklearn.ensemble import IsolationForest
import joblib


class MouseAuthenticator:
    def __init__(self, data_file="mouse_data.json", model_file="mouse_model.pkl"):
        self.data_file = data_file
        self.model_file = model_file
        self.is_tracking = False
        self.listener = None
        self.current_session_data = []

    # --- دوال التتبع (بدون تغيير) ---
    def _on_move(self, x, y):
        if self.is_tracking:
            self.current_session_data.append({"time": time.time(), "type": "move", "x": x, "y": y})

    def _on_click(self, x, y, button, pressed):
        if self.is_tracking:
            self.current_session_data.append(
                {"time": time.time(), "type": "click", "x": x, "y": y, "button": str(button), "pressed": pressed})

    def _on_scroll(self, x, y, dx, dy):
        if self.is_tracking:
            self.current_session_data.append(
                {"time": time.time(), "type": "scroll", "x": x, "y": y, "dx": dx, "dy": dy})

    def start_recording(self):
        if self.is_tracking: return False
        self.is_tracking = True
        self.current_session_data = []
        self.listener = mouse.Listener(on_move=self._on_move, on_click=self._on_click, on_scroll=self._on_scroll)
        self.listener.start()
        return True

    def stop_recording(self, save_to_file=True):
        if not self.is_tracking: return False
        self.is_tracking = False
        if self.listener: self.listener.stop()
        if save_to_file and self.current_session_data:
            all_data = []
            if os.path.exists(self.data_file):
                with open(self.data_file, 'r', encoding='utf-8') as f:
                    try:
                        all_data = json.load(f)
                    except json.JSONDecodeError:
                        pass
            all_data.extend(self.current_session_data)
            with open(self.data_file, 'w', encoding='utf-8') as f:
                json.dump(all_data, f, indent=4)
        return len(self.current_session_data)

    # ==========================================
    # 2. هندسة الميزات المتقدمة (التحليل العميق)
    # ==========================================
    def _analyze_chunk(self, chunk):
        """تحليل متقدم يشمل السرعة، التسارع، والانحراف المعياري"""
        speeds = []
        accelerations = []
        click_count = 0
        scroll_count = 0

        prev_item = None
        prev_speed = None

        for item in chunk:
            if item['type'] == 'move':
                if prev_item:
                    # 1. حساب المسافة والسرعة اللحظية
                    dist = math.sqrt((item['x'] - prev_item['x']) ** 2 + (item['y'] - prev_item['y']) ** 2)
                    dt = item['time'] - prev_item['time']
                    if dt > 0:
                        speed = dist / dt
                        speeds.append(speed)

                        # 2. حساب التسارع (تغير السرعة بالنسبة للزمن)
                        if prev_speed is not None:
                            accel = (speed - prev_speed) / dt
                            accelerations.append(accel)
                        prev_speed = speed
                prev_item = item
            elif item['type'] == 'click':
                click_count += 1
            elif item['type'] == 'scroll':
                scroll_count += 1

        # استخراج الإحصائيات المتقدمة
        avg_speed = np.mean(speeds) if speeds else 0
        std_speed = np.std(speeds) if speeds else 0  # الانحراف المعياري للسرعة
        avg_accel = np.mean(accelerations) if accelerations else 0

        # الميزات الـ 5 التي سيتعلمها الذكاء الاصطناعي الآن
        return [avg_speed, std_speed, avg_accel, click_count, scroll_count]

    def _extract_features(self, data):
        if not data: return []
        data = sorted(data, key=lambda k: k['time'])
        features = []
        start_time = data[0]['time']
        chunk_duration = 2.0
        current_chunk = []

        for item in data:
            if item['time'] - start_time <= chunk_duration:
                current_chunk.append(item)
            else:
                if len(current_chunk) > 5:  # نحتاج بيانات أكثر للحسابات الإحصائية
                    features.append(self._analyze_chunk(current_chunk))
                current_chunk = [item]
                start_time = item['time']
        return features

    # ==========================================
    # 3. التدريب بـ 500 شجرة (الغابة الكثيفة)
    # ==========================================
    def train_model(self):
        if not os.path.exists(self.data_file):
            return False, "ملف البيانات غير موجود."

        with open(self.data_file, 'r', encoding='utf-8') as f:
            data = json.load(f)

        X_train = self._extract_features(data)

        if len(X_train) < 10:
            return False, "البيانات غير كافية للتحليل المتقدم."

        # ضبط النموذج بـ 500 شجرة كما طلبت لرفع الدقة لأقصى حد
        model = IsolationForest(
            n_estimators=500,
            contamination=0.1,
            random_state=42,
            max_samples='auto'
        )
        model.fit(X_train)
        joblib.dump(model, self.model_file)

        return True, f"تم التدريب بنجاح بـ 500 شجرة وتحليل (السرعة، التسارع، الانحراف)."

    def verify_current_session(self, threshold=70.0):
        if not os.path.exists(self.model_file) or not self.current_session_data:
            return False, 0.0

        model = joblib.load(self.model_file)
        X_test = self._extract_features(self.current_session_data)

        if not X_test: return False, 0.0

        predictions = model.predict(X_test)
        normal_movements = sum(1 for p in predictions if p == 1)
        match_percentage = (normal_movements / len(predictions)) * 100
        return (match_percentage >= threshold), match_percentage