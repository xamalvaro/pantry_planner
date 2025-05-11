import 'package:flutter/material.dart';
import 'calendar_header.dart';
import 'calendar_view.dart';
import 'expiry_list_view.dart';
import 'package:pantry_pal/expiry/expiry_model.dart';
import 'package:pantry_pal/expiry/expiry_service.dart';
import 'package:pantry_pal/expiry/add_item_page.dart';
import 'package:pantry_pal/expiry/item_details_page.dart';
import 'package:pantry_pal/expiry/show_suggestions_bottom_sheet.dart';

class CalendarPage extends StatefulWidget {
  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> with AutomaticKeepAliveClientMixin {
  // View states
  bool _isListView = false;
  String _searchQuery = '';
  String? _selectedLocation;

  // Expiry service
  final ExpiryService _expiryService = ExpiryService();

  // Data
  Map<DateTime, List<PantryItem>> _expiryEvents = {};
  List<PantryItem> _allItems = [];
  DateTime? _selectedDay;

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadEvents();
    });
  }

  Future<void> _loadEvents() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final items = await _expiryService.getAllItems();
      _allItems = items;

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

  void _toggleViewMode() {
    setState(() {
      _isListView = !_isListView;
      if (!_isListView) {
        _searchQuery = '';
        _selectedLocation = null;
      }
    });
  }

  void _updateSearchQuery(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  void _updateSelectedLocation(String? location) {
    setState(() {
      _selectedLocation = location;
    });
  }

  void _addNewItem() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddItemPage(selectedDate: _selectedDay),
      ),
    );

    _loadEvents();
  }

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

  void _onDaySelected(DateTime selectedDay) {
    setState(() {
      _selectedDay = selectedDay;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          CalendarHeader(
            isListView: _isListView,
            isLoadingSuggestions: _isLoadingSuggestions,
            onToggleView: _toggleViewMode,
            onShowSuggestions: _showRecipeSuggestions,
            onAddItem: _addNewItem,
          ),

          Expanded(
            child: _isListView
                ? ExpiryListView(
              allItems: _allItems,
              searchQuery: _searchQuery,
              selectedLocation: _selectedLocation,
              isLoading: _isLoading,
              onSearchChanged: _updateSearchQuery,
              onLocationChanged: _updateSelectedLocation,
              onItemTap: _viewItemDetails,
            )
                : CalendarView(
              expiryEvents: _expiryEvents,
              selectedDay: _selectedDay,
              isLoading: _isLoading,
              onDaySelected: _onDaySelected,
              onItemTap: _viewItemDetails,
            ),
          ),
        ],
      ),
    );
  }
}