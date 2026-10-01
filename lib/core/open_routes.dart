import 'package:flutter/widgets.dart';

/// 지금 열려 있는 화면의 라우트. 알림을 탭했을 때 같은 화면을 한 겹 더 쌓지 않으려고 둔다.
///
/// 화면을 여는 곳이 여러 군데라(홈 카드·받은 툭·딥링크·알림) 여는 쪽을 고치는 대신
/// 화면이 스스로 등록한다([OpenRouteTracking]). 키: `room:{flashId}` · `friends` · `received`.
class OpenRoutes {
  OpenRoutes._();

  static final Map<String, Route<dynamic>> _routes = {};

  static bool isOpen(String key) => _routes.containsKey(key);

  static void _track(String key, Route<dynamic> route) => _routes[key] = route;

  /// 다른 라우트가 같은 키를 덮어썼으면 건드리지 않는다.
  static void _untrack(String key, Route<dynamic> route) {
    if (_routes[key] == route) _routes.remove(key);
  }

  /// 열려 있으면 그 화면까지 돌아가고 true, 아니면 false(호출한 쪽이 새로 연다).
  static bool bringToFront(NavigatorState navigator, String key) {
    final route = _routes[key];
    if (route == null || !route.isActive) return false;
    navigator.popUntil((r) => r == route);
    return true;
  }
}

/// 화면 State 에 섞어 쓴다. 라우트를 등록할 때 들고 있다가 dispose 에서 그걸로 해제한다
/// (dispose 시점엔 ModalRoute.of(context) 로 조상을 찾는 게 안전하지 않다).
mixin OpenRouteTracking<T extends StatefulWidget> on State<T> {
  String get openRouteKey;
  Route<dynamic>? _trackedRoute;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null && route != _trackedRoute) {
      _trackedRoute = route;
      OpenRoutes._track(openRouteKey, route);
    }
  }

  @override
  void dispose() {
    final route = _trackedRoute;
    if (route != null) OpenRoutes._untrack(openRouteKey, route);
    super.dispose();
  }
}
