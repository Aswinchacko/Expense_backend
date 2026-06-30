import puppeteer from 'puppeteer';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const root = path.join(__dirname, '..');
const srcDir = path.join(root, 'landing', 'screenshots');
const outDir = path.join(srcDir, 'png');

const WIDTH = 1920;
const HEIGHT = 1080;

const screens = [
  { html: '01-home.html', png: '01-home-1920x1080.png' },
  { html: '02-add-expense.html', png: '02-add-expense-1920x1080.png' },
  { html: '03-insights.html', png: '03-insights-1920x1080.png' },
  { html: '04-categories.html', png: '04-categories-1920x1080.png' },
  { html: '05-settings.html', png: '05-settings-1920x1080.png' },
];

fs.mkdirSync(outDir, { recursive: true });

const browser = await puppeteer.launch({ headless: true });
const page = await browser.newPage();
await page.setViewport({ width: WIDTH, height: HEIGHT, deviceScaleFactor: 1 });

for (const { html, png } of screens) {
  const file = path.join(srcDir, html);
  await page.goto(`file://${file.replace(/\\/g, '/')}`, { waitUntil: 'networkidle0', timeout: 30000 });
  await page.evaluateHandle('document.fonts.ready');
  const out = path.join(outDir, png);
  await page.screenshot({ path: out, type: 'png' });
  console.log(`Created ${out}`);
}

await browser.close();
console.log(`\nDone — ${screens.length} screenshots at ${WIDTH}x${HEIGHT}`);
