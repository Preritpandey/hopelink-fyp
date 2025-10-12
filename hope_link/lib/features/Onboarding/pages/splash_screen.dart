import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:hope_link/core/extensions/num_extension.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _imageController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _topImageAnimation;
  late Animation<Offset> _bottomImageAnimation;

  @override
  void initState() {
    super.initState();

    /// Logo animation
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeInOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _animationController.forward();

    /// Decorative images animation
    _imageController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _topImageAnimation =
        Tween<Offset>(
          begin: const Offset(0, -0.05), // slightly up
          end: const Offset(0, 0.05), // slightly down
        ).animate(
          CurvedAnimation(parent: _imageController, curve: Curves.easeInOut),
        );

    _bottomImageAnimation =
        Tween<Offset>(
          begin: const Offset(0.05, 0), // slightly right
          end: const Offset(-0.05, 0), // slightly left
        ).animate(
          CurvedAnimation(parent: _imageController, curve: Curves.easeInOut),
        );

    /// Navigate after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    /// Transparent system bars
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      body: Stack(
        children: [
          /// Background
          Positioned.fill(
            child: ClipPath(
              clipper: BackgroundClipper(),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFFF5F3F0),
                      Color(0xFFEAE7E0),
                      Color(0xFFF8F6F2),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ),

          /// Top-left image with animation
          Positioned(
            top: 0,
            left: -30,
            child: SlideTransition(
              position: _topImageAnimation,
              child: Transform.rotate(
                angle: -math.pi / 12,
                child: Padding(
                  padding: const EdgeInsets.only(top: 40.0),
                  child: Image.asset(
                    "assets/images/charity_helping_hands.png",
                    width: 180,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),

          /// Bottom-right image with animation
          Positioned(
            bottom: -30,
            right: -30,
            child: SlideTransition(
              position: _bottomImageAnimation,
              child: Transform.rotate(
                angle: math.pi / 14,
                child: Image.asset(
                  "assets/images/giving_help.png",
                  width: 200,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          /// Center logo with fade + scale animation
          Center(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo text
                        RichText(
                          text: const TextSpan(
                            children: [
                              TextSpan(
                                text: 'metro',
                                style: TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.w300,
                                  color: Color(0xFFFF8C42),
                                  letterSpacing: 2,
                                ),
                              ),
                              TextSpan(
                                text: 'cery',
                                style: TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF2E7D32),
                                  letterSpacing: 2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Loading line
                        Container(
                          width: 40,
                          height: 3,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF8C42), Color(0xFF2E7D32)],
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Curved background clipper
class BackgroundClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height * 0.85);

    path.quadraticBezierTo(
      size.width * 0.25,
      size.height,
      size.width * 0.5,
      size.height * 0.9,
    );

    path.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.8,
      size.width,
      size.height * 0.95,
    );

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// Dummy HomeScreen
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          "Welcome to Home Screen 🎉",
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
