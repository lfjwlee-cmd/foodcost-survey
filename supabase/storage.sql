-- ============================================================================
--  사진 투표용 이미지 저장소(svy-photos) — 사진 투표 문항을 쓸 때만 실행
--  · 공개 읽기(응답자 폼에 사진이 보여야 하므로) + 익명 업로드(관리 화면에서 올림).
--  · 업로드는 5MB 이하·이미지(jpg/png/webp/gif)만 받도록 버킷 자체에 제한을 건다(앱도 화면에서 5MB 를 한 번 더 막음).
--    제한이 없으면 anon 키를 아는 누구나 아무 종류의 파일을 공개 저장소에 올릴 수 있다. 아이폰 HEIC 사진은 거절되니 jpg/png 로 올릴 것.
--  · 익명 키로는 파일을 지울 수 없다(삭제는 대시보드 Storage 화면에서만).
-- ============================================================================
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('svy-photos', 'svy-photos', true, 5242880, array['image/jpeg','image/png','image/webp','image/gif'])
on conflict (id) do update set public = true, file_size_limit = 5242880,
  allowed_mime_types = array['image/jpeg','image/png','image/webp','image/gif'];

drop policy if exists svy_photos_insert on storage.objects;
drop policy if exists svy_photos_read   on storage.objects;
create policy svy_photos_insert on storage.objects for insert to anon, authenticated with check (bucket_id = 'svy-photos');
create policy svy_photos_read   on storage.objects for select to anon, authenticated using (bucket_id = 'svy-photos');
