// 로컬 미리보기용 정적 서버 (테스트 전용) — node serve.js → http://localhost:4500
const http=require("http"),fs=require("fs"),path=require("path");
const MIME={".html":"text/html; charset=utf-8",".js":"text/javascript; charset=utf-8",".json":"application/json; charset=utf-8",".css":"text/css",".png":"image/png",".svg":"image/svg+xml"};
const ROOT=__dirname,PORT=4500;
http.createServer((req,res)=>{
  let p=decodeURIComponent(req.url.split("?")[0]);if(p==="/")p="/index.html";
  const fp=path.join(ROOT,p);
  fs.readFile(fp,(e,data)=>{
    if(e){res.writeHead(404);res.end("404");return;}
    res.writeHead(200,{"Content-Type":MIME[path.extname(fp)]||"application/octet-stream"});res.end(data);
  });
}).listen(PORT,()=>console.log("▶ http://localhost:"+PORT));
