# 개발 로그 (DEV_LOG)

기능 하나가 끝날 때마다 아래 형식으로 정리해 쌓는다.
형식: 개요 → 개발 방식 → 구현 내용 → 핵심 결정 → 검증 → Git → 미연결 → 다음.

---

## 로그인 플로우 (툭) — 2026-07-30

### 1. 개요
디자인 핸드오프(`design_handoff_tuk_auth`) 기반으로 **앱 첫 진입부터 로그인 직후 홈까지** 구현.
스플래시 → 랜딩 → 인트로 5컷 → (dev)로그인 → 홈 콜드스타트.

### 2. 개발 방식
- **디자인 주도**: HTML/CSS를 옮기지 않고 색·타이포·간격·반경 **토큰 값만** Flutter 위젯으로 재현(고정밀).
- **검토 게이트**: 디자인시스템 → 화면 순으로 만들고, 매 단계 에뮬레이터 스크린샷으로 확인 후 진행.
- **기능별 git**: 미리 만든 코드라도 한 기능씩 커밋·푸시. 아직 안 올릴 파일은 로컬 미추적으로 대기.

### 3. 구현 내용 (Provider + MVVM)
디렉터리: `core`(디자인시스템) · `widgets` · `views` · `viewmodels` · `services` · `repositories` · `models`.

**디자인 시스템**
| 파일 | 내용 |
|---|---|
| `core/tokens.dart` | 코랄 팔레트·간격(4배수)·radius·그림자 |
| `core/typography.dart` | Pretendard 스케일(Display~Caption) |
| `core/theme.dart` | Material3 ColorScheme 조립 |
| `widgets/logo.dart` | 툭 로고 — viewBox 120 궤적 CustomPaint, 크기별 획 보정, 3변형(coral/light/splash) |
| `widgets/primitives.dart` | `PillButton`(코랄/카카오/보조, 눌림 애니메이션)·`SummaryCard` |
| `widgets/toast.dart` | 실패 토스트(다크 pill 1.8s) |

**화면**
| 파일 | 화면 |
|---|---|
| `views/splash_screen.dart` | 스플래시(코랄 전면·로고 등장·세션 분기) |
| `views/landing_screen.dart` | 랜딩(로고·헤드라인·요약카드3·카카오·둘러보기·약관) |
| `views/intro_screen.dart` | 인트로 5컷(PageView·인디케이터·건너뛰기 + 컷별 목업) |
| `views/home_coldstart_screen.dart` | 홈 콜드스타트(콜 카드·빈 상태·초대 CTA) |

**인증 배관(재사용)**: `services/token_storage`(secure storage) · `services/api_client`(dio, 401→refresh rotation single-flight) · `repositories/auth_repository` · `viewmodels/auth_view_model` · `models/auth_tokens`. + Pretendard 폰트 3종(`assets/fonts`).

### 4. 핵심 결정 (왜)
| 결정 | 이유 |
|---|---|
| 브랜드 "툭" + 코랄 | 핸드오프 확정 (코드·패키지는 계속 `bungae`) |
| 카카오 버튼 → dev 로그인 배선 | 카카오 SDK(앱키·네이티브) 설정 부담 큼 → 흐름부터 완성. 숨은 dev 경로=로고 롱프레스(멀티계정) |
| AuthViewModel에서 STOMP 분리 | 실시간은 프레즌스용 → 인증이 웹소켓 소유는 과결합 |
| 명령형 Navigator | 로그인 순간 선언형 게이트와 pushed 라우트 충돌 회피, 디자인 네비맵과 일치 |
| Pretendard 번들(OFL) | 픽셀 정밀도엔 실제 폰트 필요 |

### 5. 검증
- `flutter analyze` 클린, 위젯 테스트(로고/테마) 통과.
- 에뮬레이터 E2E: 스플래시→랜딩→인트로(스와이프/다음/건너뛰기/인디케이터)→dev로그인→홈 콜드스타트(콜 토글 켜짐↔꺼짐)까지 실제 동작.

### 6. Git
```
3e63968  기초 세팅
9b6f8ee  로그인(1): 디자인 시스템 + 스플래시 + 랜딩 + 인증배관
da3d787  로그인(2): 인트로 5컷
a542175  로그인(3): 홈 콜드스타트
```

