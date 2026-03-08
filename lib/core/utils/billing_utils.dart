double getBillAmount(Map<String, dynamic> booking) {
  double finalTotal = (booking["finalTotal"] ?? 0).toDouble();
  double estimatedTotal = (booking["estimatedTotal"] ?? 0).toDouble();

  if (finalTotal > 0) {
    return finalTotal;
  }

  return estimatedTotal;
}

double getRemainingAmount(Map<String, dynamic> booking) {
  double bill = getBillAmount(booking);
  double paid = (booking["totalPaid"] ?? 0).toDouble();

  return bill - paid;
}