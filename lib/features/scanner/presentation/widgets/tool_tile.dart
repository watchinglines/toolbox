// lib/features/scanner/presentation/widgets/tool_tile.dart
// 工具磁贴
import 'package:flutter/material.dart';

import '../../../../design_system/tokens.dart';

class ToolTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final String? route;

  const ToolTile({
    super.key,
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    this.route,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = route != null;
    final disabledSurface = Theme.of(context).colorScheme.surface.withOpacity(0.5);
    return Material(
      color: enabled ? Theme.of(context).colorScheme.surface : disabledSurface,
      borderRadius: BorderRadius.circular(TBRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(TBRadius.lg),
        onTap: enabled ? () => Navigator.pushNamed(context, route!) : null,
        child: Container(
          padding: const EdgeInsets.all(TBSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(TBRadius.lg),
            border: Border.all(color: Colors.black.withOpacity(0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(TBRadius.md),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(height: TBSpacing.sm),
              Text(
                label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
