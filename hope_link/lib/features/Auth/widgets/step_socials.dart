import 'package:flutter/material.dart';
import 'package:hope_link/features/Auth/widgets/form_section.dart';

class StepSocials extends StatefulWidget {
  @override
  State<StepSocials> createState() => _StepSocialsState();
}

class _StepSocialsState extends State<StepSocials> {
  final facebook = TextEditingController();
  final instagram = TextEditingController();
  final linkedin = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey("socials"),
      children: [
        FormSection(
          title: "Social Media Links",
          child: Column(
            children: [
              TextField(controller: facebook, decoration: _input("Facebook")),
              const SizedBox(height: 12),
              TextField(controller: instagram, decoration: _input("Instagram")),
              const SizedBox(height: 12),
              TextField(controller: linkedin, decoration: _input("LinkedIn")),
            ],
          ),
        ),
      ],
    );
  }

  InputDecoration _input(String label) =>
      InputDecoration(labelText: label, border: OutlineInputBorder());
}
