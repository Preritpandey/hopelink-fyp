import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hope_link/core/theme/app_colors.dart';
import 'package:hope_link/features/Profile/pages/profile_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

          // Floating Action Button
          Positioned(
            bottom: 80,
            right: 20,
            child: ScaleTransition(
              scale: _fabAnimation,
              child: FloatingActionButton.extended(
                onPressed: () {
                  // Navigate to create donation/campaign
                },
                backgroundColor: AppColorToken.primary.color,
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  'Start Campaign',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
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
        return _buildHomePage();
      case 1:
        return _buildExplorePage();
      case 2:
        return _buildActivityPage();
      case 3:
        return ProfilePage(token: widget.token);
      default:
        return _buildHomePage();
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
            _buildNavItem(Icons.home_rounded, Icons.home_outlined, 'Home', 0),
            _buildNavItem(
              Icons.explore_rounded,
              Icons.explore_outlined,
              'Explore',
              1,
            ),
            _buildNavItem(
              Icons.favorite_rounded,
              Icons.favorite_border,
              'Activity',
              2,
            ),
            _buildNavItem(
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

  BottomNavigationBarItem _buildNavItem(
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

  Widget _buildHomePage() {
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
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // Content
        // SliverToBoxAdapter(
        //   child: Column(
        //     children: [
        //       _buildStatsSection(),
        //       _buildFeaturedCampaigns(),
        //       _buildCategoriesSection(),
        //       _buildRecentDonations(),
        //       const SizedBox(height: 100),
        //     ],
        //   ),
        // ),
      ],
    );
  }

  // Widget _buildStatsSection() {
  //   return Container(
  //     transform: Matrix4.translationValues(0, -30, 0),
  //     padding: const EdgeInsets.symmetric(horizontal: 20),
  //     child: Container(
  //       padding: const EdgeInsets.all(20),
  //       decoration: BoxDecoration(
  //         color: Colors.white,
  //         borderRadius: BorderRadius.circular(20),
  //         boxShadow: [
  //           BoxShadow(
  //             color: AppColorToken.primary.color.withValues(alpha: 0.1),
  //             blurRadius: 20,
  //             offset: const Offset(0, 10),
  //           ),
  //         ],
  //       ),
  //       child: Row(
  //         mainAxisAlignment: MainAxisAlignment.spaceAround,
  //         children: [
  //           _buildStatItem('1.2K+', 'Campaigns', Icons.campaign),
  //           _buildStatDivider(),
  //           _buildStatItem('\$50K+', 'Raised', Icons.attach_money),
  //           _buildStatDivider(),
  //           _buildStatItem('5K+', 'Donors', Icons.people),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  // Widget _buildStatItem(String value, String label, IconData icon) {
  //   return Column(
  //     children: [
  //       Icon(icon, color: AppColorToken.primary.color, size: 28),
  //       const SizedBox(height: 8),
  //       Text(
  //         value,
  //         style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
  //       ),
  //       const SizedBox(height: 4),
  //       Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
  //     ],
  //   );
  // }

  // Widget _buildStatDivider() {
  //   return Container(height: 50, width: 1, color: Colors.grey[300]);
  // }

  // Widget _buildFeaturedCampaigns() {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Padding(
  //         padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
  //         child: Row(
  //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //           children: [
  //             const Text(
  //               'Featured Campaigns',
  //               style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
  //             ),
  //             TextButton(
  //               onPressed: () {},
  //               child: Text(
  //                 'See All',
  //                 style: TextStyle(color: AppColorToken.primary.color),
  //               ),
  //             ),
  //           ],
  //         ),
  //       ),
  //       SizedBox(
  //         height: 280,
  //         child: ListView.builder(
  //           scrollDirection: Axis.horizontal,
  //           physics: const BouncingScrollPhysics(),
  //           padding: const EdgeInsets.symmetric(horizontal: 16),
  //           itemCount: 5,
  //           itemBuilder: (context, index) => _buildCampaignCard(index),
  //         ),
  //       ),
  //     ],
  //   );
  // }

  // Widget _buildCampaignCard(int index) {
  //   final campaigns = [
  //     {
  //       'title': 'Clean Water for Rural Areas',
  //       'raised': 25000,
  //       'goal': 50000,
  //       'image': Icons.water_drop,
  //       'color': Colors.blue,
  //     },
  //     {
  //       'title': 'Education for Underprivileged',
  //       'raised': 15000,
  //       'goal': 30000,
  //       'image': Icons.school,
  //       'color': Colors.orange,
  //     },
  //     {
  //       'title': 'Medical Aid for Children',
  //       'raised': 35000,
  //       'goal': 50000,
  //       'image': Icons.medical_services,
  //       'color': Colors.red,
  //     },
  //     {
  //       'title': 'Food Distribution Program',
  //       'raised': 20000,
  //       'goal': 40000,
  //       'image': Icons.restaurant,
  //       'color': Colors.green,
  //     },
  //     {
  //       'title': 'Disaster Relief Fund',
  //       'raised': 40000,
  //       'goal': 60000,
  //       'image': Icons.emergency,
  //       'color': Colors.purple,
  //     },
  //   ];

  //   final campaign = campaigns[index % campaigns.length];
  //   final progress = (campaign['raised'] as int) / (campaign['goal'] as int);

  //   return Container(
  //     width: 280,
  //     margin: const EdgeInsets.only(right: 16, bottom: 8, top: 8, left: 4),
  //     decoration: BoxDecoration(
  //       color: Colors.white,
  //       borderRadius: BorderRadius.circular(20),
  //       boxShadow: [
  //         BoxShadow(
  //           color: Colors.black.withValues(alpha: 0.08),
  //           blurRadius: 15,
  //           offset: const Offset(0, 5),
  //         ),
  //       ],
  //     ),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Container(
  //           height: 140,
  //           decoration: BoxDecoration(
  //             gradient: LinearGradient(
  //               colors: [
  //                 (campaign['color'] as Color).withValues(alpha: 0.7),
  //                 (campaign['color'] as Color),
  //               ],
  //             ),
  //             borderRadius: const BorderRadius.only(
  //               topLeft: Radius.circular(20),
  //               topRight: Radius.circular(20),
  //             ),
  //           ),
  //           child: Center(
  //             child: Icon(
  //               campaign['image'] as IconData,
  //               size: 60,
  //               color: Colors.white,
  //             ),
  //           ),
  //         ),
  //         Padding(
  //           padding: const EdgeInsets.all(16),
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               Text(
  //                 campaign['title'] as String,
  //                 style: const TextStyle(
  //                   fontSize: 16,
  //                   fontWeight: FontWeight.bold,
  //                 ),
  //                 maxLines: 2,
  //                 overflow: TextOverflow.ellipsis,
  //               ),
  //               const SizedBox(height: 12),
  //               ClipRRect(
  //                 borderRadius: BorderRadius.circular(10),
  //                 child: LinearProgressIndicator(
  //                   value: progress,
  //                   backgroundColor: Colors.grey[200],
  //                   valueColor: AlwaysStoppedAnimation<Color>(
  //                     campaign['color'] as Color,
  //                   ),
  //                   minHeight: 8,
  //                 ),
  //               ),
  //               const SizedBox(height: 8),
  //               Row(
  //                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                 children: [
  //                   Text(
  //                     '\$${campaign['raised']}',
  //                     style: TextStyle(
  //                       fontWeight: FontWeight.bold,
  //                       color: campaign['color'] as Color,
  //                       fontSize: 16,
  //                     ),
  //                   ),
  //                   Text(
  //                     'of \$${campaign['goal']}',
  //                     style: TextStyle(color: Colors.grey[600], fontSize: 12),
  //                   ),
  //                 ],
  //               ),
  //             ],
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // Widget _buildCategoriesSection() {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       const Padding(
  //         padding: EdgeInsets.fromLTRB(20, 24, 20, 16),
  //         child: Text(
  //           'Browse by Category',
  //           style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
  //         ),
  //       ),
  //       Padding(
  //         padding: const EdgeInsets.symmetric(horizontal: 20),
  //         child: GridView.count(
  //           shrinkWrap: true,
  //           physics: const NeverScrollableScrollPhysics(),
  //           crossAxisCount: 4,
  //           mainAxisSpacing: 16,
  //           crossAxisSpacing: 16,
  //           children: [
  //             _buildCategoryItem(Icons.health_and_safety, 'Health', Colors.red),
  //             _buildCategoryItem(Icons.school, 'Education', Colors.blue),
  //             _buildCategoryItem(Icons.nature, 'Environment', Colors.green),
  //             _buildCategoryItem(Icons.food_bank, 'Food', Colors.orange),
  //             _buildCategoryItem(Icons.home, 'Shelter', Colors.purple),
  //             _buildCategoryItem(Icons.pets, 'Animals', Colors.brown),
  //             _buildCategoryItem(Icons.sports, 'Sports', Colors.teal),
  //             _buildCategoryItem(
  //               Icons.volunteer_activism,
  //               'Other',
  //               Colors.pink,
  //             ),
  //           ],
  //         ),
  //       ),
  //     ],
  //   );
  // }

  // Widget _buildCategoryItem(IconData icon, String label, Color color) {
  //   return Column(
  //     children: [
  //       Container(
  //         width: 60,
  //         height: 60,
  //         decoration: BoxDecoration(
  //           color: color.withValues(alpha: 0.1),
  //           borderRadius: BorderRadius.circular(15),
  //         ),
  //         child: Icon(icon, color: color, size: 30),
  //       ),
  //       const SizedBox(height: 8),
  //       Text(
  //         label,
  //         style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
  //         textAlign: TextAlign.center,
  //       ),
  //     ],
  //   );
  // }

  // Widget _buildRecentDonations() {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       const Padding(
  //         padding: EdgeInsets.fromLTRB(20, 24, 20, 16),
  //         child: Text(
  //           'Recent Donations',
  //           style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
  //         ),
  //       ),
  //       ListView.builder(
  //         shrinkWrap: true,
  //         physics: const NeverScrollableScrollPhysics(),
  //         padding: const EdgeInsets.symmetric(horizontal: 20),
  //         itemCount: 5,
  //         itemBuilder: (context, index) {
  //           return Container(
  //             margin: const EdgeInsets.only(bottom: 12),
  //             padding: const EdgeInsets.all(16),
  //             decoration: BoxDecoration(
  //               color: Colors.white,
  //               borderRadius: BorderRadius.circular(15),
  //               border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
  //             ),
  //             child: Row(
  //               children: [
  //                 CircleAvatar(
  //                   radius: 25,
  //                   backgroundColor: AppColorToken.primary.color.withValues(
  //                     alpha: 0.1,
  //                   ),
  //                   child: Icon(
  //                     Icons.person,
  //                     color: AppColorToken.primary.color,
  //                   ),
  //                 ),
  //                 const SizedBox(width: 12),
  //                 Expanded(
  //                   child: Column(
  //                     crossAxisAlignment: CrossAxisAlignment.start,
  //                     children: [
  //                       const Text(
  //                         'Anonymous Donor',
  //                         style: TextStyle(
  //                           fontWeight: FontWeight.bold,
  //                           fontSize: 14,
  //                         ),
  //                       ),
  //                       const SizedBox(height: 4),
  //                       Text(
  //                         'donated to Clean Water Project',
  //                         style: TextStyle(
  //                           color: Colors.grey[600],
  //                           fontSize: 12,
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //                 ),
  //                 Text(
  //                   '\$${(index + 1) * 50}',
  //                   style: TextStyle(
  //                     fontWeight: FontWeight.bold,
  //                     color: AppColorToken.primary.color,
  //                     fontSize: 16,
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           );
  //         },
  //       ),
  //     ],
  //   );
  // }

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

  Widget _buildProfilePage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Profile Page',
            style: TextStyle(fontSize: 24, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
