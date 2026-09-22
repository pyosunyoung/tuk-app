package com.tuk.app

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * 카카오톡 공유 카드로 앱이 "꺼진 상태에서" 켜졌을 때의 링크를 Dart 가 직접 가져가게 한다.
 *
 * 카카오 SDK 플러그인은 액티비티에 붙는 순간 링크를 Dart 로 보내는데, 콜드 스타트엔 그때 Dart 쪽 수신자가
 * 아직 없어 링크가 유실될 수 있다. 그래서 첫 인텐트의 kakaolink 주소를 보관했다가 DeepLinkService 가 물어보면 한 번 준다.
 * (앱이 켜져 있을 때 들어오는 링크는 카카오 SDK 콜백이 처리한다)
 */
class MainActivity : FlutterActivity() {
    private var initialLink: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        initialLink = kakaoLinkOf(intent)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.tuk.app/deeplink")
            .setMethodCallHandler { call, result ->
                if (call.method == "initialLink") {
                    result.success(initialLink)
                    initialLink = null // 한 번만
                } else {
                    result.notImplemented()
                }
            }
    }

    private fun kakaoLinkOf(intent: Intent?): String? {
        val data = intent?.data ?: return null
        if (intent.action != Intent.ACTION_VIEW) return null
        if (data.scheme?.startsWith("kakao") != true || data.host != "kakaolink") return null
        return data.toString()
    }
}
