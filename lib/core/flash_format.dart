// 번개 전용 시간 문구. 프레즌스의 "꺼져요"와 달리 번개는 "끝나요".

/// 남은 시간 → "N시간 M분 뒤 끝나요" / "곧 끝나요" / "끝났어요 · 곧 사라져요".
/// 색·강조는 호출부에서(항상 text-sub, 빨강 금지).
String flashExpiryText(DateTime expiresAt) {
  final diff = expiresAt.difference(DateTime.now());
  if (diff.inSeconds <= 0) return '끝났어요 · 곧 사라져요';
  final m = diff.inMinutes;
  if (m < 10) return '곧 끝나요';
  if (m >= 60) {
    final h = m ~/ 60;
    final r = m % 60;
    return r == 0 ? '$h시간 뒤 끝나요' : '$h시간 $r분 뒤 끝나요';
  }
  return '$m분 뒤 끝나요';
}

bool flashEnded(DateTime expiresAt) =>
    !expiresAt.isAfter(DateTime.now());

/// 예약 시각 → "오늘 저녁 8시" / "내일 점심 12시" / "8월 21일 저녁 7시".
String reservedTimeText(DateTime at) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final thatDay = DateTime(at.year, at.month, at.day);
  final dayDiff = thatDay.difference(today).inDays;

  final String dayPrefix;
  if (dayDiff == 0) {
    dayPrefix = '오늘';
  } else if (dayDiff == 1) {
    dayPrefix = '내일';
  } else {
    dayPrefix = '${at.month}월 ${at.day}일';
  }

  final period = _period(at.hour);
  final h12 = ((at.hour + 11) % 12) + 1;
  final time = at.minute == 0 ? '$h12시' : '$h12시 ${at.minute}분';
  return '$dayPrefix $period $time';
}

String _period(int hour24) {
  if (hour24 < 5) return '밤';
  if (hour24 < 11) return '아침';
  if (hour24 < 14) return '점심';
  if (hour24 < 18) return '오후';
  if (hour24 < 23) return '저녁';
  return '밤';
}
