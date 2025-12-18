import 'package:flutter/material.dart';
import 'package:hope_link/features/Auth/pages/steps/step_bank.dart';
import 'package:hope_link/features/Auth/pages/steps/step_documents.dart';
import 'package:hope_link/features/Auth/pages/steps/step_general.dart';
import 'package:hope_link/features/Auth/pages/steps/step_header.dart';
import 'package:hope_link/features/Auth/pages/steps/step_representative.dart';
import 'package:hope_link/features/Auth/widgets/step_socials.dart';

class OrginazationRegistrationPage extends StatefulWidget {
  OrginazationRegistrationPage({super.key});

  @override
  State<OrginazationRegistrationPage> createState() =>
      _OrginazationRegistrationPageState();
}

class _OrginazationRegistrationPageState
    extends State<OrginazationRegistrationPage> {
  int currentStep = 0;

  final pages = [
    StepGeneral(),
    StepSocials(),
    StepRepresentative(),
    StepBank(),
    StepDocuments(),
  ];

  void goToStep(int step) {
    setState(() => currentStep = step);
  }

  void next() {
    if (currentStep < pages.length - 1) {
      setState(() => currentStep++);
    }
  }

  void back() {
    if (currentStep > 0) {
      setState(() => currentStep--);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF2F2F7),
      body: Center(
        child: SizedBox(
          width: 900,
          child: Column(
            children: [
              const SizedBox(height: 35),

              StepHeader(currentStep: currentStep, onStepSelected: goToStep),

              const SizedBox(height: 25),

              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  switchInCurve: Curves.easeInOut,
                  child: pages[currentStep],
                ),
              ),

              const SizedBox(height: 10),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: currentStep == 0 ? null : back,
                    child: const Text("← Back"),
                  ),
                  ElevatedButton(
                    onPressed: next,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 14,
                      ),
                    ),
                    child: Text(
                      currentStep == pages.length - 1 ? "Finish" : "Next →",
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 25),
            ],
          ),
        ),
      ),
    );
  }
}
