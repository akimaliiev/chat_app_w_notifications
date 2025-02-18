import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:flutter_application_2/models/message.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance; // Firebase Storage instance

  // Stream for getting all users
  Stream<List<Map<String, dynamic>>> getUsersStream() {
    return _firestore.collection("Users").snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final user = doc.data();
        return user;
      }).toList();
    });
  }

  // Stream for getting users excluding blocked ones
  Stream<List<Map<String, dynamic>>> getUsersStreamExcludingBlocked() {
    final currentUser = _auth.currentUser;
    return _firestore.collection('Users').doc(currentUser!.uid).collection('BlockedUsers').snapshots().asyncMap((snapshot) async {
      final blockedUserIds = snapshot.docs.map((doc) => doc.id).toList();
      final usersSnapshot = await _firestore.collection('Users').get();
      return usersSnapshot.docs.where((doc) => doc.data()['email'] != currentUser.email && !blockedUserIds.contains(doc.id)).map((doc) => doc.data()).toList();
    });
  }

  // Send a text message
  Future<void> sendMessage(String receiverID, {required String message}) async {
    final String currentUserID = _auth.currentUser!.uid;
    final String currentUserEmail = _auth.currentUser!.email!;
    final Timestamp timestamp = Timestamp.now();

    Message newMessage = Message(
      senderID: currentUserID,
      senderEmail: currentUserEmail,
      receiverID: receiverID,
      message: message,
      timestamp: timestamp,
    );

    List<String> ids = [currentUserID, receiverID];
    ids.sort();
    String chatRoomID = ids.join('_');

    await _firestore.collection("chat_rooms").doc(chatRoomID).collection("messages").add(newMessage.toMap());
  }

  // Get messages between two users
  Stream<QuerySnapshot> getMessages(String userID, String otherUserID) {
    List<String> ids = [userID, otherUserID];
    ids.sort();
    String chatRoomID = ids.join('_');

    return _firestore.collection("chat_rooms").doc(chatRoomID).collection("messages").orderBy("timestamp", descending: false).snapshots();
  }

  // Report a user
  Future<void> reportUser(String messageId, String userId) async {
    final currentUser = _auth.currentUser;
    final report = {
      'reportedBy': currentUser!.uid,
      'messageId': messageId,
      'messageOwnerId': userId,
      'timestamp': FieldValue.serverTimestamp(),
    };
    await _firestore.collection("Reports").add(report);
  }

  // Block a user
  Future<void> blockUser(String userId) async {
    final currentUser = _auth.currentUser;
    await _firestore.collection("Users").doc(currentUser!.uid).collection("BlockedUsers").doc(userId).set({});
  }

  // Unblock a user
  Future<void> unblockUser(String blockedUserId) async {
    final currentUser = _auth.currentUser;
    await _firestore.collection("Users").doc(currentUser!.uid).collection("BlockedUsers").doc(blockedUserId).delete();
  }

  // Get blocked users stream
  Stream<List<Map<String, dynamic>>> getBlockedUsersStream(String userId) {
    return _firestore.collection('Users').doc(userId).collection('BlockedUsers').snapshots().asyncMap((snapshot) async {
      final blockedUserIds = snapshot.docs.map((doc) => doc.id).toList();
      final userDocs = await Future.wait(
        blockedUserIds.map((id) => _firestore.collection("Users").doc(id).get()),
      );
      return userDocs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    });
  }

  // Send media message (image or video)
  Future<void> sendMediaMessage(String receiverID, File mediaFile, String mediaType) async {
    try {
      final String currentUserID = _auth.currentUser!.uid;
      final String currentUserEmail = _auth.currentUser!.email!;
      final Timestamp timestamp = Timestamp.now();

      // Create a unique file path for the media
      String mediaFileName = DateTime.now().millisecondsSinceEpoch.toString();
      String filePath = 'chat_media/$currentUserID/$receiverID/$mediaFileName';

      // Upload file to Firebase Storage
      UploadTask uploadTask = _storage.ref().child(filePath).putFile(mediaFile);

      // Wait for the upload to complete and get the download URL
      TaskSnapshot taskSnapshot = await uploadTask;
      String downloadURL = await taskSnapshot.ref.getDownloadURL();

      // Create a new message with the media URL
      Message newMessage = Message(
        senderID: currentUserID,
        senderEmail: currentUserEmail,
        receiverID: receiverID,
        message: mediaType == 'image' ? '' : '',
        mediaURL: downloadURL,  // Add media URL to message
        mediaType: mediaType,   // Add media type (image or video)
        timestamp: timestamp,
      );

      List<String> ids = [currentUserID, receiverID];
      ids.sort();
      String chatRoomID = ids.join('_');

      await _firestore.collection("chat_rooms").doc(chatRoomID).collection("messages").add(newMessage.toMap());
    } catch (e) {
      print('Error uploading media: $e');
    }
  }
}