### 7. 의도적 미연결 (다음 기능으로)
| 항목 | 어디서 |
|---|---|
| "지금 콜" 토글 실제 API | 프레즌스(#3) |
| "친구 초대/연락처 찾기" | 친구(#4, 초대코드) |
| 프로필 아바타 실제 정보 | 백엔드 `GET /users/me` 추가 후 |
| 카카오 실제 로그인 | 카카오 SDK 연동 |

### 8. 다음
프레즌스 기능(#3) — 실제 콜 on/off·"지금 한가한 친구"·STOMP 실시간. 로그인 때 뗀 웹소켓 연결을 여기서 붙임.

---

## 프레즌스 (지금 콜 · 지금 한가한 친구) — 2026-08-13

### 1. 개요
디자인 핸드오프(`design_handoff_tuk_presence`) 기반. 로그인 이후 홈을 프레즌스 홈으로 교체.
내 콜 on/off + 지금 한가한 친구 목록 + 콜 켜기 시트 + 친구 미리보기 + STOMP 실시간.

### 2. 개발 방식
- 디자인 주도(토큰·컴포넌트는 로그인과 동일 재사용), 검토 게이트, 기능별 서브커밋(프레즌스(1)/(2)).

### 3. 구현 내용
| 파일 | 내용 |
|---|---|
| `widgets/presence.dart` | NowCallCard(켜짐/꺼짐/방금켠 강조)·FriendPresenceCard·ActivityChip·CallToggle + 만료/남은시간 문구 |
| `viewmodels/presence_view_model.dart` | 내콜·한가한친구·친구수, 로컬 카운트다운(만료시각 앵커·1분 tick), 정렬(여유 많은 순), 실시간 add/remove, turnOn/turnOff(낙관적), **STOMP 연결 lifecycle 소유** |
| `views/home_screen.dart` | 친구 0명→콜드스타트 / 있음→프레즌스 홈. 9a 콜켜짐·9b 콜꺼짐+유도배너·9c 0명. 하단 CTA 툭띄우기/지금콜켜기. 새 친구 등장 애니메이션 |
| `views/call_on_sheet.dart` | 활동 7칩 + 시간 프리셋(1/2/4/직접 휠피커) + "{시간} 동안 콜 켜기" + 안심문구 |
| `views/friend_preview_sheet.dart` | 프로필 + 던지기 CTA. 연 시점 정보 기억, 온/오프라인만 실시간 판정 |
| `main.dart` | PresenceViewModel 제공 + auth 상태→presence start/stop. 로그인 착지점=HomeScreen |

프레즌스/친구 배관(presence·friend repo, stomp_service, presence·friend·activity·realtime_event 모델) 추적 시작.

### 4. 핵심 결정 (왜)
| 결정 | 이유 |
|---|---|
| STOMP 연결을 PresenceViewModel 이 소유 | 로그인에서 뗀 실시간을 첫 소비자인 프레즌스가 관리. main 에서 auth 상태로 start/stop |
| 로컬 카운트다운(만료시각 앵커) | 서버 재폴링 없이 남은시간 표시. 1분 tick 은 문구만 갱신, 리스트 재정렬 안 함(오탭 방지) |
| 정렬 = 여유 많은 순 | 곧 꺼질 친구를 위에 두면 초읽기 압박. 무부담 원칙 |
| 친구 카드 등장 애니메이션에 AnimatedList 대신 userId 키 래퍼 | AnimatedList 는 기존 항목을 리빌드 안 해 1분 카운트다운 텍스트가 멈춤 → 키 래퍼로 신규만 애니메이션, 기존은 상태 유지+텍스트 갱신 |
| 남은시간 10분 미만 "곧 꺼져요" | 초읽기 대신. 남은시간 빨강 강조 안 함 |

### 5. 검증
에뮬 실검증(alice 로그인, 친구 bob): 9b(콜꺼짐+친구)→9d 시트(카페+1시간)→9a(콜켜짐, 만료문구·CTA전환·토스트). bob 콜 REST on/off로 **STOMP 실시간 등장/사라짐**(→9c 빈 상태)·**미리보기 시트 오프라인 전환**(CTA 비활성) 확인.

### 6. Git
```
4cd43dd  프레즌스(1): 홈(9a/9b/9c) + 콜 켜기 시트(9d)
7b87e30  프레즌스(2): 친구 미리보기 시트(9e) + 실시간 등장/사라짐
```

### 7. 의도적 미연결 (다음 기능으로)
| 항목 | 어디서 |
|---|---|
| "툭 띄우기" / 친구에게·모두에게 던지기 | 번개 기능(#5) — 지금은 토스트/파라미터 자리 |
| 프로필 아바타 실제 정보 | 백엔드 `GET /users/me` |
| 콜드스타트의 "지금 콜" 토글 | 아직 로컬 상태(친구 0명 화면). 프레즌스와 통일은 후속 |

### 8. 다음
친구 기능(#4, 초대코드) 또는 번개 기능(#5). 디자인 핸드오프 나오면 그 기준으로.

### 부수 작업
백엔드 반복 문제 해결: `application.yml` 기본 활성 프로필을 `dev`로(`spring.profiles.active: ${SPRING_PROFILES_ACTIVE:dev}`) — IntelliJ/gradle 어느 쪽으로 켜도 dev 로그인 동작. 운영은 env 로 override(백엔드 CLAUDE.md 체크리스트에 기록).

---

## 친구 (초대코드 · 받은 신청 · 친구 목록) — 2026-08-13

### 1. 개요
`design_handoff_tuk_friends` 기반. **초대코드 교환으로만** 절친을 추가(전체검색·연락처 없음). 받은 신청은 수락만(거절 안 보임).

### 2. 개발 방식
디자인 주도(토큰·컴포넌트 재사용). 한 흐름으로 만들어 통째로 검증 → **단일 커밋**(로그인·프레즌스와 달리 중간 체크포인트 없이).

### 3. 구현 내용
| 파일 | 내용 |
|---|---|
| `viewmodels/friend_view_model.dart` | friends/requests/inviteCode, load, accept(낙관적·상대이름 반환), redeem(결과 분류) |
| `views/friends_screen.dart` (10a/10b) | 받은 신청(수락만)+안심문구, 내 절친(가나다), 빈 상태, 친구 추가 CTA, ⋯ 로그아웃 |
| `views/friend_add_sheet.dart` (10c/10d) | 선택→내 코드(monospace 블록+복사+공유)/코드 입력(8자 커스텀 필드) + 결과 토스트. 같은 시트 크로스페이드 전환 |
| `widgets/avatar.dart` | 재사용 이니셜 아바타 |
| `main.dart`·`home_screen`·`home_coldstart_screen` | FriendViewModel 제공+로그인 시 load. 홈 아바타→친구 화면+신청 배지. 콜드스타트 버튼 배선 |

### 4. 핵심 결정 (왜)
| 결정 | 이유 |
|---|---|
| 초대코드만, 검색 UI 없음 | "닫힌 절친" 원칙 + 백엔드에 검색 API 없음 |
| 거절 버튼·보낸 신청 목록·읽음 없음 | "거절 안 보임" — 무시가 상대에게 전달되지 않는 게 핵심 |
| 하단 탭 대신 홈 아바타 진입 | 목적지 2개뿐, 친구는 저빈도. 아바타에 신청 배지 |
| redeem 결과를 enum 으로 분류 | accepted/pending 은 시트 닫기, 나머지는 유지+토스트(빨강·다이얼로그 없이) |
| 코드 입력은 8칸 분할 대신 단일 TextField | 붙여넣기·IME 안정. 자동 대문자+영숫자만+8자 제한 |
| `share_plus` 추가 | 내 코드 시스템 공유 |

### 5. 검증
에뮬 실검증(alice): 홈 아바타 신청 배지 1 → 친구 화면 10a. carol 수락(→내 절친, 토스트). 내 코드(HJFT846T) 표시. dave 코드 입력→PENDING 토스트("신청을 보냈어요"). 보낸 신청 목록 안 생김 확인.

### 6. Git
```
8834178  친구: 초대코드 기반 친구 기능 (10a~10e)
```

### 7. 의도적 미연결
프로필 아바타 실제 정보 → `GET /users/me`. 새 신청 실시간 배지(FCM 푸시)는 미연결 — 지금은 화면 로드/새로고침 시 갱신.

### 8. 다음
번개 기능(#5) — "툭 띄우기"·친구/모두에게 던지기·받은 번개·모임방. 디자인 핸드오프 나오면 그 기준으로.
