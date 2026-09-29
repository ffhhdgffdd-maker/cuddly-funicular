'use strict';
const form = document.querySelector('#upload-form');
const absolute = path => new URL(path, window.location.href).href;
async function copy(text, button) {
  try { await navigator.clipboard.writeText(text); button.textContent = 'تم النسخ'; }
  catch { button.textContent = 'حدد الرابط وانسخه'; window.prompt('انسخ رابط التنزيل الخاص:', text); }
}
document.querySelectorAll('.copy-history').forEach(button => button.addEventListener('click', () => copy(absolute(button.dataset.link), button)));
if (form) {
  const ipa = document.querySelector('#ipa');
  const libraries = document.querySelector('#libraries');
  const url = document.querySelector('#url');
  const submit = document.querySelector('#submit-upload');
  const error = document.querySelector('#upload-error');
  const progressArea = document.querySelector('#progress-area');
  const progress = document.querySelector('#progress');
  const label = document.querySelector('#progress-label');
  const progressValue = document.querySelector('#progress-value');
  const zone = document.querySelector('.dropzone');
  function changed() {
    document.querySelector('#ipa-name').textContent = ipa.files[0]?.name || 'لم يُحدد ملف بعد';
    if (ipa.files.length) url.value = '';
  }
  ipa.addEventListener('change', changed);
  url.addEventListener('input', () => { if (url.value) { ipa.value = ''; changed(); } });
  libraries.addEventListener('change', () => {
    document.querySelector('#library-names').textContent = [...libraries.files].map(file => file.name).join(' · ') || 'يمكنك ترك هذه الخانة فارغة.';
  });
  zone.addEventListener('dragover', event => { event.preventDefault(); zone.classList.add('dragging'); });
  zone.addEventListener('dragleave', () => zone.classList.remove('dragging'));
  zone.addEventListener('drop', event => {
    event.preventDefault(); zone.classList.remove('dragging');
    if (event.dataTransfer.files.length === 1) { ipa.files = event.dataTransfer.files; changed(); }
  });
  function fail(message) { error.textContent = message; error.hidden = false; }
  form.addEventListener('submit', event => {
    event.preventDefault(); error.hidden = true;
    if (!ipa.files.length && !url.value.trim()) return fail('اختر ملف IPA أو أدخل رابطًا مباشرًا.');
    if (ipa.files[0] && (!/\.ipa$/i.test(ipa.files[0].name) || ipa.files[0].size > 512 * 1024**2)) return fail('اختر ملف IPA بحجم لا يتجاوز 512 ميجابايت.');
    if (libraries.files.length > 8 || [...libraries.files].some(f => f.size > 32 * 1024**2 || !/\.dylib$/.test(f.name))) return fail('اختر حتى 8 ملفات dylib، بحد أقصى 32 ميجابايت للملف.');
    submit.disabled = true; progressArea.hidden = false; progress.value = 0;
    label.textContent = 'جارٍ رفع الملف…'; progressValue.textContent = '0%';
    const xhr = new XMLHttpRequest();
    xhr.open('POST', form.action); xhr.timeout = 600000; xhr.responseType = 'json';
    xhr.upload.onprogress = event => {
      if (event.lengthComputable) { const percent = Math.round(event.loaded / event.total * 100); progress.value = percent; progressValue.textContent = percent + '%'; }
    };
    xhr.upload.onload = () => { label.textContent = 'جارٍ فحص الملف وتجهيزه…'; progress.removeAttribute('value'); progressValue.textContent = 'انتظر'; };
    xhr.onload = () => {
      const data = xhr.response;
      if (!data?.ok) return fail(data?.error || 'لم تكتمل المعالجة. تحقق من حدود الرفع والمهلة في الاستضافة.');
      document.querySelector('#result-empty').hidden = true;
      const result = document.querySelector('#result'); result.hidden = false;
      document.querySelector('#result-mode').textContent = data.mode === 'unchanged' ? 'جاهز · دون تعديل' : 'اكتمل الدمج';
      document.querySelector('#result-app').textContent = data.app;
      document.querySelector('#result-bundle').textContent = data.bundle + ' · ' + data.version;
      document.querySelector('#result-size').textContent = (data.size / 1048576).toFixed(1) + ' MB';
      document.querySelector('#result-note').textContent = data.mode === 'unchanged' ? 'حُفظ الملف كما رفعته دون تعديل محتواه أو توقيعه.' : 'الناتج غير موقّع. وقّع التطبيق ومكتباته قبل التثبيت وتحقق من توفر اعتماديات المكتبات.';
      const link = absolute(data.download);
      document.querySelector('#result-link').value = link;
      document.querySelector('#download-link').href = link;
      document.querySelector('#result-hash').textContent = 'SHA-256: ' + data.sha256;
      document.querySelector('#result-libraries').textContent = data.libraries.map(lib => lib.name + '\n' + lib.dependencies.join('\n')).join('\n\n') || 'لم تُضف مكتبات.';
      document.querySelector('#copy-link').textContent = 'نسخ الرابط';
      document.querySelector('#copy-link').onclick = event => copy(link, event.currentTarget);
      form.reset(); changed(); document.querySelector('#library-names').textContent = 'يمكنك ترك هذه الخانة فارغة.';
      result.scrollIntoView({behavior:'smooth', block:'nearest'});
    };
    xhr.onerror = () => fail('انقطع الاتصال. حدّث الصفحة للتحقق من قائمة النتائج قبل إعادة الرفع.');
    xhr.ontimeout = () => fail('انتهت مهلة الاتصال. حدّث الصفحة للتحقق من قائمة النتائج.');
    xhr.onloadend = () => { submit.disabled = false; progressArea.hidden = true; };
    xhr.send(new FormData(form));
  });
}
