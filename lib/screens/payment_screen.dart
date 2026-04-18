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
            Text(
              'Payment for interval ${payment.intervalIndex}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Amount: ${widget.committee.contributionAmount.toStringAsFixed(0)} PKR',
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Payment Instructions'),
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
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedMethod,
              decoration: const InputDecoration(
                labelText: 'Payment Method Used',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'Easypaisa', child: Text('Easypaisa')),
                DropdownMenuItem(value: 'JazzCash', child: Text('JazzCash')),
                DropdownMenuItem(value: 'Bank', child: Text('Bank Transfer')),
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
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
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
