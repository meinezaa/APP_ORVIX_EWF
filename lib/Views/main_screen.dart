import 'package:flutter/material.dart';
import 'Home/beranda.dart';
import 'package:app_pt_ewf/views/Kalkulator/emasfisik.dart';
import 'package:app_pt_ewf/views/History/histori.dart';
import 'Profil/profil.dart';
import 'Profil/notifikasi.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex;
  const MainScreen({super.key, this.initialIndex = 0});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _selectedNavIndex;

  void _selectNavIndex(int index) {
    if (index == _selectedNavIndex) return;
    setState(() {
      _selectedNavIndex = index;
    });
  }

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _selectedNavIndex = widget.initialIndex;
    _pages = [
      HomeView(
        onViewAllHistory: () => _selectNavIndex(2),
        onViewNotifications: _openNotifications,
        onViewProfile: () => _selectNavIndex(3),
      ),
      const KalkulatorEmasFisikView(),
      const HistoryScreen(),
      const ProfileView(),
    ];
  }

  void _openNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotifikasiView()),
    );
  }

  final List<Map<String, dynamic>> _navItems = [
    {
      'label': 'Home',
      'iconUnselected': Icons.home_outlined,
      'iconSelected': Icons.home_rounded,
    },
    {
      'label': 'Calculate',
      'iconUnselected': Icons.calculate_outlined,
      'iconSelected': Icons.calculate_rounded,
    },
    {
      'label': 'History',
      'iconUnselected': Icons.history_toggle_off,
      'iconSelected': Icons.history_rounded,
    },
    {
      'label': 'Profil',
      'iconUnselected': Icons.person_outline,
      'iconSelected': Icons.person_rounded,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    const double navHorizontalMargin = 16;
    final double navWidth = screenWidth - (navHorizontalMargin * 2);
    final double itemWidth = navWidth / 4;
    final double activeCenterX =
        navHorizontalMargin + (itemWidth * _selectedNavIndex) + (itemWidth / 2);
    const Color primaryOrange = Color(0xFFD95B14);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: IndexedStack(index: _selectedNavIndex, children: _pages),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(
          navHorizontalMargin,
          0,
          navHorizontalMargin,
          16,
        ),
        child: SizedBox(
          height: 80,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              // 1. BACKGROUND NAVBAR FULL PILL (TANPA BACKGROUND PUTIH KOTAK DI BALIK IKON)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 70,
                  decoration: BoxDecoration(
                    color: primaryOrange,
                    borderRadius: BorderRadius.circular(35),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: List.generate(_navItems.length, (index) {
                      final bool isSelected = _selectedNavIndex == index;

                      if (isSelected) {
                        return Expanded(child: const SizedBox.shrink());
                      }

                      return Expanded(
                        child: InkWell(
                          onTap: () => _selectNavIndex(index),
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _navItems[index]['iconUnselected'],
                                color: Colors.white.withValues(alpha: 0.8),
                                size: 22,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _navItems[index]['label'],
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),

              // 2. FLOATING ACTIVE BUTTON (MENGAMBANG DI ATAS POSISI ITEM YANG AKTIF TANPA KOTAK PUTIH)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeInOutQuad,
                bottom: 12,
                left: activeCenterX - navHorizontalMargin - 27,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: primaryOrange, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(
                        _navItems[_selectedNavIndex]['iconSelected'],
                        color: primaryOrange,
                        size: 26,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _navItems[_selectedNavIndex]['label'],
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      width: 14,
                      height: 2.5,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
