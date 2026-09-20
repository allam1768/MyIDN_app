import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../common_widgets/async_value_widget.dart';
import '../../../utils/date_utils.dart';
import 'ibadah_providers.dart';

class InputIbadahPage extends ConsumerStatefulWidget {
  final String? initialTanggal;

  const InputIbadahPage({super.key, this.initialTanggal});

  @override
  ConsumerState<InputIbadahPage> createState() => _InputIbadahPageState();
}

class _InputIbadahPageState extends ConsumerState<InputIbadahPage> {
  late String _selectedTanggal;
  final Map<int, int> _selectedAnswers =
      {}; // pertanyaan_id -> pilihan_jawaban_id

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedTanggal =
        widget.initialTanggal ??
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  String _cleanHtml(String text) {
    return text
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&amp;', '&')
        .trim();
  }

  String _formatDateIndo(String dateStr) =>
      AppDateUtils.formatDateIndo(dateStr);

  DateTime _parseSelectedDate() {
    final parts = _selectedTanggal.split('-');
    if (parts.length == 3) {
      final y = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      final d = int.tryParse(parts[2]);
      if (y != null && m != null && d != null) {
        return DateTime(y, m, d);
      }
    }
    return DateTime.now();
  }

  void _setDate(DateTime dt) {
    setState(() {
      _selectedTanggal =
          "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
      _selectedAnswers.clear();
    });
  }

  void _stepDate(int days) {
    final cur = _parseSelectedDate();
    _setDate(cur.add(Duration(days: days)));
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _parseSelectedDate(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      helpText: 'Pilih Tanggal Laporan Ibadah',
    );
    if (picked != null) {
      _setDate(picked);
    }
  }

  void _setAllToOption(List<dynamic> pertanyaanList, String targetOption) {
    setState(() {
      for (final p in pertanyaanList) {
        if (p is Map && p['pilihan_jawabans'] is List) {
          final options = p['pilihan_jawabans'] as List;
          final matched = options.firstWhere(
            (opt) =>
                opt is Map &&
                opt['teks_jawaban']?.toString().toLowerCase() ==
                    targetOption.toLowerCase(),
            orElse: () => options.isNotEmpty ? options.first : null,
          );
          if (matched != null && matched is Map) {
            final pId = p['id'] as int;
            final optId = matched['id'] as int;
            _selectedAnswers[pId] = optId;
          }
        }
      }
    });
  }

  Future<void> _submitForm(List<dynamic> pertanyaanList) async {
    for (final p in pertanyaanList) {
      if (p is Map) {
        final pId = p['id'] as int;
        if (!_selectedAnswers.containsKey(pId)) {
          final teks = _cleanHtml(
            p['teks_pertanyaan']?.toString() ?? 'Pertanyaan',
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Harap jawab: $teks'),
              backgroundColor: Colors.red.shade700,
            ),
          );
          return;
        }
      }
    }

    final Map<String, dynamic> answersPayload = {};
    for (final p in pertanyaanList) {
      if (p is Map) {
        final pId = p['id'] as int;
        final val = _selectedAnswers[pId];
        answersPayload[pId.toString()] = {
          'pertanyaan_id': pId,
          'type': p['tipe_pertanyaan'] ?? 'pilihan_ganda',
          'value': val,
          'wajib': p['wajib_diisi'] ?? 1,
        };
      }
    }

    final success = await ref
        .read(ibadahSubmitControllerProvider.notifier)
        .submit(
          tanggalLaporan: _selectedTanggal,
          isHaid: false,
          answers: answersPayload,
        );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Alhamdulillah! Laporan ibadah berhasil dikirim 🎉'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } else {
      final errorMsg =
          ref.read(ibadahSubmitControllerProvider).errorMessage ??
          'Gagal mengirim laporan';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Declarative & auto-cached by Riverpod!
    final formAsync = ref.watch(formIbadahProvider(_selectedTanggal));
    final submitState = ref.watch(ibadahSubmitControllerProvider);

