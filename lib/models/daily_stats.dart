class DailyStats {
  final double todaySales;
  final double todaySpend; // Purchases + Expenses
  final double totalPending;
  final int lowStockCount;
  final double paidThisMonth;
  final double overdueAmount;

  const DailyStats({
    required this.todaySales,
    required this.todaySpend,
    required this.totalPending,
    required this.lowStockCount,
    required this.paidThisMonth,
    required this.overdueAmount,
  });

  factory DailyStats.empty() {
    return const DailyStats(
      todaySales: 0,
      todaySpend: 0,
      totalPending: 0,
      lowStockCount: 0,
      paidThisMonth: 0,
      overdueAmount: 0,
    );
  }
}

class VendorStats {
  final double totalInvoiceValue;
  final double paidAmount;
  final double unpaidAmount;
  final double todayPurchase;
  final int activeOrders;

  const VendorStats({
    required this.totalInvoiceValue,
    required this.paidAmount,
    required this.unpaidAmount,
    required this.todayPurchase,
    required this.activeOrders,
  });

  factory VendorStats.empty() {
    return const VendorStats(
      totalInvoiceValue: 0,
      paidAmount: 0,
      unpaidAmount: 0,
      todayPurchase: 0,
      activeOrders: 0,
    );
  }
}

/// 🆕 Real-Time Profit Dashboard Model
class ProfitDashboard {
  final double todaySales;
  final double todayCogs;
  final double todayPurchases;
  final double grossProfit;
  final double netProfit;
  final int billCount;
  final double profitMargin; // Percentage

  const ProfitDashboard({
    required this.todaySales,
    required this.todayCogs,
    required this.todayPurchases,
    required this.grossProfit,
    required this.netProfit,
    required this.billCount,
    required this.profitMargin,
  });

  factory ProfitDashboard.empty() {
    return const ProfitDashboard(
      todaySales: 0,
      todayCogs: 0,
      todayPurchases: 0,
      grossProfit: 0,
      netProfit: 0,
      billCount: 0,
      profitMargin: 0,
    );
  }

  bool get isProfitable => grossProfit > 0;
}
