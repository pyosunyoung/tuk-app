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
| 브랜드 "툭" + 코랄 | 핸드오프 확정 (당시 코드·패키지는 `bungae` 유지 → 이후 `tuk`으로 통일) |
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

---

## 번개 (툭 띄우기 · 받은 번개 · 모임방) — 2026-08-18

### 1. 개요
`design_handoff_tuk_flash` 기반. 앱의 핵심 행동. 발송→수신→합류→모임방 + 실시간. **거절 안 보임**이 가장 강하게 적용(합류만·무응답자/응답률 노출 금지, members=보낸사람+합류자만).

### 2. 개발 방식
디자인 주도(토큰·컴포넌트 재사용). 검토 2단계: A(보내는 사람)·B(받는 사람+실시간). 각각 커밋.

### 3. 구현 내용
| 파일 | 내용 |
|---|---|
| `core/flash_format` | '끝나요' 만료 문구 + 예약 시각(오늘/내일/시간대) 포맷 |
| `viewmodels/flash_view_model` | send/room/setPlace/join + 받은/내가띄운 목록·정렬·1분 tick·STOMP(NEW_FLASH/MEMBER_JOINED)·events 스트림 |
| `views/flash_compose_screen` (11a) | 전체화면(아래→위), 활동·한마디(≤200)·대상(절친모두/골라서)·지금/예약·유효시간. prefill(친구/홈CTA) |
| `views/room_screen` (11c) | 정보·장소카드(미설정/설정)·참여자(띄운사람/합류)·빈상태·종료방·다시띄우기·MEMBER_JOINED 실시간 |
| `views/place_sheet` (11e) | placeName 자유입력(지도 밖) |
| `views/received_flashes_screen` (11b) | 미합류/합류 카드·예약배지·합류하기/모임방열기·빈상태 |
| `home_screen` (11d) | 상단 배너 2종(내가띄운·받은, 지금콜 위), 배지=미합류만 |
| 백엔드 | `GET /api/flashes/sent`(SentFlashResponse) 추가 — 내가 띄운 번개 배너 지속 |

### 4. 핵심 결정 (왜)
| 결정 | 이유 |
|---|---|
| 발송은 전체화면, 콜 켜기는 시트 | 입력 5개+키보드. "사람 부르는 행동"과 "가벼운 상태 변경" 위계 구분 |
| recipientCount 0도 방 열림 | 발송 실패 아님. "지금 받을 절친이 없어요 · 방은 열어뒀어요" |
| 서버가 비절친 제외해 수 줄어도 차이 설명 안 함 | 거절 안 보임 |
| 배너 배지=미합류(PENDING)만 | 합류하면 배지에서 빠짐 |
| 백엔드 `GET /sent` 추가 | 앱 재시작 후에도 내가 띄운 번개 배너 유지(발송자는 NEW_FLASH 안 받음) |
| MEMBER_JOINED→reloadSent | 내가 띄운 배너 "N명 모였어요" 실시간 |

### 5. 검증
에뮬 실검증(alice/bob/carol, 실 STOMP): bob→alice 번개 → 홈 받은배너 → 목록 11b → 합류 → 모임방(2명). 합류 후 배지 사라짐(미합류만). alice 발송 + carol 합류(REST) → alice 홈에 **내가 띄운 번개 · 1명 모였어요** 배너 실시간 반영. (만료시각은 에뮬 tz 아티팩트, KST 폰 정확)

### 6. Git
```
8706410  번개(1): 발송(11a) + 모임방(11c) + 장소 시트(11e)
1ddae0b  번개(2): 받은 번개(11b) + 홈 배너(11d) + 실시간
```

### 7. 의도적 미연결 / 한계
members '나' 표시·장소 정한 사람 → `GET /users/me` + 백엔드 응답 확장. flash 만료는 서버 LocalDateTime을 기기 로컬로 해석(KST 폰 정확, 전역은 tz-aware 필요). MEMBER_JOINED 방 밖 토스트·FCM 푸시는 미연결.

### 8. 다음
**앱 MVP 5대 핵심 기능(로그인·프레즌스·친구·번개) 완성.** 남은 것: 카카오 SDK 연동, `GET /users/me`, 폴더 rename(bungae→tuk), 배포 전 체크리스트(Flyway·CORS·Swagger차단 등).

---

## 카카오 로그인 + 이름 통일 (bungae → tuk) — 2026-08-30

### 1. 개요
랜딩의 카카오 버튼을 **진짜 카카오 로그인**으로 배선(그동안 dev 로그인 stub이었음).
겸사겸사 코드·패키지·DB에 남아 있던 코드네임 `bungae` 를 제품명 `tuk` 으로 전부 통일.

