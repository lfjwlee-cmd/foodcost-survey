-- ============================================================
--  통합 시식 설문 — RLS 보안 강화 (익명 삭제 차단 + 회차 보관 전환)
--  실행 위치: Supabase SQL Editor
--    https://supabase.com/dashboard/project/aosqvruvmhaumckwuidn/sql/new
--
--  [문제] svy_surveys 정책이 "for all"(select/insert/update/delete 전부)이라,
--         공개 사이트에 노출된 익명 키만 있으면 누구나 회차 정의를 영구 삭제할 수 있었다.
--         회차가 날아가면 세그먼트별 누적 분석의 비교군이 끊긴다.
--
--  [조치] 삭제 권한만 제거한다. 편집기는 로그인 없이 계속 저장 가능(insert/update 유지).
--         관리 탭의 "삭제"는 archived=true 보관(숨기기)으로 바꾸고, 언제든 복원 가능.
--         진짜 영구 삭제가 필요하면 여기 SQL Editor에서만.
--
--  ※ 전체를 한 번에 RUN 해도 되고, 단계별로 나눠 실행해도 된다(모두 재실행 안전).
-- ============================================================

-- 0) 실행 전 현재 상태 확인
select tablename, policyname, cmd, roles
  from pg_policies
 where schemaname='public' and tablename like 'svy_%'
 order by tablename, policyname;

-- 1) 보관 플래그 추가 (기존 회차는 전부 archived=false)
alter table public.svy_surveys
  add column if not exists archived boolean not null default false;

-- 2) 삭제까지 허용하던 포괄 정책 제거
drop policy if exists svy_surveys_all on public.svy_surveys;
drop policy if exists svy_surveys_rw  on public.svy_surveys;

-- 3) 삭제만 뺀 정책으로 재구성 (delete 정책을 만들지 않는 것이 핵심)
drop policy if exists svy_surveys_select on public.svy_surveys;
drop policy if exists svy_surveys_insert on public.svy_surveys;
drop policy if exists svy_surveys_update on public.svy_surveys;

create policy svy_surveys_select on public.svy_surveys
  for select to public using (true);
create policy svy_surveys_insert on public.svy_surveys
  for insert to public with check (true);
create policy svy_surveys_update on public.svy_surveys
  for update to public using (true) with check (true);

-- 4) 테이블 권한에서도 회수 — 정책이 실수로 다시 열려도 막히는 이중 방어
revoke delete on public.svy_surveys   from anon, authenticated, public;
revoke delete on public.svy_responses from anon, authenticated, public;
revoke update on public.svy_responses from anon, authenticated, public;  -- 응답은 수정 불가(기록 보호)

grant select, insert, update on public.svy_surveys   to anon;
grant select, insert         on public.svy_responses to anon;

-- 5) 검증 — 아래 결과를 눈으로 확인할 것
select tablename, policyname, cmd, roles
  from pg_policies
 where schemaname='public' and tablename like 'svy_%'
 order by tablename, cmd;

select has_table_privilege('anon','public.svy_surveys','DELETE')   as 회차_삭제권한,
       has_table_privilege('anon','public.svy_responses','DELETE') as 응답_삭제권한,
       has_table_privilege('anon','public.svy_responses','UPDATE') as 응답_수정권한,
       has_table_privilege('anon','public.svy_surveys','UPDATE')   as 회차_수정권한;
-- 기대값: 회차_삭제권한 false / 응답_삭제권한 false / 응답_수정권한 false / 회차_수정권한 true
--         (회차_수정권한이 false면 관리 편집기 저장이 막히므로 4)의 grant를 다시 실행)

-- ============================================================
--  [남는 한계 — 알고 쓸 것]
--  익명 키로 insert/update는 여전히 가능하다. 로그인 없이 편집기가 저장해야 하므로
--  구조상 불가피하다. 즉 이 조치는 "되돌릴 수 없는 손실(삭제)"만 차단한다.
--  덮어쓰기·응답 주입까지 막으려면 Supabase Auth 관리자 로그인 도입이 필요하다.
--  (그때 주의: 같은 Supabase 프로젝트를 FoodCost와 공유하므로 세션 오염 재발 방지를 위해
--   설문앱 전용 storageKey를 쓸 것. 전체기록 B-13 참고)
--
--  svy_brands는 손대지 않았다. 브랜드는 재등록이 쉬운 참조 테이블이라
--  관리 편의를 깨면서까지 잠글 실익이 없다.
-- ============================================================
