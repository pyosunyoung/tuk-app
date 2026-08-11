/// 공유 enum — Activity. 백엔드와 문자열 값 1:1 일치.
enum Activity {
  meal('MEAL', '밥', '🍚'),
  drink('DRINK', '술', '🍺'),
  cafe('CAFE', '카페', '☕'),
  walk('WALK', '산책', '🚶'),
  movie('MOVIE', '영화', '🎬'),
  karaoke('KARAOKE', '노래방', '🎤'),
  anything('ANYTHING', '아무거나', '✨');

  const Activity(this.wire, this.label, this.emoji);

  /// 서버로 보내는 문자열 값 (예: "MEAL")
  final String wire;

  /// 화면 표시용 한글 라벨
  final String label;
  final String emoji;

  static Activity fromWire(String? value) {
    return Activity.values.firstWhere(
      (a) => a.wire == value,
      orElse: () => Activity.anything,
    );
  }
}
