import { chromium } from "playwright";
import fs from "node:fs";

const sql = fs.readFileSync("schema_drawdb.sql", "utf8");
fs.mkdirSync("render_out", { recursive: true });

const browser = await chromium.launch({ headless: true });
const page = await browser.newPage({ viewport: { width: 1920, height: 1200 }, deviceScaleFactor: 1 });
page.on("console", m => console.log("[browser]", m.type(), m.text()));

try {
await page.goto("http://127.0.0.1:5173/editor", { waitUntil: "networkidle", timeout: 120000 });
await page.screenshot({ path: "render_out/01_editor.png", fullPage: true });
fs.writeFileSync("render_out/01_body.txt", await page.locator("body").innerText());

// Pick PostgreSQL for the new diagram.
const pg = page.getByText("PostgreSQL", { exact: true }).first();
await pg.waitFor({ state: "visible", timeout: 30000 });
await pg.click();
await page.screenshot({ path: "render_out/02_db_selected.png", fullPage: true });
await page.getByRole("button", { name: /Confirm/i }).click();
await page.screenshot({ path: "render_out/03_after_confirm.png", fullPage: true });
await page.waitForTimeout(800);

// File -> Import from SQL -> PostgreSQL
const fileMenu = page.getByText("File", { exact: true }).first();
await fileMenu.waitFor({state:"visible", timeout:30000});
await fileMenu.click();
await page.screenshot({ path: "render_out/04_file_menu.png", fullPage: true });
const importItem = page.getByText("Import from SQL", { exact: true }).last();
await importItem.waitFor({ state: "visible", timeout: 30000 });
await importItem.click();
await page.screenshot({ path: "render_out/05_import_modal.png", fullPage: true });

await page.getByText(/Upload file/i).click();
const input = page.locator('input[type="file"]').last();
await input.setInputFiles({
  name: "schema_drawdb.sql",
  mimeType: "text/plain",
  buffer: Buffer.from(sql)
});
await page.waitForTimeout(500);

// New diagram is empty, so overwrite is unnecessary.

await page.getByRole("button", { name: /^Import$/i }).click();
await page.waitForTimeout(1500);
await page.screenshot({ path: "render_out/06_after_import.png", fullPage: true });
await page.waitForTimeout(2500);

// Fail loudly on DrawDB parse errors.
const err = page.locator(".semi-banner-danger");
if (await err.count()) {
  throw new Error("drawDB import failed: " + await err.innerText());
}

// Use drawDB's own Dagre auto-arrange.
const arrange = page.locator("button:has(i.fa-wand-magic-sparkles)");
await arrange.waitFor({ state: "visible", timeout: 30000 });
await arrange.click();
await page.waitForTimeout(1800);

// Fit diagram in window using drawDB shortcut.
await page.keyboard.press("Control+Alt+W");
await page.waitForTimeout(1200);

// Save evidence + the actual rendered canvas.
const canvas = page.locator("#canvas");
await canvas.waitFor({ state: "visible", timeout: 30000 });
await canvas.screenshot({ path: "render_out/uniadmsys_drawdb_canvas.png" });
await page.screenshot({ path: "render_out/uniadmsys_drawdb_full_ui.png", fullPage: true });

// Extract native SVG/HTML snapshot of DrawDB canvas if present.
const html = await canvas.evaluate(el => el.outerHTML);
fs.writeFileSync("render_out/drawdb_canvas.html", html);

const names = ["truong_dh","nganh","phuong_thuc_xet_tuyen","diem_chuan","hoc_phi","knowledge_base","ai_chat_history","danh_muc_nganh","to_hop_xet_tuyen","nganh_to_hop_xet_tuyen","chi_tieu_tuyen_sinh","thi_sinh","diem_thi","nguyen_vong","ket_qua_xet_tuyen","can_bo","thanh_tich_chung_chi","dieu_kien_xet_tuyen_thang","quy_doi_chung_chi","nguong_dau_vao","mon_thi","ho_so_xet_tuyen","hoc_ba","to_hop_mon","quy_tac_xet_hoc_ba","ky_thi_danh_gia","ket_qua_ky_thi_danh_gia"];
const bodyText = await page.locator("body").innerText();
const missing = names.filter(n => !bodyText.includes(n));
fs.writeFileSync("render_out/verification.txt",
  "Expected tables: 27\nMissing visible table names: " + JSON.stringify(missing) + "\n");
if (missing.length) throw new Error("Missing tables after drawDB import: " + missing.join(", "));

await browser.close();
} catch (e) {
  try {
    fs.writeFileSync("render_out/error.txt", String(e?.stack || e));
    fs.writeFileSync("render_out/error_body.txt", await page.locator("body").innerText());
    await page.screenshot({ path: "render_out/error.png", fullPage: true });
  } catch {}
  await browser.close();
  throw e;
}
