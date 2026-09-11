import 'package:flutter/material.dart';

class FaqView extends StatefulWidget {
	const FaqView({super.key});

	@override
	State<FaqView> createState() => _FaqViewState();
}

class _FaqViewState extends State<FaqView> {
	static const _orange = Color(0xFFE45B16);
	static const _ink = Color(0xFF241A17);
	static const _muted = Color(0xFF967A69);
	static const _surface = Color(0xFFFFFBF7);

	final _searchController = TextEditingController();
	String _selectedCategory = 'Semua';
	int? _expandedIndex;

	final List<_FaqItem> _items = const [
		_FaqItem(
			category: 'Akun',
			icon: Icons.person_outline,
			question: 'Bagaimana cara login ke aplikasi ORVIX?',
			answer:
					'Masukkan username/email dan password yang telah terdaftar, kemudian tekan tombol Login. Sistem akan melakukan validasi akun sebelum memberikan akses ke aplikasi.',
		),
		_FaqItem(
			category: 'Akun',
			icon: Icons.lock_outline,
			question: 'Bagaimana jika saya lupa password?',
			answer:
					'Pilih menu Lupa Password pada halaman login, kemudian ikuti proses pemulihan password yang tersedia.',
		),
		_FaqItem(
			category: 'Akun',
			icon: Icons.lock_person_outlined,
			question: 'Mengapa saya tidak bisa mengakses beberapa fitur?',
			answer:
					'Akses fitur ORVIX disesuaikan dengan role pengguna. Staff dan Admin memiliki hak akses yang berbeda.',
		),
		_FaqItem(
			category: 'Akun',
			icon: Icons.admin_panel_settings_outlined,
			question: 'Apa perbedaan akun Admin dan Staff?',
			answer:
					'Staff dapat menggunakan kalkulator dan melihat riwayat perhitungannya sendiri. Admin memiliki akses lebih luas, seperti melihat seluruh riwayat, dashboard, laporan, activity log, serta mengelola data staff.',
		),
		_FaqItem(
			category: 'Kalkulator Emas Fisik',
			icon: Icons.calculate_outlined,
			question: 'Apa saja data yang perlu dimasukkan pada Kalkulator Emas Fisik?',
			answer:
					'Masukkan parameter transaksi sesuai dengan data yang diperlukan oleh sistem. Setiap input akan divalidasi sebelum perhitungan dilakukan.',
		),
		_FaqItem(
			category: 'Kalkulator Emas Fisik',
			icon: Icons.autorenew,
			question: 'Apakah hasil perhitungan langsung muncul secara otomatis?',
			answer:
					'Ya. Setelah seluruh input valid, sistem akan melakukan perhitungan secara otomatis dan menampilkan hasil bersih yang diperoleh berdasarkan data yang digunakan.',
		),
		_FaqItem(
			category: 'Kalkulator Emas Fisik',
			icon: Icons.error_outline,
			question: 'Mengapa hasil perhitungan tidak muncul?',
			answer:
					'Pastikan seluruh data yang diperlukan sudah diisi dengan benar. Jika terdapat input yang tidak sesuai, sistem akan melakukan validasi dan perhitungan tidak dapat dilanjutkan.',
		),
		_FaqItem(
			category: 'Kalkulator Emas Fisik',
			icon: Icons.info_outline,
			question: 'Apa yang ditampilkan pada Detail Perhitungan?',
			answer:
					'Detail perhitungan menampilkan input yang digunakan, formula, proses perhitungan, dan hasil akhir sehingga pengguna dapat memahami bagaimana hasil tersebut diperoleh.',
		),
		_FaqItem(
			category: 'Kalkulator Emas Fisik',
			icon: Icons.restart_alt,
			question: 'Apakah saya bisa menghapus atau mengulang input perhitungan?',
			answer:
					'Bisa. Gunakan tombol Reset untuk mengosongkan kembali data dan melakukan perhitungan baru.',
		),
		_FaqItem(
			category: 'Kalkulator Pivot Point',
			icon: Icons.show_chart,
			question: 'Apa itu Kalkulator Pivot Point di ORVIX?',
			answer:
					'Kalkulator Pivot Point digunakan untuk melakukan perhitungan berdasarkan data Open, High, Low, dan Close (OHLC) untuk menghasilkan nilai Pivot Point dan indikasi.',
		),
		_FaqItem(
			category: 'Kalkulator Pivot Point',
			icon: Icons.menu_book_outlined,
			question: 'Apa arti Open, High, Low, dan Close (OHLC)?',
			answer:
					'Open adalah harga pembukaan. High adalah harga tertinggi. Low adalah harga terendah. Close adalah harga penutupan.',
		),
		_FaqItem(
			category: 'Kalkulator Pivot Point',
			icon: Icons.toggle_on_outlined,
			question: 'Apa fungsi tombol ON/OFF pada bagian Open?',
			answer:
					'Tombol ON/OFF digunakan untuk menentukan apakah nilai Open akan diambil secara otomatis oleh sistem atau dimasukkan secara manual oleh pengguna.',
		),
		_FaqItem(
			category: 'Kalkulator Pivot Point',
			icon: Icons.download_outlined,
			question: 'Apa yang terjadi jika tombol Open dalam posisi ON?',
			answer:
					'Ketika tombol ON, sistem akan secara otomatis mengambil data Open dari hari sebelumnya dan menggunakan data tersebut dalam perhitungan. Sistem kemudian akan menghasilkan nilai Pivot Point dan indikasi secara otomatis.',
		),
		_FaqItem(
			category: 'Kalkulator Pivot Point',
			icon: Icons.edit_outlined,
			question: 'Apa yang terjadi jika tombol Open dalam posisi OFF?',
			answer:
					'Ketika tombol OFF, pengguna dapat memasukkan nilai Open secara manual, misalnya menggunakan nilai Open hari ini atau nilai Open tertentu yang ingin digunakan dalam perhitungan.',
		),
		_FaqItem(
			category: 'Kalkulator Pivot Point',
			icon: Icons.help_outline,
			question: 'Kapan sebaiknya menggunakan tombol Open ON atau OFF?',
			answer:
					'Gunakan ON apabila ingin sistem mengambil nilai Open hari sebelumnya secara otomatis. Gunakan OFF apabila ingin memasukkan nilai Open secara manual, seperti nilai Open hari ini.',
		),
		_FaqItem(
			category: 'Kalkulator Pivot Point',
			icon: Icons.trending_down,
			question: 'Bagaimana sistem menentukan indikasi pada Pivot Point untuk emas (LGD)?',
			answer:
					'Pada perhitungan emas (LGD), jika Open berada di bawah Pivot Point maka indikasi BUY. Jika Open berada di atas Pivot Point maka indikasi SELL.',
		),
		_FaqItem(
			category: 'Kalkulator Pivot Point',
			icon: Icons.trending_up,
			question: 'Bagaimana sistem menentukan indikasi pada Pivot Point untuk Hang Seng (HSI)?',
			answer:
					'Pada perhitungan Hang Seng (HSI), jika Open berada di bawah nilai Hang Seng/Pivot maka indikasi SELL. Jika Open berada di atas nilai Hang Seng/Pivot maka indikasi BUY.',
		),
		_FaqItem(
			category: 'Kalkulator Pivot Point',
			icon: Icons.swap_vert,
			question: 'Mengapa indikasi LGD dan HSI memiliki aturan yang berbeda?',
			answer:
					'Karena ORVIX menerapkan aturan indikasi yang berbeda untuk masing-masing jenis perhitungan. Pada LGD, posisi Open terhadap Pivot digunakan dengan aturan BUY/SELL tertentu, sedangkan pada HSI menggunakan aturan yang berbeda.',
		),
		_FaqItem(
			category: 'Kalkulator Pivot Point',
			icon: Icons.tune,
			question: 'Apakah perubahan nilai Open dapat memengaruhi indikasi?',
			answer:
					'Ya. Nilai Open merupakan salah satu parameter yang digunakan dalam perhitungan. Perubahan nilai Open dapat memengaruhi hasil perhitungan dan indikasi BUY atau SELL yang dihasilkan sistem.',
		),
		_FaqItem(
			category: 'Kalkulator Pivot Point',
			icon: Icons.receipt_long_outlined,
			question: 'Apakah hasil Pivot Point dapat dilihat secara detail?',
			answer:
					'Ya. Pengguna dapat melihat detail hasil perhitungan, termasuk data yang digunakan dan hasil perhitungan yang diperoleh.',
		),
		_FaqItem(
			category: 'Kalkulator Pivot Point',
			icon: Icons.science_outlined,
			question: 'Apa fungsi Kalkulator Skenario?',
			answer:
					'Kalkulator Skenario digunakan untuk mengubah salah satu data input dan melihat bagaimana perubahan tersebut memengaruhi hasil akhir perhitungan.',
		),
		_FaqItem(
			category: 'Kalkulator Pivot Point',
			icon: Icons.compare_arrows,
			question: 'Apakah perubahan pada Kalkulator Skenario mengubah data perhitungan sebelumnya?',
			answer:
					'Tidak. Kalkulator Skenario digunakan untuk melihat pengaruh perubahan suatu input terhadap hasil, tanpa mengubah input lainnya pada perhitungan yang digunakan sebagai acuan.',
		),
		_FaqItem(
			category: 'Riwayat Perhitungan',
			icon: Icons.history,
			question: 'Di mana saya bisa melihat perhitungan yang sudah dilakukan?',
			answer:
					'Perhitungan yang telah dilakukan dapat dilihat melalui menu Riwayat Perhitungan. Staff dapat melihat riwayat perhitungannya sendiri, sedangkan Admin dapat melihat seluruh riwayat.',
		),
		_FaqItem(
			category: 'Riwayat Perhitungan',
			icon: Icons.filter_alt_outlined,
			question: 'Apakah riwayat perhitungan bisa difilter?',
			answer:
					'Ya. Riwayat dapat difilter berdasarkan periode dan jenis perhitungan.',
		),
		_FaqItem(
			category: 'Riwayat Perhitungan',
			icon: Icons.description_outlined,
			question: 'Bagaimana cara melihat detail perhitungan yang sudah tersimpan?',
			answer:
					'Pilih salah satu data pada riwayat. Sistem akan menampilkan input, formula, proses perhitungan, dan hasil akhirnya.',
		),
		_FaqItem(
			category: 'Dashboard',
			icon: Icons.dashboard_outlined,
			question: 'Siapa yang dapat melihat Executive Dashboard?',
			answer:
					'Executive Dashboard ditujukan untuk Admin dan memberikan informasi ringkasan mengenai perhitungan serta aktivitas sistem.',
		),
		_FaqItem(
			category: 'Dashboard',
			icon: Icons.filter_list_outlined,
			question: 'Apa saja yang dapat digunakan untuk memfilter Dashboard?',
			answer:
					'Admin dapat mengubah data yang ditampilkan berdasarkan periode, jenis perhitungan, dan staff.',
		),
		_FaqItem(
			category: 'Dashboard',
			icon: Icons.event_note_outlined,
			question: 'Apa itu Activity Log?',
			answer:
					'Activity Log digunakan untuk mencatat aktivitas penting yang terjadi di dalam sistem, sehingga aktivitas dapat dipantau oleh pihak yang memiliki akses.',
		),
	];