    final now = DateTime.now();
    final todayStr =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final isNotToday = _selectedTanggal != todayStr;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Input Laporan Ibadah'),
      ),
      body: AsyncValueWidget<List<dynamic>>(
        value: formAsync,
        onRetry: () => ref.invalidate(formIbadahProvider(_selectedTanggal)),
        data: (pertanyaanList) {
          return Column(
            children: [
              // Header Card Tanggal & Shortcut Isi Cepat
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                color: Colors.teal.shade50,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Pengatur Tanggal dengan Panah & DatePicker
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.teal.shade200),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.chevron_left_rounded,
                              color: Colors.teal,
                            ),
                            tooltip: 'Hari Sebelumnya',
                            onPressed: () => _stepDate(-1),
                          ),
                          Expanded(
                            child: InkWell(
                              onTap: _pickDate,
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: Column(
                                  children: [
                                    const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.calendar_month_rounded,
                                          size: 14,
                                          color: Colors.teal,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'Tanggal Laporan (Ketuk untuk Ubah)',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.teal,
                                          ),
                                        ),
                                        SizedBox(width: 2),
                                        Icon(
                                          Icons.arrow_drop_down,
                                          size: 16,
                                          color: Colors.teal,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _formatDateIndo(_selectedTanggal),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.chevron_right_rounded,
                              color: Colors.teal,
                            ),
                            tooltip: 'Hari Berikutnya',
                            onPressed: () => _stepDate(1),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (isNotToday)
                          ActionChip(
                            avatar: const Icon(
                              Icons.today_rounded,
                              size: 14,
                              color: Colors.teal,
                            ),
                            label: const Text(
                              'Ke Hari Ini',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            backgroundColor: Colors.white,
                            side: BorderSide(color: Colors.teal.shade300),
                            padding: EdgeInsets.zero,
                            onPressed: () => _setDate(DateTime.now()),
                          )
                        else
                          const SizedBox.shrink(),
                        Chip(
                          label: Text(
                            '${_selectedAnswers.length}/${pertanyaanList.length} Terjawab',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color:
                                  _selectedAnswers.length ==
                                      pertanyaanList.length
                                  ? Colors.green.shade800
                                  : Colors.teal.shade800,
                            ),
                          ),
                          backgroundColor:
                              _selectedAnswers.length == pertanyaanList.length
                              ? Colors.green.shade100
                              : Colors.white,
                          side: BorderSide(color: Colors.teal.shade100),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                _setAllToOption(pertanyaanList, 'Ya'),
                            icon: const Icon(
                              Icons.done_all,
                              size: 16,
                              color: Colors.teal,
                            ),
                            label: const Text(
                              'Pilih Semua "Ya"',
                              style: TextStyle(fontSize: 12),
                            ),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              side: const BorderSide(color: Colors.teal),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                _setAllToOption(pertanyaanList, 'Tidak'),
                            icon: const Icon(
                              Icons.clear_all,
                              size: 16,
                              color: Colors.grey,
                            ),
                            label: const Text(
                              'Pilih Semua "Tidak"',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black87,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              side: BorderSide(color: Colors.grey.shade400),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Daftar Pertanyaan
              Expanded(
                child: RefreshIndicator(
                  color: Colors.teal,
                  onRefresh: () async {
                    ref.invalidate(formIbadahProvider(_selectedTanggal));
                  },
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: pertanyaanList.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final p = pertanyaanList[index];
                      final Map pMap = p is Map ? p : {};
                      final pId = pMap['id'] as int? ?? index;
                      final teks = _cleanHtml(
                        pMap['teks_pertanyaan']?.toString() ?? '-',
                      );
                      final List options = (pMap['pilihan_jawabans'] is List)
                          ? pMap['pilihan_jawabans']
                          : [];

                      final currentSelectedId = _selectedAnswers[pId];

                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundColor: currentSelectedId != null
                                        ? Colors.teal
                                        : Colors.grey.shade300,
                                    child: Text(
                                      '${index + 1}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: currentSelectedId != null
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      teks,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: options.map<Widget>((opt) {
                                  final Map optMap = opt is Map ? opt : {};
                                  final optId = optMap['id'] as int?;
                                  final label =
                                      optMap['teks_jawaban']?.toString() ?? '-';
                                  final isSelected = currentSelectedId == optId;
                                  final isYa = label.toLowerCase() == 'ya';

                                  return Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4.0,
                                      ),
                                      child: InkWell(
                                        onTap: optId != null
                                            ? () {
                                                setState(() {
                                                  _selectedAnswers[pId] = optId;
                                                });
                                              }
                                            : null,
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 10,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? (isYa
                                                      ? Colors.teal
                                                      : Colors.blueGrey)
                                                : Colors.grey.shade100,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color: isSelected
                                                  ? (isYa
                                                        ? Colors.teal
                                                        : Colors.blueGrey)
                                                  : Colors.grey.shade300,
                                              width: isSelected ? 1.5 : 1,
                                            ),
                                          ),
                                          alignment: Alignment.center,
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                isSelected
                                                    ? (isYa
                                                          ? Icons.check_circle
                                                          : Icons.cancel)
                                                    : Icons
                                                          .radio_button_unchecked,
                                                size: 16,
                                                color: isSelected
                                                    ? Colors.white
                                                    : Colors.grey,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                label,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                  color: isSelected
                                                      ? Colors.white
                                                      : Colors.black87,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Bottom Submit Button
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, -4),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: submitState.isSubmitting
                        ? null
                        : () => _submitForm(pertanyaanList),
                    icon: submitState.isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.send_rounded),
                    label: Text(
                      submitState.isSubmitting
                          ? 'Mengirim Laporan...'
                          : 'Kirim Laporan Ibadah',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
