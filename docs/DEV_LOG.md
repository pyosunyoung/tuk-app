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
