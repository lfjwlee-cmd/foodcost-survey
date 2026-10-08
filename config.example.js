// ── 설문 앱 접속 설정 (예시) ─────────────────────────────────────────────────
//  이 파일을 config.js 로 복사한 뒤 아래 3개 값을 본인 것으로 바꾼다.
//    cp config.example.js config.js        (Windows: copy config.example.js config.js)
//
//  SUPABASE_URL / SUPABASE_ANON_KEY
//    Supabase 대시보드 → Project Settings → API 에서 확인.
//    ANON_KEY 는 반드시 "anon / publishable" 키만. ※ service_role / secret 키는 절대 넣지 말 것
//    (브라우저에 그대로 노출되며, 이 키가 있으면 모든 보안정책이 무시된다).
//    anon(publishable) 키는 공개돼도 되도록 만들어진 키이고, 실제 보호는 supabase/schema.sql 의
//    보안정책(RLS)이 한다.
//
//  RESULTS_KEY
//    결과 보기·관리 탭을 여는 비밀번호. 브라우저에서 비교하는 "약한 잠금"이라 화면을 가리는 용도일 뿐,
//    DB 보호 수단이 아니다. 공개 저장소에 올리는 파일에는 실제 운영 비밀번호를 쓰지 말 것.
window.SURVEY_CONFIG = {
  SUPABASE_URL: "https://<프로젝트-ref>.supabase.co",
  SUPABASE_ANON_KEY: "<anon-또는-publishable-키>",
  RESULTS_KEY: "<결과-보기-비밀번호>",
};
