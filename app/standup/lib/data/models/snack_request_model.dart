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

  static SnackRequestLocation? fromLabel(String label) {
    return switch (label.toLowerCase()) {
      'desk' => SnackRequestLocation.desk,
      'conference room' => SnackRequestLocation.conferenceRoom,
      'cabin 1' => SnackRequestLocation.cabin1,
      'cabin 2' => SnackRequestLocation.cabin2,
      'cabin 3' => SnackRequestLocation.cabin3,
      _ => null,
    };
  }
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

  factory SnackRequestLineItem.fromJson(Map<String, dynamic> json) {
    final typeStr = (json['item_type'] as String? ?? 'snack').toLowerCase();
    return SnackRequestLineItem(
      itemType: typeStr == 'drink' ? SnackItemType.drink : SnackItemType.snack,
      itemName: json['item_name'] as String? ?? '',
      quantity: (json['quantity'] as num? ?? 1).toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
        'item_name': itemName,
        'item_type': itemType == SnackItemType.drink ? 'drink' : 'snack',
        'quantity': quantity,
      };
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

  factory SnackRequestModel.fromJson(Map<String, dynamic> json) {
    final statusStr = (json['status'] as String? ?? 'pending').toLowerCase();
    final status = switch (statusStr) {
      'accepted' => SnackRequestStatus.accepted,
      'rejected' => SnackRequestStatus.rejected,
      'completed' => SnackRequestStatus.completed,
      _ => SnackRequestStatus.pending,
    };

    final locationStr = json['location'] as String?;
    final location = locationStr != null
        ? SnackRequestLocationX.fromLabel(locationStr)
        : null;

    final itemsJson = json['items'] as List<dynamic>? ?? [];
    final items = itemsJson
        .map((e) => SnackRequestLineItem.fromJson(e as Map<String, dynamic>))
        .toList();

    return SnackRequestModel(
      id: json['id'] as String? ?? '',
      requestedByUserId: json['employee'] as String? ?? '',
      requesterName: json['employee_name'] as String? ?? '',
      items: items,
      notes: json['notes'] as String?,
      location: location,
      requestedAt: json['requested_at'] != null
          ? DateTime.tryParse(json['requested_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      status: status,
      handledByPantryUserId: null,
      handledAt: json['handled_at'] != null
          ? DateTime.tryParse(json['handled_at'] as String)
          : null,
      rejectionReason: json['rejection_reason'] as String?,
    );
  }

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
