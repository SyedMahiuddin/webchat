class Connection {
  final String id;
  final String name;
  final String image;
  final String lastMessage;
  final DateTime lastMessageTime;

  Connection({
    required this.id,
    required this.name,
    required this.image,
    required this.lastMessage,
    required this.lastMessageTime,
  });
}