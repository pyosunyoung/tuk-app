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
- ~~한 번 관측된 미해결 이슈(아바타가 `나`로 남음)~~ → **원인 규명·수정됨**(아래 실기기 항목).
  세션 문제가 아니라 `home_coldstart_screen` 의 아바타를 안 고친 것이었다.
  (`/users/me` 실패 시 `debugPrint` 는 그대로 둔다 — 있으면 다음에 빨리 잡는다)

### 8. 다음
카카오톡 앱 로그인 실기기 검증, 배포 전 체크리스트(Flyway·CORS·Swagger 차단).

---

## 카카오톡 앱 로그인 실기기 검증 — 2026-09-01

### 1. 개요
그동안 미검증으로 남아 있던 **카카오톡 앱 로그인 경로**를 실기기(갤럭시 S25, Android 16)에서 확인.
에뮬레이터엔 카카오톡이 없어 계정(웹) 경로만 탈 수 있었다.

### 2. 개발 방식
USB 연결 + `adb reverse tcp:8080 tcp:8080` 으로 폰의 `localhost:8080` 을 개발 PC 백엔드에 연결.
LAN IP·방화벽을 건드리지 않아도 되고, 폰이 어느 망에 있든 된다.

### 3. 구현 내용
| 파일 | 내용 |
|---|---|
| `core/config.dart` | `API_HOST` dart-define 오버라이드. 실기기는 `10.0.2.2`(에뮬 전용 별칭)에 못 닿는다 |
| `views/home_coldstart_screen.dart` | 아바타 하드코딩 `나` → 내 닉네임/프로필 (홈과 동일. `/users/me` 때 빠뜨린 화면) |

실행: `flutter run -d <기기> --dart-define=API_HOST=localhost`

### 4. 핵심 결정 (왜)
| 결정 | 이유 |
|---|---|
| LAN IP 대신 `adb reverse` | 방화벽 인바운드 규칙·같은 Wi-Fi 조건이 필요 없다. USB 하나로 끝 |
| `API_HOST` 는 dart-define | 기본값(에뮬 10.0.2.2)은 그대로 두고 필요할 때만 덮는다. 커밋되는 기본 동작 변화 없음 |

### 5. 검증
- **카카오톡 앱 로그인 성공** — 버튼 탭 → `com.kakao.sdk.flutter.auth.TalkAuthCodeActivity` (카톡 경로) →
  이미 동의한 계정이라 동의 화면 없이 즉시 앱 복귀 → 홈 진입
- **프로필 이미지 첫 확인** — 실제 카카오 프로필 사진이 아바타에 렌더됨
  (에뮬 dev 계정은 `profileImage` 가 null 이라 여태 이니셜 경로만 봤다)
- 콜드스타트 아바타 수정 전/후를 같은 기기에서 비교(`나` → 프로필 사진)

### 6. Git
```
a8b96ee  실기기: 카카오톡 앱 로그인 검증 + 콜드스타트 아바타 수정
```

### 7. 의도적 미연결 / 한계
- iOS 실기기는 Mac + Xcode 가 필요해 이 환경(Windows)에서 불가
- 카카오 **재동의 화면**(신규 계정이 처음 로그인할 때)은 이번에 안 지나감 — 이미 동의된 계정이었다

### 8. 다음
배포 전 체크리스트(Flyway·CORS·Swagger 차단), FCM 실키 연동.

---

## FCM 푸시 알림 — 2026-09-03

### 1. 개요
**앱이 꺼져 있으면 번개가 와도 몰랐다.** "지금 볼래?"를 띄우는 앱인데 실시간 알림이 없으면
제품이 반쪽이라, 배포보다 먼저 닫았다. 배포처 결정과 독립적인 작업이기도 하다.

### 2. 개발 방식
백엔드는 이미 준비돼 있었다(`PushSender` 인터페이스 + `FcmPushSender`, `fcm.enabled` 토글).
그래서 앱 쪽 배선이 전부. Firebase 프로젝트는 무료고, 푸시는 `서버 → FCM → 기기` 경로라
**우리 서버가 공개 URL 이 아니어도 검증된다** — `adb reverse` 로 로컬 서버를 쓰면서 실기기로 확인.

