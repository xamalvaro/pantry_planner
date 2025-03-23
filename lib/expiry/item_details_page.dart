import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pantry_pal/theme_controller.dart';
import 'package:pantry_pal/expiry/expiry_model.dart';
import 'package:pantry_pal/expiry/expiry_service.dart';
import 'package:pantry_pal/expiry/add_item_page.dart';
import 'package:intl/intl.dart';

class ItemDetailsPage extends StatefulWidget {
  final PantryItem item;

  ItemDetailsPage({required this.item});

  @override
  _ItemDetailsPageState createState() => _ItemDetailsPageState();
}

class _ItemDetailsPageState extends State<ItemDetailsPage> {
  final ExpiryService _expiryService = ExpiryService();
  late PantryItem _item;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
  }

  // Edit the item
  void _editItem() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddItemPage(initialItem: _item),
      ),
    );

    if (result == true) {
      // Reload item data
      final updatedItems = await _expiryService.getAllItems();
      final updatedItem = updatedItems.firstWhere(
            (item) => item.id == _item.id,
        orElse: () => _item,
      );

      setState(() {
        _item = updatedItem;
      });
    }
  }

  // Delete the item
  void _deleteItem() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Item'),
        content: Text('Are you sure you want to delete "${_item.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _expiryService.deleteItem(_item.id);
      Navigator.pop(context, true); // Return to calendar with reload flag
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeController = Provider.of<ThemeController>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Item Details',
          style: TextStyle(
            fontFamily: themeController.currentFont,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: _editItem,
            tooltip: 'Edit Item',
          ),
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: _deleteItem,
            tooltip: 'Delete Item',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Item header
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Status indicator
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: _item.statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _item.daysRemaining.toString(),
                        style: TextStyle(
                          fontFamily: themeController.currentFont,
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                          color: _item.statusColor,
                        ),
                      ),
                      Text(
                        'days left',
                        style: TextStyle(
                          fontFamily: themeController.currentFont,
                          fontSize: 12,
                          color: _item.statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 16),

                // Item name and category
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _item.name,
                        style: TextStyle(
                          fontFamily: themeController.currentFont,
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        _item.category,
                        style: TextStyle(
                          fontFamily: themeController.currentFont,
                          fontSize: 16,
                          color: isDarkMode ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: 24),

            // Expiration card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: _item.statusColor.withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          color: _item.statusColor,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Expiration Details',
                          style: TextStyle(
                            fontFamily: themeController.currentFont,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    Divider(height: 24),

                    // Expiry date
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Expiry Date:',
                          style: TextStyle(
                            fontFamily: themeController.currentFont,
                          ),
                        ),
                        Text(
                          DateFormat('MMMM d, yyyy').format(_item.expiryDate),
                          style: TextStyle(
                            fontFamily: themeController.currentFont,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),

                    // Status
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Status:',
                          style: TextStyle(
                            fontFamily: themeController.currentFont,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: _item.statusColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            _getStatusText(_item.expiryStatus),
                            style: TextStyle(
                              fontFamily: themeController.currentFont,
                              fontWeight: FontWeight.bold,
                              color: _item.statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 12),

                    // Days remaining or overdue
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _item.daysRemaining >= 0 ? 'Days Remaining:' : 'Days Overdue:',
                          style: TextStyle(
                            fontFamily: themeController.currentFont,
                          ),
                        ),
                        Text(
                          _item.daysRemaining >= 0
                              ? '${_item.daysRemaining} days'
                              : '${-_item.daysRemaining} days',
                          style: TextStyle(
                            fontFamily: themeController.currentFont,
                            fontWeight: FontWeight.bold,
                            color: _item.statusColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Item details card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.inventory_2,
                          color: Colors.blueAccent,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Item Details',
                          style: TextStyle(
                            fontFamily: themeController.currentFont,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    Divider(height: 24),

                    // Quantity
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Quantity:',
                          style: TextStyle(
                            fontFamily: themeController.currentFont,
                          ),
                        ),
                        Text(
                          '${_item.quantity} ${_item.quantityUnit}',
                          style: TextStyle(
                            fontFamily: themeController.currentFont,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),

                    // Storage location
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Storage Location:',
                          style: TextStyle(
                            fontFamily: themeController.currentFont,
                          ),
                        ),
                        Text(
                          _item.location,
                          style: TextStyle(
                            fontFamily: themeController.currentFont,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    // Notes (if available)
                    if (_item.notes != null && _item.notes!.isNotEmpty) ...[
                      SizedBox(height: 24),
                      Text(
                        'Notes:',
                        style: TextStyle(
                          fontFamily: themeController.currentFont,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? Colors.grey.shade800
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        width: double.infinity,
                        child: Text(
                          _item.notes!,
                          style: TextStyle(
                            fontFamily: themeController.currentFont,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            SizedBox(height: 32),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _editItem,
                    icon: Icon(Icons.edit),
                    label: Text(
                      'Edit Item',
                      style: TextStyle(
                        fontFamily: themeController.currentFont,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _deleteItem,
                    icon: Icon(Icons.delete),
                    label: Text(
                      'Delete Item',
                      style: TextStyle(
                        fontFamily: themeController.currentFont,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Get status text based on expiry status
  String _getStatusText(ExpiryStatus status) {
    switch (status) {
      case ExpiryStatus.expired:
        return 'EXPIRED';
      case ExpiryStatus.critical:
        return 'EXPIRING SOON';
      case ExpiryStatus.warning:
        return 'USE SOON';
      case ExpiryStatus.ok:
        return 'GOOD';
    }
  }
}