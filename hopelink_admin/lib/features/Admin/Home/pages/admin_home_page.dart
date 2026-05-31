import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hopelink_admin/features/Admin/organizations/pages/organization_approval_page.dart';
import 'package:hopelink_admin/features/Admin/reports/pages/admin_reports_page.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070D18),
      body: Row(
        children: [
          NavigationRail(
            backgroundColor: const Color(0xFF0A111F),
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() => _selectedIndex = index);
            },
            minWidth: 82,
            groupAlignment: -0.82,
            selectedIconTheme: const IconThemeData(color: Color(0xFF38BDF8)),
            unselectedIconTheme: const IconThemeData(color: Color(0xFF8EA1BD)),
            selectedLabelTextStyle: GoogleFonts.dmSans(
              color: const Color(0xFFE5EEFB),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
            unselectedLabelTextStyle: GoogleFonts.dmSans(
              color: const Color(0xFF8EA1BD),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            labelType: NavigationRailLabelType.all,
            leading: Padding(
              padding: const EdgeInsets.only(top: 18, bottom: 28),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.35),
                  ),
                ),
                child: const Icon(
                  Icons.admin_panel_settings_rounded,
                  color: Color(0xFF38BDF8),
                ),
              ),
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.domain_verification_outlined),
                selectedIcon: Icon(Icons.domain_verification_rounded),
                label: Text('Orgs'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.fact_check_outlined),
                selectedIcon: Icon(Icons.fact_check_rounded),
                label: Text('Reports'),
              ),
            ],
          ),
          const VerticalDivider(width: 1, color: Color(0xFF243148)),
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: const [OrganizationApprovalPage(), AdminReportsPage()],
            ),
          ),
        ],
      ),
    );
  }
}
