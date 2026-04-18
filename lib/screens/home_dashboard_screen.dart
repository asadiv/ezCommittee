import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/app_routes.dart';
import '../controllers/app_controller.dart';
import '../models/committee.dart';

class HomeDashboardScreen extends StatelessWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppController>(
      builder: (context, controller, _) {
        final user = controller.appUser;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Digital Committee'),
            actions: [
              IconButton(
                tooltip: 'Trust profile',
                onPressed: () =>
                    Navigator.of(context).pushNamed(AppRoutes.trustProfile),
                icon: const Icon(Icons.verified_user),
              ),
              IconButton(
                tooltip: 'Admin panel',
                onPressed: user?.isAdmin == true
                    ? () =>
                          Navigator.of(context).pushNamed(AppRoutes.adminPanel)
                    : null,
                icon: const Icon(Icons.admin_panel_settings),
              ),
              IconButton(
                tooltip: 'Sign out',
                onPressed: controller.signOut,
                icon: const Icon(Icons.logout),
              ),
            ],
          ),
          body: StreamBuilder<List<Committee>>(
            stream: controller.committeesStream(),
            builder: (context, snapshot) {
              final committees = snapshot.data ?? const <Committee>[];
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: ListTile(
                      title: Text(
                        user == null
                            ? 'Loading profile...'
                            : user.fullName.isEmpty
                            ? user.phoneNumber
                            : user.fullName,
                      ),
                      subtitle: Text(
                        user == null
                            ? ''
                            : 'Verification: ${user.verificationStatus.name.toUpperCase()}',
                      ),
                      trailing: Text(
                        'Trust ${user?.trustScore.toStringAsFixed(0) ?? '0'}%',
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => Navigator.of(
                          context,
                        ).pushNamed(AppRoutes.createCommittee),
                        icon: const Icon(Icons.add),
                        label: const Text('Create Committee'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => Navigator.of(
                          context,
                        ).pushNamed(AppRoutes.joinCommittee),
                        icon: const Icon(Icons.group_add),
                        label: const Text('Join by Code'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your Committees',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  if (snapshot.connectionState == ConnectionState.waiting)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  if (snapshot.connectionState != ConnectionState.waiting &&
                      committees.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'No committees yet. Create one or join with an invite code.',
                        ),
                      ),
                    ),
                  ...committees.map(
                    (committee) => _CommitteeCard(
                      committee: committee,
                      onOpen: () => Navigator.of(context).pushNamed(
                        AppRoutes.groupDashboard,
                        arguments: committee.id,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _CommitteeCard extends StatelessWidget {
  const _CommitteeCard({required this.committee, required this.onOpen});

  final Committee committee;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    committee.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Chip(label: Text(committee.state.name.toUpperCase())),
              ],
            ),
            Text(
              'Invite: ${committee.inviteCode} | Members ${committee.memberCount}/${committee.memberLimit}',
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: committee.progressPercent()),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Interval ${committee.currentInterval}/${committee.totalIntervals}',
                ),
                const Spacer(),
                Text('PKR ${committee.contributionAmount.toStringAsFixed(0)}'),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(onPressed: onOpen, child: const Text('Open')),
            ),
          ],
        ),
      ),
    );
  }
}
