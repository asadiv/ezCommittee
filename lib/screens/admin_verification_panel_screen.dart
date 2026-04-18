import 'dart:convert';
import 'dart:typed_data';

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
                      if (user.cnicFrontUrl.isNotEmpty)
                        _AdminImagePreview(
                          title: 'CNIC Front',
                          encodedData: user.cnicFrontUrl,
                        ),
                      if (user.cnicBackUrl.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _AdminImagePreview(
                          title: 'CNIC Back',
                          encodedData: user.cnicBackUrl,
                        ),
                      ],
                      if (user.selfieUrl.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _AdminImagePreview(
                          title: 'Selfie',
                          encodedData: user.selfieUrl,
                        ),
                      ],
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

class _AdminImagePreview extends StatelessWidget {
  const _AdminImagePreview({required this.title, required this.encodedData});

  final String title;
  final String encodedData;

  @override
  Widget build(BuildContext context) {
    final looksLikeUrl = encodedData.startsWith('http://') ||
        encodedData.startsWith('https://');
    final bytes = looksLikeUrl ? null : _decodeSafe(encodedData);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: looksLikeUrl
              ? Image.network(
                  encodedData,
                  width: double.infinity,
                  height: 160,
                  fit: BoxFit.cover,
                )
              : bytes == null
              ? Container(
                  width: double.infinity,
                  height: 88,
                  padding: const EdgeInsets.all(12),
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: const Text('Preview unavailable'),
                )
              : Image.memory(
                  bytes,
                  width: double.infinity,
                  height: 160,
                  fit: BoxFit.cover,
                ),
        ),
      ],
    );
  }

  Uint8List? _decodeSafe(String encoded) {
    if (encoded.isEmpty) {
      return null;
    }
    try {
      return base64Decode(encoded);
    } catch (_) {
      return null;
    }
  }
}
