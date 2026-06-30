# Folio APK (direct download)

Place the release APK here as **`folio.apk`**.

```bash
cd mobile
flutter build apk --release
copy build\app\outputs\flutter-apk\app-release.apk ..\landing\downloads\folio.apk
npm run build:landing
```

Deploy to Vercel. Download buttons on the site point to `/downloads/folio.apk`.
