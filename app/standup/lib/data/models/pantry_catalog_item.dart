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
}
