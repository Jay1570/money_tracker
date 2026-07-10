import 'package:flutter/material.dart';

/// A self-contained calculator-style keypad for amount entry: digits, a
/// running left-to-right expression across all four operators, a date
/// shortcut in place of one corner key, backspace, and a confirm button.
///
/// This owns the calculator state itself (current operand, accumulated
/// value, pending operator) rather than the caller managing it —
/// [onChanged] is called with the resolved value and the full expression
/// string (e.g. "150×20") every time a key changes that state, the same
/// way a `TextField`'s `onChanged` reports text without the caller
/// managing the cursor/selection itself.
///
/// It's a simple running calculator, not a precedence-aware parser: a
/// second operator immediately reduces whatever came before it (typing
/// "100+50×" evaluates 100+50=150 right away, then starts building
/// "150×...").
///
/// To reset the calculator (e.g. when switching Expense/Income/Transfer
/// tabs), change this widget's `key` — that remounts it with fresh state,
/// same pattern as resetting any other stateful widget from a parent.
class NumericKeypad extends StatefulWidget {
  const NumericKeypad({
    super.key,
    required this.onChanged,
    required this.onDateTap,
    required this.dateLabel,
    required this.onConfirm,
  });

  /// Called with the resolved numeric value and the current expression
  /// string whenever a keypress changes them.
  final void Function(double value, String expression) onChanged;
  final VoidCallback onDateTap;
  final String dateLabel;
  final VoidCallback onConfirm;

  @override
  State<NumericKeypad> createState() => _NumericKeypadState();
}

class _NumericKeypadState extends State<NumericKeypad> {
  String _currentInput = '0';
  double _accumulated = 0;
  String? _pendingOp; // '+', '-', '*', '/'

  @override
  void initState() {
    super.initState();
    // Report the initial state on the next frame so the caller's mirrored
    // display starts in sync without setState-during-build issues.
    WidgetsBinding.instance.addPostFrameCallback((_) => _notify());
  }

  double get _value {
    final operand =
        double.tryParse(_currentInput.isEmpty ? '0' : _currentInput) ?? 0;
    if (_pendingOp == null) return operand;
    return _apply(_pendingOp!, _accumulated, operand);
  }

  String get _expression {
    if (_pendingOp == null) {
      return _currentInput.isEmpty ? '0' : _currentInput;
    }
    return '${_formatOperand(_accumulated)}${_opSymbol(_pendingOp!)}$_currentInput';
  }

  void _notify() => widget.onChanged(_value, _expression);

  double _apply(String op, double a, double b) {
    switch (op) {
      case '+':
        return a + b;
      case '-':
        return a - b;
      case '*':
        return a * b;
      case '/':
        return b == 0 ? 0 : a / b;
      default:
        return b;
    }
  }

  String _opSymbol(String op) {
    switch (op) {
      case '+':
        return '+';
      case '-':
        return '−';
      case '*':
        return '×';
      case '/':
        return '÷';
      default:
        return op;
    }
  }

  String _formatOperand(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toString();
  }

  void _handleKey(String key) {
    setState(() {
      switch (key) {
        case 'back':
          if (_currentInput.isNotEmpty) {
            _currentInput = _currentInput.length > 1
                ? _currentInput.substring(0, _currentInput.length - 1)
                : '';
          } else if (_pendingOp != null) {
            // Nothing typed yet for the right operand — backspacing here
            // removes the pending operator and goes back to editing the
            // left operand.
            _currentInput = _formatOperand(_accumulated);
            _accumulated = 0;
            _pendingOp = null;
          }
          if (_currentInput.isEmpty && _pendingOp == null) {
            _currentInput = '0';
          }
          break;
        case '+':
        case '-':
        case '*':
        case '/':
          final operand =
              double.tryParse(_currentInput.isEmpty ? '0' : _currentInput) ?? 0;
          _accumulated = _pendingOp == null
              ? operand
              : _apply(_pendingOp!, _accumulated, operand);
          _pendingOp = key;
          _currentInput = '';
          break;
        case '.':
          if (!_currentInput.contains('.')) {
            _currentInput = _currentInput.isEmpty ? '0.' : '$_currentInput.';
          }
          break;
        default:
          _currentInput = (_currentInput.isEmpty || _currentInput == '0')
              ? key
              : _currentInput + key;
      }
    });
    _notify();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    Widget cell({
      required Widget child,
      VoidCallback? onTap,
      Color? background,
      int flex = 1,
    }) {
      return Expanded(
        flex: flex,
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
      onTap: () => _handleKey(label),
      child: Text(
        label,
        style: const TextStyle(fontSize: 20, color: Colors.white),
      ),
    );

    Widget op(String label, String token) => cell(
      onTap: () => _handleKey(token),
      child: Text(
        label,
        style: const TextStyle(fontSize: 20, color: Colors.white70),
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 7, 8, 9, [Today — spans the width of the 2 operator columns
        // below it, keeping every row the same total width].
        Row(
          children: [
            digit('7'),
            digit('8'),
            digit('9'),
            cell(
              flex: 2,
              onTap: widget.onDateTap,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_note, color: colors.primary, size: 16),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      widget.dateLabel,
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
        Row(
          children: [
            digit('4'),
            digit('5'),
            digit('6'),
            op('+', '+'),
            op('−', '-'),
          ],
        ),
        Row(
          children: [
            digit('1'),
            digit('2'),
            digit('3'),
            op('×', '*'),
            op('÷', '/'),
          ],
        ),
        Row(
          children: [
            digit('.'),
            digit('0'),
            cell(
              onTap: () => _handleKey('back'),
              child: const Icon(
                Icons.backspace_outlined,
                color: Colors.white70,
                size: 20,
              ),
            ),
            cell(
              flex: 2,
              onTap: widget.onConfirm,
              background: colors.primary,
              child: const Icon(Icons.check, color: Colors.black),
            ),
          ],
        ),
      ],
    );
  }
}
