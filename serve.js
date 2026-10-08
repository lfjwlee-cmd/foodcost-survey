// 로컬 미리보기용 정적 서버 (테스트 전용) — node serve.js → http://localhost:4500
//  · 이 컴퓨터(127.0.0.1)에서만 접속된다. 같은 와이파이의 다른 기기는 접속할 수 없다.
//  · 이 폴더 바깥의 파일은 절대 내보내지 않는다(../ 로 위 폴더를 읽는 시도 차단).
//  · 주의: config.js 의 Supabase 설정을 그대로 쓰므로, 로컬에서 응답을 제출하면 그 DB 에 실제로 저장된다.
const http=require("http"),fs=require("fs"),path=require("path");
const MIME={".html":"text/html; charset=utf-8",".js":"text/javascript; charset=utf-8",".json":"application/json; charset=utf-8",".css":"text/css",".png":"image/png",".svg":"image/svg+xml"};
const ROOT=path.resolve(__dirname),PORT=4500,HOST="127.0.0.1";
http.createServer((req,res)=>{
  let p;
  try{ p=decodeURIComponent(req.url.split("?")[0]); }catch(e){ res.writeHead(400);res.end("400");return; }
  if(p==="/")p="/index.html";
  const fp=path.resolve(ROOT,"."+p);
  // 결과 경로가 ROOT 안이 아니면 거부(../ 및 인코딩된 ..%2f 모두 여기서 걸린다)
  if(fp!==ROOT && !fp.startsWith(ROOT+path.sep)){ res.writeHead(403);res.end("403");return; }
  fs.readFile(fp,(e,data)=>{
    if(e){res.writeHead(404);res.end("404");return;}
    res.writeHead(200,{"Content-Type":MIME[path.extname(fp)]||"application/octet-stream"});res.end(data);
  });
}).listen(PORT,HOST,()=>console.log("▶ http://localhost:"+PORT+"  (이 컴퓨터에서만 접속 가능)"));
