// widgets/recipe/servings_time_section.dart
import 'package:flutter/material.dart';
import 'package:pantry_pal/theme_controller.dart';
import 'package:provider/provider.dart';

class ServingsTimeSection extends StatelessWidget {
  final int servings;
  final int prepTimeMinutes;
  final int cookTimeMinutes;
  final Function() onDecreaseServings;
  final Function() onIncreaseServings;
  final Function() onDecreasePrepTime;
  final Function() onIncreasePrepTime;
  final Function() onDecreaseCookTime;
  final Function() onIncreaseCookTime;
  final bool isDisabled;

  const ServingsTimeSection({
    Key? key,
    required this.servings,
    required this.prepTimeMinutes,
    required this.cookTimeMinutes,
    required this.onDecreaseServings,
    required this.onIncreaseServings,
    required this.onDecreasePrepTime,
    required this.onIncreasePrepTime,
    required this.onDecreaseCookTime,
    required this.onIncreaseCookTime,
    this.isDisabled = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeController = Provider.of<ThemeController>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        // Servings
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Servings',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFamily: themeController.currentFont,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.remove_circle_outline),
                    onPressed: isDisabled ? null : onDecreaseServings,
                  ),
                  Text(
                    '$servings',
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: themeController.currentFont,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.add_circle_outline),
                    onPressed: isDisabled ? null : onIncreaseServings,
                  ),
                ],
              ),
            ],
          ),
        ),

        // Prep Time
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Prep Time (min)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFamily: themeController.currentFont,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.remove_circle_outline),
                    onPressed: isDisabled ? null : onDecreasePrepTime,
                  ),
                  Text(
                    '$prepTimeMinutes',
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: themeController.currentFont,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.add_circle_outline),
                    onPressed: isDisabled ? null : onIncreasePrepTime,
                  ),
                ],
              ),
            ],
          ),
        ),

        // Cook Time
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cook Time (min)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFamily: themeController.currentFont,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.remove_circle_outline),
                    onPressed: isDisabled ? null : onDecreaseCookTime,
                  ),
                  Text(
                    '$cookTimeMinutes',
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: themeController.currentFont,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.add_circle_outline),
                    onPressed: isDisabled ? null : onIncreaseCookTime,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}