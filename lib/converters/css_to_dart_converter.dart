import 'package:csslib/parser.dart' as css;
import 'package:csslib/visitor.dart';

import 'converter.dart';
import 'converter_registry.dart';

/// A single converted CSS rule with its selector and grouped Dart output.
class ConvertedBlock {
  final String selector;
  final String dartCode;

  const ConvertedBlock({required this.selector, required this.dartCode});
}

/// Main engine that parses CSS and converts it to Flutter/Dart code.
class CssToDartConverter {
  final ConverterRegistry _registry;

  CssToDartConverter({ConverterRegistry? registry})
      : _registry = registry ?? ConverterRegistry();

  /// Parse CSS input and return a list of converted blocks, one per rule.
  List<ConvertedBlock> convert(String cssInput) {
    if (cssInput.trim().isEmpty) return [];

    try {
      final stylesheet = css.parse(cssInput);
      return _visitStyleSheet(stylesheet);
    } catch (e) {
      return [
        ConvertedBlock(selector: 'Error', dartCode: '// Error parsing CSS:\n// $e'),
      ];
    }
  }

  List<ConvertedBlock> _visitStyleSheet(StyleSheet stylesheet) {
    final blocks = <ConvertedBlock>[];
    for (final node in stylesheet.topLevels) {
      if (node is RuleSet) {
        final block = _visitRuleSet(node);
        if (block != null) blocks.add(block);
      } else if (node is MediaDirective) {
        blocks.addAll(_visitMediaDirective(node));
      } else if (node is FontFaceDirective) {
        blocks.add(ConvertedBlock(
          selector: '@font-face',
          dartCode: '// Register fonts in pubspec.yaml instead',
        ));
      } else if (node is KeyFrameDirective) {
        blocks.add(ConvertedBlock(
          selector: '@keyframes ${node.name?.name ?? ''}',
          dartCode: '// Use AnimationController + Tween',
        ));
      }
    }
    return blocks;
  }

  ConvertedBlock? _visitRuleSet(RuleSet ruleSet) {
    final selector = _selectorToString(ruleSet.selectorGroup);
    final declarations = ruleSet.declarationGroup.declarations
        .whereType<Declaration>()
        .toList();

    if (declarations.isEmpty) return null;

    final textStyleProps = <ConversionResult>[];
    final containerProps = <ConversionResult>[];
    final decorationProps = <ConversionResult>[];
    final layoutProps = <ConversionResult>[];
    final unsupported = <String>[];

    for (final decl in declarations) {
      String property;
      try {
        property = decl.property;
      } catch (_) {
        continue;
      }
      final converter = _registry.findConverter(property);

      if (converter == null) {
        unsupported.add(property);
        continue;
      }

      final result = converter.convert(decl);
      if (!result.supported) {
        unsupported.add(property);
        continue;
      }

      if (_isTextStyleProperty(property)) {
        textStyleProps.add(result);
      } else if (_isLayoutProperty(property)) {
        layoutProps.add(result);
      } else if (_isDecorationProperty(property)) {
        decorationProps.add(result);
      } else {
        containerProps.add(result);
      }
    }

    final buffer = StringBuffer();

    if (textStyleProps.isNotEmpty) {
      buffer.writeln('// TextStyle');
      for (final prop in textStyleProps) {
        buffer.writeln('${prop.dartCode},');
      }
    }

    if (layoutProps.isNotEmpty) {
      if (buffer.isNotEmpty) buffer.writeln();
      buffer.writeln('// Layout');
      for (final prop in layoutProps) {
        buffer.writeln('${prop.dartCode},');
      }
    }

    if (containerProps.isNotEmpty) {
      if (buffer.isNotEmpty) buffer.writeln();
      buffer.writeln('// Container');
      for (final prop in containerProps) {
        buffer.writeln('${prop.dartCode},');
      }
    }

    if (decorationProps.isNotEmpty) {
      if (buffer.isNotEmpty) buffer.writeln();
      buffer.writeln('// BoxDecoration');
      for (final prop in decorationProps) {
        buffer.writeln('${prop.dartCode},');
      }
    }

    if (unsupported.isNotEmpty) {
      if (buffer.isNotEmpty) buffer.writeln();
      buffer.writeln('// Unsupported: ${unsupported.join(', ')}');
    }

    if (buffer.isEmpty) return null;

    return ConvertedBlock(
      selector: selector,
      dartCode: buffer.toString().trimRight(),
    );
  }

  List<ConvertedBlock> _visitMediaDirective(MediaDirective node) {
    final blocks = <ConvertedBlock>[];
    for (final rule in node.rules) {
      if (rule is RuleSet) {
        final block = _visitRuleSet(rule);
        if (block != null) {
          blocks.add(ConvertedBlock(
            selector: '${block.selector} (@media)',
            dartCode: block.dartCode,
          ));
        }
      }
    }
    return blocks;
  }

  String _selectorToString(SelectorGroup? group) {
    if (group == null) return '';
    return group.selectors.map((s) {
      return s.simpleSelectorSequences.map((seq) {
        final selector = seq.simpleSelector;
        if (selector is ClassSelector) return '.${selector.name}';
        if (selector is IdSelector) return '#${selector.name}';
        if (selector is ElementSelector) return selector.name;
        return selector.name.toString();
      }).join('');
    }).join(', ');
  }

  bool _isTextStyleProperty(String property) {
    return {
      'font-size',
      'font-weight',
      'font-style',
      'font-family',
      'text-decoration',
      'letter-spacing',
      'word-spacing',
      'line-height',
      'color',
    }.contains(property);
  }

  bool _isLayoutProperty(String property) {
    return {
      'display',
      'flex-direction',
      'justify-content',
      'align-items',
      'align-self',
      'flex-wrap',
      'flex',
      'flex-grow',
      'flex-shrink',
      'gap',
      'row-gap',
      'column-gap',
      'position',
      'top',
      'right',
      'bottom',
      'left',
      'z-index',
      'inset',
    }.contains(property);
  }

  bool _isDecorationProperty(String property) {
    return {
      'background-color',
      'border',
      'border-radius',
      'border-color',
      'border-width',
      'border-style',
      'border-top-left-radius',
      'border-top-right-radius',
      'border-bottom-left-radius',
      'border-bottom-right-radius',
      'box-shadow',
      'background',
      'background-image',
    }.contains(property);
  }
}
