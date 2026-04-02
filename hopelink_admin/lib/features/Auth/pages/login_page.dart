import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../Dashboard/home_page.dart';
import '../controller/login_controller.dart';
import '../widgets/login_widget.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.03),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut));
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060D1A),
      body: Stack(
        children: [
          // ── Background mesh ─────────────────────────────────
          const _BackgroundMesh(),

          // ── Content ─────────────────────────────────────────
          FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: Row(
                children: [
                  // ── Left decorative panel ──────────────────
                  Expanded(flex: 5, child: _LeftPanel()),
                  // ── Right login form ───────────────────────
                  Expanded(flex: 4, child: _RightPanel()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  BACKGROUND MESH  (animated gradient orbs)
// ─────────────────────────────────────────────────────────────
class _BackgroundMesh extends StatefulWidget {
  const _BackgroundMesh();

  @override
  State<_BackgroundMesh> createState() => _BackgroundMeshState();
}

class _BackgroundMeshState extends State<_BackgroundMesh>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final t = _anim.value;
        return CustomPaint(
          painter: _MeshPainter(t),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

class _MeshPainter extends CustomPainter {
  final double t;
  _MeshPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    // Orb 1 — teal top-left
    _drawOrb(
      canvas,
      Offset(size.width * (0.08 + t * 0.04), size.height * (0.12 + t * 0.06)),
      size.width * 0.28,
      const Color(0xFF00D4AA).withOpacity(0.07),
    );
    // Orb 2 — blue right
    _drawOrb(
      canvas,
      Offset(size.width * (0.75 - t * 0.03), size.height * (0.65 + t * 0.05)),
      size.width * 0.22,
      const Color(0xFF00A3FF).withOpacity(0.06),
    );
    // Orb 3 — purple mid
    _drawOrb(
      canvas,
      Offset(size.width * (0.45 + t * 0.04), size.height * (0.35 - t * 0.04)),
      size.width * 0.18,
      const Color(0xFFB47FFF).withOpacity(0.05),
    );
  }

  void _drawOrb(Canvas canvas, Offset center, double radius, Color color) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [color, color.withOpacity(0)],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(_MeshPainter old) => old.t != t;
}

// ─────────────────────────────────────────────────────────────
//  LEFT PANEL
// ─────────────────────────────────────────────────────────────
class _LeftPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: Color(0xFF0E1E35), width: 1)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const OrgHubLogo(),
            const SizedBox(height: 56),
            const Expanded(child: SidePanelContent()),
            // Bottom dots nav
            _DotsDecor(),
          ],
        ),
      ),
    );
  }
}

