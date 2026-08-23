import 'package:flutter/material.dart';
import 'package:app_pt_ewf/views/Home/beranda.dart';
import 'package:app_pt_ewf/views/Kalkulator/emasfisik.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex;
  const MainScreen({super.key, this.initialIndex = 0});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  // List Halaman Utama
  final List<Widget> _pages = [
    const HomeView(), // Index 0: Home
    const KalkulatorEmasFisikView(), // Index 1: Calculate
    const Center(child: Text('History View')), // Index 2: History
    const Center(child: Text('Profil View')), // Index 3: Profil
  ];

  // Config Data Navbar
  final List<Map<String, dynamic>> _navItems = [
    {
      'label': 'Home',
      'iconUnselected': Icons.home_outlined,
      'iconSelected': Icons.home_rounded,
    },
    {
      'label': 'Calculate',
      'iconUnselected': Icons.calculate_outlined,
      'iconSelected': Icons.calculate,
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
    double screenWidth = MediaQuery.of(context).size.width;
    double itemWidth = screenWidth / _navItems.length;
    const primaryOrange = Color(0xFFD95B14);

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: Container(
        height: 85,
        color: Colors.transparent,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            // 1. BAR BACKGROUND UTAMA (Unselected Items)
            Container(
              height: 65,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Row(
                children: List.generate(_navItems.length, (index) {
                  bool isSelected = _selectedIndex == index;

                  // Berikan slot kosong jika tab sedang dipilih (karena akan diisi oleh ikon melayang)
                  if (isSelected) {
                    return SizedBox(width: itemWidth);
                  }

                  return Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _selectedIndex = index),
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _navItems[index]['iconUnselected'],
                            color: Colors.grey.shade500,
                            size: 22,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _navItems[index]['label'],
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),

            // 2. ICON DYNAMIC FLOATING (Pindah Halus / Animated Positioned)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 250),
              curve: Curves.decelerate,
              bottom: 6,
              left:
                  (itemWidth * _selectedIndex) +
                  (itemWidth / 2) -
                  29, // Menempatkan posisi presisi di tengah slot
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Lingkaran dengan Border Oranye
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: primaryOrange, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: primaryOrange.withOpacity(0.18),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(
                      _navItems[_selectedIndex]['iconSelected'],
                      color: primaryOrange,
                      size: 26,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Judul Teks Aktif Oranye
                  Text(
                    _navItems[_selectedIndex]['label'],
                    style: const TextStyle(
                      fontSize: 11,
                      color: primaryOrange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Garis Indikator Bawah
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
    );
  }
}
