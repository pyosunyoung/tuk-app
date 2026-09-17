import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// 바텀시트 컨테이너의 하단 여백.
///
/// 안드로이드 edge-to-edge 에서는 앱이 시스템 내비게이션 바 뒤까지 그려져서,
/// 고정 여백(40)만 두면 시트 마지막 줄이 내비게이션 바에 가린다(갤럭시 S25 실기기에서 확인).
///
/// - 인셋이 없는 기기: 디자인 여백 40 그대로
/// - 내비게이션 바/홈 인디케이터가 있으면: 그 높이 + 24
/// - `paddingOf` 는 키보드에 가려진 만큼을 이미 빼준다 → 키보드가 올라온 시트(장소·코드 입력)는
///   키보드 위에 불필요한 빈칸이 생기지 않는다 (`viewPaddingOf` 를 쓰면 생긴다)
double sheetBottomPadding(BuildContext context) =>
    math.max(40, 24 + MediaQuery.paddingOf(context).bottom);
