class TempSelectedItem {
  final String inventoryItemId;
  final String name;
  final double rentPrice;

  int quantity;

  TempSelectedItem({
    required this.inventoryItemId,
    required this.name,
    required this.rentPrice,
    this.quantity = 0,
  });
}