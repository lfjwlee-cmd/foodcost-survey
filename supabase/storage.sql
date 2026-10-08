-- ============================================================================
--  사진 투표용 이미지 저장소(svy-photos) — 사진 투표 문항을 쓸 때만 실행
--  · 공개 읽기(응답자 폼에 사진이 보여야 하므로) + 익명 업로드(관리 화면에서 올림).
--  · 업로드는 5MB 이하만 받도록 앱이 화면에서 한 번 더 막는다.
--  · 익명 키로는 파일을 지울 수 없다(삭제는 대시보드 Storage 화면에서만).
-- ============================================================================
insert into storage.buckets (id, name, public)
values ('svy-photos', 'svy-photos', true)
on conflict (id) do update set public = true;

drop policy if exists svy_photos_insert on storage.objects;
drop policy if exists svy_photos_read   on storage.objects;
create policy svy_photos_insert on storage.objects for insert to anon, authenticated with check (bucket_id = 'svy-photos');
create policy svy_photos_read   on storage.objects for select to anon, authenticated using (bucket_id = 'svy-photos');
