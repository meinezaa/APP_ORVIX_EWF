import 'package:flutter/material.dart';

const _accent = Color(0xFFE98B52);
const _ink = Color(0xFF332C29);
const _muted = Color(0xFF756B66);
const _border = Color(0xFFEEDDD1);

class KeamananAplikasiView extends StatelessWidget {
  const KeamananAplikasiView({super.key});

  static const _items = [
    _SecurityItem(
      'Kebijakan Keamanan',
      'Prinsip utama perlindungan sistem',
      Icons.shield_outlined,
      1,
    ),
    _SecurityItem(
      'Akun & Hak Akses',
      'Autentikasi dan otorisasi pengguna',
      Icons.manage_accounts_outlined,
      2,
    ),
    _SecurityItem(
      'Perlindungan Data',
      'Kriptografi dan kerahasiaan informasi',
      Icons.lock_outline,
      3,
    ),
    _SecurityItem(
      'Konfigurasi Aman',
      'Pengendalian environment & secret key',
      Icons.tune,
      4,
    ),
    _SecurityItem(
      'Activity Log',
      'Pencatatan aktivitas penting sistem',
      Icons.description_outlined,
      5,
    ),
    _SecurityItem(
      'Penanganan Insiden',
      'Prosedur respon masalah & ancaman',
      Icons.warning_amber_outlined,
      6,
    ),
    _SecurityItem(
      'Status Keamanan',
      'Semua sistem berjalan dengan baik',
      Icons.verified_user_outlined,
      7,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return _SecurityShell(
      title: 'Keamanan Aplikasi',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        children: [
          const _SecurityHero(
            text:
                'Kami menerapkan standar enkripsi militer dan protokol berlapis untuk menjamin keamanan aset emas, data pribadi, dan setiap transaksi Anda.',
          ),
          const SizedBox(height: 16),
          ..._items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: _SecurityMenuTile(
                item: item,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SecurityDetailView(index: item.index),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SecurityDetailView extends StatelessWidget {
  final int index;

  const SecurityDetailView({super.key, required this.index});

  @override
  Widget build(BuildContext context) {
    final page = _securityPages[index.clamp(1, 7) - 1];
    return _SecurityShell(
      title: page.title,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
        children: [
          _SecurityHero(text: page.hero),
          const SizedBox(height: 16),
          ...page.sections.map(
            (section) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _SecuritySection(section: section),
            ),
          ),
        ],
      ),
    );
  }
}

class _SecurityShell extends StatelessWidget {
  final String title;
  final Widget child;

  const _SecurityShell({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4D8D8),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE98950), Color(0xFFF2B88F), Color(0xFFF9EEE7)],
            stops: [0, .34, .78],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 10, 20, 8),
                child: Row(
                  children: [
                    _RoundIconButton(
                      icon: Icons.arrow_back,
                      onTap: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _RoundIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    shape: const CircleBorder(),
    child: InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: const SizedBox(
        width: 40,
        height: 40,
        child: Icon(Icons.arrow_back, color: _accent, size: 24),
      ),
    ),
  );
}

class _SecurityHero extends StatelessWidget {
  final String text;

  const _SecurityHero({required this.text});

  @override
  Widget build(BuildContext context) => Container(
    height: 196,
    width: double.infinity,
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(22)),
    clipBehavior: Clip.antiAlias,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/bg_tentang_aplikasi.png',
            fit: BoxFit.cover,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/icon_logo.png',
                width: 82,
                height: 82,
                fit: BoxFit.contain,
              ),
              Image.asset(
                'assets/orvix_logo.png',
                width: 104,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 7),
              Text(
                text,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 11,
                  height: 1.25,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _SecurityMenuTile extends StatelessWidget {
  final _SecurityItem item;
  final VoidCallback onTap;

  const _SecurityMenuTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(13),
      child: Container(
        constraints: const BoxConstraints(minHeight: 58),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .92),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0E8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(item.icon, color: _accent, size: 19),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.subtitle,
                    style: const TextStyle(color: _muted, fontSize: 10),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: _muted, size: 22),
          ],
        ),
      ),
    ),
  );
}

class _SecuritySection extends StatelessWidget {
  final _SecuritySectionData section;

  const _SecuritySection({required this.section});

