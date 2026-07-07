import 'package:flutter/material.dart';

/// The calculator-style keypad for amount entry: digits, a running +/-
/// chain, a date shortcut in place of one corner key, backspace, and a
/// confirm button.
///
/// Note: only `+` and `-` are supported (not `×`/`÷`) to keep the
/// evaluation logic a simple running total rather than a full expression
/// parser — the two are by far the most common for splitting/adjusting an
/// amount on entry. Let me know if you actually want all four operators;
/// it's a bigger change (needs real operator precedence).
class NumericKeypad extends StatelessWidget {
  const NumericKeypad({
    super.key,
    required this.onKeyTap,
    required this.onDateTap,
    required this.dateLabel,
    required this.onConfirm,
  });

  final ValueChanged<String> onKeyTap;
  final VoidCallback onDateTap;
  final String dateLabel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    Widget cell({
      required Widget child,
      VoidCallback? onTap,
      Color? background,
    }) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: Material(
            color: background ?? const Color(0xff2a2a2a),
            borderRadius: BorderRadius.circular(6),
            child: InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: onTap,
              child: SizedBox(height: 56, child: Center(child: child)),
            ),
          ),
        ),
      );
    }

    Widget digit(String label) => cell(
      onTap: () => onKeyTap(label),
      child: Text(
        label,
        style: const TextStyle(fontSize: 20, color: Colors.white),
      ),
    );

    Widget op(String label, String token) => cell(
      onTap: () => onKeyTap(token),
      child: Text(
        label,
        style: const TextStyle(fontSize: 20, color: Colors.white70),
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            digit('7'),
            digit('8'),
            digit('9'),
            cell(
              onTap: onDateTap,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_note, color: colors.primary, size: 16),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      dateLabel,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        Row(children: [digit('4'), digit('5'), digit('6'), op('+', '+')]),
        Row(children: [digit('1'), digit('2'), digit('3'), op('−', '-')]),
        Row(
          children: [
            digit('.'),
            digit('0'),
            cell(
              onTap: () => onKeyTap('back'),
              child: const Icon(
                Icons.backspace_outlined,
                color: Colors.white70,
                size: 20,
              ),
            ),
            cell(
              onTap: onConfirm,
              background: colors.primary,
              child: const Icon(Icons.check, color: Colors.black),
            ),
          ],
        ),
      ],
    );
  }
}
