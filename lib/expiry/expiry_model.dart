import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

// Model for pantry items with expiration dates
class PantryItem {
  final String id;          // Unique identifier
  final String name;        // Item name
  final DateTime expiryDate; // Expiration date
  final String category;    // Category (e.g., Dairy, Produce)
  final String location;    // Storage location (e.g., Fridge, Pantry)
  final String? notes;      // Optional notes
  final int quantity;       // Quantity of item
  final String quantityUnit; // Unit for quantity (e.g., pcs, kg, oz)
  bool isNotified;          // Whether notification was sent for this item

  PantryItem({
    required this.id,
    required this.name,
    required this.expiryDate,
    required this.category,
    required this.location,
    this.notes,
    required this.quantity,
    required this.quantityUnit,
    this.isNotified = false,
  });

  // Calculate days remaining until expiration
  int get daysRemaining {
    final now = DateTime.now();
    return expiryDate.difference(now).inDays;
  }

  // Get expiration status
  ExpiryStatus get expiryStatus {
    final remaining = daysRemaining;

    if (remaining < 0) {
      return ExpiryStatus.expired;
    } else if (remaining <= 3) {
      return ExpiryStatus.critical;
    } else if (remaining <= 7) {
      return ExpiryStatus.warning;
    } else {
      return ExpiryStatus.ok;
    }
  }

  // Get color based on expiry status
  Color get statusColor {
    switch (expiryStatus) {
      case ExpiryStatus.expired:
        return Colors.red;
      case ExpiryStatus.critical:
        return Colors.orange;
      case ExpiryStatus.warning:
        return Colors.amber;
      case ExpiryStatus.ok:
        return Colors.green;
    }
  }

  // Convert to Map for Hive storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'expiryDate': expiryDate.millisecondsSinceEpoch,
      'category': category,
      'location': location,
      'notes': notes,
      'quantity': quantity,
      'quantityUnit': quantityUnit,
      'isNotified': isNotified,
    };
  }

  // Create PantryItem from Map (from Hive)
  factory PantryItem.fromMap(Map<dynamic, dynamic> map) {
    // Generate ID if not present or empty
    String id = map['id']?.toString() ?? '';
    if (id.isEmpty) {
      // Generate a new ID if the stored one is empty
      id = Uuid().v4();
    }

    return PantryItem(
      id: id,
      name: map['name']?.toString() ?? '',
      expiryDate: DateTime.fromMillisecondsSinceEpoch(map['expiryDate'] is int ? map['expiryDate'] : 0),
      category: map['category']?.toString() ?? '',
      location: map['location']?.toString() ?? '',
      notes: map['notes']?.toString(),
      quantity: map['quantity'] is int ? map['quantity'] : 1,
      quantityUnit: map['quantityUnit']?.toString() ?? 'pcs',
      isNotified: map['isNotified'] is bool ? map['isNotified'] : false,
    );
  }

  // Create a copy with modified fields
  PantryItem copyWith({
    String? id,
    String? name,
    DateTime? expiryDate,
    String? category,
    String? location,
    String? notes,
    int? quantity,
    String? quantityUnit,
    bool? isNotified,
  }) {
    return PantryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      expiryDate: expiryDate ?? this.expiryDate,
      category: category ?? this.category,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      quantity: quantity ?? this.quantity,
      quantityUnit: quantityUnit ?? this.quantityUnit,
      isNotified: isNotified ?? this.isNotified,
    );
  }
}

// Enum for expiry status
enum ExpiryStatus {
  expired,   // Already expired
  critical,  // Expires within 3 days
  warning,   // Expires within 7 days
  ok,        // Expires in more than 7 days
}

// Categories for pantry items
class PantryCategories {
  static const List<String> categories = [
    'Dairy',
    'Produce',
    'Meat',
    'Seafood',
    'Bakery',
    'Grains',
    'Canned Goods',
    'Frozen',
    'Spices',
    'Snacks',
    'Beverages',
    'Condiments',
    'Other'
  ];

  static const List<String> locations = [
    'Fridge',
    'Freezer',
    'Pantry',
    'Kitchen Cabinet',
    'Spice Rack',
    'Countertop',
    'Other'
  ];

  static const Map<String, List<String>> commonUnits = {
    'Weight': ['g', 'kg', 'oz', 'lb'],
    'Volume': ['ml', 'l', 'fl oz', 'cup', 'tbsp', 'tsp'],
    'Count': ['pcs', 'pack', 'box', 'can', 'bottle'],
  };
}

// Helper for recipe suggestions based on expiring items
class RecipeSuggestion {
  final String recipeTitle;
  final List<String> usedExpiringItems;

  RecipeSuggestion({
    required this.recipeTitle,
    required this.usedExpiringItems,
  });
}