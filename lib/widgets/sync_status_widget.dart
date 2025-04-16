// lib/widgets/sync_status_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pantry_pal/theme_controller.dart';
import 'package:pantry_pal/services/firebase_sync_service.dart';

class SyncStatusWidget extends StatelessWidget {
  const SyncStatusWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeController = Provider.of<ThemeController>(context);

    return StreamBuilder<SyncStatus>(
      stream: firebaseSyncService.syncStatus,
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.isActive) {
          return SizedBox.shrink(); // Don't show anything if not syncing
        }

        final status = snapshot.data!;

        return Container(
          padding: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: status.isError
                ? Colors.red.withOpacity(0.2)
                : Colors.blue.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              status.isError
                  ? Icon(Icons.error_outline, color: Colors.red, size: 16)
                  : SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  status.message,
                  style: TextStyle(
                    fontFamily: themeController.currentFont,
                    fontSize: 14,
                    color: status.isError ? Colors.red : Colors.blue,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}