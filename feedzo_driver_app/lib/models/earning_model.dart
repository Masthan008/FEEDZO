class EarningEntry {
  final String orderId;
  final String restaurantName;
  final double amount;
  final DateTime date;

  const EarningEntry({
    required this.orderId,
    required this.restaurantName,
    required this.amount,
    required this.date,
  });
}

enum CodStatus { pending, submitted, settled }

class CodEntry {
  final String orderId;
  final String customerName;
  final String restaurantName;
  final double orderAmount;
  final DateTime collectedAt;
  CodStatus status;
  double submittedAmount;

  CodEntry({
    required this.orderId,
    required this.customerName,
    required this.restaurantName,
    required this.orderAmount,
    required this.collectedAt,
    this.status = CodStatus.pending,
    this.submittedAmount = 0,
  });
}

class CodDailySummary {
  final DateTime date;
  final int totalCodOrders;
  final double totalCodCollected;
  final double totalSubmitted;

  const CodDailySummary({
    required this.date,
    required this.totalCodOrders,
    required this.totalCodCollected,
    required this.totalSubmitted,
  });

  double get pending => totalCodCollected - totalSubmitted;
}
