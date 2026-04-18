import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/app_controller.dart';
import '../widgets/app_scaffold.dart';

class TrustProfileScreen extends StatelessWidget {
  const TrustProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppController>(
      builder: (context, app, _) {
        final user = app.appUser;
        return AppScaffold(
          title: 'Trust Profile',
          body: user == null
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          user.fullName.isEmpty
                              ? user.phoneNumber
                              : user.fullName,
                        ),
                        subtitle: Text(user.phoneNumber),
                        trailing: CircleAvatar(
                          backgroundColor: Colors.blue.shade100,
                          child: Text('${user.trustScore.toStringAsFixed(0)}%'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              _MetricRow(
                                label: 'On-time payment',
                                value: '${user.onTimeRate.toStringAsFixed(1)}%',
                                color: Colors.green,
                              ),
                              const SizedBox(height: 12),
                              _MetricRow(
                                label: 'Late payment',
                                value: '${user.lateRate.toStringAsFixed(1)}%',
                                color: Colors.orange,
                              ),
                              const SizedBox(height: 12),
                              _MetricRow(
                                label: 'Missed intervals',
                                value: '${user.missedIntervals}',
                                color: user.missedIntervals >= 3
                                    ? Colors.red
                                    : Colors.blueGrey,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (user.atRisk)
                        const Card(
                          color: Color(0xFFFFEDED),
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: Text(
                              'This account is marked at risk due to repeated missed payments. Joining new committees may be restricted.',
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
        );
      },
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        Text(
          value,
          style: TextStyle(color: color, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
