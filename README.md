# bungae-app

번개(bungae) — 친한 친구끼리 **"지금 볼래?"를 거절 걱정 없이** 띄우는 즉흥 만남 앱 (Flutter).

- **상태관리**: Provider + MVVM
- **백엔드**: Spring Boot (별도 레포). API 계약서 기반으로 연동.
- **에뮬레이터 → 백엔드**: Android `http://10.0.2.2:8080`, iOS `http://localhost:8080`, WS `ws://10.0.2.2:8080/ws`

## 실행

```bash
flutter pub get
flutter run
```

## 진행 방식

기능별로 하나씩 리뷰 → 커밋 → 푸시한다.

1. **기초 세팅** ← 현재 — scaffold, 의존성, `core/`(config·theme)
2. 로그인/인증
3. 홈/프레즌스 (실시간)
4. 친구/초대코드
5. 번개/모임방 (실시간)

## 구조 (`lib/`)

- `core/` — 앱 설정(`config.dart`), 테마(`theme.dart`)
- 이후 추가: `models / services / repositories / viewmodels / views / widgets`
