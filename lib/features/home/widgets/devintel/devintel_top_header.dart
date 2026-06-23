import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class DevIntelTopHeader extends StatelessWidget {
  const DevIntelTopHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        decoration: const BoxDecoration(
          color: Color(0xFF0F0F12),
          border: Border(
            bottom: BorderSide(color: Color(0xFF2A2A30), width: 1),
          ),
        ),
        child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Developer Intelligence',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.0,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Real-time ecosystem insights',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textMutedDark,
                  ),
                ),
              ],
            ),
          ),
          const _SearchField(),
          const SizedBox(width: 12),
          const _BellWithDot(),
          const SizedBox(width: 12),
          const _LiveSyncBadge(),
        ],
      ),
    ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 320,
      height: 38,
      child: TextField(
        onSubmitted: (v) {
          if (v.trim().isEmpty) return;
          context.go('/trending/repos');
        },
        textInputAction: TextInputAction.search,
        style: const TextStyle(fontSize: 13, color: Colors.white),
        decoration: InputDecoration(
          prefixIcon: const Icon(
            Icons.search_rounded,
            size: 18,
            color: AppColors.textMutedDark,
          ),
          hintText: 'Search repos, tags...',
          hintStyle: const TextStyle(
            fontSize: 13,
            color: AppColors.textMutedDark,
          ),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          filled: true,
          fillColor: const Color(0xFF16161B),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.success, width: 1.4),
          ),
        ),
      ),
    );
  }
}

class _BellWithDot extends StatelessWidget {
  const _BellWithDot();

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => context.go('/monitor'),
        child: SizedBox(
          width: 38,
          height: 38,
          child: Stack(
            children: [
              const Center(
                child: Icon(
                  Icons.notifications_none_rounded,
                  size: 20,
                  color: AppColors.textSecondaryDark,
                ),
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.danger,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LiveSyncBadge extends StatelessWidget {
  const _LiveSyncBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.14),
        border: Border.all(
          color: AppColors.success.withValues(alpha: 0.4),
        ),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          _LivePulseDot(),
          SizedBox(width: 6),
          Text(
            'Live Sync',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.success,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _LivePulseDot extends StatefulWidget {
  const _LivePulseDot();

  @override
  State<_LivePulseDot> createState() => _LivePulseDotState();
}

class _LivePulseDotState extends State<_LivePulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final t = _ctrl.value;
        return Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: Color.lerp(
              AppColors.success.withValues(alpha: 0.4),
              AppColors.success,
              t,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.success.withValues(alpha: 0.5 * t),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ],
          ),
        );
      },
    );
  }
}
