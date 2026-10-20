# 인생푸드 통합 시식 설문

QR 하나로 여러 팀이 **폰에서 신메뉴 시식을 평가**하면, 응답이 **한 DB에 누적**되고, 관리자가 **실시간 대시보드·PDF 보고서·엑셀**로 확인하는 시스템입니다. 설문 도구가 아니라 **누적 DB**가 핵심입니다 — 회차를 쌓아 두고 세그먼트(성별·연령)별 선호를 계속 비교하려는 것입니다.

- 응답자는 계정 없이 아무 폰 브라우저로 참여
- 빌드 과정 없음: 정적 파일(`index.html` + `config.js`) + Supabase(DB)
- 시식 평가 말고 **사내 업무 투표**(제품 없이 선택 문항만)도 같은 시스템으로 받는다

```
[응답자 폰] ──QR──▶ GitHub Pages (정적 호스팅: index.html) ──▶ Supabase (DB + 사진 저장소)
                                                   ▲
                      [관리자] 응답 주소 끝에 #admin → 결과 보기 · 관리 (비밀번호 잠금)
```

---

## 1. 다른 PC에서 그대로 만들기

### 준비물
| 무엇 | 왜 |
|---|---|
| Git | 저장소 받기 |
| Node.js 18+ | **로컬 미리보기에만** 필요(`node serve.js`). 서비스 자체에는 불필요 |
| GitHub 계정 | 공개 배포(GitHub Pages) |
| Supabase 계정 | DB. 무료 플랜으로 충분 |

### 단계

**① 저장소 받기**
```bash
git clone https://github.com/lfjwlee-cmd/foodcost-survey.git
cd foodcost-survey
```

**② Supabase 프로젝트 만들고 스키마 넣기** — *여기가 "공개 가능한 Supabase 부분"입니다*
1. https://supabase.com → New project (가능하면 **설문 전용 프로젝트**. 이유는 `docs/보안메모.md`)
2. 왼쪽 **SQL Editor → New query** → [`supabase/schema.sql`](supabase/schema.sql) 전체를 붙여넣고 **Run**
   → 테이블 3개(`svy_surveys`·`svy_responses`·`svy_brands`)와 보안정책이 만들어지고, 맨 아래 확인 쿼리가 `false / false / false / true` 로 나오면 정상
3. 사진 투표를 쓸 때만 [`supabase/storage.sql`](supabase/storage.sql) 도 같은 방식으로 실행

**③ 접속 정보 넣기**
```bash
cp config.example.js config.js        # Windows: copy config.example.js config.js
```
`config.js` 를 열어 3개 값을 바꿉니다.
- `SUPABASE_URL` · `SUPABASE_ANON_KEY` : Supabase → **Project Settings → API** 의 *Project URL* 과 *anon / publishable* 키
  (**service_role / secret 키는 절대 넣지 마세요** — 브라우저에 노출되며 모든 보안정책을 무시합니다)
- `RESULTS_KEY` : 결과·관리 탭 비밀번호(약한 잠금)

**④ 로컬에서 확인**
```bash
node serve.js        # → http://localhost:4500  (이 컴퓨터에서만 접속됨)
```
- 처음 열면 활성 회차가 하나도 없으므로 **샘플 회차**(`questions.json`, 8개 평가 항목)가 자동으로 만들어져 활성화됩니다.
- 주소 끝에 `#admin` 을 붙여 열면 [응답하기][결과 보기][관리] 탭이 나옵니다.
- ⚠️ `config.js` 가 가리키는 DB에 **실제로 저장**됩니다. 연습은 본인 Supabase 프로젝트로 하세요.

**⑤ 공개 배포 (GitHub Pages)**
1. 본인 GitHub 저장소에 올림(포크 또는 새 저장소) → **Settings → Pages → Branch: `main` / `(root)`**
2. 1~2분 뒤 `https://<계정>.github.io/<저장소>/` 로 접속
3. `qr.html` 로 응답 주소 QR 생성 → 인쇄·게시

> 이 저장소의 `config.js` 에는 **운영 중인 프로젝트 값**이 들어 있습니다. 그대로 clone 해서 쓰면 같은 DB에 붙습니다. **별도 환경을 만들 때는 반드시 위 ③으로 본인 값으로 교체**하세요.

---

## 2. 폴더 구조

