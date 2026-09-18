/// 모임방 장소를 외부 지도 앱으로 여는 링크.
///
/// 길찾기를 직접 만들지 않고, 사람들이 이미 쓰는 지도 앱으로 넘긴다(채팅을 카톡으로 넘기는 것과 같은 원칙).
/// 앱 딥링크를 먼저 시도하고, 앱이 없으면 같은 장소의 웹 지도로 연다 → [MapLink.app] / [MapLink.web].
///
/// 무엇을 여는가 (정확한 것부터):
///  1. 카카오 장소 ID (검색으로 고른 장소) → 카카오맵은 그 가게 페이지를 바로 연다
///  2. 좌표 → 그 지점
///  3. 이름만 (직접 입력) → 이름 검색 결과
library;

enum MapApp {
  kakao('카카오맵'),
  naver('네이버 지도');

  const MapApp(this.label);
  final String label;

  /// 저장용 키 (enum 이름이 바뀌어도 기존 선택이 깨지지 않게 고정)
  String get storageKey => switch (this) {
        MapApp.kakao => 'kakao',
        MapApp.naver => 'naver',
      };

  static MapApp? fromStorageKey(String? key) =>
      MapApp.values.where((a) => a.storageKey == key).firstOrNull;
}

class MapLink {
  const MapLink({required this.app, required this.web});

  /// 지도 앱 딥링크 (앱이 설치돼 있을 때)
  final Uri app;

  /// 앱이 없을 때 여는 웹 지도
  final Uri web;
}

/// 네이버 지도 URL scheme 은 호출한 앱을 appname 으로 밝히도록 요구한다.
const _naverAppName = 'com.tuk.app';

MapLink buildMapLink(
  MapApp app, {
  required String placeName,
  double? lat,
  double? lng,
  String? kakaoPlaceId,
}) {
  final name = placeName.trim();
  final hasCoord = lat != null && lng != null;
  final placeId = kakaoPlaceId;

  switch (app) {
    case MapApp.kakao:
      // https://apis.map.kakao.com/android/guide/#urlscheme
      if (placeId != null && placeId.isNotEmpty) {
        return MapLink(
          app: Uri(scheme: 'kakaomap', host: 'place', queryParameters: {'id': placeId}),
          web: Uri(scheme: 'https', host: 'place.map.kakao.com', pathSegments: [placeId]),
        );
      }
      return MapLink(
        app: hasCoord
            ? Uri(scheme: 'kakaomap', host: 'look', queryParameters: {'p': '$lat,$lng'})
            : Uri(scheme: 'kakaomap', host: 'search', queryParameters: {'q': name}),
        web: hasCoord
            ? Uri(scheme: 'https', host: 'map.kakao.com', pathSegments: ['link', 'map', '$name,$lat,$lng'])
            : Uri(scheme: 'https', host: 'map.kakao.com', pathSegments: ['link', 'search', name]),
      );
    case MapApp.naver:
      // https://guide.ncloud-docs.com/docs/maps-url-scheme
      return MapLink(
        app: hasCoord
            ? Uri(scheme: 'nmap', host: 'place', queryParameters: {
                'lat': '$lat',
                'lng': '$lng',
                'name': name,
                'appname': _naverAppName,
              })
            : Uri(scheme: 'nmap', host: 'search', queryParameters: {
                'query': name,
                'appname': _naverAppName,
              }),
        // 네이버 웹 지도는 좌표 지정 링크가 불안정해 이름 검색으로 통일
        web: Uri(scheme: 'https', host: 'map.naver.com', pathSegments: ['p', 'search', name]),
      );
  }
}
