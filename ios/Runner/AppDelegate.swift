import Flutter
import UIKit

/// 카카오톡 공유 카드로 앱이 "꺼진 상태에서" 켜졌을 때의 링크를 보관한다.
/// 안드로이드 `MainActivity.kt` 와 같은 역할이고 채널 이름도 같다.
///
/// 카카오 SDK 는 링크를 받는 즉시 Dart 로 보내는데, 콜드 스타트엔 그때 Dart 쪽 수신자가
/// 아직 없어 유실될 수 있다. 그래서 첫 링크를 여기 담아뒀다가 `DeepLinkService` 가 물어보면 한 번 준다.
/// (앱이 켜져 있을 때 들어오는 링크는 카카오 SDK 콜백이 처리한다)
///
/// 링크가 들어오는 입구가 둘이라 양쪽에서 담는다:
///  - iOS 13+ 는 `SceneDelegate` 의 `willConnectTo`
///  - 씬을 안 쓰는 구성은 아래 `launchOptions`
enum TukDeepLink {
  private static var initialLink: String?

  /// `kakao…://kakaolink` 만 받는다. 다른 링크면 무시하고 앱은 평소처럼 열린다.
  static func capture(_ url: URL?) {
    guard let url,
          url.scheme?.hasPrefix("kakao") == true,
          url.host == "kakaolink" else { return }
    initialLink = url.absoluteString
  }

  /// 한 번만 내준다 — 두 번째부터는 nil.
  static func take() -> String? {
    defer { initialLink = nil }
    return initialLink
  }
}

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  /// 채널은 붙잡고 있어야 살아 있다.
  private var deepLinkChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    TukDeepLink.capture(launchOptions?[.url] as? URL)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    guard let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "TukDeepLink") else {
      return
    }
    let channel = FlutterMethodChannel(
      name: "com.tuk.app/deeplink",
      binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      if call.method == "initialLink" {
        result(TukDeepLink.take())
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
    deepLinkChannel = channel
  }
}
