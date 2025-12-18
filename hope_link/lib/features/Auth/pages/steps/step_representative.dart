import 'package:flutter/material.dart';
import '../../widgets/form_section.dart';

class StepRepresentative extends StatefulWidget {
  @override
  State<StepRepresentative> createState() => _StepRepresentativeState();
}

class _StepRepresentativeState extends State<StepRepresentative> {
  final repName = TextEditingController();
  final designation = TextEditingController();
  final primaryCause = TextEditingController();
  final mission = TextEditingController();
  final activeMembers = TextEditingController();
  final recentCampaigns = TextEditingController();
  final address = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey("rep"),
      children: [
        FormSection(
          title: "Representative Details",
          child: Column(
            children: [
              TextField(
                controller: repName,
                decoration: _input("Representative Name"),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: designation,
                decoration: _input("Designation"),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: primaryCause,
                decoration: _input("Primary Cause"),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: mission,
                decoration: _input("Mission Statement"),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: activeMembers,
                decoration: _input("Active Members"),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: recentCampaigns,
                decoration: _input("Recent Campaigns"),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: address,
                decoration: _input("Registered Address"),
              ),
            ],
          ),
        ),
      ],
    );
  }

  InputDecoration _input(String label) =>
      InputDecoration(labelText: label, border: OutlineInputBorder());
}
