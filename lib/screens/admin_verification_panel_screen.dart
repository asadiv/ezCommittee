import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/app_controller.dart';
import '../models/app_user.dart';

class AdminVerificationPanelScreen extends StatelessWidget {
  const AdminVerificationPanelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Verification Panel')),
      body: StreamBuilder<List<AppUser>>(
        stream: app.pendingVerificationUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final users = snapshot.data ?? const <AppUser>[];
          if (users.isEmpty) {
            return const Center(
              child: Text('No users pending verification review.'),
            );
          }
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName.isEmpty
                            ? user.phoneNumber
                            : user.fullName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text('Phone: ${user.phoneNumber}'),
                      Text(
                        'CNIC Front: ${user.cnicFrontUrl.isNotEmpty ? 'Uploaded' : 'Missing'}',
                      ),
                      Text(
                        'CNIC Back: ${user.cnicBackUrl.isNotEmpty ? 'Uploaded' : 'Missing'}',
                      ),
                      Text(
                        'Selfie: ${user.selfieUrl.isNotEmpty ? 'Uploaded' : 'Missing'}',
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: [
                          FilledButton(
                            onPressed: () => app.updateVerificationStatus(
                              uid: user.uid,
                              status: VerificationStatus.approved,
                            ),
                            child: const Text('Approve'),
                          ),
                          OutlinedButton(
                            onPressed: () => app.updateVerificationStatus(
                              uid: user.uid,
                              status: VerificationStatus.rejected,
                            ),
                            child: const Text('Reject'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
