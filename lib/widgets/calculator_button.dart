import 'package:flutter/material.dart';

enum CalculatorButtonType { digit, operator, action, equals }

class CalculatorButton extends StatefulWidget {
  const CalculatorButton({
    super.key,
    required this.label,
    required this.onTap,
    required this.type,
  });

  final String label;
  final VoidCallback onTap;
  final CalculatorButtonType type;

  @override
  State<CalculatorButton> createState() => _CalculatorButtonState();
}

class _CalculatorButtonState extends State<CalculatorButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    final _ButtonStyleData style = _styleForType(widget.type, scheme);

    return AnimatedScale(
      scale: _pressed ? 0.96 : 1,
      duration: const Duration(milliseconds: 90),
      child: Material(
        color: style.backgroundColor,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          splashColor: style.splashColor,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          onTap: widget.onTap,
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: _buildLabel(style),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(_ButtonStyleData style) {
    if (widget.label == 'BACK') {
      return Icon(
        Icons.backspace_outlined,
        size: 24,
        color: style.foregroundColor,
      );
    }

    return Text(
      widget.label,
      style: TextStyle(
        fontSize: widget.label == 'SQRT' ? 20 : 28,
        fontWeight: FontWeight.w600,
        color: style.foregroundColor,
      ),
    );
  }

  _ButtonStyleData _styleForType(CalculatorButtonType type, ColorScheme scheme) {
    switch (type) {
      case CalculatorButtonType.operator:
        return _ButtonStyleData(
          backgroundColor: scheme.primaryContainer,
          foregroundColor: scheme.onPrimaryContainer,
          splashColor: scheme.primary.withAlpha(45),
        );
      case CalculatorButtonType.action:
        return _ButtonStyleData(
          backgroundColor: scheme.secondaryContainer,
          foregroundColor: scheme.onSecondaryContainer,
          splashColor: scheme.secondary.withAlpha(45),
        );
      case CalculatorButtonType.equals:
        return _ButtonStyleData(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          splashColor: scheme.onPrimary.withAlpha(45),
        );
      case CalculatorButtonType.digit:
        return _ButtonStyleData(
          backgroundColor: scheme.surface,
          foregroundColor: scheme.onSurface,
          splashColor: scheme.primary.withAlpha(30),
        );
    }
  }
}

class _ButtonStyleData {
  const _ButtonStyleData({
    required this.backgroundColor,
    required this.foregroundColor,
    required this.splashColor,
  });

  final Color backgroundColor;
  final Color foregroundColor;
  final Color splashColor;
}
