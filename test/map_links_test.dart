import 'package:flutter_test/flutter_test.dart';
import 'package:tuk/core/map_links.dart';

void main() {
  group('이름만 있을 때(P1) — 검색 링크', () {
    test('카카오맵: 한글·공백이 인코딩된 앱 검색 + 웹 검색', () {
      final link = buildMapLink(MapApp.kakao, placeName: '강남역 11번 출구');

      expect(link.app.scheme, 'kakaomap');
      expect(link.app.host, 'search');
      expect(link.app.queryParameters['q'], '강남역 11번 출구');
      expect(link.app.toString(), isNot(contains(' ')));

      expect(link.web.toString(),
          'https://map.kakao.com/link/search/%EA%B0%95%EB%82%A8%EC%97%AD%2011%EB%B2%88%20%EC%B6%9C%EA%B5%AC');
    });

    test('네이버 지도: appname 필수 파라미터 포함', () {
      final link = buildMapLink(MapApp.naver, placeName: '스타벅스');

      expect(link.app.scheme, 'nmap');
      expect(link.app.host, 'search');
      expect(link.app.queryParameters, {'query': '스타벅스', 'appname': 'com.tuk.app'});
      expect(link.web.host, 'map.naver.com');
      expect(link.web.pathSegments, ['p', 'search', '스타벅스']);
    });

    test('앞뒤 공백은 잘라낸다', () {
      final link = buildMapLink(MapApp.kakao, placeName: '  홍대입구역  ');
      expect(link.app.queryParameters['q'], '홍대입구역');
    });

    test('URL 예약문자(&, /, #)가 들어간 이름도 한 덩어리로 전달된다', () {
      final link = buildMapLink(MapApp.naver, placeName: 'A&B 카페 / 2층 #3');
      expect(link.app.queryParameters['query'], 'A&B 카페 / 2층 #3');
      expect(link.web.pathSegments.last, 'A&B 카페 / 2층 #3');
    });
  });

  group('좌표가 있을 때(P1-B 대비) — 지점 링크', () {
    test('카카오맵: look + 좌표, 웹은 이름·좌표 핀', () {
      final link = buildMapLink(MapApp.kakao, placeName: '툭카페', lat: 37.4979, lng: 127.0276);
      expect(link.app.host, 'look');
      expect(link.app.queryParameters['p'], '37.4979,127.0276');
      expect(link.web.pathSegments, ['link', 'map', '툭카페,37.4979,127.0276']);
    });

    test('네이버 지도: place + 좌표 + 이름', () {
      final link = buildMapLink(MapApp.naver, placeName: '툭카페', lat: 37.4979, lng: 127.0276);
      expect(link.app.host, 'place');
      expect(link.app.queryParameters['lat'], '37.4979');
      expect(link.app.queryParameters['lng'], '127.0276');
      expect(link.app.queryParameters['name'], '툭카페');
    });

    test('좌표가 하나만 있으면 검색으로 대체', () {
      final link = buildMapLink(MapApp.kakao, placeName: '툭카페', lat: 37.4979);
      expect(link.app.host, 'search');
    });
  });

  test('저장 키 왕복', () {
    for (final app in MapApp.values) {
      expect(MapApp.fromStorageKey(app.storageKey), app);
    }
    expect(MapApp.fromStorageKey(null), isNull);
    expect(MapApp.fromStorageKey('unknown'), isNull);
  });
}
