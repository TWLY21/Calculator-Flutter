import 'package:flutter/material.dart';

import '../logic/calculator_logic.dart';
import '../widgets/calculator_button.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({
    super.key,
    required this.isDarkMode,
    required this.onThemeToggle,
  });

  final bool isDarkMode;
  final VoidCallback onThemeToggle;

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  static const List<List<String>> _buttonRows = <List<String>>[
    <String>['C', 'BACK', '%', '÷'],
    <String>['7', '8', '9', '×'],
    <String>['4', '5', '6', '-'],
    <String>['1', '2', '3', '+'],
    <String>['SQRT', '0', '.', '='],
  ];

  String _expression = '';
  String _result = '0';
  final List<String> _history = <String>[];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calculator'),
        centerTitle: true,
        actions: <Widget>[
          IconButton(
            tooltip: 'History',
            onPressed: _showHistory,
            icon: const Icon(Icons.history),
          ),
          IconButton(
            tooltip: widget.isDarkMode ? 'Light mode' : 'Dark mode',
            onPressed: widget.onThemeToggle,
            icon: Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool compact = constraints.maxHeight < 700;
            final int displayFlex = compact ? 3 : 4;
            final int buttonsFlex = compact ? 7 : 6;

            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: <Widget>[
                  Expanded(
                    flex: displayFlex,
                    child: _buildDisplayCard(context),
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    flex: buttonsFlex,
                    child: _buildButtonGrid(),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDisplayCard(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool compactDisplay = constraints.maxHeight < 160;
            final double expressionFont = compactDisplay ? 22 : 28;
            final double resultFont = compactDisplay ? 38 : 54;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                SingleChildScrollView(
                  reverse: true,
                  scrollDirection: Axis.horizontal,
                  child: Text(
                    _expression.isEmpty ? '0' : _expression,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: expressionFont,
                      fontWeight: FontWeight.w500,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      _result,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: resultFont,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildButtonGrid() {
    return Column(
      children: _buttonRows
          .map(
            (List<String> row) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: row
                      .map(
                        (String label) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: CalculatorButton(
                              label: label,
                              type: _buttonTypeFor(label),
                              onTap: () => _handleTap(label),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  CalculatorButtonType _buttonTypeFor(String label) {
    if (label == '=') {
      return CalculatorButtonType.equals;
    }

    if (<String>['+', '-', '×', '÷'].contains(label)) {
      return CalculatorButtonType.operator;
    }

    if (<String>['C', 'BACK', '%', 'SQRT'].contains(label)) {
      return CalculatorButtonType.action;
    }

    return CalculatorButtonType.digit;
  }

  void _handleTap(String label) {
    setState(() {
      switch (label) {
        case 'C':
          _expression = '';
          _result = '0';
          break;
        case 'BACK':
          _expression = CalculatorLogic.backspace(_expression);
          if (_expression.isEmpty) {
            _result = '0';
          }
          break;
        case '.':
          _expression = CalculatorLogic.appendDecimal(_expression);
          break;
        case '+':
        case '-':
        case '×':
        case '÷':
          _expression = CalculatorLogic.appendOperator(_expression, label);
          break;
        case '%':
          final MutationResult percentResult =
              CalculatorLogic.applyPercent(_expression);
          _expression = percentResult.expression;
          if (percentResult.error != null) {
            _result = percentResult.error!;
          }
          break;
        case 'SQRT':
          final MutationResult sqrtResult =
              CalculatorLogic.applySquareRoot(_expression);
          _expression = sqrtResult.expression;
          if (sqrtResult.error != null) {
            _result = sqrtResult.error!;
          }
          break;
        case '=':
          final EvaluationResult evaluation = CalculatorLogic.evaluate(_expression);
          if (evaluation.error != null) {
            _result = evaluation.error!;
          } else {
            if (_expression.isNotEmpty) {
              _history.insert(0, '$_expression = ${evaluation.value}');
            }
            _result = evaluation.value;
            _expression = evaluation.value;
          }
          break;
        default:
          _expression = CalculatorLogic.appendDigit(_expression, label);
      }
    });
  }

  void _showHistory() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) {
        if (_history.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: Text('No history yet')),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: _history.length,
          separatorBuilder: (_, __) => const Divider(height: 16),
          itemBuilder: (BuildContext context, int index) {
            return Text(
              _history[index],
              style: Theme.of(context).textTheme.titleMedium,
            );
          },
        );
      },
    );
  }
}