	@override
	void dispose() {
		_searchController.dispose();
		super.dispose();
	}

	List<_FaqItem> get _filteredItems {
		final query = _searchController.text.trim().toLowerCase();
		return _items.where((item) {
			final matchesCategory =
					_selectedCategory == 'Semua' || item.category == _selectedCategory;
			final matchesSearch = query.isEmpty ||
					item.question.toLowerCase().contains(query) ||
					item.answer.toLowerCase().contains(query);
			return matchesCategory && matchesSearch;
		}).toList();
	}

	@override
	Widget build(BuildContext context) {
		final visibleItems = _filteredItems;
		return Scaffold(
			body: Container(
				decoration: const BoxDecoration(
					gradient: LinearGradient(
						begin: Alignment.topCenter,
						end: Alignment.bottomCenter,
						colors: [Color(0xFFED8A4E), Color(0xFFFFF8F3)],
						stops: [0.0, 0.55],
					),
				),
				child: SafeArea(
					child: Column(
						children: [
							_buildHeader(),
							Expanded(
								child: Container(
									margin: const EdgeInsets.only(top: 14),
									padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
									decoration: const BoxDecoration(
										color: _surface,
										borderRadius: BorderRadius.vertical(
											top: Radius.circular(32),
										),
									),
									child: Column(
										children: [
											const Align(
												alignment: Alignment.centerLeft,
												child: Text(
													'Temukan jawaban dari pertanyaan yang\nsering diajukan di sini.',
													style: TextStyle(
														color: _ink,
														fontSize: 14,
														height: 1.35,
													),
												),
											),
											const SizedBox(height: 18),
											_buildSearchField(),
											const SizedBox(height: 18),
											_buildCategoryList(),
											const SizedBox(height: 20),
											Expanded(
												child: visibleItems.isEmpty
														? const Center(
																child: Text(
																	'Pertanyaan tidak ditemukan.',
																	style: TextStyle(color: _muted),
																),
															)
														: ListView.separated(
																padding: const EdgeInsets.only(bottom: 28),
																itemCount: visibleItems.length,
																separatorBuilder: (_, _) =>
																		const SizedBox(height: 10),
																itemBuilder: (context, index) =>
																		_buildFaqTile(visibleItems[index], index),
															),
											),
										],
									),
								),
							),
						],
					),
				),
			),
		);
	}

