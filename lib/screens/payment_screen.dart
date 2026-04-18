import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/app_controller.dart';
import '../models/committee.dart';
import '../models/payment_record.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key, required this.committee, this.paymentRecord});

  final Committee committee;
  final PaymentRecord? paymentRecord;

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _transactionController = TextEditingController();
  String _selectedMethod = 'Easypaisa';
  bool _submitting = false;

  @override
  void dispose() {
    _transactionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final payment = widget.paymentRecord;
    if (payment == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Pay Now')),
        body: const Center(child: Text('No payment due for this interval.')),
      );
    }
    final app = context.watch<AppController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Pay Now')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [Color(0xFF3949AB), Color(0xFF1E88E5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Payment for interval ${payment.intervalIndex}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Amount: ${widget.committee.contributionAmount.toStringAsFixed(0)} PKR',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payment Instructions',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Easypaisa: '
                      '${widget.committee.paymentInstructions['easypaisa'] ?? '-'}',
                    ),
                    Text(
                      'JazzCash: '
                      '${widget.committee.paymentInstructions['jazzCash'] ?? '-'}',
                    ),
                    Text(
                      'Bank: ${widget.committee.paymentInstructions['bank'] ?? '-'}',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: _selectedMethod,
                      decoration: const InputDecoration(
                        labelText: 'Payment Method Used',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Easypaisa',
                          child: Text('Easypaisa'),
                        ),
                        DropdownMenuItem(
                          value: 'JazzCash',
                          child: Text('JazzCash'),
                        ),
                        DropdownMenuItem(
                          value: 'Bank',
                          child: Text('Bank Transfer'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        setState(() => _selectedMethod = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _transactionController,
                      decoration: const InputDecoration(
                        labelText: 'Transaction ID',
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _submitting
                            ? null
                            : () async {
                                final tx = _transactionController.text.trim();
                                if (tx.isEmpty) {
                                  _snack('Please enter transaction ID.');
                                  return;
                                }
                                setState(() => _submitting = true);
                                await app.submitPayment(
                                  paymentId: payment.id,
                                  transactionId: tx,
                                  method: _selectedMethod,
                                );
                                if (!mounted) {
                                  return;
                                }
                                setState(() => _submitting = false);
                                if (app.errorMessage == null) {
                                  if (context.mounted) {
                                    _snack('Submitted for owner verification.');
                                    Navigator.of(context).pop();
                                  }
                                  return;
                                }
                                _snack(app.errorMessage!);
                              },
                        child: _submitting
                            ? const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Submit Transaction'),
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

  void _snack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class PaymentScreenArgs {
  const PaymentScreenArgs({required this.committee, required this.payment});

  final Committee committee;
  final PaymentRecord? payment;
}
