-- 정리 대상: 검증용 테스트 회차 2개 + 오래된 실험 회차 3개
-- 유지: 2026-09-18(아구지리탕 등 4명 실데이터), 2026-09-23-홀시식(현재 진행 중인 실제 회차)
-- 실행 위치: Supabase SQL Editor
--   https://supabase.com/dashboard/project/aosqvruvmhaumckwuidn/sql/new
-- ⚠️ 대량 삭제라 자동화 도구가 직접 실행을 막아둠 — 아래를 그대로 복사해 직접 실행할 것

delete from svy_responses where survey_slug in (
  '2026-09-23-8축테스트','2026-09-시식-2','2026-09-투표','2026-09-시식','2026-08-시식'
);

delete from svy_surveys where slug in (
  '2026-09-23-8축테스트','2026-09-시식-2','2026-09-투표','2026-09-시식','2026-08-시식'
);

-- 확인: 아래 2개 슬러그만 남아야 정상
select slug, title, is_open, archived from svy_surveys order by created_at desc;
