import 'dart:async';

import 'package:code_forge_web/code_forge_web.dart';
import 'package:flutter/material.dart';
import 'package:re_highlight/languages/css.dart';
import 'package:re_highlight/languages/dart.dart';
import 'package:re_highlight/styles/tokyo-night-dark.dart';

import '../converters/css_to_dart_converter.dart';

const _defaultCss = '''.container {
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  width: 300px;
  height: 200px;
  padding: 16px 24px;
  margin: 8px;
  background: linear-gradient(135deg, #1E1E2E, #313244);
  color: white;
  font-size: 16px;
  font-weight: bold;
  border-radius: 12px;
  box-shadow: 2px 4px 8px 0px;
  opacity: 0.95;
}

.title {
  font-size: 24px;
  font-weight: 700;
  color: #CDD6F4;
  text-align: center;
  letter-spacing: 1.5px;
  text-decoration: underline;
}

.hero {
  background: radial-gradient(circle, #CBA6F7, #89B4FA, #1E1E2E);
  width: 400px;
  height: 300px;
  border-radius: 16px;
}
''';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _converter = CssToDartConverter();
  late final CodeForgeWebController _cssController;
  Timer? _debounce;
  List<ConvertedBlock> _blocks = [];

  @override
  void initState() {
    super.initState();
    _cssController = CodeForgeWebController();
    _cssController.text = _defaultCss;
    _cssController.addListener(_onCssChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _convertCss());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _cssController.removeListener(_onCssChanged);
    _cssController.dispose();
    super.dispose();
  }

  void _onCssChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), _convertCss);
  }

  void _convertCss() {
    setState(() {
      _blocks = _converter.convert(_cssController.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1B26),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16161E),
        title: const Row(
          children: [
            Icon(Icons.transform, color: Color(0xFFBB9AF7)),
            SizedBox(width: 8),
            Text(
              'CSS to Flutter',
              style: TextStyle(
                color: Color(0xFFC0CAF5),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(child: _buildInputPanel()),
            const SizedBox(width: 12),
            Expanded(child: _buildOutputPanels()),
          ],
        ),
      ),
    );
  }

  Widget _buildInputPanel() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1B26),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF414868)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPanelHeader('CSS Input', Icons.edit, const Color(0xFF7AA2F7)),
          Expanded(
            child: CodeForgeWeb(
              controller: _cssController,
              language: langCss,
              editorTheme: tokyoNightDarkTheme,
              textStyle: const TextStyle(
                fontFamily: 'JetBrains Mono, Fira Code, monospace',
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutputPanels() {
    if (_blocks.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1B26),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF414868)),
        ),
        child: const Center(
          child: Text(
            'Write some CSS to see the output',
            style: TextStyle(color: Color(0xFF414868), fontSize: 13),
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: _blocks.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _OutputBlock(
        block: _blocks[index],
        editorTheme: tokyoNightDarkTheme,
      ),
    );
  }

  Widget _buildPanelHeader(String title, IconData icon, Color iconColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF16161E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFFC0CAF5),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _OutputBlock extends StatefulWidget {
  final ConvertedBlock block;
  final Map<String, TextStyle> editorTheme;

  const _OutputBlock({required this.block, required this.editorTheme});

  @override
  State<_OutputBlock> createState() => _OutputBlockState();
}

class _OutputBlockState extends State<_OutputBlock> {
  late final CodeForgeWebController _controller;

  @override
  void initState() {
    super.initState();
    _controller = CodeForgeWebController();
    _controller.text = widget.block.dartCode;
  }

  @override
  void didUpdateWidget(covariant _OutputBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.block.dartCode != widget.block.dartCode) {
      _controller.text = widget.block.dartCode;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lineCount = widget.block.dartCode.split('\n').length;
    final editorHeight = (lineCount * 19.5 + 24).clamp(60.0, 600.0);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1B26),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF414868)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF16161E),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                const Icon(Icons.output, size: 16, color: Color(0xFF9ECE6A)),
                const SizedBox(width: 8),
                Text(
                  widget.block.selector,
                  style: const TextStyle(
                    color: Color(0xFFC0CAF5),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: editorHeight,
            child: CodeForgeWeb(
              controller: _controller,
              language: langDart,
              editorTheme: widget.editorTheme,
              readOnly: true,
              textStyle: const TextStyle(
                fontFamily: 'JetBrains Mono, Fira Code, monospace',
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
