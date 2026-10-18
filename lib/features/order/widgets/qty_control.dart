import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/utils/formatters.dart';

/// الكمية بدون أصفار زائدة: 3.0 ← «3» و 2.5 ← «2.5»
String formatQty(double q) {
  if (q == q.roundToDouble()) return q.toInt().toString();
  return q
      .toStringAsFixed(2)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}

/// متحكم كمية على شكل حبّة: [−] [رقم قابل للكتابة] [+].
/// الزر + يتعطل عند الوصول للحد الأقصى [max]، والكتابة تتجاوز الحد فيُبلَّغ [onChanged].
class QtyControl extends StatefulWidget {
  final double qty;
  final double max;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  /// عند كتابة رقم يدويًا (بعد الانتهاء من التعديل)
  final ValueChanged<double> onTyped;
  final bool dense;

  const QtyControl({
    super.key,
    required this.qty,
    required this.max,
    required this.onIncrement,
    required this.onDecrement,
    required this.onTyped,
    this.dense = false,
  });

  @override
  State<QtyControl> createState() => _QtyControlState();
}

class _QtyControlState extends State<QtyControl> {
  late final TextEditingController _controller;
  late final FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: formatQty(widget.qty));
    _focus = FocusNode()..addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(covariant QtyControl old) {
    super.didUpdateWidget(old);
    // نزامن النص مع الكمية ما لم يكن المستخدم يكتب الآن
    if (!_focus.hasFocus && old.qty != widget.qty) {
      _controller.text = formatQty(widget.qty);
    }
  }

  void _onFocusChange() {
    if (!_focus.hasFocus) _commit();
  }

  void _commit() {
    final parsed = parseAmount(_controller.text);
    if (parsed == null || parsed < 0) {
      _controller.text = formatQty(widget.qty);
      return;
    }
    widget.onTyped(parsed);
    // الكمية قد تُقيَّد بالمتاح، فنعرض ما استقر عليه المتحكم في الإطار التالي
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_focus.hasFocus) {
        _controller.text = formatQty(widget.qty);
      }
    });
  }

  @override
  void dispose() {
    _focus
      ..removeListener(_onFocusChange)
      ..dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final size = widget.dense ? 34.0 : 42.0;
    final canAdd = widget.qty < widget.max;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(size),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _RoundButton(
            size: size,
            icon: Icons.remove_rounded,
            onPressed: widget.qty > 0 ? widget.onDecrement : null,
            filled: false,
          ),
          SizedBox(
            width: widget.dense ? 44 : 54,
            child: TextField(
              controller: _controller,
              focusNode: _focus,
              textAlign: TextAlign.center,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩.,٫]')),
              ],
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 6),
              ),
              onSubmitted: (_) => _commit(),
              onTapOutside: (_) => _focus.unfocus(),
            ),
          ),
          _RoundButton(
            size: size,
            icon: Icons.add_rounded,
            onPressed: canAdd ? widget.onIncrement : null,
            filled: true,
          ),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  final double size;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool filled;

  const _RoundButton({
    required this.size,
    required this.icon,
    required this.onPressed,
    required this.filled,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = onPressed != null;
    return Material(
      color: filled && enabled ? scheme.primary : Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(
            icon,
            size: size * 0.55,
            color: !enabled
                ? scheme.onSurface.withValues(alpha: 0.28)
                : filled
                    ? scheme.onPrimary
                    : scheme.primary,
          ),
        ),
      ),
    );
  }
}
