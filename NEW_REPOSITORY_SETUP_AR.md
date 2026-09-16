# تجهيز مستودع WolFox جديد

هذه الحزمة نسخة نظيفة من المصدر الحالي، وتشمل ملفات GitHub Actions داخل:

`.github/workflows/`

## الرفع إلى مستودع جديد

```bash
git init
git add .
git commit -m "Initial WolFox source and CI"
git branch -M main
git remote add origin <NEW_REPOSITORY_URL>
git push -u origin main
```

## إعداد البناء

- إذا كان سير العمل يحتاج قيمة عامة قابلة للاستبدال، أضفها كـ Repository Variable.
- لا ترفع أي Project Secret أو بيانات قاعدة بيانات إلى المستودع.
- رابط API الحالي: `https://gps.p3nd.fun/api/v1`.
- البناء يستهدف arm64 ويدعم الحزم Rootful وRootless.
- بيئة CI تستخدم Theos وSDK iPhoneOS 16.5.

## التحقق

شغّل قبل الرفع:

```bash
chmod +x ./*.sh tools/*.sh
./run_all_linux_tests.sh
```

تم تمرير اختبارات Linux في هذه النسخة قبل إنشاء الحزمة.
