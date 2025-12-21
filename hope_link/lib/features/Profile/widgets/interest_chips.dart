import 'package:flutter/material.dart';
import 'package:hope_link/core/theme/app_colors.dart';

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
      runSpacing: 8,
      children: allInterests.map((interest) {
        final isSelected = selected.contains(interest);
        return FilterChip(
          label: Text(
            interest,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.black : Colors.grey[700],
            ),
          ),
          selected: isSelected,
          backgroundColor: Colors.grey[100],
          selectedColor: AppColorToken.primary.color,
          checkmarkColor: Colors.white,
          side: BorderSide(
            color: isSelected ? AppColorToken.primary.color : Colors.grey[300]!,
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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

// class InterestChips extends StatelessWidget {
//   final List<String> allInterests;
//   final List<String> selected;
//   final bool editable;
//   final Function(List<String>) onChanged;

//   const InterestChips({
//     super.key,
//     required this.allInterests,
//     required this.selected,
//     required this.editable,
//     required this.onChanged,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Wrap(
//       spacing: 8,
//       children: allInterests.map((interest) {
//         final isSelected = selected.contains(interest);
//         return FilterChip(
//           label: Text(interest),
//           selected: isSelected,
//           onSelected: !editable
//               ? null
//               : (val) {
//                   final updated = List<String>.from(selected);
//                   val ? updated.add(interest) : updated.remove(interest);
//                   onChanged(updated);
//                 },
//         );
//       }).toList(),
//     );
//   }
// }
