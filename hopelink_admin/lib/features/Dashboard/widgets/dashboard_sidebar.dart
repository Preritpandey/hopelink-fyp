import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../Auth/controller/login_controller.dart';
import '../../Auth/pages/login_page.dart';
import '../controllers/campaign_controller.dart';
import 'dashboard_widgets.dart';

class DashboardSidebar extends StatelessWidget {
  final CampaignController ctrl;
  const DashboardSidebar({super.key, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 232,
      decoration: const BoxDecoration(
        color: Color(0xFF080F1E),
        border: Border(right: BorderSide(color: kBorder)),
      ),
      child: Column(
        children: [
          // Logo
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [kAccent, kAccent2],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: kAccent.withValues(alpha: 0.3),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.volunteer_activism_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'OrgHub',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'Dashboard',
                      style: GoogleFonts.dmSans(
                        fontSize: 10,
                        color: kTextMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Org card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kSurface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: kBorder2),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [kAccent, kAccent2],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Obx(
                        () => Text(
                          ctrl.orgName.isNotEmpty
                              ? ctrl.orgName[0].toUpperCase()
                              : 'O',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Obx(
                      () => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ctrl.orgName,
                            style: GoogleFonts.dmSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: kAccent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Approved',
                              style: GoogleFonts.dmMono(
                                fontSize: 9,
                                color: kAccent,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'NAVIGATION',
              style: GoogleFonts.dmMono(
                fontSize: 9,
                color: kTextMuted,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 8),

          Obx(
            () => Column(
              children: [
                NavItem(
                  icon: Icons.dashboard_rounded,
                  label: 'Dashboard',
                  active: ctrl.currentNavIndex.value == 0,
                  onTap: () => ctrl.navigateTo(0),
                ),
                NavItem(
                  icon: Icons.campaign_rounded,
                  label: 'Campaigns',
                  active: ctrl.currentNavIndex.value == 1,
                  onTap: () => ctrl.navigateTo(1),
                ),
                NavItem(
                  icon: Icons.add_circle_outline_rounded,
                  label: 'Create Campaign',
                  active: ctrl.currentNavIndex.value == 2,
                  onTap: () => ctrl.navigateTo(2),
                ),
                NavItem(
                  icon: Icons.event,
                  label: 'Create Event',
                  active: ctrl.currentNavIndex.value == 3,
                  onTap: () => ctrl.navigateTo(3),
                ),

                NavItem(
                  icon: Icons.work_outline_rounded,
                  label: 'Jobs',
                  active: ctrl.currentNavIndex.value == 4,
                  onTap: () => ctrl.navigateTo(4),
                ),
                NavItem(
                  icon: Icons.workspace_premium_outlined,
                  label: 'Volunteer Credits',
                  active: ctrl.currentNavIndex.value == 5,
                  onTap: () => ctrl.navigateTo(5),
                ),
              ],
            ),
          ),

          const Spacer(),
          const Divider(color: kBorder, height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: NavItem(
              icon: Icons.logout_rounded,
              label: 'Sign Out',
              active: false,
              onTap: () async {
                final loginCtrl = Get.find<LoginController>();
                await loginCtrl.logout();
                Get.offAll(() => const LoginPage());
              },
            ),
          ),
        ],
      ),
    );
  }
}
