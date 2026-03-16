import 'package:csslib/visitor.dart';

import 'converter.dart';

/// Converts CSS gradient properties to Flutter LinearGradient/RadialGradient/SweepGradient.
///
/// Supports:
/// - `linear-gradient(direction, color-stop, ...)`
/// - `radial-gradient(shape, color-stop, ...)`
/// - `conic-gradient(from angle, color-stop, ...)` → SweepGradient
/// - `repeating-linear-gradient(...)` / `repeating-radial-gradient(...)`
class GradientConverter extends CssPropertyConverter {
  @override
  Set<String> get supportedProperties => {
        'background',
        'background-image',
      };

  @override
  bool canConvert(String property) => supportedProperties.contains(property);

  @override
  ConversionResult convert(Declaration declaration) {
    final property = getPropertyName(declaration);
    final text = getCssValueText(declaration);

    if (!_isGradient(text)) {
      return ConversionResult.unsupported(property);
    }

    final dartCode = _convertGradient(text);
    if (dartCode == null) return ConversionResult.unsupported(property);

    return ConversionResult(property: property, dartCode: 'gradient: $dartCode');
  }

  bool _isGradient(String text) {
    final lower = text.toLowerCase();
    return lower.contains('linear-gradient') ||
        lower.contains('radial-gradient') ||
        lower.contains('conic-gradient');
  }

  String? _convertGradient(String text) {
    final lower = text.toLowerCase().trim();

    if (lower.startsWith('repeating-linear-gradient')) {
      return _convertLinearGradient(text, repeating: true);
    }
    if (lower.startsWith('linear-gradient')) {
      return _convertLinearGradient(text);
    }
    if (lower.startsWith('repeating-radial-gradient')) {
      return _convertRadialGradient(text, repeating: true);
    }
    if (lower.startsWith('radial-gradient')) {
      return _convertRadialGradient(text);
    }
    if (lower.startsWith('repeating-conic-gradient') ||
        lower.startsWith('conic-gradient')) {
      return _convertConicGradient(text);
    }

    return null;
  }

  /// Parse the arguments inside the outermost parentheses of a gradient function.
  String _extractArgs(String text) {
    final openParen = text.indexOf('(');
    final closeParen = text.lastIndexOf(')');
    if (openParen == -1 || closeParen == -1 || closeParen <= openParen) {
      return '';
    }
    return text.substring(openParen + 1, closeParen).trim();
  }

  /// Split top-level comma-separated arguments, respecting nested parentheses.
  List<String> _splitArgs(String args) {
    final result = <String>[];
    var depth = 0;
    var start = 0;
    for (var i = 0; i < args.length; i++) {
      if (args[i] == '(') depth++;
      if (args[i] == ')') depth--;
      if (args[i] == ',' && depth == 0) {
        result.add(args.substring(start, i).trim());
        start = i + 1;
      }
    }
    result.add(args.substring(start).trim());
    return result.where((s) => s.isNotEmpty).toList();
  }

  String? _convertLinearGradient(String text, {bool repeating = false}) {
    final args = _splitArgs(_extractArgs(text));
    if (args.isEmpty) return null;

    String? beginAlign;
    String? endAlign;
    List<String> colorStopArgs;

    // Check if first arg is a direction
    final direction = _parseDirection(args.first);
    if (direction != null) {
      beginAlign = direction.$1;
      endAlign = direction.$2;
      colorStopArgs = args.sublist(1);
    } else {
      beginAlign = 'Alignment.topCenter';
      endAlign = 'Alignment.bottomCenter';
      colorStopArgs = args;
    }

    final colorStops = _parseColorStops(colorStopArgs);
    if (colorStops.colors.isEmpty) return null;

    final parts = <String>[
      'begin: $beginAlign',
      'end: $endAlign',
      'colors: [${colorStops.colors.join(', ')}]',
      if (colorStops.stops.isNotEmpty)
        'stops: [${colorStops.stops.join(', ')}]',
      if (repeating) 'tileMode: TileMode.repeated',
    ];
    return 'LinearGradient(${parts.join(', ')})';
  }

  String? _convertRadialGradient(String text, {bool repeating = false}) {
    final args = _splitArgs(_extractArgs(text));
    if (args.isEmpty) return null;

    List<String> colorStopArgs;

    // Check if first arg is a shape/size keyword (e.g., "circle", "ellipse", "closest-side")
    final first = args.first.toLowerCase().trim();
    if (_isRadialShapeKeyword(first)) {
      colorStopArgs = args.sublist(1);
    } else {
      colorStopArgs = args;
    }

    final colorStops = _parseColorStops(colorStopArgs);
    if (colorStops.colors.isEmpty) return null;

    final parts = <String>[
      'colors: [${colorStops.colors.join(', ')}]',
      if (colorStops.stops.isNotEmpty)
        'stops: [${colorStops.stops.join(', ')}]',
      if (repeating) 'tileMode: TileMode.repeated',
    ];
    return 'RadialGradient(${parts.join(', ')})';
  }

