import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class MarkdownPreview extends StatelessWidget {
  const MarkdownPreview({
    required this.text,
    required this.label,
    super.key,
  });

  final String text;
  final String label;

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleSmall),
        const Divider(),
        MarkdownBody(data: text),
      ],
    );
  }
}
