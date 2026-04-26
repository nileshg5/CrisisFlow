import 'package:flutter/material.dart';
import '../../core/theme.dart';

class StatusChip extends StatelessWidget {
  final String status;

  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData? icon;
    String label;

    switch (status.toLowerCase()) {
      case 'pending':
      case 'unassigned':
        color = AppColors.criticalRed;
        icon = Icons.pending_outlined;
        label = 'PENDING';
        break;
      case 'in_progress':
      case 'matched':
        color = AppColors.warningAmber;
        icon = Icons.sync;
        label = 'IN PROGRESS';
        break;
      case 'scheduled':
        color = AppColors.outline;
        icon = Icons.schedule;
        label = 'SCHEDULED';
        break;
      case 'completed':
      case 'done':
        color = AppColors.safeGreen;
        icon = Icons.task_alt;
        label = 'COMPLETED';
        break;
      default:
        color = AppColors.outline;
        label = status.toUpperCase();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
        ],
        Text(
          label,
          style: AppTextStyles.labelCaps(color: color),
        ),
      ],
    );
  }
}