### 3. 구현 내용
| 파일 | 내용 |
|---|---|
| `services/push_service.dart` | 권한 → 토큰 → 서버 등록 → 갱신·포그라운드 표시·탭 라우팅 |
| `main.dart` | Firebase 초기화, 로그인 시 등록 / 로그아웃 시 해제, 알림 탭 네비게이션 |
| `AndroidManifest` | `POST_NOTIFICATIONS`(Android 13+), 기본 알림 채널 `tuk_flash` |
| `android/app/build.gradle.kts` | google-services 플러그인, **desugaring**(flutter_local_notifications 요구) |
| 백엔드 `FcmPushSender` | **실패를 로그로 드러내기**(§5 참고) |
| 백엔드 `.gitignore` | 서비스 계정 키 커밋 차단 |

### 4. 핵심 결정 (왜)
| 결정 | 이유 |
|---|---|
| 기기토큰은 **로그인 후** 등록, 로그아웃 시 해제 | 안 그러면 로그아웃한 기기로 남의 번개 알림이 간다 |
| 포그라운드는 직접 알림 표시 | 앱이 떠 있으면 시스템이 안 띄워준다 |
| 푸시 초기화 실패를 삼킴(로그만) | 권한을 거절해도 앱은 그대로 쓸 수 있어야 한다(앱 안 배너는 STOMP) |
| 기본 채널 `tuk_flash` 지정 | 안 하면 '기타(Miscellaneous)' 채널로 떠서 사용자가 끄기 쉽다 |
| `google-services.json` 커밋 | 배포 APK 에 어차피 들어가는 값(Firebase 공식 입장). 없으면 빌드 불가 |
| 서비스 계정 키는 gitignore | 이건 진짜 비밀 — 유출되면 남이 툭 이름으로 푸시를 보낼 수 있다 |

### 5. 검증 (그리고 삽질)
**최종 결과**: 앱 백그라운드 상태에서 alice 가 번개 발송 → `dev-alice_dev님의 번개 / soju?`
알림 도착(`channel=tuk_flash`, importance=HIGH) → 탭 → 받은 번개 화면 이동.

가는 길에 세 번 헛짚었고, 셋 다 기록해 둘 가치가 있다:
1. **`adb shell am force-stop` 한 앱에는 FCM 이 전달되지 않는다**(안드로이드 stopped state).
   테스트 방법이 틀렸던 것. 실제 사용자의 "앱 종료"(스와이프)는 stopped state 가 아니라 푸시가 온다.
2. **서버가 죽은 WebSocket 을 온라인으로 착각**해 푸시를 아예 안 보냈다. → §7
3. 서버는 정상 발송했는데 **로그가 없어** 원인을 못 봤다. `FcmPushSender` 가 죽은 토큰 외의
   실패를 조용히 버리고 성공도 안 남겼다. 그래서 로그부터 넣고 다시 봤다.

### 6. Git
```
7b2f7d7  FCM: 푸시 알림 연동
```
백엔드(tuk-server): `4b39068  fix: FCM 발송 실패를 로그로 드러내기`

### 7. 의도적 미연결 / 한계
- ~~연결이 비정상 종료되면 푸시가 안 간다(실기기에서 재현됨)~~ → **오진이었다. 아래 항목으로 정정.**
- iOS 는 APNs 키 + Mac 이 필요해 미적용
- 앱 런처 아이콘이 아직 Flutter 기본 로고 — 알림에도 그 아이콘이 나온다(배포 전 교체 필요)

### 8. 다음
STOMP heartbeat(위 §7), 앱 아이콘 교체, 배포처 결정 후 배포.

---

## 알림 배너 · 앱 아이콘 · heartbeat (그리고 오진 정정) — 2026-09-06

### 1. 개요
FCM 이 붙은 뒤 드러난 세 가지를 정리했다. 그리고 **앞 항목에서 "서버가 죽은 세션을 온라인으로
착각해 푸시가 안 간다"고 단정했던 진단을 철회한다** — 로그를 붙여 보니 사실이 아니었다.

### 2. 구현 내용
| 대상 | 내용 |
|---|---|
| 백엔드 `FcmPushSender` | `AndroidConfig.Priority.HIGH` + 채널/우선순위/소리·진동 명시 |
| 앱 아이콘 | 공식 로고 파일(`assets/icon/`)로 런처 아이콘 생성(flutter_launcher_icons), 적응형 아이콘 배경=코랄 |
| 백엔드 `WebSocketConfig` | STOMP heartbeat 10초 + 전용 TaskScheduler |
| 백엔드 로그 | `WebSocketSessionRegistry` 연결/해제, `FlashPushListener` 온·오프라인 분기 |

