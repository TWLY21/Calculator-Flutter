class MutationResult {
  const MutationResult({required this.expression, this.error});

  final String expression;
  final String? error;
}

class EvaluationResult {
  const EvaluationResult({required this.value, this.error});

  final String value;
  final String? error;
}

class CalculatorLogic {
  static const List<String> _operators = ['+', '-', '×', '÷'];

  static bool _isOperator(String value) => _operators.contains(value);

  static bool _isDigit(String value) => RegExp(r'^\d$').hasMatch(value);

  static String appendDigit(String expression, String digit) {
    if (!_isDigit(digit)) {
      return expression;
    }

    if (expression == '0') {
      return digit;
    }

    if (expression == '-0') {
      return '-$digit';
    }

    return expression + digit;
  }

  static String appendOperator(String expression, String operator) {
    if (!_isOperator(operator)) {
      return expression;
    }

    if (expression.isEmpty) {
      return operator == '-' ? operator : expression;
    }

    final String last = expression[expression.length - 1];

    if (_isOperator(last)) {
      if (expression.length == 1 && last == '-') {
        return expression;
      }

      return expression.substring(0, expression.length - 1) + operator;
    }

    if (last == '.') {
      return expression + '0' + operator;
    }

    return expression + operator;
  }

  static String appendDecimal(String expression) {
    if (expression.isEmpty || expression == '-') {
      return '${expression}0.';
    }

    final String last = expression[expression.length - 1];

    if (_isOperator(last)) {
      return expression + '0.';
    }

    final String currentNumber = _currentNumber(expression);

    if (currentNumber.contains('.')) {
      return expression;
    }

    return expression + '.';
  }

  static String backspace(String expression) {
    if (expression.isEmpty) {
      return expression;
    }

    return expression.substring(0, expression.length - 1);
  }

  static MutationResult applyPercent(String expression) {
    final Segment? segment = _findEditableSegment(expression);
    if (segment == null) {
      return MutationResult(expression: expression);
    }

    final double? value = double.tryParse(segment.value);
    if (value == null) {
      return MutationResult(expression: expression);
    }

    final String updated = _replaceSegment(
      expression,
      segment,
      _formatNumber(value / 100),
    );

    return MutationResult(expression: updated);
  }

  static MutationResult applySquareRoot(String expression) {
    final Segment? segment = _findEditableSegment(expression);
    if (segment == null) {
      return MutationResult(expression: expression);
    }

    final double? value = double.tryParse(segment.value);
    if (value == null) {
      return MutationResult(expression: expression);
    }

    if (value < 0) {
      return MutationResult(
        expression: expression,
        error: 'Square root requires a positive number',
      );
    }

    final String updated = _replaceSegment(
      expression,
      segment,
      _formatNumber(_sqrtNewton(value)),
    );

    return MutationResult(expression: updated);
  }

  static EvaluationResult evaluate(String expression) {
    final String sanitized = _sanitizeTrailingTokens(expression);

    if (sanitized.isEmpty) {
      return const EvaluationResult(value: '0');
    }

    try {
      final List<String> tokens = _tokenize(sanitized);
      if (tokens.isEmpty) {
        return const EvaluationResult(value: '0');
      }

      final List<double> values = <double>[];
      final List<String> operators = <String>[];

      for (final String token in tokens) {
        if (_isMathOperator(token)) {
          while (operators.isNotEmpty &&
              _precedence(operators.last) >= _precedence(token)) {
            _applyTopOperator(values, operators);
          }
          operators.add(token);
        } else {
          final double? parsed = double.tryParse(token);
          if (parsed == null) {
            return const EvaluationResult(value: 'Error', error: 'Invalid input');
          }
          values.add(parsed);
        }
      }

      while (operators.isNotEmpty) {
        _applyTopOperator(values, operators);
      }

      if (values.length != 1) {
        return const EvaluationResult(value: 'Error', error: 'Invalid expression');
      }

      return EvaluationResult(value: _formatNumber(values.single));
    } on _DivisionByZeroException {
      return const EvaluationResult(
        value: 'Error',
        error: 'Cannot divide by zero',
      );
    } catch (_) {
      return const EvaluationResult(value: 'Error', error: 'Calculation failed');
    }
  }

