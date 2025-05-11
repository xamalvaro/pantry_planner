import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:pantry_pal/theme_controller.dart';
import 'package:pantry_pal/expiry/expiry_model.dart';
import 'expiry_event_card.dart';
import 'package:intl/intl.dart';

class CalendarView extends StatefulWidget {
  final Map<DateTime, List<PantryItem>> expiryEvents;
  final DateTime? selectedDay;
  final bool isLoading;
  final Function(DateTime) onDaySelected;
  final Function(PantryItem) onItemTap;

  const CalendarView({
    Key? key,
    required this.expiryEvents,
    required this.selectedDay,
    required this.isLoading,
    required this.onDaySelected,
    required this.onItemTap,
  }) : super(key: key);

  @override
  _CalendarViewState createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  late DateTime _focusedDay;
  late DateTime? _selectedDay;
  List<PantryItem> _selectedEvents = [];

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = widget.selectedDay ?? _focusedDay;
    _updateSelectedEvents(_selectedDay!);
  }

  @override
  void didUpdateWidget(CalendarView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedDay != oldWidget.selectedDay) {
      _selectedDay = widget.selectedDay;
      if (_selectedDay != null) {
        _updateSelectedEvents(_selectedDay!);
      }
    }
  }

  void _updateSelectedEvents(DateTime day) {
    final normalizedDate = DateTime(day.year, day.month, day.day);
    setState(() {
      _selectedEvents = widget.expiryEvents[normalizedDate] ?? [];
    });
  }

  List<PantryItem> _getEventsForDay(DateTime day) {
    final normalizedDate = DateTime(day.year, day.month, day.day);
    return widget.expiryEvents[normalizedDate] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final themeController = Provider.of<ThemeController>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Calendar widget
        TableCalendar<PantryItem>(
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
              widget.onDaySelected(selectedDay);
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

        // Events list
        if (widget.isLoading)
          Expanded(
            child: Center(
              child: CircularProgressIndicator(),
            ),
          )
        else
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
                return ExpiryEventCard(
                  item: item,
                  onTap: () => widget.onItemTap(item),
                );
              },
            ),
          ),
      ],
    );
  }
}