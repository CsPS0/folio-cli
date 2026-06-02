class Message {
  final String senderName;
  final String subject;
  final DateTime? sentDate;
  final bool isRead;

  const Message({
    required this.senderName,
    required this.subject,
    this.sentDate,
    this.isRead = false,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    final msg = json['uzenet'];
    return Message(
      senderName: msg?['feladoNev'] ?? 'Ismeretlen feladó',
      subject: msg?['targy'] ?? 'Nincs tárgy',
      sentDate: msg?['kuldesDatum'] != null ? DateTime.tryParse(msg!['kuldesDatum'])?.toLocal() : null,
      isRead: json['isElolvasva'] == true,
    );
  }
}
