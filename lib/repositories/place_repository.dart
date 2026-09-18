import '../core/config.dart';
import '../models/place.dart';
import '../services/api_client.dart';

/// 장소 검색. 카카오 REST API 키는 서버에만 있어서 앱은 우리 서버를 거친다.
class PlaceRepository {
  PlaceRepository(this._api);
  final ApiClient _api;

  Future<List<Place>> search(String query) async {
    final data = await _api.get('${AppConfig.apiPrefix}/places/search', query: {'query': query});
    return (data as List<dynamic>)
        .map((e) => Place.fromSearchJson(e as Map<String, dynamic>))
        .toList();
  }
}
