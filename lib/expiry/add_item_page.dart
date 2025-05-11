import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pantry_pal/theme_controller.dart';
import 'package:pantry_pal/expiry/expiry_model.dart';
import 'package:pantry_pal/expiry/expiry_service.dart';
import 'package:intl/intl.dart';

class AddItemPage extends StatefulWidget {
  final DateTime? selectedDate;
  final PantryItem? initialItem; // Pass existing item for editing mode

  AddItemPage({this.selectedDate, this.initialItem});

  @override
  _AddItemPageState createState() => _AddItemPageState();
}

class _AddItemPageState extends State<AddItemPage> {
  final _formKey = GlobalKey<FormState>();
  final ExpiryService _expiryService = ExpiryService();

  // Form fields
  late TextEditingController _nameController;
  late DateTime _expiryDate;
  late String _category;
  late String _location;
  late TextEditingController _notesController;
  late TextEditingController _quantityController;
  late String _quantityUnit;

  // Edit mode flag
  bool get isEditMode => widget.initialItem != null;

  @override
  void initState() {
    super.initState();

    // Initialize with existing item data or defaults
    if (isEditMode) {
      _nameController = TextEditingController(text: widget.initialItem!.name);
      _expiryDate = widget.initialItem!.expiryDate;
      _category = widget.initialItem!.category;
      _location = widget.initialItem!.location;
      _notesController = TextEditingController(text: widget.initialItem!.notes);
      _quantityController = TextEditingController(text: widget.initialItem!.quantity.toString());
      _quantityUnit = widget.initialItem!.quantityUnit;
    } else {
      _nameController = TextEditingController();
      _expiryDate = widget.selectedDate ?? DateTime.now().add(Duration(days: 7));
      _category = PantryCategories.categories.first;
      _location = PantryCategories.locations.first;
      _notesController = TextEditingController();
      _quantityController = TextEditingController(text: '1');
      _quantityUnit = PantryCategories.commonUnits['Count']!.first;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  // Save the pantry item
  Future<void> _saveItem() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    final int quantity = int.tryParse(_quantityController.text) ?? 1;

    try {
      if (isEditMode) {
        // Update existing item - ensure we keep the original ID
        final updatedItem = widget.initialItem!.copyWith(
          name: _nameController.text.trim(),
          expiryDate: _expiryDate,
          category: _category,
          location: _location,
          notes: _notesController.text.trim(),
          quantity: quantity,
          quantityUnit: _quantityUnit,
          isNotified: false,
        );

        await _expiryService.updateItem(updatedItem);
      } else {
        // Create new item with a proper ID
        final newId = _expiryService.generateItemId();
        if (newId.isEmpty) {
          throw Exception('Failed to generate item ID');
        }

        final newItem = PantryItem(
          id: newId,
          name: _nameController.text.trim(),
          expiryDate: _expiryDate,
          category: _category,
          location: _location,
          notes: _notesController.text.trim(),
          quantity: quantity,
          quantityUnit: _quantityUnit,
        );

        await _expiryService.addItem(newItem);
      }

      // Return to previous screen with success indicator
      Navigator.pop(context, true);
    } catch (e) {
      print('Error saving pantry item: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving item. Please try again.')),
      );
    }
  }

  // Get flattened units list for dropdown
  List<String> _getAllUnits() {
    final allUnits = <String>[];

    PantryCategories.commonUnits.forEach((category, units) {
      allUnits.addAll(units);
    });

    return allUnits;
  }

  @override
  Widget build(BuildContext context) {
    final themeController = Provider.of<ThemeController>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditMode ? 'Edit Item' : 'Add New Item',
          style: TextStyle(
            fontFamily: themeController.currentFont,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Item name
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Item Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  labelStyle: TextStyle(
                    color: isDarkMode ? Colors.white70 : Colors.black87,
                    fontFamily: themeController.currentFont,
                  ),
                ),
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black87,
                  fontFamily: themeController.currentFont,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter an item name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Expiry date picker
              InkWell(
                onTap: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: _expiryDate,
                    firstDate: DateTime.now().subtract(Duration(days: 30)), // Allow backdating up to 30 days
                    lastDate: DateTime.now().add(Duration(days: 365 * 3)), // Up to 3 years in the future
                  );

                  if (pickedDate != null && pickedDate != _expiryDate) {
                    setState(() {
                      _expiryDate = pickedDate;
                    });
                  }
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade400,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: Colors.blueAccent,
                      ),
                      SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Expiry Date',
                            style: TextStyle(
                              fontFamily: themeController.currentFont,
                              fontSize: 12,
                              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            DateFormat('MMMM d, yyyy').format(_expiryDate),
                            style: TextStyle(
                              color: isDarkMode ? Colors.white : Colors.black87,
                              fontFamily: themeController.currentFont,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      Spacer(),
                      Text(
                        '${_expiryDate.difference(DateTime.now()).inDays} days left',
                        style: TextStyle(
                          fontFamily: themeController.currentFont,
                          color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),

              // Quantity and unit
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quantity input
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      controller: _quantityController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Quantity',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        labelStyle: TextStyle(
                          color: isDarkMode ? Colors.white70 : Colors.black87,
                          fontFamily: themeController.currentFont,
                        ),
                      ),
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black87,
                        fontFamily: themeController.currentFont,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Enter a number';
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(width: 12),

                  // Unit dropdown
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      value: _quantityUnit,
                      decoration: InputDecoration(
                        labelText: 'Unit',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        labelStyle: TextStyle(
                          color: isDarkMode ? Colors.white70 : Colors.black87,
                          fontFamily: themeController.currentFont,
                        ),
                      ),
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black87,
                        fontFamily: themeController.currentFont,
                      ),
                      dropdownColor: isDarkMode ? Colors.grey[800] : Colors.white,
                      items: _getAllUnits().map((unit) {
                        return DropdownMenuItem<String>(
                          value: unit,
                          child: Text(
                            unit,
                            style: TextStyle(
                              color: isDarkMode ? Colors.white : Colors.black87,
                              fontFamily: themeController.currentFont,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _quantityUnit = value;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),

              // Category dropdown
              DropdownButtonFormField<String>(
                value: _category,
                decoration: InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: Icon(Icons.category),
                  labelStyle: TextStyle(
                    color: isDarkMode ? Colors.white70 : Colors.black87,
                    fontFamily: themeController.currentFont,
                  ),
                ),
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black87,
                  fontFamily: themeController.currentFont,
                ),
                dropdownColor: isDarkMode ? Colors.grey[800] : Colors.white,
                items: PantryCategories.categories.map((category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(
                      category,
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black87,
                        fontFamily: themeController.currentFont,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _category = value;
                    });
                  }
                },
              ),
              SizedBox(height: 16),

              // Location dropdown
              DropdownButtonFormField<String>(
                value: _location,
                decoration: InputDecoration(
                  labelText: 'Storage Location',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: Icon(Icons.place),
                  labelStyle: TextStyle(
                    color: isDarkMode ? Colors.white70 : Colors.black87,
                    fontFamily: themeController.currentFont,
                  ),
                ),
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black87,
                  fontFamily: themeController.currentFont,
                ),
                dropdownColor: isDarkMode ? Colors.grey[800] : Colors.white,
                items: PantryCategories.locations.map((location) {
                  return DropdownMenuItem<String>(
                    value: location,
                    child: Text(
                      location,
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black87,
                        fontFamily: themeController.currentFont,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _location = value;
                    });
                  }
                },
              ),
              SizedBox(height: 16),

              // Notes
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Notes (Optional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignLabelWithHint: true,
                  labelStyle: TextStyle(
                    color: isDarkMode ? Colors.white70 : Colors.black87,
                    fontFamily: themeController.currentFont,
                  ),
                ),
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black87,
                  fontFamily: themeController.currentFont,
                ),
              ),
              SizedBox(height: 32),

              // Save button
              ElevatedButton(
                onPressed: _saveItem,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  isEditMode ? 'Update Item' : 'Add Item',
                  style: TextStyle(
                    fontFamily: themeController.currentFont,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}