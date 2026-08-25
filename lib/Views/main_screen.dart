import 'package:flutter/material.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // Daftar halaman/view yang akan berubah saat menu navigasi diklik
  final List<Widget> _pages = [
    const Center(child: Text('Home Screen', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
    const Center(child: Text('Calculate Screen', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
    const Center(child: Text('History Screen', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
    const Center(child: Text('Profil Screen', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}

// ==========================================
// CUSTOM BOTTOM NAVIGATION BAR WIDGET
// ==========================================
class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Warna tema oranye sesuai dengan desain Figma/referensi
    final Color primaryOrange = const Color(0xFFED6A4E);

    return Container(
      height: 96,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // Background Bar Utama yang Melengkung
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: CustomPaint(
              size: const Size(double.infinity, 70),
              painter: BottomNavPainter(
                backgroundColor: primaryOrange,
              ),
              child: Container(
                height: 70,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Spasi kosong di kiri untuk memberi ruang pada tombol Home yang mengambang
                    const SizedBox(width: 48),

                    // Menu 2: Calculate
                    _buildNavItem(
                      index: 1,
                      icon: Icons.calculate_outlined,
                      label: 'Calculate',
                    ),

                    // Menu 3: History
                    _buildNavItem(
                      index: 2,
                      icon: Icons.history_rounded,
                      label: 'History',
                    ),

                    // Menu 4: Profil
                    _buildNavItem(
                      index: 3,
                      icon: Icons.person_outline_rounded,
                      label: 'Profil',
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Tombol Home Mengambang (Lingkaran Putih, Border Oranye, & Bayangan)
          Positioned(
            left: 32, // Posisi horizontal agar pas di atas lengkongan kiri
            bottom: 22,
            child: GestureDetector(
              onTap: () => onTap(0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: primaryOrange,
                        width: 4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.home_rounded,
                      color: primaryOrange,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Home',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Garis indikator kecil merah di bawah teks Home jika sedang aktif
                  if (currentIndex == 0)
                    Container(
                      width: 16,
                      height: 3,
                      decoration: BoxDecoration(
                        color: const Color(0xFFC0392B),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final bool isSelected = currentIndex == index;

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 26,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// CUSTOM PAINTER UNTUK BENTUK LENGKUNGAN NAV BAR
// ==========================================
class BottomNavPainter extends CustomPainter {
  final Color backgroundColor;

  BottomNavPainter({required this.backgroundColor});

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;

    Path path = Path();
    double radius = 28.0;

    // Menggambar bentuk kustom dengan tonjolan lengkung di bagian atas-kiri
    path.moveTo(0, radius + 10);
    path.cubicTo(0, 5, 20, 0, 52, 0); // Kurva melengkung ke atas untuk tombol Home
    path.lineTo(size.width - radius, 0);
    path.quadraticBezierTo(size.width, 0, size.width, radius);
    path.lineTo(size.width, size.height - radius);
    path.quadraticBezierTo(size.width, size.height, size.width - radius, size.height);
    path.lineTo(radius, size.height);
    path.quadraticBezierTo(0, size.height, 0, size.height - radius);
    
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}