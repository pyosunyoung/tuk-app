# 툭 (Tuk) Android 앱

친한 친구끼리 거절 부담 없이 "지금 볼래?"를 던지는 즉흥 만남 앱입니다.
지금 한가한 친구만 보여 주고, 한 번의 탭으로 부르며, 응답하지 않아도 상대에게 아무것도 표시되지 않습니다.

기획, Flutter 앱, Spring Boot 서버, 인프라 운영까지 1인으로 개발했습니다. 운영 서버에 배포한 뒤 지인과 직접 사용하며 받은 의견을 반영해 1.0.1까지 배포했습니다.

<table>
<tr><td align="center" valign="top"><img src="docs/images/real/s_home_received.jpg" width="175"><br>툭을 받은 홈</td><td align="center" valign="top"><img src="docs/images/real/compose.jpg" width="175"><br>툭 던지기</td><td align="center" valign="top"><img src="docs/images/real/room.jpg" width="175"><br>모임방</td><td align="center" valign="top"><img src="docs/images/real/s_presence_home.jpg" width="175"><br>지금 한가한 친구</td></tr>
</table>

- **역할**: 1인 개발 (기획, 앱, 서버, 인프라)
- **기간**: 2026년 7월부터 개발, 9월 운영 서버 배포, 10월 릴리스 APK 배포
- **배포**: 운영 서버 상시 가동, 서명된 릴리스 APK 직접 배포 (Google Play 미출시)
- **스택**: Flutter, Provider + MVVM, dio, STOMP, FCM, Crashlytics, 카카오 SDK
- **테스트**: 앱 61개, 서버 149개, push마다 GitHub Actions CI 실행
- **서버 리포**: [pyosunyoung/tuk-server](https://github.com/pyosunyoung/tuk-server)
- **프로젝트 전체 정리**: [docs/OVERVIEW.md](docs/OVERVIEW.md)

## 실사용 검증

2026년 10월 22일부터 25일까지 지인 3명과 실제 폰 4대로 운영 서버에 접속해 사용했습니다.

| 참여 | 던진 툭 | 합류 | 툭 수신 후 합류까지 | 서버 에러 로그 | 의견 메일 |
|:---:|:---:|:---:|:---:|:---:|:---:|
| 4명 | 9건 | 12건 | 평균 1~2분 | 0건 | 3통 |

운영 DB와 서버 로그에서 집계한 값입니다. 테스트 목적으로 사용한 기록이므로 합류 시간은 일상 사용 지표가 아니라 알림 전달을 확인하는 값으로 봐 주세요.
캡처에 나오는 다른 사람의 이름, 프로필 사진, 초대 코드는 가렸습니다.

### 상대 폰 잠금화면에 도착한 알림

<table>
<tr><td><img src="docs/images/real/n_friend_request.jpg" width="370"></td><td><img src="docs/images/real/n_friend_accepted.jpg" width="370"></td></tr>
<tr><td><img src="docs/images/real/n_flash.jpg" width="370"></td><td><img src="docs/images/real/n_joined.jpg" width="370"></td></tr>
<tr><td><img src="docs/images/real/n_time.jpg" width="370"></td><td><img src="docs/images/real/n_place.jpg" width="370"></td></tr>
</table>

### 사용자 의견을 반영한 1.0.1 배포

"의견 보내기" 기능으로 받은 메일에는 앱 버전과 기기 정보가 자동으로 포함됩니다. 받은 내용을 검토해 2건을 수정했고, 기능 요청은 제품 원칙에 맞춰 판단했습니다.

<table>
<tr><td align="center" valign="top"><img src="docs/images/real/feedback_dad.jpg" width="250"><br>받은 의견 메일</td>
<td align="center" valign="top"><img src="docs/images/real/dots_row_before.jpg" width="250"><br>수정 전 (1.0.0)<br><br><img src="docs/images/real/dots_row_after.jpg" width="250"><br>수정 후 (1.0.1)</td>
<td align="center" valign="top"><img src="docs/images/real/update_notice.jpg" width="210"><br>1.0.0 사용자에게 표시된 안내</td></tr>
</table>

| 의견 | 원인 | 조치 |
|---|---|---|
| 친구 끊기 즉시 반영 안 됨 | 끊긴 쪽에 신호 없음 | 서버 갱신 신호, 앱 재조회 |
| ⋯ 버튼이 희미함 | 아이콘이 테두리와 같은 색 | 보조 글자색, 터치 영역 44px |
| 모임 내보내기 요청 | 내보내면 거절이 드러남 | 제품 원칙에 따라 제외 |
| 모임 취소 요청 | 아직 없는 기능 | 검토 중 |

수정본은 단톡방에 APK를 공유한 뒤 서버의 [`app-version.json`](https://github.com/pyosunyoung/tuk-server/blob/main/public/app-version.json)을 갱신해 배포했습니다. 1.0.0 사용자는 다음 실행 때 업데이트 안내를 한 번 받습니다.

## 핵심 구현

### 1. 동시 401과 토큰 재발급 (single-flight)

- **문제**: 앱을 켜면 목록 API를 동시에 호출합니다. access 토큰이 만료된 상태면 401이 동시에 발생하고, 각 요청이 따로 refresh하면 서버의 재사용 탐지에 걸려 정상 사용자의 세션이 파기됩니다.
- **해결**: 진행 중인 refresh를 하나의 Future로 공유하고, 완료 후 각 요청을 한 번씩 재시도합니다. 실시간 연결(STOMP)의 토큰 갱신도 같은 경로를 사용합니다.
- **검증**: 서버와 같은 규칙으로 토큰을 교체하는 가짜 서버로 테스트합니다. 동시 401 3건에 refresh는 1회만 호출됩니다. 공유 코드를 제거하면 3건 중 2건이 401로 실패하는 것까지 확인했습니다.

```dart
Future<bool> _ensureRefreshed() {
  return _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);
}
```

코드: [api_client.dart](lib/services/api_client.dart), [api_client_refresh_test.dart](test/api_client_refresh_test.dart)

### 2. 앱 생명주기에 맞춘 실시간 연결

- **문제**: 앱을 백그라운드로 내려도 STOMP 연결이 유지되어 서버가 접속 중으로 판단하고 FCM을 보내지 않았습니다. 화면에 없는 앱은 알림을 표시할 수 없어 알림이 유실됐습니다. 서버 라우팅 로그로 원인을 확인했습니다.
- **해결**: `paused`에서 연결을 끊고 `resumed`에서 다시 연결한 뒤 변경 내용을 재조회합니다. 알림창을 내릴 때 발생하는 `inactive`에서는 끊지 않습니다.
- **검증**: 실기기에서 홈 토스트, 모임방 즉시 반영, 백그라운드 FCM 배너, 배너 탭 이동까지 4개 경로를 확인했습니다.

코드: [main.dart](lib/main.dart), [stomp_service.dart](lib/services/stomp_service.dart)

### 3. 스토어 없는 배포를 위한 기능

Google Play를 거치지 않으면 스토어가 제공하던 기능이 없습니다. 필요한 기능을 직접 구현했습니다.

- **업데이트 안내**: 앱 실행 시 서버의 버전 파일을 확인합니다. 같은 버전은 한 번만 안내하고, `minBuild`보다 낮으면 매번 안내합니다. 판단 로직은 순수 함수로 분리해 테스트합니다. ([update_checker.dart](lib/services/update_checker.dart))
- **오류 수집**: Firebase Crashlytics로 화면 오류와 비동기 오류를 수집합니다. 개발 빌드는 제외합니다.
- **사용자 의견**: 메일 앱에 앱 버전과 기기 정보를 미리 채웁니다.
- **릴리스 검증**: 별도 키로 서명하고 카카오 콘솔에 키 해시를 등록했습니다. SDK가 릴리스 빌드에서만 깨지는 경우가 있어 R8 축소 빌드를 운영 서버에 연결해 확인했습니다.

### 4. 서버가 내려준 값을 화면의 기준으로 사용

- **문제**: 모임을 언제까지 보여 줄지 앱과 서버가 각각 계산하면서 "서버에는 있는데 화면에서 사라지는" 버그가 반복됐습니다.
- **해결**: 규칙을 서버로 옮기고 앱은 응답의 `visibleUntil`만 따릅니다. 필드가 없는 응답도 처리해 하위 호환을 유지합니다.
- **같은 원칙**: 친구 0명 화면의 토글이 화면 내부 값이라 서버와 달랐던 문제도 서버 값을 읽도록 수정했습니다.

### 5. 사용자에게 보이는 품질

- **한글 줄바꿈**: Flutter는 한글을 글자 단위로 줄바꿈합니다. 단어 사이에서만 줄이 바뀌도록 `keepWords()`를 만들어 앱의 모든 `Text` 184곳에 일괄 적용했습니다. ([keep_words.dart](lib/core/keep_words.dart))
- **오류 문구**: 네트워크 오류를 `ApiClient` 한 곳에서 사용자 문구로 변환합니다. 모든 오류 유형에 대해 개발자 용어가 노출되지 않는지 테스트합니다.
- **알림 이동**: 알림을 눌렀을 때 같은 화면이 겹쳐 쌓이지 않도록 화면이 스스로 열림 상태를 등록합니다. ([open_routes.dart](lib/core/open_routes.dart))
- **되돌리기 어려운 동작**: 탈퇴와 친구 끊기는 서버 처리가 끝난 뒤 화면에 반영합니다.

## 제품 판단: 만들지 않은 기능

- **거절 버튼**: 응답하지 않으면 상대에게 아무것도 표시되지 않습니다.
- **앱 내 채팅**: 이미 쓰는 카카오톡으로 연결하고 모임 카드를 공유합니다.
- **길찾기**: 카카오맵과 네이버 지도 앱으로 연결합니다.
- **재촉 알림**: 약속을 정하지 않아도 알림을 보내지 않습니다. 앱에 빨간색도 쓰지 않습니다.
- **친구 검색**: 초대 코드로만 친구가 되어 닫힌 그룹을 유지합니다.

## 화면

<table>
<tr><td align="center" valign="top"><img src="docs/images/real/s_landing.jpg" width="175"><br>랜딩</td><td align="center" valign="top"><img src="docs/images/real/s_intro.jpg" width="175"><br>인트로</td><td align="center" valign="top"><img src="docs/images/real/s_code.jpg" width="175"><br>초대 코드 입력</td><td align="center" valign="top"><img src="docs/images/real/s_request.jpg" width="175"><br>친구 신청</td></tr>
<tr><td align="center" valign="top"><img src="docs/images/real/s_friends.jpg" width="175"><br>친구 목록</td><td align="center" valign="top"><img src="docs/images/real/s_presence_on.jpg" width="175"><br>한가함 켜기</td><td align="center" valign="top"><img src="docs/images/real/received.jpg" width="175"><br>받은 툭</td><td align="center" valign="top"><img src="docs/images/real/s_meetups.jpg" width="175"><br>진행 중인 모임</td></tr>
<tr><td align="center" valign="top"><img src="docs/images/real/s_map.jpg" width="175"><br>지도 앱 연동</td><td align="center" valign="top"><img src="docs/images/real/join_closed.jpg" width="175"><br>합류 마감 후 모임방</td><td align="center" valign="top"><img src="docs/images/real/s_invite_card.jpg" width="175"><br>카톡 초대 카드</td><td align="center" valign="top"><img src="docs/images/real/s_share_card.jpg" width="175"><br>카톡 모임 카드</td></tr>
</table>

## 구조

```
lib/
  core/          설정, 디자인 토큰, 지도 링크, open_routes, keep_words
  models/        서버 응답 모델
  services/      api_client, stomp_service, push_service, update_checker, token_storage
  repositories/  API 호출
  viewmodels/    화면 상태와 규칙 (auth, presence, friend, flash)
  views/         화면과 시트
  widgets/       공용 UI
```

Provider + MVVM 구조입니다. 상태는 ViewModel이 소유하고 화면은 표시만 담당합니다.

## 실행

```bash
flutter pub get
flutter run                     # 에뮬레이터, 로컬 서버(10.0.2.2:8080)
flutter test                    # 테스트 61개
flutter build apk --release     # 운영 서버용, android/key.properties로 서명
```

실기기를 로컬 서버에 연결할 때는 USB 터널을 사용합니다.

```bash
adb -s <시리얼> reverse tcp:8080 tcp:8080
flutter run -d <시리얼> --dart-define=API_HOST=localhost
```

카카오 로그인에는 콘솔에 등록된 패키지명(`com.tuk.app`)과 서명 키 해시, FCM에는 `android/app/google-services.json`이 필요합니다.

## 현재 한계와 다음 단계

- **규모**: 지인 대상 소규모 사용 단계로 장기 지표(리텐션 등)는 없습니다.
- **출시**: Google Play 미출시입니다. 사용자가 늘면 Play 내부 테스트로 전환할 계획입니다.
- **iOS**: 코드는 있지만 실기기 검증 전입니다.
- **테스트**: 규칙과 네트워크 계층은 자동 테스트, 화면 흐름은 실기기 수동 검증입니다.

## 문서

- [전체 정리 (OVERVIEW)](docs/OVERVIEW.md)
- [개발 기록 (DEV_LOG)](docs/DEV_LOG.md): 잘못 짚은 진단과 정정 과정까지 기록
- 기간별 기능 정리: [07-30 ~ 08-18](docs/FEATURE_NOTES_2026-07-30_08-18.md), [08-30 ~ 09-10](docs/FEATURE_NOTES_2026-08-30_09-10.md), [09-15 ~ 09-18](docs/FEATURE_NOTES_2026-09-15_09-18.md), [09-22 ~ 09-29](docs/FEATURE_NOTES_2026-09-22_09-29.md), [09-30 ~ 10-07](docs/FEATURE_NOTES_2026-09-30_10-07.md)
