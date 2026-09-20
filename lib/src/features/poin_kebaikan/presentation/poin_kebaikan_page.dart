import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/poin_kebaikan_data.dart';
import 'widgets/kebaikan_category_section.dart';
import 'widgets/kebaikan_identity_card.dart';

class PoinKebaikanPage extends StatefulWidget {
  final String? initialUserName;

  const PoinKebaikanPage({super.key, this.initialUserName});

  @override
  State<PoinKebaikanPage> createState() => _PoinKebaikanPageState();
}

class _PoinKebaikanPageState extends State<PoinKebaikanPage> {
  late String _selectedNama;
  String _selectedProdi = 'TRPL (Programmer)';
  final String _selectedAngkatan = PoinKebaikanConfig.defaultAngkatan;
  bool _agreedToPromise = true;

  final Set<String> _selectedItemIds = {};
  final TextEditingController _saranController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  int _selectedCategoryIndex = 0; // 0 = Semua
  String _searchQuery = '';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Cari nama yang paling mirip dari list Google Form
    final defaultTarget =
        widget.initialUserName?.trim() ?? 'Allam Permata Putra';
    final matched = PoinKebaikanConfig.namaList.firstWhere(
      (n) =>
          n.toLowerCase().contains(defaultTarget.toLowerCase()) ||
          defaultTarget.toLowerCase().contains(n.toLowerCase()),
      orElse: () => 'Allam Permata Putra',
    );
    _selectedNama = matched;
  }

  @override
  void dispose() {
    _saranController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_agreedToPromise) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap centang persetujuan kejujuran terlebih dahulu.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (_selectedItemIds.isEmpty) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Belum Ada Kebaikan'),
          content: const Text(
            'Anda belum memilih satu pun poin kebaikan hari ini. Apakah tetap ingin membuka formulir?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE11D48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text(
                'Tetap Buka',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );

      if (proceed != true) return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _openPrefilledForm();
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _openPrefilledForm() async {
    final queryParams = <String, String>{
      'usp': 'pp_url',
      PoinKebaikanConfig.entryAngkatan: _selectedAngkatan,
      PoinKebaikanConfig.entryProdi: _selectedProdi,
      PoinKebaikanConfig.entryNama: _selectedNama,
      PoinKebaikanConfig.entryJanji: PoinKebaikanConfig.janjiValue,
    };

    for (final cat in PoinKebaikanConfig.categories) {
      for (final item in cat.items) {
        if (_selectedItemIds.contains(item.id)) {
          queryParams['entry.${item.id}'] = item.value;
        }
      }
    }

    if (_saranController.text.trim().isNotEmpty) {
      queryParams[PoinKebaikanConfig.entrySaran] = _saranController.text.trim();
    }

    final uri = Uri.parse(
      'https://docs.google.com/forms/d/e/1FAIpQLSeYVaIo7C9bxx14Ea9rbSaj7PTsu88-fgJOV9YqJsDeyDDlGg/viewform',
    ).replace(queryParameters: queryParams);

    try {
      final selectedCount = _selectedItemIds.length;
      // Buka sebagai In-App Browser View (tab di dalam aplikasi, tanpa switch keluar app)
      final launched = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
      if (!launched) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }

      await PoinKebaikanConfig.markDoneToday();

      // Begitu user selesai dan kembali ke aplikasi, kosongkan semua pilihan & kolom
      if (mounted) {
        setState(() {
          _selectedItemIds.clear();
          _saranController.clear();
          _searchController.clear();
          _searchQuery = '';
        });

        if (selectedCount > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Formulir telah dikirim. Semua pilihan telah dikosongkan kembali.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF16A34A),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tidak dapat membuka formulir: $err')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filter categories & items berdasarkan pencarian & filter kategori
    final activeCategories = _filterCategories();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        title: const Text(
          'Poin Kebaikan',
          style: TextStyle(
            color: Color(0xFF111827),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF111827),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_selectedItemIds.isNotEmpty)
            IconButton(
              tooltip: 'Kosongkan Semua Pilihan',
              icon: const Icon(
                Icons.restart_alt_rounded,
                color: Color(0xFFEF4444),
                size: 22,
              ),
              onPressed: () {
                setState(() {
                  _selectedItemIds.clear();
                  _saranController.clear();
                });
              },
            ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _selectedItemIds.isEmpty
                  ? const Color(0xFFF1F5F9)
                  : const Color(0xFFFFF1F2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _selectedItemIds.isEmpty
                    ? const Color(0xFFE2E8F0)
                    : const Color(0xFFFECDD3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.volunteer_activism_rounded,
                  size: 14,
                  color: _selectedItemIds.isEmpty
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFFE11D48),
                ),
                const SizedBox(width: 4),
                Text(
                  '${_selectedItemIds.length} dipilih',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _selectedItemIds.isEmpty
                        ? const Color(0xFF64748B)
                        : const Color(0xFFE11D48),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              _buildProfileCard(),
              const SizedBox(height: 16),
              _buildSearchBar(),
              const SizedBox(height: 14),
              _buildCategoryPills(),
              const SizedBox(height: 16),

              if (activeCategories.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      Icon(
                        Icons.search_off_rounded,
                        size: 48,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Tidak ditemukan kebaikan dengan kata "$_searchQuery"',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...activeCategories.map((cat) => _buildCategorySection(cat)),

              const SizedBox(height: 16),
              _buildSaranCard(),
            ],
          ),

          // Sticky Bottom Action Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_selectedItemIds.length} Poin Terpilih',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF111827),
                            ),
                          ),
                          const Text(
                            'Otomatis terisi • Siap dikirim',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF16A34A),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE11D48),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      onPressed: _isSubmitting ? null : _submitForm,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send_rounded, size: 18),
                      label: Text(
                        _isSubmitting ? 'Membuka...' : 'Kirim ke GForm',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    return KebaikanIdentityCard(
      selectedNama: _selectedNama,
      selectedProdi: _selectedProdi,
      selectedAngkatan: _selectedAngkatan,
      agreedToPromise: _agreedToPromise,
      onNamaChanged: (val) {
        if (val != null) setState(() => _selectedNama = val);
      },
      onProdiChanged: (val) {
        if (val != null) setState(() => _selectedProdi = val);
      },
      onPromiseToggled: () =>
          setState(() => _agreedToPromise = !_agreedToPromise),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: 'Cari kebaikan (misal: adzan, sampah, kipas)...',
          hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0xFF9CA3AF),
            size: 20,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: Color(0xFF9CA3AF),
                  ),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
        ),
        onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
      ),
    );
  }

  Widget _buildCategoryPills() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip(index: 0, label: 'Semua', count: null),
          for (int i = 0; i < PoinKebaikanConfig.categories.length; i++)
            _buildFilterChip(
              index: i + 1,
              label: PoinKebaikanConfig.categories[i].title,
              count: PoinKebaikanConfig.categories[i].items.length,
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required int index,
    required String label,
    int? count,
  }) {
    final isSelected = _selectedCategoryIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategoryIndex = index),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF111827) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF111827)
                : const Color(0xFFE5E7EB),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF4B5563),
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 4),
              Text(
                '($count)',
                style: TextStyle(
                  fontSize: 10,
                  color: isSelected ? Colors.white70 : const Color(0xFF9CA3AF),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<KebaikanCategory> _filterCategories() {
    final List<KebaikanCategory> filtered = [];

    for (int i = 0; i < PoinKebaikanConfig.categories.length; i++) {
      if (_selectedCategoryIndex != 0 && _selectedCategoryIndex != (i + 1)) {
        continue;
      }
      final cat = PoinKebaikanConfig.categories[i];

      if (_searchQuery.isEmpty) {
        filtered.add(cat);
      } else {
        final matchingItems = cat.items.where((it) {
          return it.label.toLowerCase().contains(_searchQuery);
        }).toList();

        if (matchingItems.isNotEmpty) {
          filtered.add(
            KebaikanCategory(
              key: cat.key,
              title: cat.title,
              icon: cat.icon,
              color: cat.color,
              bgColor: cat.bgColor,
              items: matchingItems,
            ),
          );
        }
      }
    }

    return filtered;
  }

  Widget _buildCategorySection(KebaikanCategory cat) {
    return KebaikanCategorySection(
      category: cat,
      selectedItemIds: _selectedItemIds,
      onItemToggle: (id) {
        setState(() {
          if (_selectedItemIds.contains(id)) {
            _selectedItemIds.remove(id);
          } else {
            _selectedItemIds.add(id);
          }
        });
      },
    );
  }

  Widget _buildSaranCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline_rounded,
                color: Colors.amber.shade700,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Saran atau Masukan (Opsional)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Ajukan ide jika ada jenis kebaikan baru yang bisa menjadi bahan penilaian.',
            style: TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _saranController,
            maxLines: 3,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Tulis ide atau saran kebaikan di sini...',
              hintStyle: const TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 12,
              ),
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE11D48)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
