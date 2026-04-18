import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreCollections {
  static const users = 'users';
  static const committees = 'committees';
  static const payments = 'payments';
  static const messages = 'messages';
  static const disputes = 'disputes';
  static const payouts = 'payouts';
  static const memberships = 'memberships';
  static const notifications = 'notifications';
}

CollectionReference<Map<String, dynamic>> usersRef(FirebaseFirestore db) {
  return db.collection(FirestoreCollections.users);
}

CollectionReference<Map<String, dynamic>> committeesRef(FirebaseFirestore db) {
  return db.collection(FirestoreCollections.committees);
}

DocumentReference<Map<String, dynamic>> committeeDoc(
  FirebaseFirestore db,
  String committeeId,
) {
  return committeesRef(db).doc(committeeId);
}

CollectionReference<Map<String, dynamic>> committeeMembers(
  FirebaseFirestore db,
  String committeeId,
) {
  return committeeDoc(
    db,
    committeeId,
  ).collection(FirestoreCollections.memberships);
}

CollectionReference<Map<String, dynamic>> userCommittees(
  FirebaseFirestore db,
  String uid,
) {
  return usersRef(db).doc(uid).collection(FirestoreCollections.memberships);
}

CollectionReference<Map<String, dynamic>> committeeMessages(
  FirebaseFirestore db,
  String committeeId,
) {
  return committeeDoc(
    db,
    committeeId,
  ).collection(FirestoreCollections.messages);
}

CollectionReference<Map<String, dynamic>> committeePayments(
  FirebaseFirestore db,
  String committeeId,
) {
  return committeeDoc(
    db,
    committeeId,
  ).collection(FirestoreCollections.payments);
}

CollectionReference<Map<String, dynamic>> collectionPayments(
  FirebaseFirestore db,
) {
  return db.collection(FirestoreCollections.payments);
}

CollectionReference<Map<String, dynamic>> collectionDisputes(
  FirebaseFirestore db,
) {
  return db.collection(FirestoreCollections.disputes);
}

CollectionReference<Map<String, dynamic>> committeeDisputes(
  FirebaseFirestore db,
  String committeeId,
) {
  return committeeDoc(
    db,
    committeeId,
  ).collection(FirestoreCollections.disputes);
}

CollectionReference<Map<String, dynamic>> committeePayouts(
  FirebaseFirestore db,
  String committeeId,
) {
  return committeeDoc(db, committeeId).collection(FirestoreCollections.payouts);
}
