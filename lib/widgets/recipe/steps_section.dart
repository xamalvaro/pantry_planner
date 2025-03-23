// widgets/recipe/steps_section.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pantry_pal/theme_controller.dart';

class StepsSection extends StatelessWidget {
  final List<String> steps;
  final TextEditingController stepController;
  final Function(String) onAddStep;
  final Function(int) onRemoveStep;
  final bool isDisabled;

  const StepsSection({
    Key? key,
    required this.steps,
    required this.stepController,
    required this.onAddStep,
    required this.onRemoveStep,
    this.isDisabled = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeController = Provider.of<ThemeController>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Instructions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: themeController.currentFont,
          ),
        ),
        SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: stepController,
                decoration: InputDecoration(
                  labelText: 'Add a step',
                  hintText: 'Describe what to do',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.add),
                    onPressed: isDisabled ? null : () {
                      if (stepController.text.trim().isNotEmpty) {
                        onAddStep(stepController.text.trim());
                      }
                    },
                  ),
                ),
                maxLines: 3,
                onSubmitted: isDisabled ? null : (value) {
                  if (value.trim().isNotEmpty) {
                    onAddStep(value.trim());
                  }
                },
                enabled: !isDisabled,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        if (steps.isNotEmpty)
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListView.separated(
              physics: NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: steps.length,
              separatorBuilder: (context, index) => Divider(height: 1),
              itemBuilder: (context, index) {
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blueAccent,
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: themeController.currentFont,
                      ),
                    ),
                  ),
                  title: Text(
                    steps[index],
                    style: TextStyle(
                      fontFamily: themeController.currentFont,
                    ),
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.delete_outline, color: Colors.red.shade300),
                    onPressed: isDisabled ? null : () => onRemoveStep(index),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}