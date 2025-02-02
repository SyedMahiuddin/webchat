import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String messageBody;
  final String senderId;
  final String receiverId;
  final String senderName;
  final String receiverName;
  final String senderImage;
  final String receiverImage;
  final String? imageUrl;
  final String? fileUrl;
  final String? audioUrl;  // Added audioUrl field
  final DateTime sendTime;
  final DateTime? deliveryTime;
  final DateTime? seenTime;
  final DateTime? editTime;

  Message({
    required this.id,
    required this.messageBody,
    required this.senderId,
    required this.receiverId,
    required this.senderName,
    required this.receiverName,
    required this.senderImage,
    required this.receiverImage,
    this.imageUrl,
    this.fileUrl,
    this.audioUrl,  // Added audioUrl to constructor
    required this.sendTime,
    this.deliveryTime,
    this.seenTime,
    this.editTime,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      messageBody: json['messageBody'] as String,
      senderId: json['senderId'] as String,
      receiverId: json['receiverId'] as String,
      senderName: json['senderName'] as String,
      receiverName: json['receiverName'] as String,
      senderImage: json['senderImage'] as String,
      receiverImage: json['receiverImage']==null?"something went wrong":json['receiverImage'] as String,
      imageUrl: json['imageUrl'] as String?,
      fileUrl: json['fileUrl'] as String?,
      audioUrl: json['audioUrl'] as String?,  // Added audioUrl
      sendTime: (json['sendTime'] as Timestamp).toDate(),
      deliveryTime: json['deliveryTime'] != null ? (json['deliveryTime'] as Timestamp).toDate() : null,
      seenTime: json['seenTime'] != null ? (json['seenTime'] as Timestamp).toDate() : null,
      editTime: json['editTime'] != null ? (json['editTime'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'messageBody': messageBody,
      'senderId': senderId,
      'receiverId': receiverId,
      'senderName': senderName,
      'receiverName': receiverName,
      'senderImage': senderImage,
      'receiverImage': receiverImage,
      'imageUrl': imageUrl,
      'fileUrl': fileUrl,
      'audioUrl': audioUrl,  // Added audioUrl
      'sendTime': Timestamp.fromDate(sendTime),
      'deliveryTime': deliveryTime != null ? Timestamp.fromDate(deliveryTime!) : null,
      'seenTime': seenTime != null ? Timestamp.fromDate(seenTime!) : null,
      'editTime': editTime != null ? Timestamp.fromDate(editTime!) : null,
    };
  }

  Message copyWith({
    String? id,
    String? messageBody,
    String? senderId,
    String? receiverId,
    String? senderName,
    String? receiverName,
    String? senderImage,
    String? receiverImage,
    String? imageUrl,
    String? fileUrl,
    String? audioUrl,
    DateTime? sendTime,
    DateTime? deliveryTime,
    DateTime? seenTime,
    DateTime? editTime,
  }) {
    return Message(
      id: id ?? this.id,
      messageBody: messageBody ?? this.messageBody,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      senderName: senderName ?? this.senderName,
      receiverName: receiverName ?? this.receiverName,
      senderImage: senderImage ?? this.senderImage,
      receiverImage: receiverImage ?? this.receiverImage,
      imageUrl: imageUrl ?? this.imageUrl,
      fileUrl: fileUrl ?? this.fileUrl,
      audioUrl: audioUrl ?? this.audioUrl,
      sendTime: sendTime ?? this.sendTime,
      deliveryTime: deliveryTime ?? this.deliveryTime,
      seenTime: seenTime ?? this.seenTime,
      editTime: editTime ?? this.editTime,
    );
  }
}