```
index.html          앱 전체(응답 폼 + 결과 대시보드 + 관리). 단일 파일, 빌드 없음
config.js           Supabase 접속·비밀번호 (이 저장소 것은 운영 값 — 위 ③ 참고)
config.example.js   config.js 작성용 예시(값이 비어 있음)
questions.json      활성 회차가 하나도 없을 때 쓰는 샘플 회차(8축 표준)
qr.html             응답 주소 QR 생성기
results.html        index.html 로 넘기는 옛 주소 호환용
serve.js            로컬 미리보기 서버(127.0.0.1 전용, 폴더 바깥 접근 차단)
tools/
  report-to-pdf.mjs 결과 보고서를 실제 PDF 파일로 뽑아 쪽 나눔을 확인하는 검증용 스크립트(Chrome 필요)
supabase/
  schema.sql        테이블·보안정책·권한 (처음 설치 시 1회)
  storage.sql       사진 투표용 저장소(선택)
  maintenance.sql   운영 중 쓰는 조회·삭제 SQL 모음(삭제는 전부 주석 처리)
docs/
  운영가이드.md     회차 만들기·항목 이름 수정·판정 규칙·결과/PDF/엑셀
  보안메모.md       무엇이 공개되고 무엇이 비공개인지, 삭제 정책
  검증체크리스트.md 수정 후 직접 확인할 항목(회귀 방지)
  변경기록.md       공개용 변경 요약
```

---

## 3. 핵심 규칙 한눈에

| | |
|---|---|
| **평가 항목** | 제품마다 8개 — **맛 그룹 3**(첫맛·뒷맛·간의 적절성) + **관능 그룹 5**(향·풍미·색감·플레이팅·식감·제공량), 각 5점 척도 |
| **이름 수정** | 관리 → 회차 편집 → "평가 항목 이름". 이름·설명만 바뀌고 그룹·개수는 고정(맛 평균은 이름과 무관). **8자 이내**, **응답이 1건이라도 있으면 잠금** |
| **판정** | 맛 평균 ≥ 4.2 **그리고** 관능 평균 ≥ 4.2 → `다음 단계 진행`. 맛만 미달 `맛 보강` · 관능만 미달 `관능 수정` · 둘 다 `맛·관능 보강`. **표본 3명 미만은 `표본 부족`** |
| **기준값 위치** | `index.html` 의 `const TASTE_MIN=4.2, SENSORY_MIN=4.2, MIN_SAMPLE=3;` |
| **회차 종류** | 제품이 있으면 *시식*, 없으면 *투표*(응답자 정보도 끌 수 있어 익명 투표 가능) |
| **활성 회차** | 응답 주소에는 항상 **1개 회차**만 보인다. 새 회차를 활성화하면 이전 회차는 자동 비활성(데이터 보존) |
| **삭제 정책** | 웹 화면은 **삭제 불가**(`숨기기`만). 영구 삭제는 `supabase/maintenance.sql` + SQL Editor 에서만 |

자세한 운영 방법은 [`docs/운영가이드.md`](docs/운영가이드.md).

---

## 4. 자주 겪는 문제

- **코드를 고쳐 배포했는데 화면이 그대로** → GitHub Pages 가 10분간 캐시를 허용합니다. **Ctrl+Shift+R**(강력 새로고침)로 확인하세요.
- **결과 보기에서 응답이 0건** → 같은 Supabase 프로젝트에 다른 앱 로그인 세션이 있으면 익명 접근이 오염될 수 있습니다(앱은 익명 전용으로 고정해 막아 둠). 그래도 이상하면 설문 전용 프로젝트를 쓰세요.
- **엑셀 저장이 CSV로 저장됨** → 엑셀 라이브러리(CDN)를 못 불러온 경우의 자동 대체입니다. 사내망이면 외부 CDN 허용 여부를 확인하세요.
- **활성 회차가 없어지면** → 응답 주소를 여는 순간 샘플 회차가 자동 생성·활성화됩니다. 의도치 않게 만들어지지 않도록 활성 회차를 비워 두지 마세요.

---

## 5. 외부 서비스 의존

CDN: `supabase-js@2`, `xlsx@0.18.5`(jsDelivr) · 폰트: Google Fonts · QR 이미지: `api.qrserver.com`(`qr.html`).
