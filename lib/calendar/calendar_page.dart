import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:pantry_pal/theme_controller.dart';
import 'package:pantry_pal/expiry/expiry_model.dart';
import 'package:pantry_pal/expiry/expiry_service.dart';
import 'package:pantry_pal/expiry/add_item_page.dart';
import 'package:pantry_pal/expiry/item_details_page.dart';
import 'package:pantry_pal/expiry/show_suggestions_bottom_sheet.dart';
import 'package:pantry_pal/recipes/view_recipe_page.dart';
import 'package:intl/intl.dart';

class CalendarPage extends StatefulWidget {
  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> with AutomaticKeepAliveClientMixin {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // Expiry service
  final ExpiryService _expiryService = ExpiryService();

  // Event sources
  Map<DateTime, List<PantryItem>> _expiryEvents = {};

  // Currently visible events
  List<PantryItem> _selectedEvents = [];

  // Loading states
  bool _isLoading = true;
  bool _isLoadingSuggestions = false;

  // For recipe suggestions caching
  List<RecipeSuggestion>? _cachedSuggestions;
  DateTime? _lastSuggestionsLoadTime;

  @override
  bool get wantKeepAlive => true; // Keep the state alive when switching tabs

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;

    // Load events after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadEvents();
    });
  }

  // Load expiry events
  Future<void> _loadEvents() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Get all pantry items
      final items = await _expiryService.getAllItems();

      // Group by expiry date
      final Map<DateTime, List<PantryItem>> events = {};

      for (final item in items) {
        // Normalize date to remove time component for mapping
        final normalizedDate = DateTime(
          item.expiryDate.year,
          item.expiryDate.month,
          item.expiryDate.day,
        );

        if (events[normalizedDate] == null) {
          events[normalizedDate] = [];
        }

        events[normalizedDate]!.add(item);
      }

      if (mounted) {
        setState(() {
          _expiryEvents = events;
          _isLoading = false;

          // Update selected events
          if (_selectedDay != null) {
            _updateSelectedEvents(_selectedDay!);
          }
        });
      }
    } catch (e) {
      print('Error loading expiry events: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Update events when a day is selected
  void _updateSelectedEvents(DateTime day) {
    final normalizedDate = DateTime(day.year, day.month, day.day);
    setState(() {
      _selectedEvents = _expiryEvents[normalizedDate] ?? [];
    });
  }

  // Calculate event count for calendar day marker
  List<PantryItem> _getEventsForDay(DateTime day) {
    final normalizedDate = DateTime(day.year, day.month, day.day);
    return _expiryEvents[normalizedDate] ?? [];
  }

  // Add a new pantry item
  void _addNewItem() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddItemPage(selectedDate: _selectedDay),
      ),
    );

    if (result == true) {
      // Reload events if item was added
      _loadEvents();
    }
  }

  // View item details
  void _viewItemDetails(PantryItem item) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ItemDetailsPage(item: item),
      ),
    );

    if (result == true) {
      // Reload events if item was modified or deleted
      _loadEvents();
    }
  }

  // Show recipe suggestions for expiring items
  void _showRecipeSuggestions() async {
    // Check if we have a recent cache to use
    final now = DateTime.now();
    if (_cachedSuggestions != null &&
        _lastSuggestionsLoadTime != null &&
        now.difference(_lastSuggestionsLoadTime!).inMinutes < 5) {
      // Use cached suggestions if recent
      showSuggestionsBottomSheet(context, _cachedSuggestions!);
      return;
    }

    // Otherwise, load new suggestions
    setState(() {
      _isLoadingSuggestions = true;
    });

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    try {
      // Get suggestions using the simplified service
      final suggestions = await _expiryService.forceRefreshSuggestions();

      // Close loading dialog
      Navigator.of(context).pop();

      // Cache the suggestions
      _cachedSuggestions = suggestions;
      _lastSuggestionsLoadTime = now;

      // Update loading state
      setState(() {
        _isLoadingSuggestions = false;
      });

      if (suggestions.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No recipe suggestions found for expiring items'),
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      // Show suggestions using the new bottom sheet
      showSuggestionsBottomSheet(context, suggestions);
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();

      // Update loading state
      setState(() {
        _isLoadingSuggestions = false;
      });

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading suggestions: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    final themeController = Provider.of<ThemeController>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color:Theme.of(context).scaffoldBackgroundColor,
      child:Column(
        children: [
          // AppBar-like header
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top,
              left: 16,
              right: 16,
              bottom: 16,
            ),
            color: Theme.of(context).appBarTheme.backgroundColor,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Expiry Calendar',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: themeController.currentFont,
                    color: Theme.of(context).appBarTheme.foregroundColor,
                  ),
                ),
                Row(
                  children: [
                    // Recipe suggestions button with prominent styling
                    ElevatedButton.icon(
                      icon: Icon(
                        Icons.restaurant_menu,
                        color: Colors.white,
                        size: 20,
                      ),
                      label: Text(
                        'Suggestions',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: themeController.currentFont,
                          fontSize: 12,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: _isLoadingSuggestions ? null : _showRecipeSuggestions,
                    ),
                    SizedBox(width: 8),
                    // Add item button
                    IconButton(
                      icon: Icon(
                          Icons.add,
                          color: Theme.of(context).appBarTheme.foregroundColor
                      ),
                      onPressed: _addNewItem,
                      tooltip: 'Add Item',
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Main content
          Expanded(
            child: Column(
              children: [
                // Calendar widget - Use const for optimization
                TableCalendar(
                  firstDay: DateTime.now().subtract(Duration(days: 365)),
                  lastDay: DateTime.now().add(Duration(days: 365)),
                  focusedDay: _focusedDay,
                  calendarFormat: _calendarFormat,
                  eventLoader: _getEventsForDay,
                  selectedDayPredicate: (day) {
                    return isSameDay(_selectedDay, day);
                  },
                  onDaySelected: (selectedDay, focusedDay) {
                    if (!isSameDay(_selectedDay, selectedDay)) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                        _updateSelectedEvents(selectedDay);
                      });
                    }
                  },
                  onFormatChanged: (format) {
                    if (_calendarFormat != format) {
                      setState(() {
                        _calendarFormat = format;
                      });
                    }
                  },
                  onPageChanged: (focusedDay) {
                    _focusedDay = focusedDay;
                  },
                  calendarStyle: CalendarStyle(
                    defaultTextStyle: TextStyle(
                      fontFamily: themeController.currentFont,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                    weekendTextStyle: TextStyle(
                      fontFamily: themeController.currentFont,
                      color: Colors.red.withOpacity(isDarkMode ? 0.8 : 0.6),
                    ),
                    selectedTextStyle: TextStyle(
                      fontFamily: themeController.currentFont,
                      color: Colors.white,
                    ),
                    todayTextStyle: TextStyle(
                      fontFamily: themeController.currentFont,
                      color: Colors.white,
                    ),
                    selectedDecoration: BoxDecoration(
                      color: Colors.blueAccent,
                      shape: BoxShape.circle,
                    ),
                    todayDecoration: BoxDecoration(
                      color: Colors.blue.shade300,
                      shape: BoxShape.circle,
                    ),
                    markerDecoration: BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  headerStyle: HeaderStyle(
                    titleTextStyle: TextStyle(
                      fontFamily: themeController.currentFont,
                      fontSize: 17.0,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                    formatButtonTextStyle: TextStyle(
                      fontFamily: themeController.currentFont,
                      fontSize: 14.0,
                    ),
                    formatButtonDecoration: BoxDecoration(
                      color: Colors.blueAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  daysOfWeekStyle: DaysOfWeekStyle(
                    weekdayStyle: TextStyle(
                      fontFamily: themeController.currentFont,
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                    weekendStyle: TextStyle(
                      fontFamily: themeController.currentFont,
                      color: Colors.red.withOpacity(0.6),
                    ),
                  ),
                ),

                SizedBox(height: 8),

                // Date header for selected events
                if (_selectedDay != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.event,
                          color: isDarkMode ? Colors.white70 : Colors.blueGrey,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Items expiring on ${DateFormat('MMMM d, yyyy').format(_selectedDay!)}',
                          style: TextStyle(
                            fontFamily: themeController.currentFont,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),

                SizedBox(height: 8),

                // Divider between calendar and events list
                Divider(height: 1),

                // Loading indicator
                if (_isLoading)
                  Expanded(
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),

                // Events list
                if (!_isLoading)
                  Expanded(
                    child: _selectedEvents.isEmpty
                        ? Center(
                      child: Text(
                        'No items expiring on this date',
                        style: TextStyle(
                          fontFamily: themeController.currentFont,
                          color: isDarkMode ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    )
                        : ListView.builder(
                      itemCount: _selectedEvents.length,
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemBuilder: (context, index) {
                        final item = _selectedEvents[index];
                        return _buildExpiryEventCard(item, context);
                      },
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Build a card for an expiring item
  Widget _buildExpiryEventCard(PantryItem item, BuildContext context) {
    final themeController = Provider.of<ThemeController>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Card(
      key: ValueKey(item.id), // Use key for better list performance
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
        onTap: () => _viewItemDetails(item),
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

                    // Quantity
                    Text(
                      'Quantity: ${item.quantity} ${item.quantityUnit}',
                      style: TextStyle(
                        fontFamily: themeController.currentFont,
                        fontSize: 14,
                      ),
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

  // Get status icon based on expiry status
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

  // Get status text based on expiry status
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