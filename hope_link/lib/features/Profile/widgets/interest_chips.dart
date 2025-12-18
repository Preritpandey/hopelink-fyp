import 'package:flutter/material.dart';

class InterestChips extends StatelessWidget {
  final List<String> allInterests;
  final List<String> selected;
  final bool editable;
  final Function(List<String>) onChanged;

  const InterestChips({
    super.key,
    required this.allInterests,
    required this.selected,
    required this.editable,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: allInterests.map((interest) {
        final isSelected = selected.contains(interest);
        return FilterChip(
          label: Text(interest),
          selected: isSelected,
          onSelected: !editable
              ? null
              : (val) {
                  final updated = List<String>.from(selected);
                  val ? updated.add(interest) : updated.remove(interest);
                  onChanged(updated);
                },
        );
      }).toList(),
    );
  }
}
