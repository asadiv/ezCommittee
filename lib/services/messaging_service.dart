import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../models/group_message.dart';
import 'firestore_collections.dart';

class MessagingService {
  MessagingService(this._firestore);

  final FirebaseFirestore _firestore;
  final Uuid _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> _messageCollection(
    String committeeId,
  ) {
    return committeeDoc(_firestore, committeeId).collection('messages');
  }

  Stream<List<GroupMessage>> streamMessages(String committeeId) {
    return _messageCollection(committeeId)
        .orderBy('createdAt', descending: true)
        .limit(200)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => GroupMessage.fromMap(doc.data()))
              .toList(),
        );
  }

  Future<void> sendMessage({
    required String committeeId,
    required String senderId,
    required String senderName,
    required String body,
  }) async {
    final now = DateTime.now();
    final id = _uuid.v4();
    final message = GroupMessage(
      id: id,
      groupId: committeeId,
      senderId: senderId,
      senderName: senderName,
      body: body,
      createdAt: now,
    );
    await _messageCollection(committeeId).doc(id).set(message.toMap());
  }
}
