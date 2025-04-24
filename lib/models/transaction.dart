class Transaction {
  final int? id;
  final DateTime date;
  final double totalAmount;

  Transaction({
    this.id,
    required this.date,
    required this.totalAmount,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.millisecondsSinceEpoch,
      'total_amount': totalAmount,
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
      totalAmount: map['total_amount'],
    );
  }
} 