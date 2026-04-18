import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/app_controller.dart';
import '../widgets/app_scaffold.dart';

class JoinCommitteeScreen extends StatefulWidget {
  const JoinCommitteeScreen({super.key});

  @override
  State<JoinCommitteeScreen> createState() => _JoinCommitteeScreenState();
}

class _JoinCommitteeScreenState extends State<JoinCommitteeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _inviteCodeController = TextEditingController();
  bool _joining = false;

  @override
  void dispose() {
    _inviteCodeController.dispose();
    super.dispose();
  }

  Future<void> _submit(AppController controller) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _joining = true);
    await controller.joinCommittee(_inviteCodeController.text.trim());
    if (!mounted) {
      return;
    }
    setState(() => _joining = false);
    if (controller.errorMessage == null) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Joined committee successfully.')),
      );
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(controller.errorMessage!)));
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.read<AppController>();
    return AppScaffold(
      title: 'Join Committee',
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Join with Invite Code',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _inviteCodeController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'Invite Code',
                        hintText: 'e.g. 12AB34CD',
                        prefixIcon: Icon(Icons.vpn_key_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Invite code is required.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _joining ? null : () => _submit(controller),
                        icon: _joining
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.group_add_outlined),
                        label: Text(_joining ? 'Joining...' : 'Join Committee'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
