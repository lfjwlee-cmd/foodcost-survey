// 결과 보고서를 실제 PDF 파일로 뽑아 페이지 나눔을 확인하는 검증용 스크립트 (Windows + Chrome, Node 22+)
//   node tools/report-to-pdf.mjs <출력폴더> [회차ID] [사이트주소] [가상응답수]
//   예) node tools/report-to-pdf.mjs out 2026-10-시식-2 http://127.0.0.1:4500/ 100
// 사이트에 접속해 해당 회차의 응답을 읽기만 하고(쓰기 없음), 보고서의 각 범위(전체/브랜드/투표·의견)를 Chrome 인쇄 경로로 PDF 로 저장한다.
// 가상응답수를 주면 응답이 많을 때(예: 100명)의 쪽 나눔을 화면 메모리에서만 흉내 낸다. 쪽 수·쪽별 내용은 pdftotext 등으로 확인한다.
// Chrome 경로가 다르면 아래 CHROME 을 고친다.
import { spawn } from "node:child_process";
import { writeFileSync, mkdirSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import path from "node:path";

const CHROME = "C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe";
const OUT = process.argv[2];
const SLUG = process.argv[3] || "2026-10-시식-2";
const SITE = process.argv[4] || "https://lfjwlee-cmd.github.io/foodcost-survey/";
const MOCK = +process.argv[5] || 0; // (선택) 응답자 수를 가상으로 늘려 많은 응답일 때의 쪽 나눔을 확인 — 화면 메모리에서만, DB 쓰기 없음
mkdirSync(OUT, { recursive: true });
const profile = path.join(tmpdir(), "pdf-prof-" + Date.now());
const port = 9400 + Math.floor(Math.random() * 300);
const chrome = spawn(CHROME, ["--headless=new", `--remote-debugging-port=${port}`, `--user-data-dir=${profile}`, "--no-first-run", "--disable-gpu", "about:blank"], { stdio: "ignore" });
const sleep = ms => new Promise(r => setTimeout(r, ms));
let ws, id = 0; const pend = new Map();
function send(method, params = {}) { return new Promise((res, rej) => { const i = ++id; pend.set(i, { res, rej }); ws.send(JSON.stringify({ id: i, method, params })); }); }
async function ev(expr) { const r = await send("Runtime.evaluate", { expression: expr, awaitPromise: true, returnByValue: true }); if (r.exceptionDetails) throw new Error(JSON.stringify(r.exceptionDetails).slice(0, 400)); return r.result.value; }
try {
  let targets;
  for (let i = 0; i < 40; i++) { try { targets = await (await fetch(`http://127.0.0.1:${port}/json/list`)).json(); if (targets.length) break; } catch (e) {} await sleep(250); }
  const page = targets.find(t => t.type === "page");
  ws = new WebSocket(page.webSocketDebuggerUrl);
  await new Promise(r => ws.addEventListener("open", r));
  ws.addEventListener("message", m => { const d = JSON.parse(m.data); if (d.id && pend.has(d.id)) { const p = pend.get(d.id); pend.delete(d.id); d.error ? p.rej(new Error(JSON.stringify(d.error))) : p.res(d.result); } });
  await send("Page.enable"); await send("Runtime.enable");
  await send("Page.navigate", { url: SITE + "?cb=pdf" + Date.now() + "#admin" });
  await sleep(4500);
  const html = await ev(`(async()=>{ try{clearInterval(timer)}catch(e){} unlocked=true; setView("results"); viewSlug=${JSON.stringify(SLUG)}; await loadDash(); try{clearInterval(timer)}catch(e){}
    if(${MOCK}){ const real=ROWS; sb=null; ROWS=[...Array(${MOCK}).keys()].map(i=>({...real[i%real.length],extras:{...real[i%real.length].extras,opinion:"의견 "+(i+1)+" — 맛과 가격에 대한 의견을 조금 길게 적어 본 가상 문장입니다."}})); }
    let h=null; const oo=window.open; window.open=()=>({document:{open(){},write(x){h=x},close(){}}}); openReport(); window.open=oo; return h; })()`);
  if (!html) throw new Error("보고서 HTML 을 만들지 못함");
  writeFileSync(path.join(OUT, "report.html"), html);
  // 보고서를 별도 문서로 열고, 브라우저 인쇄와 같은 경로(Page.printToPDF)로 각 범위를 PDF 로 저장
  await send("Page.navigate", { url: "about:blank" }); await sleep(500);
  await ev(`document.open(); document.write(${JSON.stringify(html)}); document.close(); 1`); await sleep(800);
  const views = await ev(`[...document.querySelectorAll('#vsel option')].map(o=>o.value+'|'+o.textContent)`);
  writeFileSync(path.join(OUT, "views.json"), JSON.stringify(views));
  const list = views.length ? views.map(v => v.split("|")[0]) : ["__all"];
  for (const v of list) {
    await ev(`(function(){ var s=document.getElementById('vsel'); if(s){s.value=${JSON.stringify(v)};} show(${JSON.stringify(v)}); return 1; })()`);
    await sleep(300);
    const r = await send("Page.printToPDF", { printBackground: true, paperWidth: 8.27, paperHeight: 11.69, marginTop: 0.4, marginBottom: 0.4, marginLeft: 0.4, marginRight: 0.4 });
    writeFileSync(path.join(OUT, `report_${v.replace(/[^a-z0-9_]/gi, "_")}.pdf`), Buffer.from(r.data, "base64"));
  }
  console.log("OK", list.join(","));
} catch (e) { console.log("ERR", e.message); }
finally { try { ws && ws.close(); } catch (e) {} chrome.kill(); await sleep(500); try { rmSync(profile, { recursive: true, force: true }); } catch (e) {} process.exit(0); }
