import 'package:flutter/material.dart';

import 'chart_styles.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: ChartStyles.chartTitleStyle(context)),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(subtitle!, style: ChartStyles.chartSubtitleStyle(context)),
        ],
      ],
    );
  }
}
