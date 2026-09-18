/// 모임방 장소 한 곳.
///
/// - 검색으로 고른 장소: 이름 + 좌표 + 카카오 장소 ID + 주소 (지도 앱에서 그 가게 페이지를 바로 연다)
/// - 직접 입력한 장소: 이름만 ("학교 정문"처럼 검색에 안 나오는 약속 장소)
class Place {
  const Place({
    required this.name,
    this.lat,
    this.lng,
    this.kakaoPlaceId,
    this.address,
    this.category,
  });

  /// 직접 입력
  const Place.manual(this.name)
      : lat = null,
        lng = null,
        kakaoPlaceId = null,
        address = null,
        category = null;

  final String name;
  final double? lat;
  final double? lng;
  final String? kakaoPlaceId;
  final String? address;

  /// 검색 결과 표시용("카페", "음식점"). 저장하지 않는다.
  final String? category;

  bool get isSearched => kakaoPlaceId != null;

  /// GET /api/places/search 응답 한 건
  factory Place.fromSearchJson(Map<String, dynamic> json) => Place(
        name: json['name'] as String,
        lat: (json['lat'] as num?)?.toDouble(),
        lng: (json['lng'] as num?)?.toDouble(),
        kakaoPlaceId: json['kakaoPlaceId'] as String?,
        address: json['address'] as String?,
        category: json['category'] as String?,
      );
}
