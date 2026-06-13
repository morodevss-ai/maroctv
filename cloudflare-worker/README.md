# Cloudflare Worker — MarocTV Proxy

## نشر في دقيقتين

1. افتح https://dash.cloudflare.com وسجّل مجاناً
2. Workers & Pages → Create → Hello World → Deploy
3. اضغط "Edit Code"
4. احذف كل شيء والصق محتوى ملف `worker.js`
5. اضغط Deploy
6. احتفظ بالرابط: `https://maroctv.YOUR-NAME.workers.dev`
7. في تطبيق MarocTV → ⚙️ الإعدادات → الصق الرابط → فعّل Proxy

## كيف يعمل

```
هاتفك (*6) → Cloudflare (مو محجوب) → CloudFront/Stream → مشاهدة ✅
```

Cloudflare يحلّ مشكلة الروابط النسبية (../../../) تلقائياً أيضاً.
