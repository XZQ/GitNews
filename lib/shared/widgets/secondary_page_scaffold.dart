import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n/app_localizations.dart';
import '../../core/theme/app_spacing.dart';
import 'page_header.dart';

/*
*Responsive wrapper for secondary pages.
*Compact screens keep the familiar AppBar; desktop screens use the same
*workspace header as primary pages so back navigation and hierarchy stay
*visible without introducing a second navigation shell.
*/
class SecondaryPageScaffold extends StatelessWidget {
  const SecondaryPageScaffold({
    required this.title,
    required this.body,
    this.subtitle,
    this.icon,
    this.actions = const [],
    this.bottomNavigationBar,
    this.fallbackPath = '/home',
    super.key,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final List<Widget> actions;
  final Widget? bottomNavigationBar;
  final Widget body;
  final String fallbackPath;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 600;
    final l10n = AppLocalizations.of(context);
    final back = Tooltip(
      message: MaterialLocalizations.of(context).backButtonTooltip,
      child: BackButton(
        onPressed: () => context.canPop() ? context.pop() : context.go(fallbackPath),
      ),
    );
    return Scaffold(
      appBar: compact ? AppBar(title: Text(title), leading: back, actions: actions) : null,
      bottomNavigationBar: compact ? bottomNavigationBar : null,
      body: compact
          ? body
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PageHeader(
                  leading: back,
                  icon: icon,
                  title: title,
                  subtitle: subtitle ?? l10n.tr('common.secondary_page_subtitle'),
                  actions: actions,
                ),
                const SizedBox(height: AppSpacing.xs),
                Expanded(child: body),
              ],
            ),
    );
  }
}
