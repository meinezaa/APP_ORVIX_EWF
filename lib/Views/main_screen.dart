import 'package:flutter/material.dart';
import 'Home/beranda.dart';
import 'package:app_pt_ewf/views/Kalkulator/emasfisik.dart';
import 'package:app_pt_ewf/views/History/histori.dart'; // Import file histori
import 'Profil/profil.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex;
  const MainScreen({super.key, this.initialIndex = 0});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  late int _selectedNavIndex;
  late int _previousNavIndex;

  void _selectNavIndex(int index) {
    if (index == _selectedNavIndex) return;
    setState(() {
      _previousNavIndex = _selectedNavIndex;
      _selectedNavIndex = index;
    });
  }

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _selectedNavIndex = widget.initialIndex;
    _previousNavIndex = widget.initialIndex;
    AppUsageTracker.start();
    _pages = [
      HomeView(onViewAllHistory: () => _selectNavIndex(2)), // Index 0
      const KalkulatorEmasFisikView(), // Index 1
      const HistoryScreen(), // Index 2
      const ProfileView(), // Index 3
    ];
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AppUsageTracker.stop();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      AppUsageTracker.start();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      AppUsageTracker.stop();
    }
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
    const double navHorizontalMargin = 12;
    final double navWidth = screenWidth - (navHorizontalMargin * 2);
    final double itemWidth = navWidth / 4;
    final double previousCenterX =
        navHorizontalMargin + (itemWidth * _previousNavIndex) + (itemWidth / 2);
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
          8,
        ),
        child: SizedBox(
          height: 72,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              // 1. BACKGROUND LEKUKAN WHITE NAVBAR (Presisi & Dinamis)
              Positioned.fill(
                child: TweenAnimationBuilder<double>(
                  key: ValueKey(_selectedNavIndex),
                  tween: Tween<double>(
                    begin: previousCenterX,
                    end: activeCenterX,
                  ),
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeInOutQuad,
                  builder: (context, animX, child) {
                    return CustomPaint(
                      size: Size(navWidth, 72),
                      painter: SeamlessNavBarPainter(
                        notchCenterX: animX - navHorizontalMargin,
                      ),
                    );
                  },
                ),
              ),

              // 2. ITEM NAVBAR UNSELECTED
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 60,
                child: Row(
                  children: List.generate(_navItems.length, (index) {
                    final bool isSelected = _selectedNavIndex == index;

                    if (isSelected) {
                      return SizedBox(width: itemWidth);
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
                              color: const Color(0xFF757575),
                              size: 22,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _navItems[index]['label'],
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF757575),
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

              // 3. FLOATING ACTIVE BUTTON (Mengikuti Lekukan)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeInOutQuad,
                bottom: 4,
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
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 8,
                            spreadRadius: 1,
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
                    const SizedBox(height: 2),
                    Text(
                      _navItems[_selectedNavIndex]['label'],
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: primaryOrange,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      width: 14,
                      height: 2.5,
                      decoration: BoxDecoration(
                        color: primaryOrange,
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

class SeamlessNavBarPainter extends CustomPainter {
  final double notchCenterX;

  SeamlessNavBarPainter({required this.notchCenterX});

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    Path path = Path();
    double barTop = 0.0;
    double cornerRadius = 18.0;
    double notchWidth = 38.0;
    double notchDepth = 26.0;

    path.moveTo(0, size.height);

    path.lineTo(0, barTop + cornerRadius);
    path.quadraticBezierTo(0, barTop, cornerRadius, barTop);

    path.lineTo(notchCenterX - notchWidth - 8, barTop);

    path.cubicTo(
      notchCenterX - notchWidth,
      barTop,
      notchCenterX - notchWidth + 6,
      barTop + notchDepth,
      notchCenterX,
      barTop + notchDepth,
    );
    path.cubicTo(
      notchCenterX + notchWidth - 6,
      barTop + notchDepth,
      notchCenterX + notchWidth,
      barTop,
      notchCenterX + notchWidth + 8,
      barTop,
    );

    path.lineTo(size.width - cornerRadius, barTop);
    path.quadraticBezierTo(
      size.width,
      barTop,
      size.width,
      barTop + cornerRadius,
    );

    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawShadow(path, Colors.black.withValues(alpha: 0.08), 5.0, true);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant SeamlessNavBarPainter oldDelegate) {
    return oldDelegate.notchCenterX != notchCenterX;
  }
}
