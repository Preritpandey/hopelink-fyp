import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hope_link/core/theme/app_colors.dart';
import 'package:hope_link/features/Auth/pages/forgot_password_page.dart';
import 'package:hope_link/features/Donate%20Funds/pages/campaigns_list_page.dart';
import 'package:hope_link/features/Profile/pages/profile_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/widgets/app_button.dart';
import '../../Auth/pages/login_page.dart';

class HomePage extends StatefulWidget {
  Future<void> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
  }

  final String token;
  const HomePage({super.key, required this.token});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _fabAnimationController;
  late AnimationController _contentAnimationController;
  late Animation<double> _fabAnimation;
  late Animation<double> _contentFadeAnimation;
  late Animation<Offset> _contentSlideAnimation;

  @override
  void initState() {
    super.initState();

    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _contentAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fabAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.easeOut),
    );

    _contentFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentAnimationController,
        curve: Curves.easeIn,
      ),
    );

    _contentSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _contentAnimationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _fabAnimationController.forward();
    _contentAnimationController.forward();
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    _contentAnimationController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
      _contentAnimationController.reset();
      _contentAnimationController.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Content
          FadeTransition(
            opacity: _contentFadeAnimation,
            child: SlideTransition(
              position: _contentSlideAnimation,
              child: _getPageContent(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _getPageContent() {
    switch (_currentIndex) {
      case 0:
        return homePage();
      case 1:
        return CampaignsListPage();
      case 2:
        return ForgotPasswordPage();
      case 3:
        return ProfilePage(token: widget.token);
      default:
        return homePage();
    }
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppColorToken.primary.color,
          unselectedItemColor: Colors.grey[400],
          selectedFontSize: 12,
          unselectedFontSize: 12,
          showUnselectedLabels: true,
          elevation: 0,
          items: [
            bottomNavItem(Icons.home_rounded, Icons.home_outlined, 'Home', 0),
            bottomNavItem(
              Icons.explore_rounded,
              Icons.explore_outlined,
              'Explore',
              1,
            ),
            bottomNavItem(
              Icons.favorite_rounded,
              Icons.favorite_border,
              'Activity',
              2,
            ),
            bottomNavItem(
              Icons.person_rounded,
              Icons.person_outline,
              'Profile',
              3,
            ),
          ],
        ),
      ),
    );
  }

  BottomNavigationBarItem bottomNavItem(
    IconData selectedIcon,
    IconData unselectedIcon,
    String label,
    int index,
  ) {
    final isSelected = _currentIndex == index;
    return BottomNavigationBarItem(
      icon: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColorToken.primary.color.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(isSelected ? selectedIcon : unselectedIcon, size: 26),
      ),
      label: label,
    );
  }

  Widget homePage() {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // App Bar
        SliverAppBar(
          expandedHeight: 200,
          floating: false,
          pinned: true,
          backgroundColor: AppColorToken.primary.color,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColorToken.primary.color,
                    AppColorToken.primary.color.withValues(alpha: 0.8),
                  ],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Text(
                        'Make a Difference',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Together we can change lives',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 16,
                        ),
                      ),
                      AppButton(
                        title: "Logout",
                        onPressed: () async {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.clear();
                          Get.to(() => LoginPage());
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExplorePage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.explore, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Explore Page',
            style: TextStyle(fontSize: 24, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityPage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Activity Page',
            style: TextStyle(fontSize: 24, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