### 2. 개발 방식
백엔드는 이미 카카오 토큰 검증(`KakaoClient` → `kapi.kakao.com/v2/user/me`)이 있어 **앱만** 작업.
```
카카오 SDK(앱) → access token → POST /api/auth/login {provider:"kakao", token}
                              → 백엔드가 카카오에 검증 → 우리 JWT 발급
```
이름 통일은 카카오 콘솔에 패키지명을 등록하기 **전에** 해야 두 번 등록하지 않으므로 같은 날 묶어서 진행.

### 3. 구현 내용
| 파일 | 내용 |
|---|---|
| `pubspec.yaml` | `kakao_flutter_sdk_user ^2.0.0+1` |
| `core/config.dart` | `KakaoConfig` — 네이티브 앱 키(`--dart-define` 오버라이드 가능) |
| `services/kakao_auth_service.dart` | SDK 래퍼. 카카오톡 설치 시 톡 로그인, 아니면 카카오계정. 취소=`null`, 실패=`KakaoLoginException` |
| `viewmodels/auth_view_model.dart` | `loginWithKakao()` 추가, 토큰 교환은 `_exchange()`로 추출해 dev 로그인과 공유. 로그아웃 시 카카오 세션도 정리 |
| `views/landing_screen.dart` | 카카오 버튼 배선(취소는 토스트 없음) |
| `views/intro_screen.dart` | 마지막 컷 "카카오로 시작하기"도 같은 배선 (랜딩만 고쳤다가 누락분 발견) |
| `main.dart` | `KakaoSdk.init()` — 키 없으면 건너뛰고 나머지 기능은 정상 동작 |
| `AndroidManifest.xml` | `AuthCodeHandlerActivity` 에 `kakao{앱키}://oauth` 인텐트 필터 |
| `ios/Runner/Info.plist` | `LSApplicationQueriesSchemes`(kakaokompassauth·kakaolink) + `CFBundleURLSchemes` |
| **이름 통일(앱)** | dart 패키지 `bungae`→`tuk`, applicationId·번들ID `com.bungae.bungae`→**`com.tuk.app`**, Kotlin `com/tuk/app/MainActivity.kt`, 런처 라벨·iOS 표시명 "툭", web/README/.iml |
| **이름 통일(백엔드)** | 자바 패키지 `com.bungae`→`com.tuk`(106파일), `TukServerApplication`, gradle group·rootProject, `spring.application.name`, docker-compose, Swagger 타이틀, DB `bungae`→`tuk`(ALTER DATABASE, 데이터 유지) |

### 4. 핵심 결정 (왜)
| 결정 | 이유 |
|---|---|
| v2의 `loginWithKakao(context)` 브릿지 시트 미사용 | 카카오가 그린 바텀시트라 툭 디자인과 안 맞음. `isKakaoTalkInstalled()` → 톡/계정 고전 패턴으로 우리 랜딩 유지 |
| 톡 로그인 실패 시 계정 로그인 폴백 (취소는 폴백 안 함) | 카톡은 깔렸는데 로그인 안 된 상태 등 구제. 사용자가 스스로 나간 건 재시도 강요 X |
| 취소는 토스트 없음 | `error == null` 로 구분. 취소 신호가 3갈래(`ClientErrorCause.cancelled`·`PlatformException('CANCELED')`·`AuthErrorCause.accessDenied`)라 모두 취소로 처리 |
| 로그아웃 시 `UserApi.logout()` 도 호출 | 안 하면 다음 로그인이 계정 선택 없이 통과해 계정 전환 테스트 불가 |
| 네이티브 앱 키를 소스에 둠 | 배포 APK에 어차피 포함되는 값이라 비밀키가 아님. 실제 보호는 콘솔에 등록한 **키 해시(Android)/번들 ID(iOS)** |
| dev 로그인(로고 롱프레스) 유지 | 멀티계정 에뮬 테스트에 계속 필요 |
| 한글 "번개"는 그대로 | 제품명이 아니라 **기능 이름(Flash)**. 바꾼 건 코드네임 `bungae` 뿐 |
| applicationId `com.tuk.app` | `com.tuk.tuk` 보다 읽기 좋고 스토어 선점 위험도 낮음 |

### 5. 검증
- 서버 `./gradlew test` **78개 통과**, 앱 `flutter analyze`(변경분 에러 0)·`flutter test`·`build apk` 성공, APK 패키지명 `com.tuk.app` 확인
- DB rename 후 데이터 유지 확인 (users 13 · friendships 5 · flashes 7)
- **에뮬 E2E**: 카카오 버튼 → (카톡 미설치) 카카오계정 웹 로그인 → 실계정 로그인 → 앱 복귀 → 홈 진입.
  로그로 리다이렉트 확인: `dat=kakaoe0a9…://oauth cmp=com.tuk.app/com.kakao.sdk.flutter.auth.AuthCodeHandlerActivity`.
  DB에서 기존 카카오 유저(id 339, providerId 5004466861) 재매칭 — 중복 생성 없음.