  String? _convertConicGradient(String text) {
    final args = _splitArgs(_extractArgs(text));
    if (args.isEmpty) return null;

    List<String> colorStopArgs;
    String? startAngle;

    // Check for "from <angle>" prefix
    final first = args.first.toLowerCase().trim();
    if (first.startsWith('from ')) {
      startAngle = _parseAngle(first.replaceFirst('from ', '').trim());
      colorStopArgs = args.sublist(1);
    } else {
      colorStopArgs = args;
    }

    final colorStops = _parseColorStops(colorStopArgs);
    if (colorStops.colors.isEmpty) return null;

    final parts = <String>[
      if (startAngle != null) 'startAngle: $startAngle',
      'colors: [${colorStops.colors.join(', ')}]',
      if (colorStops.stops.isNotEmpty)
        'stops: [${colorStops.stops.join(', ')}]',
    ];
    return 'SweepGradient(${parts.join(', ')})';
  }

  /// Parse a CSS direction into Flutter Alignment begin/end.
  (String, String)? _parseDirection(String arg) {
    final lower = arg.toLowerCase().trim();

    // "to <side>" syntax
    if (lower.startsWith('to ')) {
      final target = lower.substring(3).trim();
      return switch (target) {
        'top' => ('Alignment.bottomCenter', 'Alignment.topCenter'),
        'bottom' => ('Alignment.topCenter', 'Alignment.bottomCenter'),
        'left' => ('Alignment.centerRight', 'Alignment.centerLeft'),
        'right' => ('Alignment.centerLeft', 'Alignment.centerRight'),
        'top left' => ('Alignment.bottomRight', 'Alignment.topLeft'),
        'top right' => ('Alignment.bottomLeft', 'Alignment.topRight'),
        'bottom left' => ('Alignment.topRight', 'Alignment.bottomLeft'),
        'bottom right' => ('Alignment.topLeft', 'Alignment.bottomRight'),
        _ => null,
      };
    }

    // Angle syntax (e.g., "180deg", "0.5turn")
    final angle = _parseAngleDeg(lower);
    if (angle != null) {
      return _angleToAlignments(angle);
    }

    return null;
  }

  /// Parse a CSS angle string to degrees.
  double? _parseAngleDeg(String text) {
    final lower = text.trim().toLowerCase();
    if (lower.endsWith('deg')) {
      return double.tryParse(lower.replaceAll('deg', ''));
    }
    if (lower.endsWith('turn')) {
      final turns = double.tryParse(lower.replaceAll('turn', ''));
      return turns != null ? turns * 360 : null;
    }
    if (lower.endsWith('rad')) {
      final rad = double.tryParse(lower.replaceAll('rad', ''));
      return rad != null ? rad * 180 / 3.14159265 : null;
    }
    if (lower.endsWith('grad')) {
      final grad = double.tryParse(lower.replaceAll('grad', ''));
      return grad != null ? grad * 0.9 : null;
    }
    return null;
  }

  /// Parse a CSS angle to a Dart radians expression string.
  String? _parseAngle(String text) {
    final deg = _parseAngleDeg(text);
    if (deg == null) return null;
    final rad = deg * 3.14159265 / 180;
    return rad.toStringAsFixed(4);
  }

  /// Map a CSS gradient angle (in degrees) to Flutter begin/end Alignments.
  /// CSS: 0deg = to top, 90deg = to right, 180deg = to bottom (default).
  (String, String) _angleToAlignments(double deg) {
    // Normalize to 0-360
    deg = deg % 360;
    if (deg < 0) deg += 360;

    return switch (deg) {
      0 => ('Alignment.bottomCenter', 'Alignment.topCenter'),
      45 => ('Alignment.bottomLeft', 'Alignment.topRight'),
      90 => ('Alignment.centerLeft', 'Alignment.centerRight'),
      135 => ('Alignment.topLeft', 'Alignment.bottomRight'),
      180 => ('Alignment.topCenter', 'Alignment.bottomCenter'),
      225 => ('Alignment.topRight', 'Alignment.bottomLeft'),
      270 => ('Alignment.centerRight', 'Alignment.centerLeft'),
      315 => ('Alignment.bottomRight', 'Alignment.topLeft'),
      _ => (
          'Alignment(${_cos(deg).toStringAsFixed(2)}, ${(-_sin(deg)).toStringAsFixed(2)})',
          'Alignment(${(-_cos(deg)).toStringAsFixed(2)}, ${_sin(deg).toStringAsFixed(2)})',
        ),
    };
  }

