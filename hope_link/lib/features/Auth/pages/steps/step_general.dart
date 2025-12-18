import 'package:flutter/material.dart';
import 'package:hope_link/features/Auth/widgets/form_section.dart';

class StepGeneral extends StatefulWidget {
  @override
  State<StepGeneral> createState() => _StepGeneralState();
}

class _StepGeneralState extends State<StepGeneral> {
  final orgName = TextEditingController();
  final orgType = TextEditingController();
  final regNumber = TextEditingController();
  final regDate = TextEditingController();
  final country = TextEditingController();
  final city = TextEditingController();
  final officialEmail = TextEditingController();
  final officialPhone = TextEditingController();
  final website = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey("general"),
      children: [
        FormSection(
          title: "Organization Details",
          child: Column(
            children: [
              TextField(
                controller: orgName,
                decoration: _input("Organization Name"),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: orgType,
                decoration: _input("Organization Type"),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: regNumber,
                decoration: _input("Registration Number"),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: regDate,
                decoration: _input("Date of Registration"),
              ),
              const SizedBox(height: 12),
              TextField(controller: country, decoration: _input("Country")),
              const SizedBox(height: 12),
              TextField(controller: city, decoration: _input("City")),
              const SizedBox(height: 12),
              TextField(
                controller: officialEmail,
                decoration: _input("Official Email"),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: officialPhone,
                decoration: _input("Official Phone"),
              ),
              const SizedBox(height: 12),
              TextField(controller: website, decoration: _input("Website")),
            ],
          ),
        ),
      ],
    );
  }

  InputDecoration _input(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}
