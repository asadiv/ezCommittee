import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/app_controller.dart';
import '../models/committee_enums.dart';
import '../widgets/app_scaffold.dart';

class CreateCommitteeScreen extends StatefulWidget {
  const CreateCommitteeScreen({super.key});

  @override
  State<CreateCommitteeScreen> createState() => _CreateCommitteeScreenState();
}

class _CreateCommitteeScreenState extends State<CreateCommitteeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _amount = TextEditingController(text: '5000');
  final _intervals = TextEditingController(text: '12');
  final _members = TextEditingController(text: '12');
  final _customFrequency = TextEditingController();
  final _easypaisa = TextEditingController();
  final _jazzCash = TextEditingController();
  final _bank = TextEditingController();
  CommitteeFrequency _frequency = CommitteeFrequency.monthly;
  bool _loading = false;

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    _intervals.dispose();
    _members.dispose();
    _customFrequency.dispose();
    _easypaisa.dispose();
    _jazzCash.dispose();
    _bank.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _loading = true);
    final ctrl = context.read<AppController>();
    await ctrl.createCommittee(
      name: _name.text.trim(),
      amount: double.parse(_amount.text.trim()),
      frequency: _frequency,
      totalIntervals: int.parse(_intervals.text.trim()),
      members: int.parse(_members.text.trim()),
      customFrequencyLabel: _frequency == CommitteeFrequency.custom
          ? _customFrequency.text.trim()
          : '',
      paymentInstructions: {
        'easypaisa': _easypaisa.text.trim(),
        'jazzCash': _jazzCash.text.trim(),
        'bank': _bank.text.trim(),
      },
    );
    if (!mounted) {
      return;
    }
    setState(() => _loading = false);
    if (ctrl.errorMessage == null) {
      Navigator.pop(context);
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(ctrl.errorMessage!)));
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Create Committee',
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
                      'Committee Details',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _name,
                      decoration: const InputDecoration(
                        labelText: 'Committee name',
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _amount,
                      decoration: const InputDecoration(
                        labelText: 'Contribution amount',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        final amount = double.tryParse(v ?? '');
                        if (amount == null || amount <= 0) {
                          return 'Enter valid amount';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<CommitteeFrequency>(
                      initialValue: _frequency,
                      decoration: const InputDecoration(labelText: 'Frequency'),
                      items: CommitteeFrequency.values
                          .map(
                            (f) => DropdownMenuItem(
                              value: f,
                              child: Text(f.name.toUpperCase()),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _frequency = v ?? _frequency),
                    ),
                    if (_frequency == CommitteeFrequency.custom) ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _customFrequency,
                        decoration: const InputDecoration(
                          labelText: 'Custom frequency label',
                        ),
                        validator: (v) =>
                            _frequency == CommitteeFrequency.custom &&
                                (v == null || v.trim().isEmpty)
                            ? 'Required'
                            : null,
                      ),
                    ],
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _intervals,
                      decoration: const InputDecoration(
                        labelText: 'Total cycle intervals',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        final parsed = int.tryParse(v ?? '');
                        if (parsed == null || parsed <= 0) {
                          return 'Enter valid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _members,
                      decoration: const InputDecoration(
                        labelText: 'Number of members',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        final parsed = int.tryParse(v ?? '');
                        if (parsed == null || parsed < 2) {
                          return 'Minimum 2 members';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payment Instructions',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _easypaisa,
                      decoration: const InputDecoration(
                        labelText: 'Easypaisa number',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _jazzCash,
                      decoration: const InputDecoration(
                        labelText: 'JazzCash number',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _bank,
                      decoration: const InputDecoration(
                        labelText: 'Bank account details',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Create Committee'),
            ),
          ],
        ),
      ),
    );
  }
}
