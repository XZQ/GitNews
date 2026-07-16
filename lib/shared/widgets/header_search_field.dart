import 'package:flutter/material.dart';

import '../../core/i18n/app_localizations.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_typography.dart';

/* 
*顶部栏通用搜索框。
*/
class HeaderSearchField extends StatefulWidget {
  const HeaderSearchField({
    required this.hintText,
    this.value = '',
    this.onChanged,
    this.onSubmitted,
    this.height = 40,
    this.outlined = false,
    this.fillColor,
    this.borderRadius = AppRadius.sm,
    super.key,
  });

  final String hintText;
  final String value;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  // 搜索框高度;移动端强调态可使用 48dp。
  final double height;

  // 是否显示细描边,用于浅色页面上的独立搜索表面。
  final bool outlined;

  // 可选填充色;为空时沿用共享搜索框默认表面色。
  final Color? fillColor;

  // 搜索框圆角,默认保持原有紧凑样式。
  final double borderRadius;

  @override
  State<HeaderSearchField> createState() => _HeaderSearchFieldState();
}

class _HeaderSearchFieldState extends State<HeaderSearchField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant HeaderSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text) {
      _controller.value = TextEditingValue(text: widget.value, selection: TextSelection.collapsed(offset: widget.value.length));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _clear() {
    _controller.clear();
    widget.onChanged?.call('');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(widget.borderRadius);
    final borderSide = widget.outlined ? BorderSide(color: colors.outlineVariant.withValues(alpha: 0.82)) : BorderSide.none;
    final isEmphasized = widget.height >= 46;
    return Semantics(
        label: l10n.tr('a11y.search'),
        hint: widget.hintText,
        textField: true,
        child: SizedBox(
            height: widget.height,
            child: TextField(
                controller: _controller,
                onChanged: widget.onChanged,
                onSubmitted: widget.onSubmitted,
                textInputAction: TextInputAction.search,
                style: (isEmphasized ? AppTypography.bodyLarge : AppTypography.bodyMedium).copyWith(color: colors.onSurface),
                decoration: InputDecoration(
                    prefixIcon: Icon(Icons.search_rounded, size: isEmphasized ? 22 : 18, color: colors.onSurfaceVariant),
                    hintText: widget.hintText,
                    hintStyle: (isEmphasized ? AppTypography.bodyMedium : AppTypography.bodySmall).copyWith(color: colors.onSurfaceVariant),
                    suffixIcon: ListenableBuilder(
                        listenable: _controller,
                        builder: (context, _) {
                          if (_controller.text.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return IconButton(
                            tooltip: l10n.tr('a11y.clear_search'),
                            onPressed: _clear,
                            icon: Icon(Icons.close_rounded, size: 16, color: colors.onSurfaceVariant),
                          );
                        }),
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    filled: true,
                    fillColor: widget.fillColor ?? (widget.outlined ? colors.surface : colors.surfaceContainerHighest),
                    border: OutlineInputBorder(borderRadius: radius, borderSide: borderSide),
                    enabledBorder: OutlineInputBorder(borderRadius: radius, borderSide: borderSide),
                    focusedBorder: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: colors.primary, width: 1.4))))));
  }
}
