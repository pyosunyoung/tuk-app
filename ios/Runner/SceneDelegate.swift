import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {

  /// 앱을 켠 링크는 iOS 13+ 에서 `AppDelegate` 의 launchOptions 가 아니라 여기로 들어온다.
  /// 공유 카드로 앱이 꺼진 상태에서 켜지는 경우가 이 경로다 — [TukDeepLink] 참고.
  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    TukDeepLink.capture(connectionOptions.urlContexts.first?.url)
    super.scene(scene, willConnectTo: session, options: connectionOptions)
  }
}
