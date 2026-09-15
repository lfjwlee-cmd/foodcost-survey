-- 통합 시식 설문: 테스트 응답 삭제용 SQL
-- 실행 위치: Supabase SQL Editor
--   https://supabase.com/dashboard/project/aosqvruvmhaumckwuidn/sql/new
-- 주의: 응답 데이터만 삭제. 설문 정의(svy_surveys)·브랜드(svy_brands)·구조는 유지됨.
-- anon(익명) 권한으로는 삭제가 막혀 있으므로(보안), 반드시 관리자 SQL Editor에서 실행할 것.

-- 1) 특정 회차의 응답만 삭제 (권장)
delete from svy_responses where survey_slug = '2026-08-시식';

-- 2) (전체 초기화가 필요할 때만) 모든 응답 삭제
-- delete from svy_responses;

-- 확인: 0 이면 정상
select count(*) as 남은응답 from svy_responses;
