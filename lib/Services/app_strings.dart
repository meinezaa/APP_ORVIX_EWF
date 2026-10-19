import 'package:flutter/material.dart';

import 'app_preferences.dart';

abstract final class AppStrings {
  static const Map<String, String> _english = {
    'Pengaturan': 'Settings',
    'Notifikasi': 'Notifications',
    'Ganti Password': 'Change Password',
    'Tema': 'Theme',
    'Gelap': 'Dark',
    'Terang': 'Light',
    'Bahasa': 'Language',
    'Bahasa Indonesia': 'Indonesian',
    'English': 'English',
    'Pilih Tema': 'Choose Theme',
    'Pilih Bahasa': 'Choose Language',
    'Tentang Aplikasi': 'About the App',
    'FAQ': 'FAQ',
    'Hari ini': 'Today',
    'Kemarin': 'Yesterday',
    'Hari Ini': 'Today',
    'Sudah dibaca': 'Read',
    'Belum dibaca': 'Unread',
    'Notifikasi gagal ditandai dibaca.':
        'Could not mark notifications as read.',
    'Data harga emas terbaru sudah tersedia.':
        'The latest gold price data is now available.',
    'Selamat datang di ORVIX': 'Welcome to ORVIX',
    'Mulai gunakan kalkulator untuk membantu perhitungan Anda.':
        'Start using the calculator to help with your calculations.',
    'Jangan lupa cek histori': 'Remember to check your history',
    'Lihat kembali seluruh aktivitas perhitungan Anda.':
        'Review all your calculation activity.',
    'Harga emas diperbarui': 'Gold prices updated',
    'Pengguna': 'User',
    'Kalkulator': 'Calculator',
    'Jenis': 'Type',
    'Bergabung sejak': 'Member since',
    'Informasi Profil': 'Profile Information',
    'Ubah Foto Profil': 'Change Profile Photo',
    'Nama Lengkap': 'Full Name',
    'Nomor Telepon': 'Phone Number',
    'Tanggal Lahir': 'Date of Birth',
    'Jenis Kelamin': 'Gender',
    'Pilih tanggal lahir': 'Select date of birth',
    'Pilih jenis kelamin': 'Select gender',
    'Simpan Perubahan': 'Save Changes',
    'PT. EQUITYWORLD FUTURES': 'PT. EQUITYWORLD FUTURES',
    'Profil perusahaan, visi, misi, nilai, legalitas dan informasi ORVIX':
        'Company profile, vision, mission, values, regulatory information, and the meaning of ORVIX',
    'PT Equityworld Futures ("EWF") hadir sebagai mitra investasi yang mengutamakan kepercayaan dan profesionalisme di industri perdagangan berjangka. Dengan fokus pada kualitas layanan dan edukasi berkelanjutan, EWF membantu nasabah menavigasi peluang pasar secara lebih terarah dan aman.':
        'PT Equityworld Futures ("EWF") is an investment partner that prioritizes trust and professionalism in the futures trading industry. With a focus on service quality and continuous education, EWF helps clients navigate market opportunities in a more informed and secure way.',
    'Sejak mulai beroperasi pada tahun 2005, EWF terus tumbuh dan memperluas jangkauan layanan hingga memiliki tujuh kantor operasional di Jakarta, Surabaya, Semarang, Manado, dan Cirebon.':
        'Since commencing operations in 2005, EWF has continued to grow and expand its services, with seven operational offices across Jakarta, Surabaya, Semarang, Manado, and Cirebon.',
    'Sebagai perusahaan pialang berjangka resmi, EWF terdaftar dan diawasi oleh Badan Pengawas Perdagangan Berjangka Komoditi (BAPPEBTI), Otoritas Jasa Keuangan (OJK), dan Bank Indonesia (BI), serta menjadi anggota PT Bursa Berjangka Jakarta (BBJ) dan PT Kliring Berjangka Indonesia (Persero). Dengan landasan regulasi yang kuat, EWF berkomitmen memberikan pengalaman transaksi yang transparan, akuntabel, dan berstandar tinggi.':
        'As an officially registered futures brokerage, EWF is registered with and supervised by the Commodity Futures Trading Regulatory Agency (BAPPEBTI), the Financial Services Authority (OJK), and Bank Indonesia (BI). It is also a member of the Jakarta Futures Exchange (BBJ) and PT Kliring Berjangka Indonesia (Persero). With a strong regulatory foundation, EWF is committed to providing a transparent, accountable, and high-standard trading experience.',
    'Visi': 'Vision',
    'Menjadi perusahaan pialang berjangka yang unggul dan terpercaya, dengan standar operasional yang modern, transparan, serta memberikan nilai strategis bagi perkembangan industri dan perekonomian nasional.':
        'To become an outstanding and trusted futures brokerage, with modern and transparent operational standards that provide strategic value to the development of the industry and the national economy.',
    'Misi': 'Mission',
    'Menyediakan layanan perdagangan berjangka yang profesional, aman, dan berintegritas tinggi.':
        'Provide professional, secure, and highly principled futures trading services.',
    'Mengembangkan kualitas sumber daya manusia untuk menghadirkan layanan yang kompeten dan berdaya saing.':
        'Develop human resources to deliver competent and competitive services.',
    'Mengimplementasikan tata kelola perusahaan yang transparan dan akuntabel.':
        'Implement transparent and accountable corporate governance.',
    'Memperluas akses edukasi serta literasi perdagangan berjangka kepada masyarakat.':
        'Expand public access to futures trading education and literacy.',
    'Mengoptimalkan teknologi untuk mendukung operasional dan pengalaman nasabah secara efisien.':
        'Optimize technology to support efficient operations and client experiences.',
    'Nilai-Nilai Perusahaan': 'Company Values',
    'Integritas Profesional': 'Professional Integrity',
    'Menegakkan standar etika yang tinggi serta menjaga konsistensi tindakan dan keputusan dalam setiap aktivitas perusahaan.':
        'Uphold high ethical standards and ensure consistency in actions and decisions across all company activities.',
    'Fokus pada Nasabah': 'Client Focus',
    'Mengutamakan kebutuhan dan tujuan investasi nasabah melalui layanan yang responsif, akurat, dan transparan.':
        'Prioritize clients’ investment needs and goals through responsive, accurate, and transparent service.',
    'Disiplin Kepatuhan': 'Compliance Discipline',
    'Menjalankan seluruh proses bisnis sesuai kerangka regulasi dengan kontrol internal yang kuat dan berkelanjutan.':
        'Conduct all business processes within the regulatory framework, supported by strong and continuous internal controls.',
    'Inovasi Berkelanjutan': 'Continuous Innovation',
    'Mendorong pengembangan teknologi, produk, dan proses kerja untuk menghadirkan pengalaman transaksi yang semakin efisien dan kompetitif.':
        'Advance technology, products, and workflows to deliver an increasingly efficient and competitive trading experience.',
    'Apa arti ORVIX?': 'What does ORVIX mean?',
    'OR terinspirasi dari kata or dalam bahasa Prancis yang berarti emas. VIX menggambarkan kesan teknologi, kecepatan, dan inovasi.':
        'OR is inspired by the French word or, meaning gold. VIX evokes technology, speed, and innovation.',
    'Berita & Analisis Terbaru': 'Latest News & Analysis',
    'Discover': 'Discover',
    'News from all around the market': 'News from across the markets',
    'Cari berita': 'Search news',
    'Hapus pencarian': 'Clear search',
    'Tidak ada berita yang cocok.': 'No matching news found.',
    'Market Update': 'Market Update',
    'Gold': 'Gold',
    'Oil': 'Oil',
    'Silver': 'Silver',
    'Berita terbaru gagal dimuat.': 'Could not load the latest news.',
    'Tautan tidak dapat dibuka.': 'Could not open the link.',
    'Coba Lagi': 'Try Again',
    'Belum ada berita terbaru.': 'No recent news available.',
    'Perbarui berita': 'Refresh news',
    'Kembali': 'Back',
    'Buka sumber berita': 'Open news source',
    'Sumber berita': 'News source',
    'Konten lengkap belum dapat dimuat.':
        'The full article could not be loaded.',
    'Anda masih dapat membuka artikel asli dari sumber berita.':
        'You can still open the original article from the news source.',
    'Konten lengkap belum tersedia dari sumber berita.':
        'The full article is not available from the news source.',
    'Buka artikel di situs sumber': 'Open article on source website',
    'Ringkasan Aktivitas': 'Activity Summary',
    'Total Perhitungan': 'Total Calculations',
    'Keluar': 'Sign out',
    'Detail Perhitungan': 'Calculation Details',
    'Hasil Perhitungan': 'Calculation Result',
    'Hasil Pivot Point': 'Pivot Point Result',
    'Hasil Nest': 'NEST Result',
    'Siap melakukan perhitungan hari ini?': 'Ready to calculate today?',
    'Perhitungan Terakhir': 'Recent Calculations',
    'Lihat Semua >': 'View All >',
    'Belum ada perhitungan.': 'No calculations yet.',
    'Data historical gagal dimuat. Periksa koneksi lalu coba lagi.':
        'Historical data failed to load. Check your connection and try again.',
    'Gagal memuat data: ': 'Failed to load data: ',
    'Date': 'Date',
    'Open': 'Open',
    'High': 'High',
    'Low': 'Low',
    'Close': 'Close',
    'Pilih tanggal': 'Select date',
    'Hapus riwayat terpilih': 'Delete selected history',
    'Tidak ada perhitungan pada': 'No calculations on',
    'PDF': 'PDF',
    'PNG': 'PNG',
    'Selamat Datang, Admin': 'Welcome, Admin',
    'Pantau aktivitas dan performa ORVIX hari ini':
        'Monitor ORVIX activity and performance today',
    'Ringkasan Sistem': 'System Summary',
    'Aktivitas Terbaru': 'Recent Activity',
    'Perhitungan Terbaru': 'Recent Calculations',
    'Jenis Perhitungan': 'Calculation Types',
    'Total Staff': 'Total Staff',
    'Perhitungan Hari\nIni': "Today's Calculations",
    'Aktivitas Hari Ini': "Today's Activity",
    'aktif hari ini': 'active today',
    'total data tercatat': 'total records',
    'tercatat hari ini': 'recorded today',
    'menit aktif hari ini': 'active minutes today',
    'Belum ada data': 'No data yet',
    'Belum ada perhitungan tercatat': 'No calculations recorded',
    'Data masih kosong': 'There is no data yet',
    'Login ke sistem': 'System login',
    'Gagal membaca riwayat login': 'Could not read login history',
    'Memuat riwayat login...': 'Loading login history...',
    'Periksa koneksi atau izin Firestore':
        'Check your connection or Firestore permissions',
    'Mohon tunggu': 'Please wait',
    'Silakan lakukan perhitungan': 'Please perform a calculation',
    'Analitik': 'Analytics',
    'Halo, ': 'Hello, ',
    'Hitung dengan ': 'Calculate ',
    'Cepat ': 'Fast ',
    'dan ': 'and ',
    'Akurat': 'Accurate',
    'Hasil: ': 'Result: ',
    'Otomatis': 'Automatic',
    'Harga Jual': 'Sell Price',
    'Harga Beli': 'Buy Price',
    'Modal': 'Capital',
    'Hitung': 'Calculate',
    'Indikasi': 'Signal',
    'Kategori': 'Category',
    'Action': 'Action',
    'Open dibawah Pivot = BUY': 'Open below Pivot = BUY',
    'Open diatas Pivot = SELL': 'Open above Pivot = SELL',
    'Jika Close diatas Open BUY': 'If Close is above Open, BUY',
    'Jika Close dibawah Open SELL': 'If Close is below Open, SELL',
    'Hitung ': 'Calculate ',
    'Emas Fisik, Pivot\nPoint & NEST': 'Physical Gold, Pivot\nPoint & NEST',
    ' dengan mudah': ' more easily',
    'Gunakan kalkulator ORVIX untuk perhitungan yang cepat, akurat, dan terpercaya.':
        'Use the ORVIX calculator for fast, accurate, and reliable calculations.',
    'Home': 'Home',
    'Calculate': 'Calculate',
    'History': 'History',
    'Profil': 'Profile',
    'Profile': 'Profile',
    'Masuk': 'Sign In',
    'Email': 'Email',
    'Password': 'Password',
    'Buat Akun Baru': 'Create a New Account',
    'Buat akun sebagai staff atau nasabah. Setelah terdaftar, Anda bisa langsung masuk dan menggunakan sistem kalkulator.':
        'Register as staff or a customer. After registering, you can sign in and use the calculator.',
    'Daftar Sebagai': 'Register As',
    'Staff': 'Staff',
    'Nasabah': 'Customer',
    'Data perhitungan staff akan tersedia untuk admin.':
        'Staff calculations will be available to administrators.',
    'Data perhitungan nasabah hanya tersimpan di akun Anda.':
        'Customer calculations are stored only in your account.',
    'Masukkan nama lengkap Anda': 'Enter your full name',
    'Contoh: 08123456789': 'Example: 08123456789',
    'Buat kata sandi minimal 8 karakter':
        'Create a password with at least 8 characters',
    'Masukkan kembali kata sandi': 'Re-enter your password',
    'Konfirmasi Password': 'Confirm Password',
    'Sudah punya akun? ': 'Already have an account? ',
    'Daftar': 'Register',
    'Baca selengkapnya': 'Read more',
    'Tutup': 'Close',
    'NEST': 'NEST',
    'Grafik gagal dimuat.': 'Could not load chart.',
    'Grafik gagal dimuat. Periksa koneksi internet.':
        'Could not load the chart. Check your internet connection.',
    'Coba lagi': 'Try again',
    'Tidak dapat membuka TradingView.': 'Could not open TradingView.',
    'Gold Spot / U.S. Dollar': 'Gold Spot / U.S. Dollar',
    'Hang Seng Index': 'Hang Seng Index',
    'Nikkei 225 Index': 'Nikkei 225 Index',
    'Kurs gagal diperbarui; periksa koneksi.':
        'Could not refresh the exchange rate; check your connection.',
    'Kurs diperbarui': 'Rate updated',
    'Kurs USD/IDR': 'USD/IDR rate',
    'Perbarui kurs': 'Refresh exchange rate',
    'Kurs USD/IDR belum tersedia.':
        'The USD/IDR exchange rate is not available yet.',
    'Kurs': 'Rate',
    'midpoint': 'midpoint',
    'Emas': 'Gold',
    'Syarat dan Ketentuan': 'Terms and Conditions',
    'Saya telah menyetujui ': 'I agree to the ',
    ' yang berlaku.': '.',
    'Apa itu Emas Fisik?': 'What is Physical Gold?',
    'Apa itu Pivot Point?': 'What is Pivot Point?',
    'Apa itu NEST?': 'What is NEST?',
    'Emas fisik adalah emas berwujud yang dapat disimpan sebagai aset riil.':
        'Physical gold is tangible gold that can be held as a real asset.',
    'Emas fisik adalah emas yang berwujud, dapat berupa batangan, koin, atau perhiasan, yang dibeli oleh investor dan disimpan sebagai aset riil. Emas fisik memiliki nilai intrinsik yang dihargai di seluruh dunia, dan karena bentuknya yang nyata, investor dapat menyimpannya di rumah dan atau di tempat penyimpanan khusus.':
        'Physical gold is tangible gold, such as bars, coins, or jewelry, purchased and held by investors as a real asset. It has intrinsic value recognized worldwide and can be stored at home or in a dedicated facility.',
    'Pivot Point adalah harga acuan untuk menentukan aksi beli atau jual berdasarkan harga Open.':
        'Pivot Point is a reference price used to determine buy or sell actions based on the Open price.',
    'Pivot Point adalah harga wajar atau harga pasaran untuk menentukan aksi beli dan jual yang mengacu pada harga pembukaan (Open).\n\nOpen < Pivot Point: BUY\nOpen > Pivot Point: SELL':
        'Pivot Point is a fair or market price used to guide buy and sell decisions based on the opening price (Open).\n\nOpen < Pivot Point: BUY\nOpen > Pivot Point: SELL',
    'NEST adalah konsep Follow the Trend yang mengacu pada harga penutupan (Close).':
        'NEST follows the trend using the closing price (Close).\n\nClose > Open: BUY\nClose < Open: SELL',
    'NEST adalah konsep Follow the Trend yang mengacu pada harga penutupan (Close).\n\nClose > Open: BUY\nClose < Open: SELL':
        'NEST follows the trend using the closing price (Close).\n\nClose > Open: BUY\nClose < Open: SELL',
    'Grafik Harga': 'Price Chart',
    'Buka': 'Open',
    '1 menit': '1 minute',
    '5 menit': '5 minutes',
    '15 menit': '15 minutes',
    '30 menit': '30 minutes',
    '1 jam': '1 hour',
    '4 jam': '4 hours',
    '1 hari': '1 day',
    '1 minggu': '1 week',
    '1 bulan': '1 month',
    'Lupa Password?': 'Forgot Password?',
    'Continue with Google': 'Continue with Google',
    'Belum punya akun? ': "Don't have an account? ",
    'Buat Akun': 'Create Account',
    'Detail History': 'History Details',
    'ID Histori': 'History ID',
    'Hasil akhir': 'Final result',
    'Data Harga': 'Price Data',
    'Data Emas Fisik': 'Physical Gold Data',
    'Detail Pivot Point': 'Pivot Point Details',
    'Detail NEST': 'NEST Details',
    'Detail Emas Fisik': 'Physical Gold Details',
    'Jenis proses': 'Calculation type',
    'Perhitungan Pivot Point': 'Pivot Point Calculation',
    'Perhitungan NEST': 'NEST Calculation',
    'Perhitungan Emas Fisik': 'Physical Gold Calculation',
    'Status': 'Status',
    'Selesai': 'Completed',
    'Input rinci tersimpan pada histori akan ditampilkan di bagian ini.':
        'Detailed inputs saved in history will be shown here.',
    'Harga beli / gram': 'Buy price / gram',
    'Harga jual / gram': 'Sell price / gram',
    'Selisih / gram (2 - 1)': 'Difference / gram (2 - 1)',
    'Jumlah emas': 'Gold quantity',
    'Profil Administrator': 'Administrator Profile',
    'INFORMASI AKUN': 'ACCOUNT INFORMATION',
    'HAK AKSES & KEAMANAN': 'ACCESS & SECURITY',
    'ORVIX Management System © 2026': 'ORVIX Management System © 2026',
    'STAFF DIAWASI': 'STAFF SUPERVISED',
    'Aktif': 'Active',
    'BERGABUNG SEJAK': 'JOINED SINCE',
    'Edit Data Pribadi': 'Edit Personal Information',
    'Nama, telepon, dan identitas admin': 'Name, phone, and admin identity',
    'Ubah Kata Sandi & PIN': 'Change Password & PIN',
    'Terakhir diperbarui 28 hari lalu': 'Last updated 28 days ago',
    'Perangkat Terhubung': 'Connected Devices',
    'Sesi Utama': 'Primary Session',
    'Online': 'Online',
    'Password Lama': 'Current Password',
    'Password Baru': 'New Password',
    'Konfirmasi Password Baru': 'Confirm New Password',
    'Persyaratan Password': 'Password Requirements',
    'Masukkan password lama': 'Enter your current password',
    'Masukkan password baru': 'Enter a new password',
    'Ulangi password baru': 'Re-enter the new password',
    'Silakan masukkan password lama Anda dan buat password baru yang lebih aman.':
        'Enter your current password and create a more secure new password.',
    'Memperbolehkan huruf besar (A-Z)': 'Include an uppercase letter (A-Z)',
    'Memperbolehkan huruf kecil (a-z)': 'Include a lowercase letter (a-z)',
    'Memperbolehkan angka (0-9)': 'Include a number (0-9)',
    'Memperbolehkan simbol atau tanda baca':
        'Include a symbol or punctuation mark',
    'Simpan': 'Save',
    'Password lama tidak boleh kosong': 'Current password is required',
    'Password baru tidak boleh kosong': 'New password is required',
    'Password harus minimal 8 karakter':
        'Password must be at least 8 characters long',
    'Password tidak memenuhi semua persyaratan':
        'Password does not meet all requirements',
    'Password baru tidak cocok': 'New passwords do not match',
    'Password baru tidak boleh sama dengan password lama':
        'New password must differ from the current password',
    'Pengguna tidak ditemukan': 'User not found',
    'Password lama tidak sesuai': 'Current password is incorrect',
    'Password berhasil diubah!': 'Password changed successfully!',
    'Password terlalu lemah': 'Password is too weak',
    'Silakan login kembali untuk keamanan': 'Please sign in again for security',
    'Gagal mengubah password': 'Could not change password',
    'Gagal mengubah password: ': 'Could not change password: ',
    'Informasi Aplikasi': 'App Information',
    'Nama Aplikasi': 'App Name',
    'Platform': 'Platform',
    'Dikembangkan Oleh': 'Developed By',
    'Tim ORVIX': 'ORVIX Team',
    'Kami berkomitmen untuk memberikan pengalaman terbaik dalam setiap fitur.':
        'We are committed to providing the best experience in every feature.',
    'ORVIX adalah aplikasi yang membantu Anda memantau harga emas terkini, menghitung nilai emas, serta memudahkan transaksi dengan lebih cepat dan akurat.':
        'ORVIX helps you monitor current gold prices, calculate gold values, and make transactions faster and more accurately.',
    '© 2026 ORVIX. Semua hak dilindungi': '© 2026 ORVIX. All rights reserved.',
    'Akun': 'Account',
    'Kalkulator Emas Fisik': 'Physical Gold Calculator',
    'Kalkulator Pivot Point': 'Pivot Point Calculator',
    'Riwayat Perhitungan': 'Calculation History',
    'Dashboard': 'Dashboard',
    'Cari': 'Search',
    'Temukan jawaban dari pertanyaan yang\nsering diajukan di sini.':
        'Find answers to frequently asked questions here.',
    'Pertanyaan tidak ditemukan.': 'No questions found.',
    'Cari pertanyaan...': 'Search questions...',
    'Bagaimana cara login ke aplikasi ORVIX?':
        'How do I log in to the ORVIX app?',
    'Masukkan username/email dan password yang telah terdaftar, kemudian tekan tombol Login. Sistem akan melakukan validasi akun sebelum memberikan akses ke aplikasi.':
        'Enter your registered username/email and password, then tap Login. The system will verify your account before granting access.',
    'Bagaimana jika saya lupa password?': 'What if I forget my password?',
    'Pilih menu Lupa Password pada halaman login, kemudian ikuti proses pemulihan password yang tersedia.':
        'Select Forgot Password on the login page, then follow the available password recovery steps.',
    'Mengapa saya tidak bisa mengakses beberapa fitur?':
        'Why can’t I access some features?',
    'Akses fitur ORVIX disesuaikan dengan role pengguna. Staff dan Admin memiliki hak akses yang berbeda.':
        'Access to ORVIX features depends on the user role. Staff and Admin accounts have different permissions.',
    'Apa perbedaan akun Admin dan Staff?':
        'What is the difference between Admin and Staff accounts?',
    'Staff dapat menggunakan kalkulator dan melihat riwayat perhitungannya sendiri. Admin memiliki akses lebih luas, seperti melihat seluruh riwayat, dashboard, laporan, activity log, serta mengelola data staff.':
        'Staff can use the calculators and view their own calculation history. Admins have broader access, including all history, the dashboard, reports, activity logs, and staff management.',
    'Apa saja data yang perlu dimasukkan pada Kalkulator Emas Fisik?':
        'What information should I enter in the Physical Gold Calculator?',
    'Masukkan parameter transaksi sesuai dengan data yang diperlukan oleh sistem. Setiap input akan divalidasi sebelum perhitungan dilakukan.':
        'Enter the transaction parameters required by the system. Each input is validated before a calculation is performed.',
    'Apakah hasil perhitungan langsung muncul secara otomatis?':
        'Are calculation results displayed automatically?',
    'Ya. Setelah seluruh input valid, sistem akan melakukan perhitungan secara otomatis dan menampilkan hasil bersih yang diperoleh berdasarkan data yang digunakan.':
        'Yes. Once all inputs are valid, the system calculates automatically and displays the net result based on the provided data.',
    'Mengapa hasil perhitungan tidak muncul?':
        'Why is the calculation result not displayed?',
    'Pastikan seluruh data yang diperlukan sudah diisi dengan benar. Jika terdapat input yang tidak sesuai, sistem akan melakukan validasi dan perhitungan tidak dapat dilanjutkan.':
        'Make sure all required information is entered correctly. If any input is invalid, the system will flag it and the calculation cannot continue.',
    'Apa yang ditampilkan pada Detail Perhitungan?':
        'What is shown in Calculation Details?',
    'Detail perhitungan menampilkan input yang digunakan, formula, proses perhitungan, dan hasil akhir sehingga pengguna dapat memahami bagaimana hasil tersebut diperoleh.':
        'Calculation details show the inputs, formula, calculation steps, and final result so users can understand how the result was obtained.',
    'Apakah saya bisa menghapus atau mengulang input perhitungan?':
        'Can I clear or re-enter calculation inputs?',
    'Bisa. Gunakan tombol Reset untuk mengosongkan kembali data dan melakukan perhitungan baru.':
        'Yes. Use the Reset button to clear the inputs and start a new calculation.',
    'Apa itu Kalkulator Pivot Point di ORVIX?':
        'What is the Pivot Point Calculator in ORVIX?',
    'Kalkulator Pivot Point digunakan untuk melakukan perhitungan berdasarkan data Open, High, Low, dan Close (OHLC) untuk menghasilkan nilai Pivot Point dan indikasi.':
        'The Pivot Point Calculator uses Open, High, Low, and Close (OHLC) data to calculate a Pivot Point value and signal.',
    'Apa arti Open, High, Low, dan Close (OHLC)?':
        'What do Open, High, Low, and Close (OHLC) mean?',
    'Open adalah harga pembukaan. High adalah harga tertinggi. Low adalah harga terendah. Close adalah harga penutupan.':
        'Open is the opening price. High is the highest price. Low is the lowest price. Close is the closing price.',
    'Apa fungsi tombol ON/OFF pada bagian Open?':
        'What does the ON/OFF switch for Open do?',
    'Tombol ON/OFF digunakan untuk menentukan apakah nilai Open akan diambil secara otomatis oleh sistem atau dimasukkan secara manual oleh pengguna.':
        'The ON/OFF switch determines whether the system retrieves the Open value automatically or the user enters it manually.',
    'Apa yang terjadi jika tombol Open dalam posisi ON?':
        'What happens when the Open switch is ON?',
    'Ketika tombol ON, sistem akan secara otomatis mengambil data Open dari hari sebelumnya dan menggunakan data tersebut dalam perhitungan. Sistem kemudian akan menghasilkan nilai Pivot Point dan indikasi secara otomatis.':
        'When ON, the system automatically retrieves the previous day’s Open value and uses it in the calculation. It then calculates the Pivot Point and signal.',
    'Apa yang terjadi jika tombol Open dalam posisi OFF?':
        'What happens when the Open switch is OFF?',
    'Ketika tombol OFF, pengguna dapat memasukkan nilai Open secara manual, misalnya menggunakan nilai Open hari ini atau nilai Open tertentu yang ingin digunakan dalam perhitungan.':
        'When OFF, users can enter an Open value manually, such as today’s Open or another value they want to use in the calculation.',
    'Kapan sebaiknya menggunakan tombol Open ON atau OFF?':
        'When should I turn the Open switch ON or OFF?',
    'Gunakan ON apabila ingin sistem mengambil nilai Open hari sebelumnya secara otomatis. Gunakan OFF apabila ingin memasukkan nilai Open secara manual, seperti nilai Open hari ini.':
        'Turn it ON to automatically use the previous day’s Open value. Turn it OFF to enter an Open value manually, such as today’s value.',
    'Bagaimana sistem menentukan indikasi pada Pivot Point untuk emas (LGD)?':
        'How does Pivot Point determine the signal for gold (LGD)?',
    'Pada perhitungan emas (LGD), jika Open berada di bawah Pivot Point maka indikasi BUY. Jika Open berada di atas Pivot Point maka indikasi SELL.':
        'For gold (LGD), an Open below the Pivot Point indicates BUY. An Open above the Pivot Point indicates SELL.',
    'Bagaimana sistem menentukan indikasi pada Pivot Point untuk Hang Seng (HSI)?':
        'How does Pivot Point determine the signal for Hang Seng (HSI)?',
    'Pada perhitungan Hang Seng (HSI), jika Open berada di bawah nilai Hang Seng/Pivot maka indikasi SELL. Jika Open berada di atas nilai Hang Seng/Pivot maka indikasi BUY.':
        'For Hang Seng (HSI), an Open below the Hang Seng/Pivot value indicates SELL. An Open above it indicates BUY.',
    'Mengapa indikasi LGD dan HSI memiliki aturan yang berbeda?':
        'Why do LGD and HSI use different signal rules?',
    'Karena ORVIX menerapkan aturan indikasi yang berbeda untuk masing-masing jenis perhitungan. Pada LGD, posisi Open terhadap Pivot digunakan dengan aturan BUY/SELL tertentu, sedangkan pada HSI menggunakan aturan yang berbeda.':
        'ORVIX applies different signal rules to each calculation type. LGD uses one BUY/SELL rule based on Open relative to Pivot, while HSI uses a different rule.',
    'Apakah perubahan nilai Open dapat memengaruhi indikasi?':
        'Can changing the Open value affect the signal?',
    'Ya. Nilai Open merupakan salah satu parameter yang digunakan dalam perhitungan. Perubahan nilai Open dapat memengaruhi hasil perhitungan dan indikasi BUY atau SELL yang dihasilkan sistem.':
        'Yes. Open is one of the calculation parameters. Changing it can affect the result and the BUY or SELL signal.',
    'Apakah hasil Pivot Point dapat dilihat secara detail?':
        'Can I view Pivot Point results in detail?',
    'Ya. Pengguna dapat melihat detail hasil perhitungan, termasuk data yang digunakan dan hasil perhitungan yang diperoleh.':
        'Yes. Users can view calculation details, including the data used and the resulting values.',
    'Apa fungsi Kalkulator Skenario?': 'What does the Scenario Calculator do?',
    'Kalkulator Skenario digunakan untuk mengubah salah satu data input dan melihat bagaimana perubahan tersebut memengaruhi hasil akhir perhitungan.':
        'The Scenario Calculator lets you change one input and see how that change affects the final result.',
    'Apakah perubahan pada Kalkulator Skenario mengubah data perhitungan sebelumnya?':
        'Does the Scenario Calculator change a previous calculation?',
    'Tidak. Kalkulator Skenario digunakan untuk melihat pengaruh perubahan suatu input terhadap hasil, tanpa mengubah input lainnya pada perhitungan yang digunakan sebagai acuan.':
        'No. It shows how changing one input affects the result without changing the other inputs in the reference calculation.',
    'Di mana saya bisa melihat perhitungan yang sudah dilakukan?':
        'Where can I see completed calculations?',
    'Perhitungan yang telah dilakukan dapat dilihat melalui menu Riwayat Perhitungan. Staff dapat melihat riwayat perhitungannya sendiri, sedangkan Admin dapat melihat seluruh riwayat.':
        'Completed calculations are available in Calculation History. Staff can view their own history, while Admins can view all history.',
    'Apakah riwayat perhitungan bisa difilter?':
        'Can I filter calculation history?',
    'Ya. Riwayat dapat difilter berdasarkan periode dan jenis perhitungan.':
        'Yes. History can be filtered by date range and calculation type.',
    'Bagaimana cara melihat detail perhitungan yang sudah tersimpan?':
        'How do I view the details of a saved calculation?',
    'Pilih salah satu data pada riwayat. Sistem akan menampilkan input, formula, proses perhitungan, dan hasil akhirnya.':
        'Select an item in History. The system displays its inputs, formula, calculation steps, and final result.',
    'Siapa yang dapat melihat Executive Dashboard?':
        'Who can access the Executive Dashboard?',
    'Executive Dashboard ditujukan untuk Admin dan memberikan informasi ringkasan mengenai perhitungan serta aktivitas sistem.':
        'The Executive Dashboard is for Admins and provides an overview of calculations and system activity.',
    'Apa saja yang dapat digunakan untuk memfilter Dashboard?':
        'What filters are available on the Dashboard?',
    'Admin dapat mengubah data yang ditampilkan berdasarkan periode, jenis perhitungan, dan staff.':
        'Admins can filter displayed data by date range, calculation type, and staff member.',
    'Apa itu Activity Log?': 'What is the Activity Log?',
    'Activity Log digunakan untuk mencatat aktivitas penting yang terjadi di dalam sistem, sehingga aktivitas dapat dipantau oleh pihak yang memiliki akses.':
        'The Activity Log records important events in the system so they can be monitored by authorized users.',
    'Historical Data': 'Historical Data',
    'Mulai  ': 'Start  ',
    'Sampai  ': 'End  ',
    'Perhitungan Hari Ini': "Today's Calculations",
    'Pilih Tanggal': 'Select Date',
    'Semua Kalkulator': 'All Calculators',
    'Pivot Point': 'Pivot Point',
    'Emas Fisik': 'Physical Gold',
    'Semua': 'All',
    'Batal': 'Cancel',
    'Batalkan': 'Cancel',
    'Pilih semua': 'Select all',
    'Hapus': 'Delete',
    'Hapus riwayat?': 'Delete history?',
    'Histori belum dapat dimuat.': 'History could not be loaded.',
    'Hari ini tidak ada perhitungan.': 'There are no calculations today.',
    'Riwayat berhasil dihapus.': 'History deleted successfully.',
    'Riwayat gagal dihapus.': 'Could not delete history.',
    'Baca semua': 'Mark all as read',
    'Tandai Dibaca': 'Mark as read',
    'Belum ada notifikasi': 'No notifications yet',
    'Belum ada staff yang sesuai.': 'No matching staff found.',
    'Belum ada data pada periode ini.': 'No data for this period.',
    'Unduh Laporan (PDF)': 'Download Report (PDF)',
    'Simpan tampilan hasil sebagai gambar': 'Save result view as an image',
    'Simpan ringkasan hasil sebagai PDF': 'Save result summary as a PDF',
    'Download': 'Download',
    'Reset': 'Reset',
    'Atau': 'Or',
    'Nama (A-Z)': 'Name (A-Z)',
    'Nama (Z-A)': 'Name (Z-A)',
    'Prioritas Aktif': 'Active First',
    'Prioritas Nonaktif': 'Inactive First',
    'Tanggal tidak ditemukan': 'Date not found',
    'Perempuan': 'Female',
    'Laki-laki': 'Male',
    'Staff berhasil ditambahkan.': 'Staff added successfully.',
    'Profil berhasil diperbarui': 'Profile updated successfully.',
    'Profil berhasil diperbarui.': 'Profile updated successfully.',
    'Gagal menyimpan perubahan profil': 'Could not save profile changes.',
    'Foto profil berhasil diperbarui': 'Profile photo updated successfully.',
    'Foto profil gagal diunggah': 'Could not upload profile photo.',
    'Harap isi semua kolom password': 'Please fill in all password fields.',
    'Konfirmasi password tidak cocok': 'Password confirmation does not match.',
    'Harap penuhi semua kriteria keamanan password':
        'Please meet all password security requirements.',
    'Password berhasil diperbarui. Silakan login kembali.':
        'Password updated. Please sign in again.',
    'Silakan masukkan email Anda terlebih dahulu':
        'Please enter your email first.',
    'Email dan Password tidak boleh kosong!':
        'Email and password cannot be empty.',
    'Login Berhasil! Selamat datang, ': 'Login successful! Welcome, ',
    'Hasil tampil, tetapi histori gagal disimpan.':
        'The result is shown, but could not be saved to history.',
    'ORVIX membantu perhitungan Emas Fisik, Pivot Point, dan NEST lebih mudah':
        'ORVIX makes Physical Gold, Pivot Point, and NEST calculations easier',
  };

