import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/pantry_catalog_item.dart';
import '../../../data/models/snack_request_model.dart';
import '../../home/providers/home_provider.dart';
import '../providers/snack_provider.dart';

class ApplySnackRequestScreen extends ConsumerStatefulWidget {
  const ApplySnackRequestScreen({super.key});

  @override
  ConsumerState<ApplySnackRequestScreen> createState() =>
      _ApplySnackRequestScreenState();
}

class _ApplySnackRequestScreenState
    extends ConsumerState<ApplySnackRequestScreen> {
  final _notesController = TextEditingController();

  SnackItemType _itemType = SnackItemType.snack;
  final Map<String, int> _cart = {};
  SnackRequestLocation? _location;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  bool get _hasCartItems => _cart.values.any((quantity) => quantity > 0);

  int get _cartItemCount =>
      _cart.values.fold(0, (total, quantity) => total + quantity);

  void _submit() {
    if (!_hasCartItems) return;

    final catalog = ref.read(pantryCatalogProvider);
    final catalogByName = {for (final item in catalog) item.name: item};
    final lineItems = _cart.entries
        .where((entry) => entry.value > 0)
        .map(
          (entry) => SnackRequestLineItem(
            itemType: catalogByName[entry.key]!.type,
            itemName: entry.key,
            quantity: entry.value,
          ),
        )
        .toList();

    final user = ref.read(currentUserProvider);
    ref.read(snackProvider.notifier).createRequest(
          requestedByUserId: user.id,
          requesterName: user.name,
          items: lineItems,
          notes: _notesController.text.trim(),
          location: _location,
        );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Snack request submitted')),
    );
    Navigator.of(context).pop();
  }

  void _addToCart(PantryCatalogItem item) {
    setState(() {
      _cart[item.name] = (_cart[item.name] ?? 0) + 1;
    });
  }

  void _decrementCartItem(String itemName) {
    setState(() {
      final quantity = _cart[itemName];
      if (quantity == null) return;
      if (quantity <= 1) {
        _cart.remove(itemName);
      } else {
        _cart[itemName] = quantity - 1;
      }
    });
  }

  void _incrementCartItem(String itemName) {
    setState(() {
      _cart[itemName] = (_cart[itemName] ?? 0) + 1;
    });
  }

  void _toggleLocation(SnackRequestLocation location) {
    setState(() {
      _location = _location == location ? null : location;
    });
  }

  @override
  Widget build(BuildContext context) {
    final items = _itemType == SnackItemType.snack
        ? ref.watch(snackCatalogProvider)
        : ref.watch(drinkCatalogProvider);
    final catalog = ref.watch(pantryCatalogProvider);
    final catalogByName = {for (final item in catalog) item.name: item};
    final cartEntries = _cart.entries
        .where((entry) => entry.value > 0)
        .toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('New Pantry Request'),
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _CategoryChip(
                          label: 'Snack',
                          selected: _itemType == SnackItemType.snack,
                          onTap: () => setState(
                            () => _itemType = SnackItemType.snack,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _CategoryChip(
                          label: 'Drink',
                          selected: _itemType == SnackItemType.drink,
                          onTap: () => setState(
                            () => _itemType = SnackItemType.drink,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: items.length,
                    itemBuilder: (_, index) {
                      final item = items[index];
                      final quantity = _cart[item.name] ?? 0;
                      return _PantryItemTile(
                        item: item,
                        quantity: quantity,
                        onTap: () => _addToCart(item),
                      );
                    },
                  ),
                  if (cartEntries.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Text(
                          'Your order',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        Text(
                          '$_cartItemCount item${_cartItemCount == 1 ? '' : 's'}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...cartEntries.map((entry) {
                      final catalogItem = catalogByName[entry.key]!;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Text(
                              catalogItem.emoji,
                              style: const TextStyle(fontSize: 24),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    catalogItem.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    catalogItem.type == SnackItemType.snack
                                        ? 'Snack'
                                        : 'Drink',
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => _decrementCartItem(entry.key),
                              icon: const Icon(Icons.remove_circle_outline),
                              visualDensity: VisualDensity.compact,
                            ),
                            Text(
                              '${entry.value}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                            IconButton(
                              onPressed: () => _incrementCartItem(entry.key),
                              icon: const Icon(Icons.add_circle_outline),
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                  const SizedBox(height: 20),
                  const Text(
                    'Location (optional)',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: SnackRequestLocation.values.map((location) {
                      final selected = _location == location;
                      return ChoiceChip(
                        label: Text(location.label),
                        selected: selected,
                        onSelected: (_) => _toggleLocation(location),
                        selectedColor: AppColors.primary,
                        backgroundColor: AppColors.cardBackground,
                        labelStyle: TextStyle(
                          color:
                              selected ? AppColors.white : AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        side: BorderSide(
                          color: selected
                              ? AppColors.primary
                              : AppColors.border,
                        ),
                        showCheckmark: false,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Notes (optional)',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: _inputDecoration(hintText: 'Any preference...'),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _hasCartItems ? _submit : null,
                  child: Text(
                    _hasCartItems
                        ? 'Submit Request ($_cartItemCount)'
                        : 'Submit Request',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({String? hintText}) => InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: AppColors.cardBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
      );
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _PantryItemTile extends StatelessWidget {
  final PantryCatalogItem item;
  final int quantity;
  final VoidCallback onTap;

  const _PantryItemTile({
    required this.item,
    required this.quantity,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final inCart = quantity > 0;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color:
                  inCart ? AppColors.surfaceVariant : AppColors.cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: inCart ? AppColors.primary : AppColors.border,
                width: inCart ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(item.emoji, style: const TextStyle(fontSize: 36)),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    item.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: inCart ? FontWeight.w600 : FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (inCart)
            Positioned(
              top: -6,
              right: -6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$quantity',
                  style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