class _DotsDecor extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        12,
        (i) => Padding(
          padding: const EdgeInsets.only(right: 6),
          child: Container(
            width: i == 0 ? 20 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: i == 0 ? const Color(0xFF00D4AA) : const Color(0xFF1A2E4A),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  RIGHT PANEL  (the login form)
// ─────────────────────────────────────────────────────────────
class _RightPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(LoginController());

    return Container(
      color: const Color(0xFF06101E),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 52, vertical: 40),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Obx(() {
              // ── Show welcome card after login ───────────────
              if (ctrl.loginSuccess.value && ctrl.currentUser.value != null) {
                return _buildSuccessView(ctrl);
              }
              // ── Login form ──────────────────────────────────
              return _buildForm(ctrl);
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessView(LoginController ctrl) {
    final user = ctrl.currentUser.value!;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: Column(
        key: const ValueKey('success'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _formHeader(
            'Welcome back,',
            user.name,
            'You are signed in to your organization portal.',
          ),
          const SizedBox(height: 28),
          UserWelcomeCard(
            name: user.name,
            email: user.email,
            orgName: user.organization.name,
            orgType: user.organization.type,
            orgStatus: user.organization.status,
            onLogout: ctrl.logout,
          ),
          const SizedBox(height: 20),
          _GlassButton(
            label: 'Go to Dashboard',
            icon: Icons.dashboard_rounded,
            onTap: () => Get.to(() => const DashboardShell()),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(LoginController ctrl) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      child: Column(
        key: const ValueKey('form'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _formHeader(
            'Sign in to',
            'Your Organization',
            'Access your dashboard, manage campaigns, and more.',
          ),
          const SizedBox(height: 32),

          // Form
          Form(
            key: ctrl.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Email
                LoginTextField(
                  controller: ctrl.emailCtrl,
                  label: 'EMAIL ADDRESS',
                  hint: 'org@example.com',
                  prefixIcon: Icons.alternate_email_rounded,
                  keyboardType: TextInputType.emailAddress,
                  focusNode: ctrl.emailFocus,
                  nextFocus: ctrl.passwordFocus,
                  validator: ctrl.validateEmail,
                ),
                const SizedBox(height: 18),

                // Password
                Obx(
                  () => LoginTextField(
                    controller: ctrl.passwordCtrl,
                    label: 'PASSWORD',
                    hint: '••••••••••••',
                    prefixIcon: Icons.lock_outline_rounded,
                    obscure: ctrl.obscurePassword.value,
                    focusNode: ctrl.passwordFocus,
                    validator: ctrl.validatePassword,
                    onFieldSubmitted: (_) => ctrl.login(),
                    suffixWidget: IconButton(
                      onPressed: ctrl.toggleObscure,
                      icon: Icon(
                        ctrl.obscurePassword.value
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 17,
                        color: const Color(0xFF3D5580),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Remember me + forgot
                Row(
                  children: [
                    Obx(
                      () => SizedBox(
                        width: 18,
                        height: 18,
                        child: Checkbox(
                          value: ctrl.rememberMe.value,
                          onChanged: ctrl.toggleRemember,
                          activeColor: const Color(0xFF00D4AA),
                          checkColor: Colors.black,
                          side: const BorderSide(
                            color: Color(0xFF1E3050),
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Remember me',
                      style: GoogleFonts.dmSans(
                        fontSize: 12.5,
                        color: const Color(0xFF4A6688),
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        // Get.toNamed('/forgot-password');
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Forgot password?',
                        style: GoogleFonts.dmSans(
                          fontSize: 12.5,
                          color: const Color(0xFF00D4AA),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Error banner
                Obx(() => ErrorBanner(message: ctrl.errorMessage.value)),
                Obx(
                  () => ctrl.errorMessage.value.isNotEmpty
                      ? const SizedBox(height: 16)
                      : const SizedBox.shrink(),
                ),

                // Login button
                Obx(
                  () => LoginButton(
                    isLoading: ctrl.isLoading.value,
                    onTap: ctrl.login,
                  ),
                ),

                const SizedBox(height: 28),
                const GradientDivider(),
                const SizedBox(height: 20),

                // Register link
                Center(
                  child: RichText(
                    text: TextSpan(
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: const Color(0xFF3D5580),
                      ),
                      children: [
                        const TextSpan(text: "Don't have an account? "),
                        WidgetSpan(
                          child: GestureDetector(
                            onTap: () {
                              // Get.toNamed('/register');
                            },
                            child: Text(
                              'Register your organization',
                              style: GoogleFonts.dmSans(
                                fontSize: 13,
                                color: const Color(0xFF00D4AA),
                                fontWeight: FontWeight.w600,
                              ),
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
        ],
      ),
    );
  }

  Widget _formHeader(String topLine, String name, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          topLine,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: const Color(0xFF4A6688),
            fontWeight: FontWeight.w500,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          name,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.8,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            color: const Color(0xFF3D5580),
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  GLASS BUTTON  (used on success screen)
// ─────────────────────────────────────────────────────────────
class _GlassButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _GlassButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<_GlassButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: double.infinity,
          height: 48,
          decoration: BoxDecoration(
            color: _hovered ? const Color(0xFF112034) : const Color(0xFF0C1A2C),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _hovered
                  ? const Color(0xFF00D4AA).withOpacity(0.4)
                  : const Color(0xFF1A2E4A),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                size: 16,
                color: _hovered
                    ? const Color(0xFF00D4AA)
                    : const Color(0xFF4A6688),
              ),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _hovered ? Colors.white : const Color(0xFF4A6688),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
