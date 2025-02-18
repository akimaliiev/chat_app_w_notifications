import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String senderID;
  final String senderEmail;
  final String receiverID;
  final String? message;
  final Timestamp timestamp;
  final String? mediaURL;    // URL of the media (optional)
  final String? mediaType;   // Type of media, e.g., 'image', 'video' (optional)

  Message({
    required this.senderID,
    required this.senderEmail,
    required this.receiverID,
    this.message,
    required this.timestamp,
    this.mediaURL,
    this.mediaType,
  });

  Map<String, dynamic> toMap() {
    return {
      'senderID': senderID,
      'senderEmail': senderEmail,
      'receiverID': receiverID,
      'message': message,
      'timestamp': timestamp,
      'mediaURL': mediaURL,
      'mediaType': mediaType,
    };
  }

  static Message fromMap(Map<String, dynamic> map) {
    return Message(
      senderID: map['senderID'],
      senderEmail: map['senderEmail'],
      receiverID: map['receiverID'],
      message: map['message'],
      timestamp: map['timestamp'],
      mediaURL: map['mediaURL'],
      mediaType: map['mediaType'],
    );
  }
}
