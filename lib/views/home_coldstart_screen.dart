import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/tokens.dart';
import '../core/typography.dart';
import '../viewmodels/auth_view_model.dart';
import '../widgets/logo.dart';
import '../widgets/primitives.dart';
import '../widgets/toast.dart';
import 'landing_screen.dart';

/// 홈 — 콜드스타트 (1b). 로그인 직후, 친구 0명 상태.
/// 지금 콜은 기본 ON, 친구 초대를 유도한다.
/// 라이브 프레즌스(실제 콜 API·친구 목록)는 프레즌스 기능에서 연결한다.
class HomeColdstartScreen extends StatefulWidget {
  const HomeColdstartScreen({super.key});

  @override
  State<HomeColdstartScreen> createState() => _HomeColdstartScreenState();
}

class _HomeColdstartScreenState extends State<HomeColdstartScreen> {
  // 신규 사용자 기본값: 콜 ON, 활동 "아무거나", 2시간 뒤 만료.
  bool _callOn = true;
  DateTime _expiresAt = DateTime.now().add(const Duration(hours: 2));
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // 만료 문구를 1분마다 갱신.
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  /// 남은 시간 → 부담 덜어주는 만료 문구.
  String get _expiryText {
    final diff = _expiresAt.difference(DateTime.now());
    if (diff.inSeconds <= 0) return '곧 자동으로 꺼져요';
    if (_expiresAt.hour == 0 && _expiresAt.minute == 0) {
      return '자정에 자동으로 꺼져요';
    }
    final m = diff.inMinutes;
    if (m >= 60) {
      final h = m ~/ 60;
      final r = m % 60;
      return r == 0
          ? '$h시간 뒤 자동으로 꺼져요'
          : '$h시간 $r분 뒤 자동으로 꺼져요';
    }
    return '$m분 뒤 자동으로 꺼져요';
  }

  void _toggleCall() {
    setState(() {
      _callOn = !_callOn;
      if (_callOn) _expiresAt = DateTime.now().add(const Duration(hours: 2));
    });
    // TODO(프레즌스 기능): 실제 콜 on/off API 연결.
  }

  Future<void> _confirmLogout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('로그아웃할까요?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('로그아웃')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await context.read<AuthViewModel>().logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LandingScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.x20),
              child: _nowCallCard(),
            ),
            const Expanded(child: _EmptyState()),
            _bottomActions(),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.only(
          left: AppSpace.x20, right: AppSpace.x20, top: AppSpace.x8, bottom: AppSpace.x12),
      child: Row(
        children: [
          const TukLogo(size: 40),
          const Spacer(),
          // 프로필 아바타 — /users/me 붙기 전 임시 이니셜.
          GestureDetector(
            onTap: _confirmLogout,
            child: Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                  color: AppColors.primaryTint, shape: BoxShape.circle),
              child: Text('나',
                  style: AppText.label14.copyWith(
                      color: AppColors.primaryPress,
                      fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _nowCallCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpace.x20),
      decoration: BoxDecoration(
        color: _callOn ? AppColors.surface : AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _callOn ? AppColors.success : AppColors.border,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppSpace.x8),
                    Text(
                      _callOn ? '지금 콜 켜짐 · 아무거나' : '지금 콜 꺼짐',
                      style: AppText.title20.copyWith(
                        color: _callOn ? AppColors.text : AppColors.textSub,
                        fontWeight:
                            _callOn ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                if (_callOn)
                  Padding(
                    padding: const EdgeInsets.only(
                        left: AppSpace.x16, top: AppSpace.x4),
                    child: Text(_expiryText, style: AppText.label14),
                  ),
              ],
            ),
          ),
          _CallToggle(on: _callOn, onTap: _toggleCall),
        ],
      ),
    );
  }

  Widget _bottomActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpace.x20, 0, AppSpace.x20, AppSpace.x20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PillButton.primary(
            '친구 초대하기',
            onPressed: () => showTukToast(context, '친구 초대는 다음 단계(친구 기능)에서 연결됩니다'),
          ),
          const SizedBox(height: AppSpace.x12),
          PillButton.secondary(
            '연락처에서 찾기',
            onPressed: () => showTukToast(context, '연락처 찾기는 다음 단계에서 연결됩니다'),
          ),
          const SizedBox(height: AppSpace.x12),
          Text('초대해도 상대에겐 부담 없어요 · 링크 하나면 끝',
              textAlign: TextAlign.center, style: AppText.caption12),
        ],
      ),
    );
  }
}

/// 지금 콜 토글 52×32, 노브 26.
class _CallToggle extends StatelessWidget {
  const _CallToggle({required this.on, required this.onTap});
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 52,
        height: 32,
        padding: const EdgeInsets.all(3),
        alignment: on ? Alignment.centerRight : Alignment.centerLeft,
        decoration: BoxDecoration(
          color: on ? AppColors.primary : AppColors.border,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Container(
          width: 26,
          height: 26,
          decoration: const BoxDecoration(
              color: Colors.white, shape: BoxShape.circle),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.x8, vertical: AppSpace.x32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const TukLogo(size: 96, variant: TukLogoVariant.light),
            const SizedBox(height: AppSpace.x16),
            Text('아직 절친이 없어요',
                textAlign: TextAlign.center,
                style: AppText.title20.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: AppSpace.x8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 260),
              child: Text(
                '먼저 켜두면 친구가 한가해질 때 알려줄게요',
                textAlign: TextAlign.center,
                style: AppText.body
                    .copyWith(color: AppColors.textSub, height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
