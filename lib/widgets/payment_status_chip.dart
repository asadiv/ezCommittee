import 'package:flutter/material.dart';

import '../models/payment_record.dart';

class PaymentStatusChip extends StatelessWidget {
  const PaymentStatusChip({super.key, required this.status});

  final PaymentStatus status;

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      PaymentStatus.pendingVerification => (Colors.orange, 'Pending'),
      PaymentStatus.verified => (Colors.green, 'Paid'),
      PaymentStatus.rejected => (Colors.red, 'Rejected'),
      PaymentStatus.unpaid => (Colors.grey, 'Unpaid'),
    };
    return Chip(
      label: Text(label),
      backgroundColor: color.withValues(alpha: 0.16),
      side: BorderSide(color: color),
    );
  }
}
