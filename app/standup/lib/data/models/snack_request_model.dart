enum SnackItemType { snack, drink }

enum SnackRequestStatus { pending, accepted, rejected, completed }

enum SnackRequestLocation { desk, conferenceRoom, cabin1, cabin2, cabin3 }

extension SnackRequestLocationX on SnackRequestLocation {
  String get label => switch (this) {
        SnackRequestLocation.desk => 'Desk',
        SnackRequestLocation.conferenceRoom => 'Conference Room',
        SnackRequestLocation.cabin1 => 'Cabin 1',
        SnackRequestLocation.cabin2 => 'Cabin 2',
        SnackRequestLocation.cabin3 => 'Cabin 3',
      };
}

class SnackRequestLineItem {
  final SnackItemType itemType;
  final String itemName;
  final int quantity;

  const SnackRequestLineItem({
    required this.itemType,
    required this.itemName,
    required this.quantity,
  });
}

class SnackRequestModel {
  final String id;
  final String requestedByUserId;
  final String requesterName;
  final List<SnackRequestLineItem> items;
  final String? notes;
  final SnackRequestLocation? location;
  final DateTime requestedAt;
  final SnackRequestStatus status;
  final String? handledByPantryUserId;
  final DateTime? handledAt;
  final String? rejectionReason;

  const SnackRequestModel({
    required this.id,
    required this.requestedByUserId,
    required this.requesterName,
    required this.items,
    required this.notes,
    this.location,
    required this.requestedAt,
    required this.status,
    this.handledByPantryUserId,
    this.handledAt,
    this.rejectionReason,
  });

  String get itemsSummary =>
      items.map((item) => '${item.itemName} x${item.quantity}').join(', ');

  int get totalQuantity =>
      items.fold(0, (total, item) => total + item.quantity);

  SnackRequestModel copyWith({
    String? id,
    String? requestedByUserId,
    String? requesterName,
    List<SnackRequestLineItem>? items,
    String? notes,
    SnackRequestLocation? location,
    DateTime? requestedAt,
    SnackRequestStatus? status,
    String? handledByPantryUserId,
    DateTime? handledAt,
    String? rejectionReason,
  }) {
    return SnackRequestModel(
      id: id ?? this.id,
      requestedByUserId: requestedByUserId ?? this.requestedByUserId,
      requesterName: requesterName ?? this.requesterName,
      items: items ?? this.items,
      notes: notes ?? this.notes,
      location: location ?? this.location,
      requestedAt: requestedAt ?? this.requestedAt,
      status: status ?? this.status,
      handledByPantryUserId: handledByPantryUserId ?? this.handledByPantryUserId,
      handledAt: handledAt ?? this.handledAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }
}
