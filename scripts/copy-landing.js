const fs = require('fs');
const path = require('path');

const src = path.join(__dirname, '..', 'landing');
const dest = path.join(__dirname, '..', 'public');
const files = ['index.html', 'styles.css', 'privacy.html', 'terms.html', 'legal.css'];
const APK_NAME = 'folio.apk';

if (!fs.existsSync(src)) {
  console.warn('landing/ not found — using committed public/ files');
  process.exit(0);
}

if (!fs.existsSync(dest)) fs.mkdirSync(dest, { recursive: true });

for (const file of files) {
  const from = path.join(src, file);
  if (!fs.existsSync(from)) {
    console.warn(`landing/${file} missing — skipping`);
    continue;
  }
  fs.copyFileSync(from, path.join(dest, file));
  console.log(`Copied landing/${file} → public/${file}`);
}

const apkSrc = path.join(src, 'downloads', APK_NAME);
const downloadsDest = path.join(dest, 'downloads');
if (fs.existsSync(apkSrc)) {
  if (!fs.existsSync(downloadsDest)) fs.mkdirSync(downloadsDest, { recursive: true });
  fs.copyFileSync(apkSrc, path.join(downloadsDest, APK_NAME));
  console.log(`Copied landing/downloads/${APK_NAME} → public/downloads/${APK_NAME}`);
} else {
  console.warn(`landing/downloads/${APK_NAME} missing — direct download disabled until APK is added`);
}
