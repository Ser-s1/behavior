import time
from mouse_biometrics import MouseAuthenticator
from keyboard_biometrics import KeyboardAuthenticator


def main():
    mouse_auth = MouseAuthenticator()
    kb_auth = KeyboardAuthenticator()

    print("\n=== 🛡️ نظام الحماية المدمج (بصمة الماوس + الكيبورد) 🛡️ ===")
    print("1. وضع جمع البيانات الشامل (مع حفظ تلقائي كل 5 دقائق)")
    print("2. تدريب نماذج الذكاء الاصطناعي (لكلا البصمتين)")
    print("3. المراقبة الذكية المدمجة (عرض الحالة الحالية وسجل الحالات)")
    print("=========================================================")

    choice = input("اختر الوضع (1/2/3): ")

    if choice == '1':
        print("\n[جمع البيانات] جاري مراقبة الماوس والكيبورد في الخلفية...")
        print("💡 سيتم الحفظ التلقائي كل 5 دقائق. (اضغط Ctrl+C للإيقاف)")
        print("-" * 55)
        try:
            while True:
                mouse_auth.start_recording()
                kb_auth.start_recording()

                time.sleep(300)  # التسجيل لمدة 5 دقائق

                mouse_auth.stop_recording(save_to_file=True)
                kb_auth.stop_recording(save_to_file=True)

                print(f"[{time.strftime('%H:%M:%S')}] تم حفظ جلسة البيانات للماوس والكيبورد بنجاح.")
        except KeyboardInterrupt:
            mouse_auth.stop_recording(save_to_file=True)
            kb_auth.stop_recording(save_to_file=True)
            print("\n🛑 تم إيقاف التسجيل وحفظ كل البيانات بأمان.")

    elif choice == '2':
        print("\n[التدريب] جاري تدريب نماذج الذكاء الاصطناعي...")
        print("1. الماوس:", mouse_auth.train_model()[1])
        print("2. الكيبورد:", kb_auth.train_model()[1])
        print("✅ جاهز للمراقبة!")

    elif choice == '3':
        print("\n[المراقبة المستمرة] 👁️ محرك الدمج الذكي وسجل الأحداث يعمل الآن...")
        print("🛑 للإيقاف، اضغط (Ctrl + C).")
        print("-" * 75)

        try:
            while True:
                mouse_auth.start_recording()
                kb_auth.start_recording()

                time.sleep(5)  # تحديث الحالة كل 10 ثوانٍ

                mouse_auth.stop_recording(save_to_file=False)
                kb_auth.stop_recording(save_to_file=False)

                mouse_active = len(mouse_auth.current_session_data) > 2
                kb_active = len(kb_auth.current_session_data) > 2

                m_safe, m_perc = mouse_auth.verify_current_session(threshold=70.0)
                k_safe, k_perc = kb_auth.verify_current_session(threshold=70.0)

                status_msg = ""

                if not mouse_active and not kb_active:
                    status_msg = "💤 وضع السكون (لا يوجد استخدام)"

                elif mouse_active and not kb_active:
                    state = "✅ (آمن)" if m_safe else "🚨 (شاذ)"
                    status_msg = f"🖱️ الماوس فقط  | التطابق: {m_perc:05.2f}% | الحالة: {state}"

                elif kb_active and not mouse_active:
                    state = "✅ (آمن)" if k_safe else "🚨 (شاذ)"
                    status_msg = f"⌨️ الكيبورد فقط | التطابق: {k_perc:05.2f}% | الحالة: {state}"

                else:
                    best_perc = max(m_perc, k_perc)
                    worst_perc = min(m_perc, k_perc)
                    best_device = "الماوس" if m_perc >= k_perc else "الكيبورد"
                    worst_device = "الكيبورد" if best_device == "الماوس" else "الماوس"

                    state = "✅ (آمن)" if best_perc >= 70.0 else "🚨 (شاذ)"
                    status_msg = f"🔄 دمج | الاعتماد على {best_device} ({best_perc:05.2f}%) {state}"

                    if worst_perc > 0 and worst_perc < 50.0:
                        status_msg += f" | ⚠️ [خطر: بصمة {worst_device} شاذة جداً ({worst_perc:05.2f}%)]"

                # طباعة السجل الزمني الجديد:
                # سيظهر هذا كقائمة متتالية تبني لك سجلاً تاريخياً لكل جلسة
                current_time = time.strftime('%Y-%m-%d %H:%M:%S')
                print(f"[{current_time}] {status_msg}")

        except KeyboardInterrupt:
            print("\n\n🛑 تم إيقاف المراقبة المستمرة بنجاح.")

    else:
        print("خيار غير صحيح.")


if __name__ == "__main__":
    main()