  static const Map<String, String> _indonesian = {
    'Discover': 'Jelajahi',
    'News from all around the market': 'Berita seputar pasar global',
    'Home': 'Beranda',
    'History': 'Riwayat',
    'Historical Data': 'Data Historis',
    'Date': 'Tanggal',
    'Open': 'Buka',
    'High': 'Tertinggi',
    'Low': 'Terendah',
    'Close': 'Tutup',
    'midpoint': 'titik tengah',
    'Gold Spot / U.S. Dollar': 'Emas Spot / Dolar AS',
    'Calculate': 'Hitung',
    'Nest': 'NEST',
    'Market Update': 'Pembaruan Pasar',
    'Analysis & Opinion': 'Analisis & Opini',
    'Gold': 'Emas',
    'Oil': 'Minyak',
    'Silver': 'Perak',
  };

  static String text(BuildContext context, String source) {
    return Localizations.localeOf(context).languageCode == 'en'
        ? _english[source] ?? source
        : _indonesian[source] ?? source;
  }

  static String monthName(int month) {
    const english = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    const indonesian = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    final months = AppPreferences.instance.locale.languageCode == 'en'
        ? english
        : indonesian;
    return months[month - 1];
  }

  static String selectedCount(int count) =>
      AppPreferences.instance.locale.languageCode == 'en'
      ? '$count selected'
      : '$count dipilih';

  static String deleteSelectedCount(int count) =>
      AppPreferences.instance.locale.languageCode == 'en'
      ? 'Delete $count selected calculations?'
      : 'Hapus $count riwayat perhitungan terpilih?';

  static String summaryText(BuildContext context, String text) {
    if (Localizations.localeOf(context).languageCode != 'en') return text;
    for (final entry in const {
      ' aktif hari ini': ' active today',
      ' total data tercatat': ' total records',
      'tercatat hari ini': 'recorded today',
      'menit aktif hari ini': 'active minutes today',
    }.entries) {
      if (text.endsWith(entry.key)) {
        return '${text.substring(0, text.length - entry.key.length)}${entry.value}';
      }
    }
    return text;
  }

  static String historicalDataError(BuildContext context, Object error) =>
      Localizations.localeOf(context).languageCode == 'en'
      ? 'Historical data failed to load. Check your connection and try again.'
      : 'Data historical gagal dimuat. Periksa koneksi lalu coba lagi.';
}