  static String _sanitizeTrailingTokens(String expression) {
    String output = expression;

    while (output.isNotEmpty) {
      final String tail = output[output.length - 1];
      if (_isOperator(tail) || tail == '.') {
        output = output.substring(0, output.length - 1);
      } else {
        break;
      }
    }

    return output;
  }

  static String _currentNumber(String expression) {
    int index = expression.length - 1;

    while (index >= 0) {
      final String char = expression[index];

      if (_isOperator(char)) {
        final bool isUnaryMinus =
            char == '-' && (index == 0 || _isOperator(expression[index - 1]));

        if (!isUnaryMinus) {
          break;
        }
      }

      index--;
    }

    return expression.substring(index + 1);
  }

  static Segment? _findEditableSegment(String expression) {
    if (expression.isEmpty) {
      return null;
    }

    int end = expression.length;
    int index = end - 1;

    while (index >= 0) {
      final String char = expression[index];

      if (_isOperator(char)) {
        final bool isUnaryMinus =
            char == '-' && (index == 0 || _isOperator(expression[index - 1]));

        if (!isUnaryMinus) {
          break;
        }
      }

      index--;
    }

    final int start = index + 1;
    if (start >= end) {
      return null;
    }

    final String value = expression.substring(start, end);
    if (value == '-' || value.isEmpty) {
      return null;
    }

    return Segment(start: start, end: end, value: value);
  }

  static String _replaceSegment(String expression, Segment segment, String value) {
    return expression.substring(0, segment.start) +
        value +
        expression.substring(segment.end);
  }

  static List<String> _tokenize(String expression) {
    final List<String> tokens = <String>[];
    final StringBuffer numberBuffer = StringBuffer();

    for (int i = 0; i < expression.length; i++) {
      final String char = expression[i];

      if (_isOperator(char)) {
        final bool isUnaryMinus =
            char == '-' && (i == 0 || _isOperator(expression[i - 1]));

        if (isUnaryMinus) {
          numberBuffer.write(char);
          continue;
        }

        if (numberBuffer.length > 0) {
          tokens.add(numberBuffer.toString());
          numberBuffer.clear();
        }

        tokens.add(_toMathOperator(char));
      } else {
        numberBuffer.write(char);
      }
    }

    if (numberBuffer.length > 0) {
      tokens.add(numberBuffer.toString());
    }

    return tokens;
  }

  static String _toMathOperator(String char) {
    if (char == '×') {
      return '*';
    }

    if (char == '÷') {
      return '/';
    }

    return char;
  }

  static bool _isMathOperator(String token) {
    return token == '+' || token == '-' || token == '*' || token == '/';
  }

  static int _precedence(String operator) {
    if (operator == '+' || operator == '-') {
      return 1;
    }

    return 2;
  }

  static void _applyTopOperator(List<double> values, List<String> operators) {
    if (values.length < 2 || operators.isEmpty) {
      throw StateError('Invalid expression');
    }

    final double right = values.removeLast();
    final double left = values.removeLast();
    final String operator = operators.removeLast();

    switch (operator) {
      case '+':
        values.add(left + right);
        break;
      case '-':
        values.add(left - right);
        break;
      case '*':
        values.add(left * right);
        break;
      case '/':
        if (right == 0) {
          throw _DivisionByZeroException();
        }
        values.add(left / right);
        break;
      default:
        throw StateError('Unknown operator');
    }
  }

  static String _formatNumber(double value) {
    double output = value;

    if (output == -0.0) {
      output = 0.0;
    }

    if (output % 1 == 0) {
      return output.toInt().toString();
    }

    final String fixed = output.toStringAsFixed(10);
    return fixed.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  }

  // Newton's method keeps this dependency-free and beginner-friendly.
  static double _sqrtNewton(double value) {
    if (value == 0) {
      return 0;
    }

    double guess = value;
    for (int i = 0; i < 12; i++) {
      guess = (guess + value / guess) / 2;
    }

    return guess;
  }
}

class Segment {
  const Segment({required this.start, required this.end, required this.value});

  final int start;
  final int end;
  final String value;
}

class _DivisionByZeroException implements Exception {}
