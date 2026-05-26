import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
import '../screens/dashboard_screen.dart';
import '../screens/tasks_screen.dart';
import '../screens/categories_screen.dart';
import '../screens/history_screen.dart';
import '../screens/profile_screen.dart';

class ResponsiveLayout extends StatefulWidget {
  const ResponsiveLayout({super.key});

  @override
  State<ResponsiveLayout> createState() => _ResponsiveLayoutState();
}

class _ResponsiveLayoutState extends State<ResponsiveLayout> {
  int _currentIndex = 0;
  int? _preselectedCategoryId;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 768;
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    // Deep Indigo Accent Palette
    const primaryColor = Color(0xFF4F46E5); 

    final lang = Provider.of<LanguageProvider>(context);

    // List halaman tab yang akan ditampilkan di aplikasi.
    // Dibuat dinamis agar bisa mendeteksi state filter kategori yang dikirim dari tab Kategori.
    final List<Widget> screens = [
      const DashboardScreen(),
      // Mengirimkan filter kategori aktif ke TasksScreen
      TasksScreen(preselectedCategoryId: _preselectedCategoryId),
      // Menerima callback klik dari CategoriesScreen untuk mengarahkan ke tab Tasks & memasang filter
      CategoriesScreen(onCategorySelected: (catId) {
        setState(() {
          _preselectedCategoryId = catId; // Simpan ID kategori terpilih
          _currentIndex = 1; // Pindah otomatis ke tab Tasks (index 1)
        });
      }),
      const HistoryScreen(),
      const ProfileScreen(),
    ];

    if (isMobile) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC), // Slate 50
        // Menggunakan rendering kondisional screens[index] alih-alih IndexedStack.
        // Ini memastikan halaman memuat ulang data (initState terpanggil) setiap kali user berpindah tab,
        // sehingga data jumlah task pada kategori selalu akurat dan terupdate secara real-time.
        body: screens[_currentIndex],
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: BottomNavigationBar(
                currentIndex: _currentIndex,
                onTap: (index) {
                  setState(() {
                    _currentIndex = index;
                    if (index != 1) {
                      _preselectedCategoryId = null; // Clear filter when switching tabs
                    }
                  });
                },
                elevation: 0,
                backgroundColor: Colors.transparent,
                type: BottomNavigationBarType.fixed,
                selectedItemColor: primaryColor,
                unselectedItemColor: const Color(0xFF94A3B8), // Slate 400
                selectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  fontFamily: 'Outfit',
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                  fontFamily: 'Outfit',
                ),
                items: [
                  BottomNavigationBarItem(
                    icon: const Icon(CupertinoIcons.square_grid_2x2),
                    activeIcon: const Icon(CupertinoIcons.square_grid_2x2_fill),
                    label: lang.translate('nav_dashboard'),
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(CupertinoIcons.list_bullet),
                    activeIcon: const Icon(CupertinoIcons.list_bullet),
                    label: lang.translate('nav_tasks'),
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(CupertinoIcons.folder),
                    activeIcon: const Icon(CupertinoIcons.folder_fill),
                    label: lang.translate('nav_category'),
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(CupertinoIcons.clock),
                    activeIcon: const Icon(CupertinoIcons.clock_fill),
                    label: lang.translate('nav_history'),
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(CupertinoIcons.person),
                    activeIcon: const Icon(CupertinoIcons.person_fill),
                    label: lang.translate('nav_profile'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Desktop Layout with Sleek Left Sidebar
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // Slate 100
      body: Row(
        children: [
          // Elegant Desktop Sidebar
          Container(
            width: 260,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 20,
                  offset: const Offset(4, 0),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo Area
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 40, 24, 30),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          CupertinoIcons.checkmark_seal_fill,
                          color: primaryColor,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'TaskFlow',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                          fontFamily: 'Outfit',
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),

                // User Information Panel
                if (user != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFF1F5F9)),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: primaryColor.withOpacity(0.1),
                            child: Text(
                              user.name.substring(0, 1).toUpperCase(),
                              style: const TextStyle(
                                color: primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.name,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                    fontFamily: 'Outfit',
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  user.email,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                    fontFamily: 'Outfit',
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 20),

                // Navigation Items
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        _buildSidebarItem(0, CupertinoIcons.square_grid_2x2, CupertinoIcons.square_grid_2x2_fill, lang.translate('nav_dashboard')),
                        _buildSidebarItem(1, CupertinoIcons.list_bullet, CupertinoIcons.list_bullet, lang.translate('nav_tasks')),
                        _buildSidebarItem(2, CupertinoIcons.folder, CupertinoIcons.folder_fill, lang.translate('nav_category')),
                        _buildSidebarItem(3, CupertinoIcons.clock, CupertinoIcons.clock_fill, lang.translate('nav_history')),
                        _buildSidebarItem(4, CupertinoIcons.person, CupertinoIcons.person_fill, lang.translate('nav_profile')),
                      ],
                    ),
                  ),
                ),

                // Logout Bottom Panel
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: InkWell(
                    onTap: () {
                      _showLogoutConfirm(context, authProvider);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2), // Rose 50
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(CupertinoIcons.square_arrow_right, color: Colors.redAccent, size: 20),
                          const SizedBox(width: 10),
                          Text(
                            lang.translate('logout'),
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              fontFamily: 'Outfit',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Main Panel
          Expanded(
            child: screens[_currentIndex],
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(int index, IconData icon, IconData activeIcon, String title) {
    final isActive = _currentIndex == index;
    const activeColor = Color(0xFF4F46E5);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: InkWell(
        onTap: () {
          setState(() {
            _currentIndex = index;
            if (index != 1) {
              _preselectedCategoryId = null; // Clear filter
            }
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: isActive ? activeColor.withOpacity(0.08) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                isActive ? activeIcon : icon,
                color: isActive ? activeColor : const Color(0xFF64748B),
                size: 22,
              ),
              const SizedBox(width: 14),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive ? activeColor : const Color(0xFF475569),
                  fontFamily: 'Outfit',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutConfirm(BuildContext context, AuthProvider auth) {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(lang.translate('confirm_logout'), style: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold)),
        content: Text(lang.translate('logout_confirm_msg'), style: const TextStyle(fontFamily: 'Outfit')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(lang.translate('cancel'), style: const TextStyle(color: Color(0xFF64748B), fontFamily: 'Outfit')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              auth.logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(lang.translate('logout'), style: const TextStyle(color: Colors.white, fontFamily: 'Outfit', fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