### 3. 핵심 결정 (왜)
| 결정 | 이유 |
|---|---|
| 푸시를 HIGH 우선순위로 | 안드로이드는 우선순위가 낮으면 **배너를 생략**하고 서랍에만 쌓는다. 번개는 서랍을 내려봐야 아는 알림이면 의미가 없다 |
| 적응형 아이콘 전경은 62% 로 축소 | 안드로이드가 바깥 33% 를 잘라낸다. 배경을 코랄로 깔면 타일 경계가 사라져 글리프만 남는다 |
| heartbeat 유지 | 관측된 버그를 고친 건 아니지만(§4), TCP half-open(모바일 네트워크 유실 등 FIN 이 안 오는 경우)은 heartbeat 말고 감지 수단이 없다 |
| 세션·라우팅 로그 추가 | 이번 오진의 근본 원인이 "보이지 않음"이었다 |

### 4. 오진 정정 (중요)
앞 항목에서 "클라이언트가 비정상 종료되면 서버가 온라인으로 오판해 푸시를 건너뛴다"고 적었다.
로그를 붙여 확인하니 **세션 해제는 `am kill` 후 2초 만에 정상 감지**되고 있었다.

그때 푸시가 안 온 진짜 이유는 셋이었다:
1. `am force-stop` 한 앱에는 안드로이드가 FCM 을 전달하지 않는다(stopped state) — 테스트 방법 문제
2. **앱을 재설치하면 기기토큰이 무효해진다.** FCM 이 UNREGISTERED 를 주고 서버가 토큰을 지운 뒤라
   푸시 대상이 0명이었다(서버는 올바르게 동작한 것)
3. 서버 로그가 한글이라 내 grep 이 인코딩 때문에 실제 로그를 놓쳤다 — 클래스명으로 grep 해야 했다

덤으로 확인된 것: **로그아웃 → 다른 계정 로그인 시 기기토큰이 새 사용자로 정확히 이관된다**
(bob 토큰 해제 → 카카오 계정으로 재등록). 의도한 동작이 실제로 그렇게 돌고 있었다.

### 5. 검증
- 배너: 홈 화면 위에 알림 팝업 표시 확인(이전엔 서랍을 내려야 보였다)
- 아이콘: 앱 서랍·알림 모두 툭 아이콘
- **최종 E2E**: 카카오 실계정 로그인 → 앱 프로세스 종료(`am kill`) → alice 가 번개 발송 →
  `dev-alice_dev님의 번개 / real test` 배너 도착. 서버 로그 `오프라인 1명` → `FCM 발송 성공 count=1`

### 6. Git
```
9dff68e(서버)  feat: STOMP heartbeat + 세션·푸시 라우팅 로그
8fb2dff(서버)  fix: 푸시를 HIGH 우선순위로 — 화면 위 배너가 뜨게
```

### 7. 의도적 미연결 / 한계
- 배너가 카드형이 아니라 알약형인 건 삼성 **알림 팝업 스타일 = 간략히** 설정(앱 무관)
- 알림 전용 흑백 아이콘(small icon)은 따로 안 만들었다 — 삼성은 앱 아이콘을 쓰지만 순정 안드로이드에선 실루엣이 나올 수 있다
- 테스트용으로 `friendships` 에 alice ↔ 카카오계정 행을 직접 넣었다(정리 필요 시 id=311 삭제)

### 8. 다음
배포처 결정 → 배포. (Apple 로그인, iOS 는 맥 필요)

## 운영 배포 (Vultr) + 실기기 E2E — 2026-09-15

### 1. 개요
백엔드를 Vultr 서울 VM(`158.247.230.36`, 2GB)에 Docker Compose 로 올리고, 갤럭시 S25 로 운영 서버에 붙어
카카오 로그인·STOMP 실시간·FCM 푸시까지 끝까지 검증했다. 도메인은 임시로 `tuk.158-247-230-36.sslip.io`.

### 2. 방식
- 서버: Docker 설치 → ufw 22·80·443 → 코드 전송 → `.env`(DB 비번·JWT 시크릿은 **서버에서 생성**, 로컬에 없음) → `docker compose up -d --build`
- 리포가 비공개라 서버에서 clone 하지 않고 `git archive HEAD | ssh ... tar -x` 로 보냈다(서버에 GitHub 자격증명 불필요)
- 앱: `flutter run --dart-define=API_BASE_URL=https://tuk.158-247-230-36.sslip.io`

