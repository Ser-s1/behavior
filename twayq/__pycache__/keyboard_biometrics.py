import json
import time
import os
from pynput import keyboard
from sklearn.ensemble import IsolationForest
import joblib


class KeyboardAuthenticator:
    def __init__(self, data_file="keyboard_data.json", model_file="keyboard_model.pkl"):
        self.data_file = data_file
        self.model_file = model_file
        self.is_tracking = False
        self.listener = None
        self.current_session_data = []

    # ==========================================
    # 1. دوال تتبع أحداث الكيبورد (الضغط والإفلات)
    # ==========================================
    def _on_press(self, key):
        if self.is_tracking:
            try:
                # تحويل الزر إلى نص سواء كان حرفاً عادياً أو زراً خاصاً (مثل Enter, Space)
                key_name = key.char if hasattr(key, 'char') and key.char else str(key)
            except Exception:
                key_name = "unknown"

            self.current_session_data.append({
                "time": time.time(),
                "action": "press",
                "key": key_name
            })

    def _on_release(self, key):
        if self.is_tracking:
            try:
                key_name = key.char if hasattr(key, 'char') and key.char else str(key)
            except Exception:
                key_name = "unknown"

            self.current_session_data.append({
                "time": time.time(),
                "action": "release",
                "key": key_name
            })

    def start_recording(self):
        if self.is_tracking:
            return False

        self.is_tracking = True
        self.current_session_data = []

        self.listener = keyboard.Listener(
            on_press=self._on_press,
            on_release=self._on_release
        )
        self.listener.start()
        return True

    def stop_recording(self, save_to_file=True):
        if not self.is_tracking:
            return False

        self.is_tracking = False
        if self.listener:
            self.listener.stop()

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
    # 2. هندسة استخراج الميزات (Dwell & Flight Time)
    # ==========================================
    def _analyze_chunk(self, chunk):
        """تحليل نافذة زمنية لاستخراج متوسطات الكتابة"""
        dwell_times = []
        flight_times = []
        press_times = {}  # لتتبع متى تم الضغط على كل زر
        last_release_time = None
        keystroke_count = 0

        for event in chunk:
            key = event['key']
            current_time = event['time']

            if event['action'] == 'press':
                keystroke_count += 1
                press_times[key] = current_time

                # حساب وقت الطيران (من آخر إفلات إلى هذا الضغط)
                if last_release_time is not None:
                    flight = current_time - last_release_time
                    # استبعاد التوقفات الطويلة (أكثر من ثانيتين) لأنها تعني توقف عن الكتابة
                    if flight < 2.0:
                        flight_times.append(flight)

            elif event['action'] == 'release':
                last_release_time = current_time

                # حساب وقت المكوث (من الضغط إلى الإفلات لنفس الزر)
                if key in press_times:
                    dwell = current_time - press_times[key]
                    if dwell < 2.0:
                        dwell_times.append(dwell)
                    del press_times[key]  # تنظيف الزر بعد إفلاته

        # حساب المتوسطات للنافذة الزمنية
        avg_dwell = sum(dwell_times) / len(dwell_times) if dwell_times else 0
        avg_flight = sum(flight_times) / len(flight_times) if flight_times else 0

        # الميزات التي سيتعلمها الذكاء الاصطناعي
        return [avg_dwell, avg_flight, keystroke_count]

    def _extract_features(self, data):
        """تقسيم البيانات الطويلة إلى نوافذ زمنية (مثلاً كل 5 ثوانٍ تمثل عينة دراسة)"""
        if not data:
            return []

        data = sorted(data, key=lambda k: k['time'])
        features = []

        if not data:
            return features

        start_time = data[0]['time']
        chunk_duration = 5.0  # 5 ثوانٍ لكل عينة (لأن الكتابة تحتاج وقتاً أطول من الماوس لجمع نمط)
        current_chunk = []

        for item in data:
            if item['time'] - start_time <= chunk_duration:
                current_chunk.append(item)
            else:
                if len(current_chunk) > 2:  # تجاهل النوافذ التي فيها أقل من نقرتين
                    features.append(self._analyze_chunk(current_chunk))
                current_chunk = [item]
                start_time = item['time']

        if len(current_chunk) > 2:
            features.append(self._analyze_chunk(current_chunk))

        return features

    # ==========================================
    # 3. التدريب والمراقبة
    # ==========================================
    def train_model(self):
        if not os.path.exists(self.data_file):
            return False, "ملف بيانات الكيبورد غير موجود."

        with open(self.data_file, 'r', encoding='utf-8') as f:
            data = json.load(f)

        X_train = self._extract_features(data)

        if len(X_train) < 5:
            return False, "بيانات الكيبورد غير كافية للتدريب. يرجى كتابة نصوص أطول."

        model = IsolationForest(contamination=0.1, random_state=42)
        model.fit(X_train)
        joblib.dump(model, self.model_file)

        return True, "تم تدريب نموذج الكيبورد بنجاح."

    def verify_current_session(self, threshold=70.0):
        if not os.path.exists(self.model_file):
            return False, 0.0

        if not self.current_session_data:
            return False, 0.0

        model = joblib.load(self.model_file)
        X_test = self._extract_features(self.current_session_data)

        if len(X_test) == 0:
            return False, 0.0  # لا توجد بيانات كتابة كافية في هذه العينة

        predictions = model.predict(X_test)
        normal_movements = sum(1 for p in predictions if p == 1)
        match_percentage = (normal_movements / len(predictions)) * 100

        is_authorized = match_percentage >= threshold

        return is_authorized, match_percentage