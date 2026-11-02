# 툭 (Tuk) Flutter 앱

> 친한 친구끼리 **거절 걱정 없이 "지금 볼래?"를 던지는** 즉흥 만남 앱
>
> - 백엔드(Spring Boot) 리포: [pyosunyoung/tuk-server](https://github.com/pyosunyoung/tuk-server)
> - 전체 정리(기획, 구조, 부딪힌 문제, 운영, 타임라인): [docs/OVERVIEW.md](docs/OVERVIEW.md)

단톡방에 "오늘 저녁 누구 시간 돼?"를 던지고 읽씹당하는 경험에서 시작했다.
**지금 한가한 친한 친구만 보여 주고, 한 탭으로 부르고, 거절은 아무에게도 보이지 않는다.**

- 릴리스 APK **1.0.1**을 지인에게 카톡으로 직접 배포했고, 서버는 Vultr에서 운영 중이다
- 테스트 **61개**, 기능마다 Android 실기기로 확인했다

## 실사용 기록 (2026-10-22 ~ 10-25)

친구 1명, 부모님과 함께 실제 폰 4대로 운영 서버에 붙여 1주 동안 썼다.
캡처 속 다른 사람의 이름, 프로필 사진, 초대 코드는 가렸다.

| 가입 | 친구 관계 | 던진 툭 | 합류 | 툭 받고 합류까지 | 서버 에러 로그 |
|:---:|:---:|:---:|:---:|:---:|:---:|
| 5 | 4 | 9 | 12 | **평균 1~2분** | **0건** |

### 시작하고 친구 맺기

<table>
<tr><td align="center" valign="top"><img src="docs/images/real/s_landing.jpg" width="220"><br>랜딩</td><td align="center" valign="top"><img src="docs/images/real/s_intro.jpg" width="220"><br>인트로 6컷</td><td align="center" valign="top"><img src="docs/images/real/s_code.jpg" width="220"><br>초대 코드 입력</td></tr>
<tr><td align="center" valign="top"><img src="docs/images/real/s_request.jpg" width="220"><br>친구 신청 받기</td><td align="center" valign="top"><img src="docs/images/real/s_friends.jpg" width="220"><br>친구 목록</td><td align="center" valign="top"><img src="docs/images/real/s_invite_card.jpg" width="220"><br>카톡으로 받은 초대 카드</td></tr>
</table>

검색 기능이 없어서 카톡으로 주고받은 초대 코드로만 친구가 된다.

### 한가함 켜고 툭 던지기

<table>
<tr><td align="center" valign="top"><img src="docs/images/real/s_presence_on.jpg" width="220"><br>한가함 켜기</td><td align="center" valign="top"><img src="docs/images/real/s_presence_home.jpg" width="220"><br>지금 한가한 친구</td><td align="center" valign="top"><img src="docs/images/real/compose.jpg" width="220"><br>툭 던지기</td></tr>
<tr><td align="center" valign="top"><img src="docs/images/real/s_home_received.jpg" width="220"><br>툭이 온 홈</td><td align="center" valign="top"><img src="docs/images/real/received.jpg" width="220"><br>받은 툭</td><td align="center" valign="top"><img src="docs/images/real/room.jpg" width="220"><br>모임방</td></tr>
</table>

### 모인 다음

<table>
<tr><td align="center" valign="top"><img src="docs/images/real/s_map.jpg" width="220"><br>지도 앱으로 넘기기</td><td align="center" valign="top"><img src="docs/images/real/s_meetups.jpg" width="220"><br>진행 중인 모임 여러 개</td><td align="center" valign="top"><img src="docs/images/real/join_closed.jpg" width="220"><br>합류 마감 뒤 모임방</td></tr>
</table>

<p align="center"><img src="docs/images/real/s_share_card.jpg" width="300"><br>카톡방에 올린 모임 공유 카드</p>

합류 받는 시간이 끝나도 약속 시간과 장소는 그대로 바꿀 수 있다. 모임이 언제까지 보이는지는 서버가 정해서 내려준다.

### 실제 잠금화면 알림

친구 신청과 수락, 새 툭, 합류, 약속 시간과 장소 변경이 상대 폰 잠금화면에 이렇게 왔다. 바뀐 경우에는 누가 무엇을 무엇으로 바꿨는지까지 보여 준다.

<table>
<tr><td><img src="docs/images/real/n_friend_request.jpg" width="370"></td><td><img src="docs/images/real/n_friend_accepted.jpg" width="370"></td></tr>
<tr><td><img src="docs/images/real/n_flash.jpg" width="370"></td><td><img src="docs/images/real/n_joined.jpg" width="370"></td></tr>
<tr><td><img src="docs/images/real/n_time.jpg" width="370"></td><td><img src="docs/images/real/n_place.jpg" width="370"></td></tr>
</table>

### 실사용 의견으로 낸 1.0.1 (10-27)

앱의 "의견 보내기"는 앱 버전과 기기 정보를 메일에 자동으로 붙인다. 1주 동안 3통을 받았고 그중 2건을 고쳐 바로 배포했다.

<table>
<tr><td align="center" valign="top"><img src="docs/images/real/feedback_dad.jpg" width="250"><br>받은 의견 메일</td>
<td align="center" valign="top"><img src="docs/images/real/dots_row_before.jpg" width="250"><br>1.0.0<br><img src="docs/images/real/dots_row_after.jpg" width="250"><br>1.0.1</td>
<td align="center" valign="top"><img src="docs/images/real/update_notice.jpg" width="210"><br>1.0.0 사용자에게 뜬 안내</td></tr>
</table>

- **"친구 끊기를 해도 바로 안 지워져요"**: 끊긴 쪽에 알리지 않으려고 아무 신호도 보내지 않았더니, 상대는 앱을 다시 열 때까지 끊은 사람을 계속 봤다. 이제 서버가 커밋이 끝난 뒤 `/user/queue/friends`로 목록 갱신 신호만 보내고, 앱은 토스트나 알림 없이 목록을 다시 불러온다.
- **"⋯ 버튼이 희미해요"**: 아이콘 색이 카드 테두리와 같았다. 보조 글자색으로 바꾸고 누르는 영역을 44px로 늘렸다.
- **배포**: 단톡방에 APK를 올린 뒤 서버의 `app-version.json` 한 줄을 바꿨다. 1.0.0 사용자는 다음 실행 때 안내를 한 번 본다.
- **"모임 쫓아내기" 요청**: 쫓겨난 사람에게 거절이 드러나서 만들지 않았다.

---

## 이 프로젝트에서 봐 주셨으면 하는 것

### 1. 실시간을 두 경로로 받고, 앱 생명주기에 맞춰 끊는다

새 툭, 합류, 장소와 시간 변경, 친구 신청 같은 사건은 **앱이 켜져 있으면 STOMP로, 꺼져 있으면 FCM으로** 온다. 서버가 접속 여부를 보고 나눠 보낸다.

- **앱을 내리면(`paused`) STOMP 연결을 끊는다.** 처음에는 백그라운드에서도 연결이 살아 있어서 서버가 "접속 중"으로 보고 FCM을 보내지 않았다. 새 툭 알림까지 놓칠 수 있던 버그였다. 다시 켜지면(`resumed`) 재연결하고 그사이 바뀐 내용을 다시 불러온다.
- 알림을 누르면 해당 화면으로 간다. 그 화면이 이미 열려 있으면 **새로 쌓지 않고 열린 화면으로 돌아간다.** 화면을 여는 곳이 여러 군데라서, 화면이 스스로 "열려 있음"을 등록하게 했다(`core/open_routes.dart`).
- 앱을 보는 중에 모임방 밖에 있으면 같은 사건을 토스트로 알린다("밥, OO님이 합류했어요").

### 2. 토큰 재발급을 single-flight로 처리한다

앱을 켜면 여러 목록을 **동시에** 요청한다. access 토큰이 만료돼 있으면 401이 동시에 여러 개 오는데, 각 요청이 따로 refresh하면 rotation 규칙 때문에 하나만 성공하고 나머지는 세션이 끊긴다. 그래서 `ApiClient`가 진행 중인 refresh를 하나로 합치고, 끝나면 각 요청을 한 번씩 다시 보낸다.

서버처럼 토큰을 교체하고 옛 토큰에는 401을 주는 가짜 서버로 테스트한다. 합치는 코드를 빼면 동시 요청 3개 중 2개가 401로 실패하는 것까지 확인했다.

### 3. 스토어 없이 배포하는 데 필요한 것을 직접 만들었다

APK를 직접 나눠 주면 스토어가 대신 해 주던 일이 없다.

- **업데이트 알림**: 앱을 켤 때 서버의 `app-version.json`을 읽어 안내한다. 같은 버전은 **한 번만** 알리고, `minBuild`보다 오래된 버전이면 매번 알린다.
- **충돌 보고**: Firebase Crashlytics로 화면 오류와 비동기 오류를 모은다. 개발 빌드는 수집하지 않는다.
- **리뷰와 문의**: "의견 보내기"가 메일 앱에 앱 버전과 기기 정보를 미리 채운다.

릴리스는 별도 키로 서명하고 카카오 콘솔에 키 해시를 추가했다. SDK가 릴리스 빌드에서만 깨지는 경우가 있어서, R8로 줄인 릴리스 빌드를 운영 서버에 붙여 다시 확인했다.

### 4. 한글이 단어 중간에서 끊기지 않게 했다

Flutter는 한글을 글자마다 줄을 바꿀 수 있는 곳으로 본다("알려줄/게요"). 글자 사이에 보이지 않는 문자 U+2060을 넣는 `keepWords()`를 만들어 **앱의 모든 `Text` 184곳**에 적용했다. 👍🏻 같은 조합 이모지는 깨지기 때문에 이모지 옆은 건너뛴다.

### 5. 실패를 어디까지 보여 줄지 정했다

- 카카오 로그인을 **취소**하면 조용히 넘어가고, 실패했을 때만 알린다.
- 오류 문구는 사용자 말투로 쓴다("지금 연결이 안 돼요. 인터넷 연결을 확인해 주세요").
- 탈퇴와 친구 끊기는 **화면에서 먼저 지우지 않는다.** 되돌리기 어려운 동작이라 서버 처리가 끝난 뒤 목록을 바꾼다.
- 빨간색을 쓰지 않는다. 재촉하지 않는 앱인데 경고색은 "빨리 안 하면 큰일 난다"는 느낌을 준다.

---

## 주요 기능

- **시작**: 카카오 로그인, 6컷 인트로, 약관과 개인정보 처리방침
- **한가함**: "지금 한가해요" 켜기(활동과 유지 시간 선택), 한가한 친구 먼저 보기, 시간이 지나면 자동으로 꺼짐
- **툭**: 친구 모두 또는 골라서 던지기(한가한 친구 표시), 예약, 받은 툭, 합류
- **모임방**: 약속 시간, 장소 검색(카카오 로컬 API를 서버가 대신 호출), 카카오맵과 네이버 지도로 열기, 카톡 공유 카드, 장소와 시간 변경 알림
- **친구**: 초대 코드로만 친구 맺기(검색 없음), 신청과 수락 알림, 보낸 신청 취소, 친구 끊기
- **계정**: 의견 보내기, 로그아웃, 탈퇴(카카오 연결 끊기 포함)

## 기술 스택

- **Flutter**, Dart, **Provider + MVVM**
- **dio**(JWT 자동 첨부, refresh single-flight), **stomp_dart_client**, **flutter_secure_storage**
- **firebase_messaging**, **flutter_local_notifications**, **firebase_crashlytics**
- **kakao_flutter_sdk_user**(로그인), **kakao_flutter_sdk_share**(카카오톡 공유), **url_launcher**(지도 앱), **package_info_plus**

## 구조 (`lib/`)

```
core/          설정, 디자인 토큰, 지도 링크, open_routes, keep_words
models/        서버 응답 모델
services/      api_client(dio + refresh), stomp_service, push_service, update_checker, token_storage
repositories/  엔드포인트별 호출
viewmodels/    화면 상태와 규칙 (auth, presence, friend, flash)
views/         화면과 시트
widgets/       공용 UI
```

상태는 **ViewModel이 갖고** 화면은 그리기만 한다. 모임이 언제까지 보이는지 같은 규칙은 앱이 정하지 않고 **서버가 내려준 값(`visibleUntil`)만 따른다.** 앱과 서버가 각자 계산하다가 "서버에는 있는데 화면에서는 사라지는" 버그를 두 번 겪은 뒤 정한 원칙이다.

## 실행

```bash
flutter pub get
flutter run                     # 에뮬레이터에서 로컬 서버(10.0.2.2:8080)로
flutter build apk --release     # 운영 서버용 릴리스, android/key.properties로 서명
```

실기기에서 로컬 서버에 붙일 때는 USB 터널을 쓴다.

```bash
adb -s <시리얼> reverse tcp:8080 tcp:8080
flutter run -d <시리얼> --dart-define=API_HOST=localhost
```

카카오 로그인을 쓰려면 카카오 콘솔에 패키지명(`com.tuk.app`)과 **서명 키의 해시**가 등록돼 있어야 한다. FCM은 `android/app/google-services.json`이 필요하다.

> 개발 빌드에서는 랜딩 로고를 길게 누르면 dev 로그인(아무 문자열)을 쓸 수 있다. 릴리스 빌드에서는 숨겨진다.

## 테스트

```bash
flutter test      # 61개
```

동시 401의 refresh 합치기, 모임 수명 규칙, 지도 링크, 업데이트 안내 판단, keepWords, 약속 시간 후보 등을 테스트한다. 언제 보이고 언제 안내하는지 같은 순수 규칙은 함수로 빼서 테스트하고, 화면 흐름은 실기기로 확인했다.

## 문서

기능 단위 정리본은 **배경, 선정 이유, 구현, 전후 비교(캡처와 수치), 테스트, 남은 과제** 순서로 썼다.

- [07-30 ~ 08-18](docs/FEATURE_NOTES_2026-07-30_08-18.md): 초기 MVP(로그인, 한가함, 친구, 툭)
- [08-30 ~ 09-10](docs/FEATURE_NOTES_2026-08-30_09-10.md): 카카오 로그인, 이름 통일, FCM, 앱 아이콘
- [09-15 ~ 09-18](docs/FEATURE_NOTES_2026-09-15_09-18.md): 운영 배포, CI/CD, 지도 보기, 장소 검색
- [09-22 ~ 09-29](docs/FEATURE_NOTES_2026-09-22_09-29.md): 카톡 공유 카드, 약속 시간, 여러 모임, 모임 수명 규칙, 변경 알림
- [09-30 ~ 10-07](docs/FEATURE_NOTES_2026-09-30_10-07.md): 탈퇴, 친구 끊기, 알림 다듬기, 릴리스 APK, 외부 백업, 모니터링

백엔드 정리본(7월 MVP, 배포 준비)은 서버 리포 `docs/`에 있다. 시간순 개발 기록 [docs/DEV_LOG.md](docs/DEV_LOG.md)에는 잘된 것뿐 아니라 **잘못 짚었던 진단과 그 정정**도 함께 적었다.