### 3. 핵심 결정 (왜)
| 결정 | 이유 |
|---|---|
| sslip.io 임시 도메인 | Caddy 의 Let's Encrypt 발급엔 도메인이 필요하다. 구매·가입 없이 오늘 HTTPS 까지 가려고. 진짜 도메인은 `.env` 두 줄 + 앱 재빌드로 교체 |
| `API_HOST` 와 별도로 `API_BASE_URL` 추가 | 운영은 Caddy 가 443 에서 TLS 를 종단해서 `http://host:8080` 고정 형식으론 못 붙는다. 로컬 개발 경로는 그대로 둠 |
| 두 번째 사용자는 DB 에 테스트 유저로 | 카카오 계정이 하나뿐. 수신 측(STOMP·FCM)은 동일하게 검증되고, 끝나고 전부 삭제 |

### 4. 배포하며 잡은 버그 2개
1. **compose YAML 파싱 실패** — `${TUK_DOMAIN:?... (예: tuk.example.com)}` 의 `: ` 가 매핑으로 해석됐다. 개발 PC 에 Docker 가 없어 한 번도 파싱된 적이 없던 파일. 따옴표로 해결.
2. **좀비 세션(중요)** — refresh 전용 Dio 에 `validateStatus` 가 없어 refresh **401 이 예외로 던져졌고**, catch 가 이를
   "네트워크 오류 → 세션 유지"로 처리해 `onSessionExpired` 가 절대 불리지 않았다. 무효 토큰으로 홈에 갇혀 STOMP 만 무한 재시도.
   로컬에선 토큰이 늘 유효해 이 경로가 실행된 적이 없었다. 운영(다른 JWT 시크릿)에 처음 붙는 순간 드러남.
   실사용자라면 refresh 토큰 만료(또는 다른 기기 로그인으로 rotation) 순간 앱이 먹통이 됐을 버그. 5xx 는 세션 유지.

### 5. 검증
- 외부: health 200 / HTTP→HTTPS 308 / Swagger·actuator·dev로그인 401 / 타 오리진 CORS 403 / `/ws` 101 / 8080 외부 차단
- 빈 DB 에 Flyway V1 적용, 이미지 빌드 약 4분·기동 약 40초, 메모리 여유 1.1GB
- 실기기: 옛 토큰 → 랜딩으로 정상 로그아웃 → 카카오톡 로그인(운영 첫 유저 id=1, 프로필 사진) → 기기토큰 등록
- **STOMP**: 앱 포그라운드에서 번개 수신 → 새로고침 없이 2초 내 배너 "받은 번개 1 → 2"
- **FCM**: HOME 으로 백그라운드 → 서버 `WS 해제 (온라인 0명)` → `FCM 발송 성공 count=1` → 서랍에 "테스트친구님의 번개 / 푸시 테스트"

### 6. Git
```
94eb503(서버)  fix: prod compose YAML 파싱 오류 수정 + 배포 기록
1d184e8(앱)    feat: API_BASE_URL 로 배포 서버(HTTPS) 접속 지원
ebcd4d7(앱)    fix: refresh 401 을 네트워크 오류로 오인해 세션 만료가 안 되던 버그
```

### 7. 의도적 미연결 / 한계
- **콜드스타트 화면(친구 0명)의 "지금 콜 켜짐" 토글이 로컬 상태** — 신규 가입자에게 실제론 꺼져 있는데 켜진 것처럼 보인다. 서버 상태와 맞춰야 함
- 친구 관계가 생겨도 콜드스타트 화면이 자동 갱신되지 않는다(앱 재시작 필요) — 코드를 입력한 쪽이 특히
- 콜드스타트 화면엔 받은번개 배너가 없다(친구가 생기면 홈으로 가므로 실사용 영향은 작음)
- 보내는 쪽 UI(초대코드·번개 발송)는 운영에서 미검증 — 실사용 때 두 번째 사람과 확인
- 재배포 절차: 로컬 `git archive HEAD | ssh root@158.247.230.36 'tar -x -C /opt/tuk-server'` → 서버에서 `docker compose -f docker-compose.prod.yml up -d --build`

### 8. 다음
콜드스타트 콜 토글 서버 연동 → P1 지도 링크 · P2 카톡 공유 버튼 → 진짜 도메인·릴리스 APK 로 실사용 시작.
