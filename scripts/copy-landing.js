const fs = require('fs');
const path = require('path');

const src = path.join(__dirname, '..', 'landing');
const dest = path.join(__dirname, '..', 'public');

if (!fs.existsSync(dest)) fs.mkdirSync(dest, { recursive: true });

for (const file of ['index.html', 'styles.css']) {
  fs.copyFileSync(path.join(src, file), path.join(dest, file));
  console.log(`Copied landing/${file} → public/${file}`);
}