- **인트로 경로**: 로그아웃 → 랜딩 → 둘러보기 → 마지막 컷 "카카오로 시작하기" → 카카오 로그인 화면 진입 확인(dev 로그인 아님)
- **취소 경로**: 커스텀탭 닫기 → 토스트 없이 원래 화면 복귀, 로딩 안 걸림

### 6. Git
```
1c793a1  chore: 프로젝트 이름 bungae → tuk 통일 (com.tuk.app)
a743f7a  카카오 로그인: 네이티브 SDK 연동
```
백엔드(tuk-server): `8038704  chore: 프로젝트 이름 bungae → tuk 통일`

### 7. 의도적 미연결 / 한계
- **카카오톡 앱 로그인 경로는 에뮬에서 검증 불가**(카톡 미설치) — 실기기에서 한 번 확인 필요
- 카카오 버튼 아이콘은 아직 자리표시자(공식 로고 에셋 미적용)
- 카카오 프로필(닉네임·사진)은 최초 가입 시에만 반영 — 재로그인 시 갱신 안 함
- 로컬 폴더명은 아직 `bungae-*` — `C:\Users\A\rename-to-tuk.ps1` 로 별도 진행(IDE·세션 종료 후)

### 8. 다음
`GET /users/me`(모임방 '나' 표시·프로필 아바타), 배포 전 체크리스트(Flyway·CORS·Swagger 차단).

---

## 내 정보 (GET /users/me) — 2026-08-31

### 1. 개요
앱이 **"이게 나"를 판단할 근거**가 없어서 미뤄둔 것들을 닫았다.
홈 프로필 아바타가 하드코딩 '나'였고, 모임방 참여자 목록에서 내가 누군지 표시할 수 없었다.

### 2. 개발 방식
백엔드 먼저(엔드포인트 + 테스트 + 계약서) → 앱에서 소비. `user` 패키지는 그동안 domain/repository만
있고 controller/service 자리가 `.gitkeep`으로 비어 있었는데, 이번에 채웠다.

### 3. 구현 내용
**백엔드** (`tuk-server`)
| 파일 | 내용 |
|---|---|
| `user/dto/MeResponse` | `{ userId, nickname, profileImage }` |
| `user/service/UserService` | `getMe(userId)` — 없으면 404 |
| `user/controller/UserController` | `GET /api/users/me` (`@AuthenticationPrincipal Long userId`) |
| `global/auth/AuthService` | 기본 닉네임 `"번개유저"` → `"툭유저"` (이름 통일 때 놓친 사용자 노출 문자열) |
| `docs/API_FOR_APP.md`·`CLAUDE.md` | 계약서·엔드포인트 목록 갱신 |

**앱** (`tuk-app`)
| 파일 | 내용 |
|---|---|
| `models/me.dart` | `Me` 모델 |
| `repositories/user_repository.dart` | `GET /api/users/me` |
| `viewmodels/auth_view_model.dart` | `me` 보유. 로그인 성공·부트스트랩 후 로드, 로그아웃 시 null |
| `views/home_screen.dart` | 프로필 아바타 하드코딩 '나' → 내 닉네임 이니셜/프로필 이미지 |
| `views/room_screen.dart` | 참여자 목록에서 내 행에 `· 나` 표시 |

### 4. 핵심 결정 (왜)
| 결정 | 이유 |
|---|---|
| `me` 를 AuthViewModel이 소유 | 세션 스코프 정체성이라 로그인/로그아웃 lifecycle과 정확히 일치. 별도 VM을 두면 두 곳에서 비우는 걸 잊기 쉽다 |
| `/users/me` 실패해도 세션 유지 | 네트워크 일시 실패로 로그아웃시키면 과잉. 아바타가 이니셜 '나'로 나올 뿐 |
| 단, 404면 세션 정리 | 토큰은 유효한데 유저가 없다 = 탈퇴/DB 초기화. 계속 두면 이후 요청이 전부 깨진다 |
| 아바타 fallback을 '나'로 유지 | 로드 전 빈 원보다 낫다 |
| `inviteCode`는 응답에 미포함 | 이미 `GET /api/friendships/invite-code` 가 있다. 화면 하나에서만 쓰는 값을 공용 응답에 얹지 않음 |

### 5. 검증
- 백엔드 테스트 **80개 통과**(UserServiceTest 2개 추가). 실서버: `GET /api/users/me` → `{"userId":364,...}`, 무인증 401
- **에뮬 E2E**: dev alice 로그인 → 홈 아바타가 하드코딩 '나' → **'d'**(dev-alice_dev)로 바뀜
- REST로 alice 번개 발송 + bob 합류 → 홈 "내가 띄운 번개 · 1명 모였어요" 배너(STOMP 실시간) → 모임방에서
  **`dev-alice_dev · 나` + '띄운 사람'**, bob은 '합류'만

