import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/app_controller.dart';
import '../models/dispute.dart';

class DisputeScreenArgs {
  const DisputeScreenArgs({
    required this.committeeId,
    required this.committeeName,
  });

  final String committeeId;
  final String committeeName;
}

class DisputeScreen extends StatefulWidget {
  const DisputeScreen({
    super.key,
    required this.committeeId,
    required this.committeeName,
  });

  final String committeeId;
  final String committeeName;

  @override
  State<DisputeScreen> createState() => _DisputeScreenState();
}

class _DisputeScreenState extends State<DisputeScreen> {
  final _reasonController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _raiseDispute(BuildContext context) async {
    final controller = context.read<AppController>();
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      _snack(context, 'Enter dispute reason.');
      return;
    }
    setState(() => _submitting = true);
    try {
      await controller.raiseDispute(
        committeeId: widget.committeeId,
        reason: reason,
      );
      _reasonController.clear();
      if (context.mounted) {
        _snack(context, 'Dispute raised.');
      }
    } catch (error) {
      if (context.mounted) {
        _snack(context, error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();
    return Scaffold(
      appBar: AppBar(title: Text('${widget.committeeName} Disputes')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    TextField(
                      controller: _reasonController,
                      decoration: const InputDecoration(
                        labelText: 'Reason',
                      ),
                      minLines: 3,
                      maxLines: 4,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _submitting
                            ? null
                            : () => _raiseDispute(context),
                        child: _submitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Raise Dispute'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Dispute>>(
              stream: controller.disputesStream(widget.committeeId),
              builder: (context, snapshot) {
                final disputes = snapshot.data ?? const <Dispute>[];
                if (disputes.isEmpty) {
                  return const Center(child: Text('No disputes yet.'));
                }
                return ListView.builder(
                  itemCount: disputes.length,
                  itemBuilder: (context, index) {
                    final dispute = disputes[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      child: ListTile(
                        title: Text(dispute.reason),
                        subtitle: Text(
                          'Status: ${dispute.status.name.toUpperCase()}\n'
                          'Admin: ${dispute.adminResolution.isEmpty ? 'Pending' : dispute.adminResolution}',
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
