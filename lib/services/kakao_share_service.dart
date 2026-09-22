import 'package:flutter/foundation.dart';
import 'package:kakao_flutter_sdk_share/kakao_flutter_sdk_share.dart';
import 'package:share_plus/share_plus.dart';

import '../core/config.dart';
import '../models/activity.dart';

/// 카카오톡 공유 카드.
///
/// 채팅을 만들지 않고 대화는 카톡으로 넘긴다 — 그 다리가 이 카드다.
/// 카드의 앱 링크는 받은 사람의 툭을 열고 [TukLink] 로 해석된다(모임방 / 초대 코드).
///
/// 카카오톡이 없거나 카드 전송이 실패하면(콘솔 설정 누락 등) 같은 내용을 글자로 시스템 공유한다 —
/// 공유 자체가 막히지는 않게.
class KakaoShareService {
  const KakaoShareService();

  /// 모임방 → "카톡으로 이야기하기"
  Future<void> shareRoom({
    required int flashId,
    required Activity activity,
    String? placeName,
    String? placeAddress,
    String? kakaoPlaceId,
    DateTime? expiresAt,
  }) {
    final until = expiresAt == null ? null : '${_hhmm(expiresAt)}까지';
    final title = '툭 · ${activity.label} 모임';
    final description = [
      if (placeName != null) '📍 $placeName' else '장소는 아직 안 정했어요',
      ?until,
    ].join('\n');

    final appLink = Link(
      androidExecutionParams: {'room': '$flashId'},
      iosExecutionParams: {'room': '$flashId'},
      mobileWebUrl: ShareConfig.appPage,
      webUrl: ShareConfig.appPage,
    );
    // 검색으로 고른 장소만 지도 버튼 — 카카오 장소 페이지(콘솔에 등록한 place.map.kakao.com)
    final mapUrl = kakaoPlaceId == null ? null : Uri.parse('https://place.map.kakao.com/$kakaoPlaceId');

    final template = FeedTemplate(
      content: _content(title: title, description: description, link: appLink),
      buttons: [
        Button(title: '툭에서 보기', link: appLink),
        if (mapUrl != null) Button(title: '지도 보기', link: Link(webUrl: mapUrl, mobileWebUrl: mapUrl)),
      ],
    );

    final text = [
      title,
      if (placeName != null) '📍 $placeName${placeAddress != null ? ' ($placeAddress)' : ''}',
      ?until,
      if (mapUrl != null) '지도: $mapUrl',
    ].join('\n');

    return _share(template, fallbackText: text);
  }

  /// 내 초대 코드 → 초대 카드
  Future<void> shareInvite({required String code, String? inviterName}) {
    final who = inviterName == null ? '친구가' : '$inviterName님이';
    final appLink = Link(
      androidExecutionParams: {'invite': code},
      iosExecutionParams: {'invite': code},
      mobileWebUrl: ShareConfig.invitePage(code),
      webUrl: ShareConfig.invitePage(code),
    );
    final template = FeedTemplate(
      content: _content(
        title: '$who 툭에 초대했어요',
        description: '초대 코드 $code\n한가할 때 한 탭으로 부르는 절친 앱',
        link: appLink,
      ),
      buttons: [Button(title: '툭에서 친구 되기', link: appLink)],
    );
    return _share(
      template,
      fallbackText: '$who 툭에 초대했어요!\n초대 코드: $code\n${ShareConfig.invitePage(code)}',
    );
  }

  Content _content({required String title, required String description, required Link link}) =>
      Content(
        title: title,
        description: description,
        imageUrl: ShareConfig.cardImage,
        imageWidth: ShareConfig.cardImageWidth,
        imageHeight: ShareConfig.cardImageHeight,
        link: link,
      );

  Future<void> _share(DefaultTemplate template, {required String fallbackText}) async {
    try {
      if (await ShareClient.instance.isKakaoTalkSharingAvailable()) {
        await ShareClient.instance.shareDefault(template: template);
        return;
      }
    } catch (e) {
      // 콘솔 설정(사이트 도메인·카카오톡 공유) 문제면 여기로 온다 — 원인은 로그로 남기고 글자 공유로
      debugPrint('[tuk] 카카오톡 공유 실패 → 글자 공유로 대체: $e');
    }
    await SharePlus.instance.share(ShareParams(text: fallbackText));
  }

  static String _hhmm(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}
