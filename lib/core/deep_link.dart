/// 카카오톡 공유 카드를 눌러 앱이 열릴 때 들어오는 링크.
///
/// 카드의 링크는 `kakao{네이티브앱키}://kakaolink?room=123` 또는 `?invite=HJFT846T` 모양으로 들어온다
/// (카드를 만들 때 넣은 androidExecutionParams / iosExecutionParams 가 쿼리가 된다).
sealed class TukLink {
  const TukLink();

  /// 모르는 링크·잘못된 값이면 null — 앱은 그냥 평소처럼 열린다.
  static TukLink? parse(Uri uri) {
    final q = uri.queryParameters;

    final room = int.tryParse(q['room'] ?? '');
    if (room != null && room > 0) return RoomLink(room);

    final code = (q['invite'] ?? '').trim().toUpperCase();
    if (_inviteCode.hasMatch(code)) return InviteLink(code);

    return null;
  }

  /// 서버의 초대 코드: 8자, 헷갈리는 문자 제외 영숫자. 여유 있게 4~16자 영숫자만 받는다.
  static final _inviteCode = RegExp(r'^[A-Z0-9]{4,16}$');
}

/// 모임방 카드 → 그 모임방
class RoomLink extends TukLink {
  const RoomLink(this.flashId);
  final int flashId;

  @override
  bool operator ==(Object other) => other is RoomLink && other.flashId == flashId;
  @override
  int get hashCode => flashId.hashCode;
}

/// 초대 카드 → 코드가 채워진 친구 추가
class InviteLink extends TukLink {
  const InviteLink(this.code);
  final String code;

  @override
  bool operator ==(Object other) => other is InviteLink && other.code == code;
  @override
  int get hashCode => code.hashCode;
}
