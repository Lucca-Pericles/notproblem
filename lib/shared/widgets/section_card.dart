import 'package:flutter/material.dart';

import '../../core/constants/app_spacing.dart';

class SectionCard extends StatelessWidget {
  const SectionCard({
    required this.child,
    this.title,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    super.key,
  });

  final String? title;
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Text(title!, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.lg),
            ],
            child,
          ],
        ),
      ),
    );
  }
}
