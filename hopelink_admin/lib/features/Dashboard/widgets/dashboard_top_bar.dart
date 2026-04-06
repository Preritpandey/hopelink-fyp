import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'dashboard_widgets.dart';

class DashboardTopBar extends StatelessWidget {
  final String title;
  final String sub;
  final List<Widget> actions;
  const DashboardTopBar({
    super.key,
    required this.title,
    required this.sub,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: kBorder)),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: kText,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                sub,
                style: GoogleFonts.dmSans(fontSize: 11, color: kTextSub),
              ),
            ],
          ),
          const Spacer(),
          ...actions,
        ],
      ),
    );
  }
}
