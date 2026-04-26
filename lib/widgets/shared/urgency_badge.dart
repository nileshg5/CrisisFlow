import 'package:flutter/material.dart';
import '../../core/theme.dart';

class UrgencyBadge extends StatelessWidget {
  final String label;

  const UrgencyBadge({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (label.toLowerCase()) {
      case 'critical':
        color = AppColors.criticalRed;
        break;
      case 'high':
      case 'medium':
        color = AppColors.warningAmber;
        break;
      case 'normal':
      case 'low':
        color = AppColors.safeGreen;
        break;
      default:
        color = AppColors.outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(4),
        boxShadow: label.toLowerCase() == 'critical'
            ? [BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 10)]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (label.toLowerCase() == 'critical') ...[
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label.toUpperCase(),
            style: AppTextStyles.labelCaps(color: color).copyWith(fontSize: 10),
          ),
        ],
      ),
    );
  }
}
