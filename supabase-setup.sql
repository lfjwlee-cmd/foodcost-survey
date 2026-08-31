-- ============================================================
--  인생푸드 신메뉴 시식 설문 — Supabase 테이블 & 보안 설정
--  Supabase 대시보드 → 왼쪽 "SQL Editor" → New query 에 전체 붙여넣고 RUN
--  (FoodCost와 같은 프로젝트에서 실행해도 기존 테이블에 영향 없음 — 이름이 svy_ 로 분리됨)
-- ============================================================

-- 1) 설문 정의 (선택) — 여러 시식 이벤트를 slug 로 구분해 보관
create table if not exists public.svy_surveys (
  slug        text primary key,                       -- 예: '2026-08-시식'
  title       text not null default '신메뉴 시식 평가',
  config      jsonb not null default '{}'::jsonb,      -- questions.json 백업(선택)
  is_open     boolean not null default true,
  created_at  timestamptz not null default now()
);

-- 2) 응답 — 모든 팀의 폰 응답이 여기에 자동 누적
create table if not exists public.svy_responses (
  id           uuid primary key default gen_random_uuid(),
  survey_slug  text not null,                          -- 어느 시식 회차인지
  gender       text,                                   -- 남 / 여
  age          text,                                   -- 20대 / 30대 / 40대 이상
  items        jsonb not null default '[]'::jsonb,     -- [{brand,name,cat,taste,aroma,look,texture,portion}, ...]
  extras       jsonb not null default '{}'::jsonb,     -- {kalPrice, eggPref, opinions, 모듈 등}
  created_at   timestamptz not null default now()
);
create index if not exists idx_svy_resp_slug on public.svy_responses(survey_slug);

-- 3) 행 수준 보안(RLS)
alter table public.svy_surveys   enable row level security;
alter table public.svy_responses enable row level security;

-- 4) 정책 (내부 도구 기준):
--    · 설문 정의: 자유 (편집기가 로그인 없이 저장)
--    · 응답: 넣기(응답 제출) + 읽기(대시보드 집계) 허용. 수정/삭제는 불가.
drop policy if exists svy_surveys_all   on public.svy_surveys;
drop policy if exists svy_resp_insert   on public.svy_responses;
drop policy if exists svy_resp_read     on public.svy_responses;

create policy svy_surveys_all on public.svy_surveys
  for all to anon using (true) with check (true);

create policy svy_resp_insert on public.svy_responses
  for insert to anon with check (true);

create policy svy_resp_read on public.svy_responses
  for select to anon using (true);