	Widget _buildHeader() {
		return Padding(
			padding: const EdgeInsets.fromLTRB(26, 18, 22, 0),
			child: Row(
				children: [
					_circleButton(Icons.arrow_back, () => Navigator.pop(context)),
					const SizedBox(width: 18),
					const Text(
						'FAQ',
						style: TextStyle(
							color: Colors.white,
							fontSize: 24,
							fontWeight: FontWeight.w700,
						),
					),
				],
			),
		);
	}

	Widget _circleButton(IconData icon, VoidCallback onTap) {
		return Material(
			color: Colors.white,
			shape: const CircleBorder(),
			child: InkWell(
				onTap: onTap,
				customBorder: const CircleBorder(),
				child: SizedBox(
					width: 40,
					height: 40,
					child: Icon(icon, color: _ink, size: 24),
				),
			),
		);
	}

	Widget _buildSearchField() {
		return TextField(
			controller: _searchController,
			onChanged: (_) => setState(() => _expandedIndex = null),
			decoration: InputDecoration(
				hintText: 'Cari pertanyaan...',
				hintStyle: const TextStyle(color: _muted, fontSize: 13),
				prefixIcon: const Icon(Icons.search, color: _muted, size: 22),
				suffixIcon: _searchController.text.isEmpty
						? null
						: IconButton(
								onPressed: () {
									_searchController.clear();
									setState(() => _expandedIndex = null);
								},
								icon: const Icon(Icons.close, color: _muted, size: 18),
							),
				filled: true,
				fillColor: const Color(0xFFF5F0EC),
				contentPadding: const EdgeInsets.symmetric(vertical: 12),
				border: OutlineInputBorder(
					borderRadius: BorderRadius.circular(14),
					borderSide: const BorderSide(color: Color(0xFFE9D8CA)),
				),
				enabledBorder: OutlineInputBorder(
					borderRadius: BorderRadius.circular(14),
					borderSide: const BorderSide(color: Color(0xFFE9D8CA)),
				),
				focusedBorder: OutlineInputBorder(
					borderRadius: BorderRadius.circular(14),
					borderSide: const BorderSide(color: _orange),
				),
			),
		);
	}

