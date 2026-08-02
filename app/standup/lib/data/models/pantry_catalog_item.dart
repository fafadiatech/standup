import 'snack_request_model.dart';

class PantryCatalogItem {
  final String name;
  final SnackItemType type;
  final String emoji;

  const PantryCatalogItem({
    required this.name,
    required this.type,
    required this.emoji,
  });

  factory PantryCatalogItem.fromJson(Map<String, dynamic> json) {
    final typeStr = (json['item_type'] as String? ?? 'snack').toLowerCase();
    return PantryCatalogItem(
      name: json['name'] as String? ?? '',
      type: typeStr == 'drink' ? SnackItemType.drink : SnackItemType.snack,
      emoji: json['emoji'] as String? ?? '🍽️',
    );
  }
}
