# فروع WolFox

الأسماء أدناه لتمييز الفروع والبناء فقط؛ الاسم داخل التطبيق WolFox.

| النسخة | الفرع | اللون | التطبيق المضيف |
|---|---|---|---|
| V2 Lite | `wolfox/v2-lite` | أزرق أصلي | `sa.gov.moia.mosques-2` |
| V2 Full | `wolfox/v2-full` | أزرق أصلي | `sa.gov.moia.mosques-2` |
| المساجد | `wolfox/masajid` | أزرق هادئ | `sa.gov.moia.mosques-2` |
| التحكم | `wolfox/control` | أزرق | `com.tahakom.mytahakom` |
| Bluetooth V3 | `wolfox/bluetooth-v3-blue` | أزرق هادئ | `sa.gov.moia.mosques-2` |
| Bluetooth V4 | `wolfox/bluetooth-v4` | أزرق هادئ | `sa.gov.moia.mosques-2` |
| Bluetooth V5 | `wolfox/bluetooth-v5` | أزرق هادئ | `sa.gov.moia.mosques-2` |
| V3 أزرق — التحكم | `wolfox/v3-blue-control` | أزرق | `com.tahakom.mytahakom` |
| V3 فيروزي — المساجد | `wolfox/v3-teal-masajid` | فيروزي | `sa.gov.moia.mosques-2` |
| V3 كهرماني — Lite التحكم | `wolfox/v3-amber-lite-control` | كهرماني | `com.tahakom.mytahakom` |
| V3 كهرماني — Lite المساجد | `wolfox/v3-amber-lite-masajid` | كهرماني | `sa.gov.moia.mosques-2` |
| V3 بنفسجي — Full التحكم | `wolfox/v3-purple-full-control` | بنفسجي | `com.tahakom.mytahakom` |
| V3 بنفسجي — Full المساجد | `wolfox/v3-purple-full-masajid` | بنفسجي | `sa.gov.moia.mosques-2` |
| V3 أزرق أصلي | `wolfox/v3-blue-original` | أزرق أصلي | `sa.gov.moia.mosques-2` |
| V3 بنفسجي ليلي أصلي | `wolfox/v3-violet-original` | بنفسجي ليلي | `sa.gov.moia.mosques-2` |

كل فرع يملك release.json وWorkflow وحزم Rootful وRootless ومصدره المطابق. ملفات الألوان مأخوذة من سجل المصدر، ويثبت release.json مرجعها. إصدارات الصيانة 2.0.1 و3.0.1 و4.0.1 و5.0.1 تمنع خلط الحزم الجديدة مع البناء السابق.

تبقى فروع codex القديمة وv2-interface-settings-unified وفرع revert محفوظة كمراجع تاريخية؛ لا تُحذف. codex/private-ipa-portal خاص ببوابة الويب وليس نسخة تطبيق iOS. إنشاء فروع هذه الدفعة لا يغير main.

كافة الوظائف غير مختبرة على جهاز حقيقي. لا يفرض تثبيت الحزمة إعادة تشغيل SpringBoard أو قتل التطبيق؛ تحميل المكتبة الجديدة يتم عند فتح المضيف من جديد بواسطة المستخدم.
