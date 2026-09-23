-- 8축 시스템 검증 과정에서 생긴 테스트 데이터 정리
-- 실행 위치: Supabase SQL Editor
--   https://supabase.com/dashboard/project/aosqvruvmhaumckwuidn/sql/new
--
-- 대상 1) 의도한 테스트 회차 — 실제 제출 흐름을 검증하려고 만든 응답 1건
-- 대상 2) 검증 중 실수로 남은 잔여 응답 2건(자동 생성된 슬러그 "2026-09-시식-2"에
--         제출된 것 — CSS 버그 확인 과정에서 실수로 제출까지 이어진 것으로 보임)
-- 두 회차 모두 이미 "숨김" 처리(archived=true)돼 있어 결과·응답 화면 어디에도 노출되지 않음.
-- 진행 중인 실제 회차(2026-09-23-홀시식)에는 전혀 영향 없음.

delete from svy_responses where survey_slug in ('2026-09-23-8축테스트', '2026-09-시식-2');

-- 확인: 0이면 정상
select count(*) as 남은_테스트응답
  from svy_responses
 where survey_slug in ('2026-09-23-8축테스트', '2026-09-시식-2');

-- (선택) 회차 정의 자체도 완전히 지우고 싶다면 — 숨김 상태로만 둬도 문제는 없음
-- delete from svy_surveys where slug in ('2026-09-23-8축테스트', '2026-09-시식-2');
