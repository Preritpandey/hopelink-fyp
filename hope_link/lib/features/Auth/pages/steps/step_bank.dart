import 'package:flutter/material.dart';
import 'package:hope_link/features/Auth/widgets/form_section.dart';

class StepBank extends StatefulWidget {
  @override
  State<StepBank> createState() => _StepBankState();
}

class _StepBankState extends State<StepBank> {
  final bankName = TextEditingController();
  final accHolder = TextEditingController();
  final accNumber = TextEditingController();
  final branch = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey("bank"),
      children: [
        FormSection(
          title: "Bank Account Details",
          child: Column(
            children: [
              TextField(controller: bankName, decoration: _input("Bank Name")),
              const SizedBox(height: 12),
              TextField(
                controller: accHolder,
                decoration: _input("Account Holder Name"),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: accNumber,
                decoration: _input("Account Number"),
              ),
              const SizedBox(height: 12),
              TextField(controller: branch, decoration: _input("Branch")),
            ],
          ),
        ),
      ],
    );
  }

  InputDecoration _input(String label) =>
      InputDecoration(labelText: label, border: OutlineInputBorder());
}
