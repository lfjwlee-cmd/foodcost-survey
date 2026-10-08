-- ============================================================================
--  인생푸드 통합 시식 설문 — Supabase 스키마 (공개해도 되는 부분만)
--
--  · 테이블 3개 + 보안정책(RLS) + 권한. 접속 키·비밀번호·실제 데이터는 들어 있지 않다.
--  · 여러 번 실행해도 안전하다(idempotent). 이미 운영 중인 DB에 다시 실행해도 정책이
--    같은 내용으로 다시 만들어질 뿐이다 — 단, 운영 중에는 되도록 실행하지 말 것.
--  · 실행: Supabase 대시보드 → SQL Editor → New query → 전체 붙여넣기 → Run
--  · 사진 투표를 쓸 때만 supabase/storage.sql 을 추가로 실행한다.
--
--  테이블 이름은 전부 svy_ 로 시작한다. 같은 프로젝트의 다른 앱 테이블과 섞이지 않게 하려는 것.
--  (다른 앱이 같은 프로젝트에 로그인 세션을 만들면 이 앱의 익명 접근을 오염시킬 수 있다 —
--   가능하면 설문 전용 프로젝트를 쓴다. 자세한 건 docs/보안메모.md)
-- ============================================================================

-- ── 1) 설문 회차(정의) ──────────────────────────────────────────────────────
create table if not exists public.svy_surveys (
  slug        text primary key,                        -- 회차 ID. 예: '2026-09-23-홀시식'
  title       text not null default '신메뉴 시식 평가',
  config      jsonb not null default '{}'::jsonb,       -- 제품·평가 항목·문항 전체 정의
  is_open     boolean not null default true,            -- 응답 폼에 보이는(활성) 회차. 한 번에 1개만 true
  archived    boolean not null default false,           -- 관리 목록에서 숨김(삭제 대신 보관)
  created_at  timestamptz not null default now()
);
-- 예전 버전(archived 컬럼 이전)에서 올라오는 DB를 위한 보강
alter table public.svy_surveys add column if not exists archived boolean not null default false;

-- ── 2) 응답 ─────────────────────────────────────────────────────────────────
create table if not exists public.svy_responses (
  id           uuid primary key default gen_random_uuid(),
  survey_slug  text not null,                           -- 어느 회차의 응답인지
  gender       text,                                    -- 남 / 여 (응답자 정보를 끈 회차는 null)
  age          text,                                    -- 20대 / 30대 / 40대 이상 (동일)
  items        jsonb not null default '[]'::jsonb,      -- [{brand,name,cat,<축key>:점수,...}, ...] 제품별 평가
  extras       jsonb not null default '{}'::jsonb,      -- {문항id: 선택/서술, ...}
  created_at   timestamptz not null default now()
);
create index if not exists idx_svy_resp_slug on public.svy_responses(survey_slug);

-- ── 3) 브랜드 목록(제품에 붙는 이름표·색) ───────────────────────────────────
create table if not exists public.svy_brands (
  name        text primary key,
  color       text not null default '#c1553a',
  note        text not null default '',
  sort        integer not null default 0,
  created_at  timestamptz not null default now()
);

-- ── 4) 행 수준 보안(RLS) ────────────────────────────────────────────────────
alter table public.svy_surveys   enable row level security;
alter table public.svy_responses enable row level security;
alter table public.svy_brands    enable row level security;

drop policy if exists svy_surveys_all    on public.svy_surveys;   -- 예전의 'for all'(삭제까지 허용) 정책 제거
drop policy if exists svy_surveys_select on public.svy_surveys;
drop policy if exists svy_surveys_insert on public.svy_surveys;
drop policy if exists svy_surveys_update on public.svy_surveys;
drop policy if exists svy_resp_insert    on public.svy_responses;
drop policy if exists svy_resp_read      on public.svy_responses;
drop policy if exists svy_brands_all     on public.svy_brands;

-- 회차 정의: 읽기·추가·수정만. **삭제 정책은 일부러 만들지 않는다**(누적 분석의 기준 데이터 보호).
--   관리 화면의 "숨기기"는 archived=true 로 바꾸는 update 이다.
create policy svy_surveys_select on public.svy_surveys for select to public using (true);
create policy svy_surveys_insert on public.svy_surveys for insert to public with check (true);
create policy svy_surveys_update on public.svy_surveys for update to public using (true) with check (true);

-- 응답: 제출(insert)과 집계용 읽기(select)만. 수정·삭제 불가 = 기록 보호.
create policy svy_resp_insert on public.svy_responses for insert to anon with check (true);
create policy svy_resp_read   on public.svy_responses for select to anon using (true);

-- 브랜드: 재등록이 쉬운 참조 데이터라 관리 화면에서 자유롭게 추가·수정·삭제.
create policy svy_brands_all on public.svy_brands for all to public using (true) with check (true);

-- ── 5) 권한(정책과 별개의 2중 방어) ─────────────────────────────────────────
-- 새 Supabase 프로젝트는 public 스키마의 새 테이블에 anon 에게 기본으로 전체 권한을 준다.
-- 삭제·응답 수정 권한을 명시적으로 회수해, 정책이 실수로 열려도 막히게 한다.
revoke delete on public.svy_surveys   from anon, authenticated, public;
revoke delete on public.svy_responses from anon, authenticated, public;
revoke update on public.svy_responses from anon, authenticated, public;
grant select, insert, update on public.svy_surveys   to anon;
grant select, insert         on public.svy_responses to anon;

-- ── 6) 확인용 조회(결과 화면에서 아래 값이 나오면 정상) ─────────────────────
-- 기대값: 회차_삭제권한 false / 응답_삭제권한 false / 응답_수정권한 false / 회차_수정권한 true
select has_table_privilege('anon','public.svy_surveys','DELETE')   as 회차_삭제권한,
       has_table_privilege('anon','public.svy_responses','DELETE') as 응답_삭제권한,
       has_table_privilege('anon','public.svy_responses','UPDATE') as 응답_수정권한,
       has_table_privilege('anon','public.svy_surveys','UPDATE')   as 회차_수정권한;