  double _sin(double deg) {
    const pi = 3.14159265;
    // CSS angle: 0deg = to top (12 o'clock), clockwise.
    // Convert to standard math angle: subtract 90, negate for clockwise.
    final rad = (deg - 90) * pi / 180;
    return _sinRad(rad);
  }

  double _cos(double deg) {
    const pi = 3.14159265;
    final rad = (deg - 90) * pi / 180;
    return _cosRad(rad);
  }

  double _sinRad(double x) {
    // Taylor series approximation, good enough for code generation
    x = x % (2 * 3.14159265);
    double result = 0, term = x;
    for (int n = 1; n <= 10; n++) {
      result += term;
      term *= -x * x / ((2 * n) * (2 * n + 1));
    }
    return result;
  }

  double _cosRad(double x) => _sinRad(x + 3.14159265 / 2);

  bool _isRadialShapeKeyword(String text) {
    final keywords = {
      'circle',
      'ellipse',
      'closest-side',
      'closest-corner',
      'farthest-side',
      'farthest-corner',
    };
    return keywords.any((k) => text.contains(k));
  }

  /// Parse color stops from a list of comma-separated arguments.
  _ColorStops _parseColorStops(List<String> args) {
    final colors = <String>[];
    final stops = <String>[];
    var hasExplicitStops = false;

    for (final arg in args) {
      final parts = arg.trim().split(RegExp(r'\s+'));
      final colorStr = parts.first;
      final dartColor = _colorToDart(colorStr);
      if (dartColor == null) continue;

      colors.add(dartColor);
      if (parts.length > 1) {
        final stop = _parseStopPosition(parts.last);
        if (stop != null) {
          stops.add(stop);
          hasExplicitStops = true;
        }
      } else {
        stops.add(''); // placeholder
      }
    }

    // If some stops are explicit, fill in the blanks with even distribution
    if (hasExplicitStops && stops.length == colors.length) {
      final resolved = <String>[];
      for (var i = 0; i < stops.length; i++) {
        if (stops[i].isNotEmpty) {
          resolved.add(stops[i]);
        } else if (i == 0) {
          resolved.add('0.0');
        } else if (i == stops.length - 1) {
          resolved.add('1.0');
        } else {
          resolved.add((i / (stops.length - 1)).toStringAsFixed(2));
        }
      }
      return _ColorStops(colors, resolved);
    }

    return _ColorStops(colors, []);
  }

  String? _parseStopPosition(String text) {
    if (text.endsWith('%')) {
      final value = double.tryParse(text.replaceAll('%', ''));
      if (value != null) return (value / 100).toStringAsFixed(2);
    }
    return null;
  }

  static const _namedColors = <String, String>{
    'red': 'Colors.red',
    'blue': 'Colors.blue',
    'green': 'Colors.green',
    'yellow': 'Colors.yellow',
    'orange': 'Colors.orange',
    'purple': 'Colors.purple',
    'pink': 'Colors.pink',
    'black': 'Colors.black',
    'white': 'Colors.white',
    'grey': 'Colors.grey',
    'gray': 'Colors.grey',
    'transparent': 'Colors.transparent',
    'cyan': 'Colors.cyan',
    'teal': 'Colors.teal',
    'amber': 'Colors.amber',
    'indigo': 'Colors.indigo',
    'lime': 'Colors.lime',
    'brown': 'Colors.brown',
  };

  String? _colorToDart(String text) {
    final lower = text.toLowerCase().trim();

    // Hex color
    if (lower.startsWith('#')) {
      var hex = lower.substring(1);
      if (hex.length == 3) {
        hex = hex.split('').map((c) => '$c$c').join();
      }
      if (hex.length == 6) return 'Color(0xFF${hex.toUpperCase()})';
      if (hex.length == 8) return 'Color(0x${hex.toUpperCase()})';
    }

    // Named color
    final named = _namedColors[lower];
    if (named != null) return named;

    // rgb/rgba function
    if (lower.startsWith('rgb')) {
      final inner = _extractArgs(lower);
      final values = inner
          .split(RegExp(r'[,/\s]+'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      if (values.length >= 3) {
        final r = values[0], g = values[1], b = values[2];
        if (values.length >= 4) {
          final a = double.tryParse(values[3]) ?? 1.0;
          final alpha = (a <= 1.0 ? a * 255 : a).round();
          return 'Color.fromARGB($alpha, $r, $g, $b)';
        }
        return 'Color.fromARGB(255, $r, $g, $b)';
      }
    }

    return null;
  }
}

class _ColorStops {
  final List<String> colors;
  final List<String> stops;

  _ColorStops(this.colors, this.stops);
}
