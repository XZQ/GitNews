import 'package:flutter/material.dart';

import '../../core/theme/app_radius.dart';
import '../../core/theme/app_typography.dart';

/// 顶部栏通用搜索框。
class HeaderSearchField extends StatefulWidget {
  const HeaderSearchField({
    required this.hintText,
    this.value = '',
    this.onChanged,
    this.onSubmitted,
    super.key,
  });

  final String hintText;
  final String value;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  State<HeaderSearchField> createState() => _HeaderSearchFieldState();
}

class _HeaderSearchFieldState extends State<HeaderSearchField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
    _controller.addListener(_handleTextChanged);
  }

  @override
  void didUpdateWidget(covariant HeaderSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _handleTextChanged() {
    setState(() {});
  }

  void _clear() {
    _controller.clear();
    widget.onChanged?.call('');
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      height: 40,
      child: TextField(
        controller: _controller,
        onChanged: widget.onChanged,
        onSubmitted: widget.onSubmitted,
        textInputAction: TextInputAction.search,
        style: AppTypography.bodyMedium.copyWith(color: colors.onSurface),
        decoration: InputDecoration(
          prefixIcon: Icon(
            Icons.search_rounded,
            size: 18,
            color: colors.onSurfaceVariant,
          ),
          hintText: widget.hintText,
          hintStyle: AppTypography.bodySmall.copyWith(
            color: colors.onSurfaceVariant,
          ),
          suffixIcon: _controller.text.isEmpty
              ? null
              : IconButton(
                  tooltip: '清除搜索',
                  onPressed: _clear,
                  icon: Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: colors.onSurfaceVariant,
                  ),
                ),
          isDense: true,
          contentPadding: EdgeInsets.zero,
          filled: true,
          fillColor: colors.surfaceContainerHighest,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            borderSide: BorderSide(color: colors.primary, width: 1.4),
          ),
        ),
      ),
    );
  }
}
