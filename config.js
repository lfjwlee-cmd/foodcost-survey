// ── 설문 전용 Supabase 접속 설정 ──
//  프로젝트: 인생푸드 (lfjwlee-cmd's Project) — 테이블은 svy_ 로 분리됨
//  Publishable 키는 브라우저에 공개돼도 되는 키입니다(보호는 RLS로 함).
window.SURVEY_CONFIG = {
  SUPABASE_URL: "https://aosqvruvmhaumckwuidn.supabase.co",
  SUPABASE_ANON_KEY: "sb_publishable_snEBmk1dvtRdsd63a7ef2g_eqYdbmLk",
  // 결과 보기 탭 비밀번호 (사장·본부만 아는 값으로 바꾸세요)
  RESULTS_KEY: "insaeng2026",
};
