import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:pantry_pal/theme_controller.dart';
import 'package:pantry_pal/expiry/expiry_model.dart';
import 'package:pantry_pal/expiry/expiry_service.dart';
import 'package:pantry_pal/expiry/add_item_page.dart';
import 'package:pantry_pal/expiry/item_details_page.dart';
import 'package:pantry_pal/expiry/show_suggestions_bottom_sheet.dart';
import 'package:intl/intl.dart';

class CalendarPage extends StatefulWidget {
  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> with AutomaticKeepAliveClientMixin {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // Add view mode toggle
  bool _isListView = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Expiry service
  final ExpiryService _expiryService = ExpiryService();

  // Event sources
  Map<DateTime, List<PantryItem>> _expiryEvents = {};
  List<PantryItem> _allItems = [];

  // Currently visible events
  List<PantryItem> _selectedEvents = [];

  // Loading states
  bool _isLoading = true;
  bool _isLoadingSuggestions = false;

  // For recipe suggestions caching
  List<RecipeSuggestion>? _cachedSuggestions;
  DateTime? _lastSuggestionsLoadTime;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadEvents();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Load expiry events
  Future<void> _loadEvents() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final items = await _expiryService.getAllItems();

      // Store all items for list view
      _allItems = items;

      // Group by expiry date for calendar view
      final Map<DateTime, List<PantryItem>> events = {};

      for (final item in items) {
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

  // Get filtered items for list view
  List<PantryItem> _getFilteredItems() {
    if (_searchQuery.isEmpty) {
      // Sort by expiry date (soonest first)
      _allItems.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
      return _allItems;
    }

    // Filter by search query
    return _allItems.where((item) {
      final query = _searchQuery.toLowerCase();
      return item.name.toLowerCase().contains(query) ||
          item.category.toLowerCase().contains(query) ||
          item.location.toLowerCase().contains(query) ||
          (item.notes?.toLowerCase().contains(query) ?? false);
    }).toList()..sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
  }

  // Toggle between calendar and list view
  void _toggleViewMode() {
    setState(() {
      _isListView = !_isListView;
      if (!_isListView) {
        _searchController.clear();
        _searchQuery = '';
      }
    });
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
      _loadEvents();
    }
  }

  // Show recipe suggestions for expiring items
  void _showRecipeSuggestions() async {
    final now = DateTime.now();
    if (_cachedSuggestions != null &&
        _lastSuggestionsLoadTime != null &&
        now.difference(_lastSuggestionsLoadTime!).inMinutes < 5) {
      showSuggestionsBottomSheet(context, _cachedSuggestions!);
      return;
    }

    setState(() {
      _isLoadingSuggestions = true;
    });

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
      final suggestions = await _expiryService.forceRefreshSuggestions();
      Navigator.of(context).pop();

      _cachedSuggestions = suggestions;
      _lastSuggestionsLoadTime = now;

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

      showSuggestionsBottomSheet(context, suggestions);
    } catch (e) {
      Navigator.of(context).pop();
      setState(() {
        _isLoadingSuggestions = false;
      });

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
    super.build(context);

    final themeController = Provider.of<ThemeController>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          // Simplified AppBar-like header
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top,
              left: 16,
              right: 8,
              bottom: 12,
            ),
            color: Theme.of(context).appBarTheme.backgroundColor,
            child: Row(
              children: [
                // Title
                Expanded(
                  child: Text(
                    'Expiry Calendar',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: themeController.currentFont,
                      color: Theme.of(context).appBarTheme.foregroundColor,
                    ),
                  ),
                ),

                // View toggle (list/calendar)
                IconButton(
                  icon: Icon(
                    _isListView ? Icons.calendar_month : Icons.search,
                    color: Theme.of(context).appBarTheme.foregroundColor,
                  ),
                  onPressed: _toggleViewMode,
                  tooltip: _isListView ? 'Calendar View' : 'Search View',
                ),

                // Recipe suggestions
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Material(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: _isLoadingSuggestions ? null : _showRecipeSuggestions,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(
                          children: [
                            Icon(
                              Icons.restaurant_menu,
                              color: Colors.white,
                              size: 18,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Suggestions',
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: themeController.currentFont,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Add item button
                IconButton(
                  icon: Icon(
                    Icons.add,
                    color: Theme.of(context).appBarTheme.foregroundColor,
                  ),
                  onPressed: _addNewItem,
                  tooltip: 'Add Item',
                ),
              ],
            ),
          ),

          // Main content
          Expanded(
            child: _isListView ? _buildListView() : _buildCalendarView(),
          ),
        ],
      ),
    );
  }

  // Build the list view
  Widget _buildListView() {
    final themeController = Provider.of<ThemeController>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search items...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
        ),

        // Loading indicator
        if (_isLoading)
          Expanded(
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),

        // Items list
        if (!_isLoading)
          Expanded(
            child: _getFilteredItems().isEmpty
                ? Center(
              child: Text(
                _searchQuery.isEmpty
                    ? 'No items to display'
                    : 'No items match your search',
                style: TextStyle(
                  fontFamily: themeController.currentFont,
                  color: isDarkMode ? Colors.white60 : Colors.black54,
                ),
              ),
            )
                : ListView.builder(
              itemCount: _getFilteredItems().length,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemBuilder: (context, index) {
                final item = _getFilteredItems()[index];
                return _buildExpiryEventCard(item, context);
              },
            ),
          ),
      ],
    );
  }

  // Build the calendar view (rest of the existing code)
  Widget _buildCalendarView() {
    final themeController = Provider.of<ThemeController>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Calendar widget
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
    );
  }

  // Build a card for an expiring item (rest of the existing code)
  Widget _buildExpiryEventCard(PantryItem item, BuildContext context) {
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