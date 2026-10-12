// Runs every move's form checks in the real page and saves screenshots
// of the start and end positions. Run from app/:
//
//   node tool/motion/check.js /tmp/motion-lab.html /tmp/motion-shots
//
// Needs Playwright with Chromium and network access for three.js.
const path = require('path');
const fs = require('fs');
const { chromium } = require(process.env.PLAYWRIGHT || 'playwright');

(async () => {
  const [page, out] = process.argv.slice(2);
  fs.mkdirSync(out, { recursive: true });
  const proxy = process.env.HTTPS_PROXY ? { server: process.env.HTTPS_PROXY } : undefined;
  const browser = await chromium.launch({
    executablePath: process.env.CHROMIUM || undefined,
    proxy,
    args: ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-certificate-errors'],
  });
  const p = await browser.newPage({ viewport: { width: 1200, height: 800 } });
  const errors = [];
  p.on('pageerror', (e) => errors.push(e.message));
  await p.goto('file://' + path.resolve(page));
  await p.waitForFunction(() => window.__lab, null, { timeout: 30000 });
  let failed = 0;
  for (const id of await p.evaluate(() => window.__lab.ids)) {
    const res = await p.evaluate((id) => window.__lab.select(id), id);
    for (const r of res) {
      console.log(`${r.pass ? 'PASS' : 'FAIL'}  ${id.padEnd(7)} ${r.title} (${r.rule}): ${r.value}`);
      if (!r.pass) failed++;
    }
    for (const a of [0, 1]) {
      await p.evaluate((a) => window.__lab.freeze(a), a);
      await p.waitForTimeout(1300);
      await p.screenshot({ path: path.join(out, `${id}-${a ? 'end' : 'start'}.png`), clip: { x: 0, y: 40, width: 800, height: 760 } });
    }
    await p.evaluate(() => window.__lab.freeze(null));
  }
  if (errors.length) { console.log('Page errors:\n' + errors.join('\n')); failed++; }
  await browser.close();
  console.log(failed ? `${failed} problem(s)` : 'All form checks pass.');
  process.exit(failed ? 1 : 0);
})();
