-- 8축 시스템 검증용 테스트 응답 삭제
-- 실행 위치: Supabase SQL Editor
--   https://supabase.com/dashboard/project/aosqvruvmhaumckwuidn/sql/new
-- 대상: 2026-09-23-8축테스트 회차(이미 "숨김" 처리됨, 응답자 화면엔 안 보임)에
--       실제 제출 흐름 검증을 위해 넣은 테스트 응답 1건.
-- 진행 중인 실제 회차(2026-09-18)에는 전혀 영향 없음.

delete from svy_responses where survey_slug = '2026-09-23-8축테스트';

-- 확인: 0이면 정상
select count(*) as 남은_테스트응답 from svy_responses where survey_slug = '2026-09-23-8축테스트';

-- (선택) 회차 정의 자체도 완전히 지우고 싶다면 — 숨김 상태로만 둬도 문제는 없음
-- delete from svy_surveys where slug = '2026-09-23-8축테스트';
