
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pantry_pal/theme_controller.dart';
import 'package:pantry_pal/tabs/grocery_lists_tab.dart';
import 'package:pantry_pal/recipes/recipes_page.dart';
import 'package:pantry_pal/create_page_selector.dart';
import 'package:pantry_pal/calendar/calendar_page.dart';
import 'package:pantry_pal/settings_page.dart';
import 'package:pantry_pal/expiry/expiry_service.dart';
import 'package:pantry_pal/widgets/sync_status_widget.dart';

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late TabController _tabController;
  String _searchQuery = '';
  String? _selectedTag;

  // List of lazy-loaded tab widgets
  final List<Widget> _tabWidgets = [];

  // Track if we've shown the expiry notification
  static bool _hasShownExpiryNotification = false;

  @override
  void initState() {
    super.initState();

    // Create tab controller
    _tabController = TabController(length: 5, vsync: this);

    // Listen to tab changes
    _tabController.addListener(() {
      setState(() {
        _selectedIndex = _tabController.index;
      });
    });

    // Initialize lazy loaded tab widgets
    _initializeTabWidgets();

    // Only show expiry info once when the app is first opened
    if (!_hasShownExpiryNotification) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          ExpiryService().showExpiryInfo(context);
          _hasShownExpiryNotification = true;
        } catch (e) {
          print('Error showing expiry info: $e');
        }
      });
    }
  }

  // Initialize tab widgets once
  void _initializeTabWidgets() {
    _tabWidgets.add(GroceryListsTab(
      searchQuery: _searchQuery,
      selectedTag: _selectedTag,
      onSearchChanged: (value) {
        setState(() => _searchQuery = value);
      },
      onTagSelected: (tag) {
        setState(() => _selectedTag = tag);
      },
    ));
    _tabWidgets.add(RecipesPage());
    _tabWidgets.add(CreatePageSelector());
    _tabWidgets.add(CalendarPage());
    _tabWidgets.add(SettingsPage());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Access the current theme to make UI respond to theme changes
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('PantryPlanner'),
      ),
      body: Column(
        children: [
          // Add sync status widget
          SyncStatusWidget(),

          // Existing TabBarView wrapped in Expanded
          Expanded(
            child: TabBarView(
              controller: _tabController,
              // This physics setting reduces animation overhead
              physics: const NeverScrollableScrollPhysics(),
              children: _tabWidgets,
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_basket_outlined),
            label: 'Lists',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu),
            label: 'Recipes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: 'Create',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Calendar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: isDarkMode ? Colors.grey : Colors.blueGrey,
        backgroundColor: isDarkMode ? Colors.black : null,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
            _tabController.animateTo(index);
          });
        },
      ),
    );
  }
}