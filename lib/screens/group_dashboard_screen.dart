import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/app_routes.dart';
import '../controllers/app_controller.dart';
import '../models/app_user.dart';
import '../models/committee.dart';
import '../models/payment_record.dart';
import '../models/payout_event.dart';
import '../widgets/payment_status_chip.dart';
import 'dispute_screen.dart';
import 'messaging_screen.dart';
import 'payment_screen.dart';

class GroupDashboardScreen extends StatefulWidget {
  const GroupDashboardScreen({super.key, required this.committeeId});

  final String committeeId;

  @override
  State<GroupDashboardScreen> createState() => _GroupDashboardScreenState();
}

class _GroupDashboardScreenState extends State<GroupDashboardScreen> {
  final TextEditingController _payoutTxnController = TextEditingController();
  bool _confirmingPayout = false;

  @override
  void dispose() {
    _payoutTxnController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();
    final currentUser = controller.appUser;
    if (currentUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return StreamBuilder<Committee?>(
      stream: controller.committeeStream(widget.committeeId),
      builder: (context, committeeSnap) {
        final committee = committeeSnap.data;
        if (committee == null) {
          return const Scaffold(
            body: Center(child: Text('Committee not found.')),
          );
        }
        return StreamBuilder<List<AppUser>>(
          stream: controller.membersStream(committee.id),
          builder: (context, memberSnap) {
            final members = memberSnap.data ?? const <AppUser>[];
            return StreamBuilder<List<PaymentRecord>>(
              stream: controller.committeePaymentsStream(committee.id),
              builder: (context, paymentSnap) {
                final payments = paymentSnap.data ?? const <PaymentRecord>[];
                return StreamBuilder<List<PayoutEvent>>(
                  stream: controller.payoutStream(committee.id),
                  builder: (context, payoutSnap) {
                    final payouts = payoutSnap.data ?? const <PayoutEvent>[];
                    final myIntervalPayment = _paymentForUserInterval(
                      payments: payments,
                      userId: currentUser.uid,
                      interval: committee.currentInterval,
                    );
                    final canPayNow =
                        myIntervalPayment == null ||
                        myIntervalPayment.status == PaymentStatus.unpaid ||
                        myIntervalPayment.status == PaymentStatus.rejected;
                    final isOwner = currentUser.uid == committee.ownerId;
                    final currentRecipient = _recipientForCycle(committee);
                    final currentPayout = payouts
                        .cast<PayoutEvent?>()
                        .firstWhere(
                          (event) =>
                              event?.cycleNumber == committee.currentInterval,
                          orElse: () => null,
                        );

                    return Scaffold(
                      appBar: AppBar(title: Text(committee.name)),
                      body: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          Text(
                            'State: ${committee.state.name.toUpperCase()}',
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: committee.progressPercent(),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Cycle ${committee.currentInterval}/${committee.totalIntervals}',
                          ),
                          const SizedBox(height: 12),
                          Text('Invite code: ${committee.inviteCode}'),
                          const SizedBox(height: 16),
                          _memberTable(
                            members: members,
                            payments: payments,
                            interval: committee.currentInterval,
                          ),
                          const SizedBox(height: 20),
                          if (canPayNow)
                            ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pushNamed(
                                  AppRoutes.payment,
                                  arguments: PaymentScreenArgs(
                                    committee: committee,
                                    payment: myIntervalPayment,
                                  ),
                                );
                              },
                              child: const Text('Pay Now'),
                            ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    Navigator.of(context).pushNamed(
                                      AppRoutes.messaging,
                                      arguments: MessagingScreenArgs(
                                        committeeId: committee.id,
                                        committeeName: committee.name,
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.chat_bubble_outline),
                                  label: const Text('Group Chat'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    Navigator.of(context).pushNamed(
                                      AppRoutes.dispute,
                                      arguments: DisputeScreenArgs(
                                        committeeId: committee.id,
                                        committeeName: committee.name,
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.gavel_outlined),
                                  label: const Text('Disputes'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Payout Timeline',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          ..._buildPayoutTimeline(
                            committee: committee,
                            members: members,
                            payouts: payouts,
                          ),
                          const SizedBox(height: 12),
                          if (isOwner) ...[
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Owner payout action',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleSmall,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Current recipient: ${_memberName(members, currentRecipient)}',
                                    ),
                                    const SizedBox(height: 8),
                                    TextField(
                                      controller: _payoutTxnController,
                                      decoration: const InputDecoration(
                                        labelText:
                                            'Owner payout transaction ID',
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: _confirmingPayout
                                            ? null
                                            : () async {
                                                final txn = _payoutTxnController
                                                    .text
                                                    .trim();
                                                if (txn.isEmpty) {
                                                  _showSnack(
                                                    'Please enter a transaction ID.',
                                                  );
                                                  return;
                                                }
                                                setState(
                                                  () =>
                                                      _confirmingPayout = true,
                                                );
                                                await controller
                                                    .ownerConfirmPayout(
                                                      committee: committee,
                                                      cycleNumber: committee
                                                          .currentInterval,
                                                      ownerTransactionId: txn,
                                                    );
                                                if (!mounted) {
                                                  return;
                                                }
                                                setState(
                                                  () =>
                                                      _confirmingPayout = false,
                                                );
                                                if (controller.errorMessage ==
                                                    null) {
                                                  _payoutTxnController.clear();
                                                  _showSnack(
                                                    'Payout confirmation submitted.',
                                                  );
                                                } else {
                                                  _showSnack(
                                                    controller.errorMessage!,
                                                  );
                                                }
                                              },
                                        child: const Text(
                                          'Confirm payout sent',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            OutlinedButton(
                              onPressed: () async {
                                await controller.advanceCommitteeInterval(
                                  committee,
                                );
                                if (!mounted) {
                                  return;
                                }
                                _showSnack('Committee moved to next interval.');
                              },
                              child: const Text('Advance interval'),
                            ),
                            const SizedBox(height: 8),
                            OutlinedButton(
                              onPressed: () async {
                                await controller.runMissedPaymentCheck(
                                  committeeId: committee.id,
                                  ownerUid: committee.ownerId,
                                );
                                if (!mounted) {
                                  return;
                                }
                                _showSnack(
                                  controller.errorMessage ??
                                      'Missed payment check complete.',
                                );
                              },
                              child: const Text('Run missed-payment checks'),
                            ),
                          ],
                          if (!isOwner &&
                              currentRecipient == currentUser.uid &&
                              currentPayout != null &&
                              currentPayout.ownerConfirmed &&
                              !currentPayout.recipientConfirmed)
                            FilledButton.icon(
                              onPressed: () async {
                                await controller.recipientConfirmPayout(
                                  committeeId: committee.id,
                                  cycleNumber: committee.currentInterval,
                                );
                                if (!mounted) {
                                  return;
                                }
                                _showSnack(
                                  controller.errorMessage ??
                                      'Payout receipt confirmed.',
                                );
                              },
                              icon: const Icon(Icons.check_circle_outline),
                              label: const Text('Confirm payout received'),
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  PaymentRecord? _paymentForUserInterval({
    required List<PaymentRecord> payments,
    required String userId,
    required int interval,
  }) {
    return payments.cast<PaymentRecord?>().firstWhere(
      (payment) =>
          payment?.memberUid == userId && payment?.intervalIndex == interval,
      orElse: () => null,
    );
  }

  Widget _memberTable({
    required List<AppUser> members,
    required List<PaymentRecord> payments,
    required int interval,
  }) {
    final rows = members
        .map((member) {
          final payment = payments.cast<PaymentRecord?>().firstWhere(
            (item) =>
                item?.memberUid == member.uid &&
                item?.intervalIndex == interval,
            orElse: () => null,
          );
          return DataRow(
            cells: [
              DataCell(
                Text(
                  member.fullName.isEmpty
                      ? member.phoneNumber
                      : member.fullName,
                ),
              ),
              DataCell(
                PaymentStatusChip(
                  status: payment?.status ?? PaymentStatus.unpaid,
                ),
              ),
              DataCell(Text('${member.trustScore.toStringAsFixed(0)}%')),
            ],
          );
        })
        .toList(growable: false);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Member')),
              DataColumn(label: Text('Payment')),
              DataColumn(label: Text('Trust')),
            ],
            rows: rows,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildPayoutTimeline({
    required Committee committee,
    required List<AppUser> members,
    required List<PayoutEvent> payouts,
  }) {
    final widgets = <Widget>[];
    for (var cycle = 1; cycle <= committee.totalIntervals; cycle++) {
      final recipientUid = cycle - 1 < committee.payoutOrder.length
          ? committee.payoutOrder[cycle - 1]
          : '';
      final recipientName = _memberName(members, recipientUid);
      final payout = payouts.cast<PayoutEvent?>().firstWhere(
        (event) => event?.cycleNumber == cycle,
        orElse: () => null,
      );
      widgets.add(
        Card(
          child: ListTile(
            title: Text('Cycle $cycle - $recipientName'),
            subtitle: Text(
              payout == null
                  ? 'Pending owner confirmation'
                  : payout.recipientConfirmed
                  ? 'Paid and confirmed'
                  : payout.ownerConfirmed
                  ? 'Sent by owner, awaiting recipient confirmation'
                  : 'Pending owner confirmation',
            ),
            trailing: payout == null
                ? const Icon(Icons.hourglass_top)
                : payout.recipientConfirmed
                ? const Icon(Icons.check_circle, color: Colors.green)
                : const Icon(Icons.timelapse, color: Colors.orange),
          ),
        ),
      );
    }
    return widgets;
  }

  String _memberName(List<AppUser> members, String uid) {
    final member = members.cast<AppUser?>().firstWhere(
      (item) => item?.uid == uid,
      orElse: () => null,
    );
    if (member == null) {
      return uid.isEmpty ? 'TBD' : uid;
    }
    return member.fullName.isEmpty ? member.phoneNumber : member.fullName;
  }

  String _recipientForCycle(Committee committee) {
    final index = committee.currentInterval - 1;
    if (index < 0 || index >= committee.payoutOrder.length) {
      return '';
    }
    return committee.payoutOrder[index];
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
