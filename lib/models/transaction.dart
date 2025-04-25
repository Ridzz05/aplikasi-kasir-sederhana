class Transaction {
  final int? id;
  final DateTime date;
  final double totalAmount;
  final String paymentMethod;

  Transaction({
    this.id,
    required this.date,
    required this.totalAmount,
    this.paymentMethod = 'Tunai',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.millisecondsSinceEpoch,
      'total_amount': totalAmount,
      'payment_method': paymentMethod,
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
      totalAmount: map['total_amount'],
      paymentMethod: map['payment_method'] ?? 'Tunai',
    );
  }
}