  @override
  Widget build(BuildContext context) {
    if (section.grid) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.title,
            style: const TextStyle(
              color: _ink,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 9,
            mainAxisSpacing: 9,
            childAspectRatio: 1.32,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: section.cards
                .map((card) => _ContentCard(card: card))
                .toList(),
          ),
        ],
      );
    }
    final content = section.cards.length == 1
        ? _ContentCard(card: section.cards.first)
        : Column(
            children: section.cards
                .map(
                  (card) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _ContentCard(card: card),
                  ),
                )
                .toList(),
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          section.title,
          style: const TextStyle(
            color: _ink,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        content,
      ],
    );
  }
}

class _ContentCard extends StatelessWidget {
  final _SecurityCardData card;

  const _ContentCard({required this.card});

  @override
  Widget build(BuildContext context) {
    if (card.warning) {
      return Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF0E6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline, color: _accent, size: 18),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                card.description,
                style: const TextStyle(
                  color: _accent,
                  fontSize: 10.5,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      );
    }
    if (card.status) {
      return Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .93),
          border: Border.all(color: _border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFDDF8EF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                '• AKTIF',
                style: TextStyle(
                  color: Color(0xFF08A879),
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 9),
            Text(
              card.title,
              style: const TextStyle(
                color: _ink,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              card.description,
              style: const TextStyle(
                color: _muted,
                fontSize: 9.5,
                height: 1.25,
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .93),
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: card.items.isEmpty
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (card.step != null) ...[
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: _accent,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${card.step}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                ] else if (card.icon != null) ...[
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: card.darkIcon
                          ? const Color(0xFF292522)
                          : const Color(0xFFFFF0E8),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      card.icon,
                      color: card.darkIcon ? Colors.white : _accent,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (card.title.isNotEmpty)
                        Text(
                          card.title,
                          style: const TextStyle(
                            color: _ink,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      if (card.description.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            card.description,
                            style: const TextStyle(
                              color: _muted,
                              fontSize: 10.5,
                              height: 1.3,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (card.title.isNotEmpty)
                  Text(
                    card.title,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                if (card.description.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      card.description,
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 10.5,
                        height: 1.3,
                      ),
                    ),
                  ),
                ...card.items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 18,
                          height: 18,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: item.negative
                                ? const Color(0xFFFFE5E5)
                                : const Color(0xFFFFF0E8),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            item.negative ? Icons.close : Icons.check,
                            color: item.negative ? Colors.redAccent : _accent,
                            size: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.text,
                            style: const TextStyle(
                              color: _muted,
                              fontSize: 10.5,
                              height: 1.3,
                            ),
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
}

class _SecurityItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final int index;

  const _SecurityItem(this.title, this.subtitle, this.icon, this.index);
}

class _SecurityBullet {
  final String text;
  final bool negative;

  const _SecurityBullet(this.text, {this.negative = false});
}

class _SecurityCardData {
  final String title;
  final String description;
  final List<_SecurityBullet> items;
  final IconData? icon;
  final bool darkIcon;
  final int? step;
  final bool status;
  final bool warning;

  const _SecurityCardData({
    this.title = '',
    this.description = '',
    this.items = const [],
    this.icon,
    this.darkIcon = false,
    this.step,
    this.status = false,
    this.warning = false,
  });
}

class _SecuritySectionData {
  final String title;
  final List<_SecurityCardData> cards;
  final bool grid;

  const _SecuritySectionData(this.title, this.cards, {this.grid = false});
}

class _SecurityPageData {
  final String title;
  final String hero;
  final List<_SecuritySectionData> sections;

  const _SecurityPageData(this.title, this.hero, this.sections);
}

const _securityPages = [
  _SecurityPageData(
    'Kebijakan Keamanan',
    'Pedoman komprehensif yang dirancang untuk menjaga integritas data transaksi emas serta melindungi privasi seluruh pengguna ORVIX.',
    [
      _SecuritySectionData('Tujuan', [
        _SecurityCardData(
          description:
              'Menghindari kebocoran informasi sensitif, mencegah manipulasi harga emas pada sistem, serta menetapkan batas tanggung jawab operasional yang aman demi kenyamanan perdagangan.',
        ),
      ]),
      _SecuritySectionData('Prinsip Utama', [
        _SecurityCardData(
          items: [
            _SecurityBullet(
              'Hanya pengguna terdaftar yang dapat mengakses aplikasi secara sah.',
            ),
            _SecurityBullet(
              'Data pengguna dan transaksi dijamin kerahasiaannya dengan enkripsi end-to-end.',
            ),
            _SecurityBullet(
              'Sistem harus selalu tersedia dan aman dari ancaman siber eksternal.',
            ),
            _SecurityBullet(
              'Semua aktivitas sensitif terekam dengan rapi di dalam audit log sistem.',
            ),
            _SecurityBullet(
              'Perlindungan terhadap aset fisik emas dan data digital menjadi prioritas utama.',
            ),
          ],
        ),
      ]),
    ],
  ),
  _SecurityPageData(
    'Akun & Hak Akses',
    'Sistem manajemen identitas untuk memastikan hanya individu yang sah yang dapat mengakses sistem sesuai perannya.',
    [
      _SecuritySectionData('Proses Autentikasi', [
        _SecurityCardData(
          description:
              'Proses ketat untuk memverifikasi identitas pengguna sebelum memberikan izin akses ke dashboard utama.',
          items: [
            _SecurityBullet(
              'Login menggunakan email, password kuat, dan link email lupa password dua-faktor.',
            ),
            _SecurityBullet(
              'Logout otomatis jika terdeteksi tidak ada aktivitas selama 15 menit.',
            ),
            _SecurityBullet('Verifikasi berlapis untuk reset password.'),
            _SecurityBullet(
              'Session Management terpusat dengan token JWT aman.',
            ),
          ],
        ),
      ]),
      _SecuritySectionData('Role & Otorisasi', [
        _SecurityCardData(
          title: 'Staff',
          icon: Icons.work_outline,
          description:
              'Menggunakan kalkulator gold/lot, melakukan pemantauan harga terkini, dan mengelola profil transaksi nasabah.',
        ),
        _SecurityCardData(
          title: 'Admin',
          icon: Icons.groups_outlined,
          darkIcon: true,
          description:
              'Memiliki akses luas termasuk verifikasi data staff, pengelolaan parameter harga, serta audit log keamanan menyeluruh.',
        ),
      ]),
    ],
  ),
  _SecurityPageData(
    'Perlindungan Data',
    'Sistem manajemen identitas untuk memastikan hanya individu yang sah yang dapat mengakses sistem sesuai perannya.',
    [
      _SecuritySectionData('Langkah Perlindungan', [
        _SecurityCardData(
          items: [
            _SecurityBullet(
              'Seluruh password disimpan menggunakan algoritma hashing bcrypt yang kuat.',
            ),
            _SecurityBullet(
              'Credential dan secret API key dikelola menggunakan environment variable aman.',
            ),
            _SecurityBullet(
              'Data transaksi gold serta info sensitif nasabah dienkripsi dengan standar AES-256.',
            ),
            _SecurityBullet(
              'Informasi pribadi tidak pernah ditampilkan secara langsung dalam log sistem.',
            ),
          ],
        ),
      ]),
      _SecuritySectionData('Catatan Keamanan', [
        _SecurityCardData(
          warning: true,
          description:
              'Setiap perubahan data harga emas diverifikasi silang (cross-verified) menggunakan checksum digital guna memastikan tidak ada manipulasi ilegal.',
        ),
      ]),
    ],
  ),
  _SecurityPageData(
    'Konfigurasi Aman',
    'Isolasi infrastruktur aplikasi untuk memastikan kestabilan dan integritas operasional trading emas.',
    [
      _SecuritySectionData('Environment Terpisah', [
        _SecurityCardData(
          title: 'Development',
          description:
              'Tempat pengembangan fitur baru ORVIX secara terisolasi.',
        ),
        _SecurityCardData(
          title: 'Testing',
          description:
              'Environment khusus untuk proses QA dan simulasi trading.',
        ),
        _SecurityCardData(
          title: 'Production',
          description:
              'Sistem rilis resmi dengan proteksi keamanan paling ketat.',
        ),
      ]),
      _SecuritySectionData('Konfigurasi Penting', [
        _SecurityCardData(
          items: [
            _SecurityBullet(
              'Penggunaan file config environment dienkripsi untuk mengelola kredensial server.',
            ),
            _SecurityBullet(
              'Semua endpoint API internal dilindungi rate limiter untuk menangkal serangan brute force.',
            ),
            _SecurityBullet(
              'Akses SSH ke database trading dibatasi hanya dari IP kantor resmi (whitelist).',
            ),
            _SecurityBullet(
              'Sertifikat SSL/TLS selalu diperbarui secara terjadwal otomatis.',
            ),
          ],
        ),
      ]),
    ],
  ),
  _SecurityPageData(
    'Activity Log',
    'Pencatatan aktivitas penting aplikasi untuk membantu penelusuran keamanan dan riwayat transaksi ORVIX.',
    [
      _SecuritySectionData('Aktivitas yang Dicatat', [
        _SecurityCardData(
          items: [
            _SecurityBullet(
              'Aktivitas login dan logout melalui Firebase Authentication.',
            ),
            _SecurityBullet(
              'Riwayat penggunaan kalkulator yang disimpan melalui HistoryService.',
            ),
            _SecurityBullet(
              'Pembuatan dan pembaruan riwayat perhitungan harga emas.',
            ),
            _SecurityBullet(
              'Perubahan profil dan pergantian password yang berhasil dilakukan pengguna.',
            ),
            _SecurityBullet(
              'Waktu pembuatan serta detail transaksi pada histori pengguna.',
            ),
          ],
        ),
      ]),
      _SecuritySectionData('Aktivitas yang Tidak Dicatat', [
        _SecurityCardData(
          items: [
            _SecurityBullet(
              'Password mentah (raw plain password) milik pengguna.',
              negative: true,
            ),
            _SecurityBullet(
              'Kredensial payment gateway atau info bank rahasia.',
              negative: true,
            ),
            _SecurityBullet(
              'Secret dynamic salt key yang digunakan untuk token data.',
              negative: true,
            ),
          ],
        ),
      ]),
    ],
  ),
  _SecurityPageData(
    'Penanganan Insiden',
    'Protokol taktis penanganan cepat apabila terjadi gangguan teknis atau indikasi aktivitas mencurigakan.',
    [
      _SecuritySectionData('Tahapan Penanganan', [
        _SecurityCardData(
          title: 'Identifikasi',
          step: 1,
          description:
              'Mendeteksi anomali pada perubahan harga emas secara real-time melalui anomaly detection engine.',
        ),
        _SecurityCardData(
          title: 'Penanganan',
          step: 2,
          description:
              'Mengisolasi akun atau transaksi yang terindikasi mencurigakan untuk mencegah penyebaran dampak sistem.',
        ),
        _SecurityCardData(
          title: 'Investigasi',
          step: 3,
          description:
              'Melakukan forensik log aktivitas oleh tim siber internal guna melacak akar permasalahan.',
        ),
        _SecurityCardData(
          title: 'Pemulihan',
          step: 4,
          description:
              'Memulihkan sistem menggunakan backup berkala dan mengaktifkan kembali fitur setelah dinyatakan steril.',
        ),
        _SecurityCardData(
          title: 'Dokumentasi',
          step: 5,
          description:
              'Mencatat insiden sebagai bahan evaluasi dalam penyusunan patch keamanan baru.',
        ),
      ]),
    ],
  ),
  _SecurityPageData(
    'Status Keamanan',
    'Sistem ORVIX beroperasi normal dengan proteksi optimal harian.',
    [
      _SecuritySectionData('Komponen Keamanan Aktif', [
        _SecurityCardData(
          title: 'Input Validation',
          status: true,
          description: 'Mencegah injeksi kode berbahaya.',
        ),
        _SecurityCardData(
          title: 'Authentication',
          status: true,
          description: 'Verifikasi melalui link email reset password aktif.',
        ),
        _SecurityCardData(
          title: 'Role Authorization',
          status: true,
          description: 'Hak akses sesuai jabatan.',
        ),
        _SecurityCardData(
          title: 'Data Protection',
          status: true,
          description: 'Kriptografi database AES-256.',
        ),
        _SecurityCardData(
          title: 'Activity Logging',
          status: true,
          description: 'Audit trail tercatat berkala.',
        ),
      ], grid: true),
    ],
  ),
];
