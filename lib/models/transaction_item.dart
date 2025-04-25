class TransactionItem {
  final int? id;
  final int transactionId;
  final int productId;
  final String productName;
  final double productPrice;
  final int quantity;
  final double total;

  TransactionItem({
    this.id,
    required this.transactionId,
    required this.productId,
    required this.productName,
    required this.productPrice,
    required this.quantity,
    required this.total,
  });

  // Metode copyWith untuk membuat salinan dengan beberapa properti yang diubah
  TransactionItem copyWith({
    int? id,
    int? transactionId,
    int? productId,
    String? productName,
    double? productPrice,
    int? quantity,
    double? total,
  }) {
    return TransactionItem(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productPrice: productPrice ?? this.productPrice,
      quantity: quantity ?? this.quantity,
      total: total ?? this.total,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'transaction_id': transactionId,
      'product_id': productId,
      'product_name': productName,
      'product_price': productPrice,
      'quantity': quantity,
      'total': total,
    };
  }

  factory TransactionItem.fromMap(Map<String, dynamic> map) {
    return TransactionItem(
      id: map['id'],
      transactionId: map['transaction_id'],
      productId: map['product_id'],
      productName: map['product_name'],
      productPrice: map['product_price'],
      quantity: map['quantity'],
      total: map['total'],
    );
  }
}