	Widget _buildCategoryList() {
		const categories = [
			'Semua',
			'Akun',
				'Kalkulator Emas Fisik',
				'Kalkulator Pivot Point',
				'Riwayat Perhitungan',
				'Dashboard',
		];
		return SizedBox(
			height: 34,
			child: ListView.separated(
				scrollDirection: Axis.horizontal,
				itemCount: categories.length,
				separatorBuilder: (_, _) => const SizedBox(width: 8),
				itemBuilder: (context, index) {
					final category = categories[index];
					final selected = category == _selectedCategory;
					return ChoiceChip(
						label: Text(category),
						selected: selected,
						onSelected: (_) => setState(() {
							_selectedCategory = category;
							_expandedIndex = null;
						}),
						labelStyle: TextStyle(
							color: selected ? Colors.white : _muted,
							fontSize: 12,
							fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
						),
						backgroundColor: const Color(0xFFFFF8F3),
						selectedColor: _orange,
						side: BorderSide(
							color: selected ? _orange : const Color(0xFFE6CDBD),
						),
						shape: RoundedRectangleBorder(
							borderRadius: BorderRadius.circular(18),
						),
						showCheckmark: false,
						padding: const EdgeInsets.symmetric(horizontal: 10),
					);
				},
			),
		);
	}

	Widget _buildFaqTile(_FaqItem item, int index) {
		final expanded = _expandedIndex == index;
		return DecoratedBox(
			decoration: BoxDecoration(
				color: const Color(0xFFFCF8F4),
				borderRadius: BorderRadius.circular(15),
				border: Border.all(color: const Color(0xFFEADDCF)),
			),
			child: InkWell(
				borderRadius: BorderRadius.circular(15),
				onTap: () => setState(() {
					_expandedIndex = expanded ? null : index;
				}),
				child: Column(
					children: [
						Padding(
							padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
							child: Row(
								children: [
									Container(
										width: 40,
										height: 40,
										decoration: const BoxDecoration(
											color: Color(0xFFFFF0E7),
											shape: BoxShape.circle,
										),
										child: Icon(item.icon, color: _orange, size: 21),
									),
									const SizedBox(width: 12),
									Expanded(
										child: Text(
											item.question,
											style: const TextStyle(
												color: _ink,
												fontSize: 13,
												height: 1.25,
												fontWeight: FontWeight.w500,
											),
										),
									),
									Icon(
										expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
										color: _muted,
										size: 22,
									),
								],
							),
						),
						if (expanded) ...[
							const Divider(height: 1, color: Color(0xFFEADDCF)),
							Padding(
								padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
								child: Align(
									alignment: Alignment.centerLeft,
									child: Text(
										item.answer,
										style: const TextStyle(
											color: _muted,
											fontSize: 12,
											height: 1.4,
										),
									),
								),
							),
						],
					],
				),
			),
		);
	}
}

class _FaqItem {
	final String category;
	final IconData icon;
	final String question;
	final String answer;

	const _FaqItem({
		required this.category,
		required this.icon,
		required this.question,
		required this.answer,
	});
}
