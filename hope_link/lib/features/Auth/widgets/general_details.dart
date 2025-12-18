import 'package:flutter/material.dart';
import 'package:hope_link/core/widgets/app_text_field.dart';

class GeneralDetails extends StatelessWidget {
  const GeneralDetails({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomDropdownField<String>(
          items: const ["NGO", "Non-Profit", "Club", "Social Org"],
          itemLabel: (v) => v,
          hintText: "",
        ),
        const SizedBox(height: 16),

        AppTextField(title: "Organization Name", hintText: ""),
        const SizedBox(height: 16),

        AppTextField(title: "Registration Number", hintText: ""),
        const SizedBox(height: 16),

        AppTextField(
          title: "Date of Registration",
          hintText: "",
          readOnly: true,
          onTap: () async {
            DateTime? pick = await showDatePicker(
              context: context,
              firstDate: DateTime(1900),
              lastDate: DateTime.now(),
              initialDate: DateTime.now(),
            );
          },
        ),
        const SizedBox(height: 16),

        CustomDropdownField<String>(
          items: const ["Nepal", "India", "Bhutan"],
          itemLabel: (v) => v,
          hintText: "",
        ),
        const SizedBox(height: 16),

        AppTextField(title: "City", hintText: ""),
        const SizedBox(height: 16),

        AppTextField(title: "Registered Address", hintText: ""),
        const SizedBox(height: 16),

        AppTextField(title: "Primary Cause", hintText: ""),
        const SizedBox(height: 16),

        AppTextField(
          title: "Active Members",
          hintText: "",
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 25),
      ],
    );
  }
}