### 6. Git
```
5c1d3c5  내 정보: GET /users/me 연동 (홈 아바타 · 모임방 '나')
```
백엔드(tuk-server): `9af85ad  feat: 내 정보 조회 (GET /api/users/me)`

### 7. 의도적 미연결 / 한계
- **"장소 정한 사람"은 여전히 못 함** — `/users/me` 만으론 부족하고 백엔드가 모임방 응답에
  `placeSetBy` 같은 필드를 줘야 한다. 별도 작업
- 카카오 프로필(닉네임·사진)은 최초 가입 시에만 반영 — 재로그인해도 갱신 안 함
- `me` 는 세션 중 갱신 없음(프로필 변경 기능이 아직 없어 문제되지 않음)

### 8. 다음
카카오톡 앱 로그인 실기기 검증, 배포 전 체크리스트(Flyway·CORS·Swagger 차단).

---

## 모임방 "장소 정한 사람" — 2026-09-01

### 1. 개요
장소만 보이고 **누가 정했는지** 알 수 없던 것을 닫았다. `/users/me` 때 "백엔드 필드가 필요하다"고
남겨둔 항목.

### 2. 개발 방식
백엔드에 필드 추가 → 응답 확장 → 앱에서 한 줄 문구로. 두 갈래(내가/남이)를 각각 실검증.

### 3. 구현 내용
**백엔드** (`tuk-server`)
| 파일 | 내용 |
|---|---|
| `flash/domain/MeetupRoom` | `@ManyToOne(LAZY) User placeSetBy` + `setPlace(..., User setter)` |
| `flash/dto/MeetupRoomResponse` | `placeSetById`, `placeSetByNickname` 추가 |
| `flash/service/FlashService` | `setPlace` 가 설정자를 함께 기록. 응답의 닉네임은 **members 에서 찾아** 추가 조회 없음 |
| 테스트 | 보낸이가 정한 경우 / 합류자가 정한 경우 / 아무도 안 정한 경우 (3개 추가, 총 82개) |

**앱** (`tuk-app`)
| 파일 | 내용 |
|---|---|
| `models/meetup_room.dart` | `placeSetById`, `placeSetByNickname` |
| `views/room_screen.dart` | 장소 밑 문구: `내가 정했어요` / `OO님이 정했어요` / (모르면) `장소가 정해졌어요` |
| `viewmodels/auth_view_model.dart` | `/users/me` 실패를 조용히 삼키지 않고 `debugPrint` (아래 §7) |

### 4. 핵심 결정 (왜)
| 결정 | 이유 |
|---|---|
| 닉네임을 members 에서 조회 | 장소를 정한 사람은 **항상 멤버**다. 이미 만든 members 리스트에서 찾으면 추가 쿼리 0 |
| `getReferenceById` 로 FK 만 기록 | 설정자 User 를 select 할 이유가 없다(닉네임은 위에서 해결) |
| 마지막에 바꾼 사람으로 덮음 | 장소는 멤버 누구나 다시 정할 수 있다. "처음 정한 사람"을 남기면 현재 상태와 어긋난다 |
| 못 찾으면 `장소가 정해졌어요` | 이 필드가 없던 시절의 방(placeSetBy = null)도 깨지지 않게 |

### 5. 검증
- 백엔드 테스트 **82개 통과**. REST: bob 이 장소 변경 → `placeSetById:365, placeSetByNickname:"dev-bob_dev"`
- **에뮬 E2E**: alice 가 앱에서 장소 설정 → `Cafe / 내가 정했어요` →
  bob 이 REST 로 변경 → 방 재진입 시 `Student Hall / dev-bob_dev님이 정했어요`

### 6. Git
```
eb7a96d  모임방: 장소를 정한 사람 표시
```
백엔드(tuk-server): `4a10440  feat: 모임방 장소를 정한 사람 (placeSetBy)`

### 7. 의도적 미연결 / 한계
- **장소 변경은 실시간 반영 안 됨** — MEMBER_JOINED 같은 이벤트가 없어 방을 다시 열어야 보인다
- **한 번 관측된 미해결 이슈**: 어제 발급된 카카오 세션으로 앱을 켰을 때 홈 아바타가 `나`(fallback)로 남았다.
  = `/users/me` 가 실패했다는 뜻인데, 재시작·재로그인으로 **재현되지 않음**. 원인 미상.
  실패를 삼키던 catch 에 `debugPrint` 를 넣어 다음에 잡을 수 있게만 해뒀다.

### 8. 다음
카카오톡 앱 로그인 실기기 검증, 배포 전 체크리스트(Flyway·CORS·Swagger 차단).
