-- ============================================================================
--  운영 중 쓰는 SQL 모음 — Supabase SQL Editor 에서 필요한 블록만 골라 실행
--  · 조회(SELECT)는 바로 실행해도 안전하다.
--  · 삭제(DELETE)는 전부 주석 처리돼 있다. 되돌릴 수 없으니 슬러그를 한 번 더 확인하고,
--    "-- " 를 지운 뒤 그 블록만 선택해서 Run 한다.
--  · 웹 화면(익명 키)에서는 회차·응답을 지울 수 없게 막아 두었다(supabase/schema.sql).
--    그래서 영구 삭제는 이 파일 + SQL Editor 로만 가능하다. 화면의 "숨기기"는 삭제가 아니다.
-- ============================================================================

-- ① 회차 목록과 응답 수 (삭제 전에 항상 먼저 확인)
select s.slug, s.title, s.is_open as 활성, s.archived as 보관, count(r.id) as 응답수, s.created_at
  from svy_surveys s
  left join svy_responses r on r.survey_slug = s.slug
 group by s.slug, s.title, s.is_open, s.archived, s.created_at
 order by s.created_at desc;

-- ② 슬러그에 해당하는 회차가 없는데 응답만 남은 경우 찾기
select survey_slug, count(*) as 응답수
  from svy_responses
 where survey_slug not in (select slug from svy_surveys)
 group by survey_slug;

-- ③ 숨긴(보관) 회차 복원 — 삭제가 아니라 목록에 다시 나타나게만 한다
-- update svy_surveys set archived = false where slug = '여기에-슬러그';

-- ④ [되돌릴 수 없음] 테스트 회차 하나를 응답까지 통째로 삭제
--    ※ 활성 회차(is_open = true)나 실제 응답이 있는 회차는 지우지 말 것
-- delete from svy_responses where survey_slug = '여기에-슬러그';
-- delete from svy_surveys   where slug        = '여기에-슬러그';

-- ⑤ 삭제 후 확인 — ①을 다시 실행해 의도한 회차만 사라졌는지 본다

-- ⑥ 보안정책이 의도대로인지 점검(삭제·수정 권한이 막혀 있어야 정상)
select tablename, policyname, cmd, roles
  from pg_policies
 where schemaname = 'public' and tablename like 'svy\_%'
 order by tablename, cmd;
