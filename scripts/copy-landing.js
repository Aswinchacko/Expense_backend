const fs = require('fs');
const path = require('path');

const src = path.join(__dirname, '..', 'landing');
const dest = path.join(__dirname, '..', 'public');
const files = ['index.html', 'styles.css'];

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
