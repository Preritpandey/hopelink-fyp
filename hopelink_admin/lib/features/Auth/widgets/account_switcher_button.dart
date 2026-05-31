import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hopelink_admin/features/Admin/Home/pages/admin_home_page.dart';
import 'package:hopelink_admin/features/Auth/pages/login_page.dart';
import 'package:hopelink_admin/features/Auth/services/account_switcher_service.dart';
import 'package:hopelink_admin/features/Dashboard/home_page.dart';

class AccountSwitcherButton extends StatefulWidget {
  final Color backgroundColor;
  final Color hoverColor;
  final Color borderColor;
  final Color accentColor;
  final Color textColor;
  final Color mutedColor;
  final bool expanded;

  const AccountSwitcherButton({
    super.key,
    required this.backgroundColor,
    required this.hoverColor,
    required this.borderColor,
    required this.accentColor,
    required this.textColor,
    required this.mutedColor,
    this.expanded = false,
  });

  @override
  State<AccountSwitcherButton> createState() => _AccountSwitcherButtonState();
}

class _AccountSwitcherButtonState extends State<AccountSwitcherButton> {
  final _service = AccountSwitcherService();
  List<SavedAccount> _accounts = const [];
  String? _activeEmail;
  bool _loading = true;
  bool _switching = false;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    final accounts = await _service.getAccounts();
    final activeEmail = await _service.getActiveEmail();
    if (!mounted) return;
    setState(() {
      _accounts = accounts;
      _activeEmail = activeEmail;
      _loading = false;
    });
  }

  Future<void> _switchTo(SavedAccount account) async {
    if (_switching || account.email == _activeEmail) return;
    setState(() => _switching = true);

    try {
      final user = await _service.switchTo(account);
      if (user.role.toLowerCase() == 'admin') {
        Get.offAll(() => const AdminHomePage());
      } else {
        Get.offAll(() => const DashboardShell());
      }
    } on AccountSwitchException catch (e) {
      _showMessage(e.message, isError: true);
      await _loadAccounts();
    } finally {
      if (mounted) setState(() => _switching = false);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    Get.snackbar(
      isError ? 'Account switch failed' : 'Account switched',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: isError ? const Color(0xFFFF4C6A) : widget.accentColor,
      colorText: Colors.black,
      margin: const EdgeInsets.all(16),
      maxWidth: 420,
      duration: const Duration(seconds: 3),
    );
  }

  @override
  Widget build(BuildContext context) {
    final active = _findAccount(_activeEmail);

    return PopupMenuButton<String>(
      tooltip: 'Switch account',
      color: widget.hoverColor,
      offset: const Offset(0, -8),
      onOpened: _loadAccounts,
      onSelected: (value) {
        if (value == '__login__') {
          Get.offAll(() => const LoginPage(addAccountMode: true));
          return;
        }
        final selected = _findAccount(value);
        if (selected != null) _switchTo(selected);
      },
      itemBuilder: (_) {
        if (_loading) {
          return [
            const PopupMenuItem<String>(
              enabled: false,
              child: SizedBox(
                width: 220,
                height: 44,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            ),
          ];
        }

        return [
          ..._accounts.map(
            (account) => PopupMenuItem<String>(
              value: account.email,
              enabled: !_switching && account.email != _activeEmail,
              child: _AccountMenuItem(
                account: account,
                active: account.email == _activeEmail,
                accentColor: widget.accentColor,
                textColor: widget.textColor,
                mutedColor: widget.mutedColor,
              ),
            ),
          ),
          const PopupMenuDivider(),
          PopupMenuItem<String>(
            value: '__login__',
            child: Row(
              children: [
                Icon(
                  Icons.person_add_alt_1_rounded,
                  size: 18,
                  color: widget.accentColor,
                ),
                const SizedBox(width: 10),
                Text(
                  'Add another account',
                  style: GoogleFonts.dmSans(
                    color: widget.textColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ];
      },
      child: _SwitcherSurface(
        account: active,
        expanded: widget.expanded,
        switching: _switching,
        backgroundColor: widget.backgroundColor,
        borderColor: widget.borderColor,
        accentColor: widget.accentColor,
        textColor: widget.textColor,
        mutedColor: widget.mutedColor,
      ),
    );
  }

  SavedAccount? _findAccount(String? email) {
    if (email == null) return null;
    for (final account in _accounts) {
      if (account.email == email) return account;
    }
    return null;
  }
}

class _SwitcherSurface extends StatelessWidget {
  final SavedAccount? account;
  final bool expanded;
  final bool switching;
  final Color backgroundColor;
  final Color borderColor;
  final Color accentColor;
  final Color textColor;
  final Color mutedColor;

  const _SwitcherSurface({
    required this.account,
    required this.expanded,
    required this.switching,
    required this.backgroundColor,
    required this.borderColor,
    required this.accentColor,
    required this.textColor,
    required this.mutedColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: expanded ? null : 38,
      padding: EdgeInsets.symmetric(
        horizontal: expanded ? 12 : 10,
        vertical: expanded ? 10 : 0,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
        children: [
          _Avatar(label: account?.initials ?? 'A', accentColor: accentColor),
          if (expanded) ...[
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    account?.displayName ?? 'Switch account',
                    style: GoogleFonts.dmSans(
                      color: textColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    switching
                        ? 'Switching...'
                        : account?.subtitle ?? 'Saved accounts',
                    style: GoogleFonts.dmSans(color: mutedColor, fontSize: 10),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(width: 8),
            Text(
              switching ? 'Switching' : 'Switch',
              style: GoogleFonts.dmSans(
                color: textColor,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(width: 8),
          Icon(Icons.keyboard_arrow_down_rounded, color: mutedColor, size: 18),
        ],
      ),
    );
  }
}

class _AccountMenuItem extends StatelessWidget {
  final SavedAccount account;
  final bool active;
  final Color accentColor;
  final Color textColor;
  final Color mutedColor;

  const _AccountMenuItem({
    required this.account,
    required this.active,
    required this.accentColor,
    required this.textColor,
    required this.mutedColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      child: Row(
        children: [
          _Avatar(label: account.initials, accentColor: accentColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  account.displayName,
                  style: GoogleFonts.dmSans(
                    color: textColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  account.email,
                  style: GoogleFonts.dmSans(color: mutedColor, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (active)
            Icon(Icons.check_circle_rounded, color: accentColor, size: 18),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String label;
  final Color accentColor;

  const _Avatar({required this.label, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.16),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            color: accentColor,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
