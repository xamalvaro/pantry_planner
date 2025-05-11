import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pantry_pal/theme_controller.dart';
import 'package:pantry_pal/expiry/expiry_model.dart';
import 'package:intl/intl.dart';

class ExpiryEventCard extends StatelessWidget {
  final PantryItem item;
  final VoidCallback onTap;

  const ExpiryEventCard({
    Key? key,
    required this.item,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeController = Provider.of<ThemeController>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Card(
      key: ValueKey(item.id),
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: item.statusColor.withOpacity(0.5),
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status indicator
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: item.statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        item.daysRemaining.toString(),
                        style: TextStyle(
                          fontFamily: themeController.currentFont,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: item.statusColor,
                        ),
                      ),
                      Text(
                        'days',
                        style: TextStyle(
                          fontFamily: themeController.currentFont,
                          fontSize: 12,
                          color: item.statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(width: 12),

              // Item details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Item name
                    Text(
                      item.name,
                      style: TextStyle(
                        fontFamily: themeController.currentFont,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),

                    SizedBox(height: 4),

                    // Category and location
                    Row(
                      children: [
                        Icon(
                          Icons.category,
                          size: 14,
                          color: isDarkMode ? Colors.white60 : Colors.black54,
                        ),
                        SizedBox(width: 4),
                        Text(
                          item.category,
                          style: TextStyle(
                            fontFamily: themeController.currentFont,
                            fontSize: 14,
                            color: isDarkMode ? Colors.white60 : Colors.black54,
                          ),
                        ),
                        SizedBox(width: 12),
                        Icon(
                          Icons.place,
                          size: 14,
                          color: isDarkMode ? Colors.white60 : Colors.black54,
                        ),
                        SizedBox(width: 4),
                        Text(
                          item.location,
                          style: TextStyle(
                            fontFamily: themeController.currentFont,
                            fontSize: 14,
                            color: isDarkMode ? Colors.white60 : Colors.black54,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 4),

                    // Quantity and expiry date
                    Row(
                      children: [
                        Text(
                          'Qty: ${item.quantity} ${item.quantityUnit}',
                          style: TextStyle(
                            fontFamily: themeController.currentFont,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(width: 16),
                        Text(
                          'Expires: ${DateFormat('MMM d').format(item.expiryDate)}',
                          style: TextStyle(
                            fontFamily: themeController.currentFont,
                            fontSize: 14,
                            color: item.statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    // Notes (if any)
                    if (item.notes != null && item.notes!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          item.notes!,
                          style: TextStyle(
                            fontFamily: themeController.currentFont,
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: isDarkMode ? Colors.white70 : Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),

              // Status icon
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? item.statusColor.withOpacity(0.2)
                      : item.statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  children: [
                    Icon(
                      _getStatusIcon(item.expiryStatus),
                      color: item.statusColor,
                      size: 20,
                    ),
                    SizedBox(height: 2),
                    Text(
                      _getStatusText(item.expiryStatus),
                      style: TextStyle(
                        fontFamily: themeController.currentFont,
                        fontSize: 10,
                        color: item.statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getStatusIcon(ExpiryStatus status) {
    switch (status) {
      case ExpiryStatus.expired:
        return Icons.error_outline;
      case ExpiryStatus.critical:
        return Icons.warning_amber_outlined;
      case ExpiryStatus.warning:
        return Icons.access_time;
      case ExpiryStatus.ok:
        return Icons.check_circle_outline;
    }
  }

  String _getStatusText(ExpiryStatus status) {
    switch (status) {
      case ExpiryStatus.expired:
        return 'EXPIRED';
      case ExpiryStatus.critical:
        return 'CRITICAL';
      case ExpiryStatus.warning:
        return 'SOON';
      case ExpiryStatus.ok:
        return 'OK';
    }
  }
}