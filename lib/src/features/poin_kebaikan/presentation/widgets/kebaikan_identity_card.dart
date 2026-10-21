import 'package:flutter/material.dart';
import 'package:reminder/src/utils/date_utils.dart';
import '../../data/poin_kebaikan_data.dart';

/// Kartu identitas santri & janji kejujuran pengisian form poin kebaikan
class KebaikanIdentityCard extends StatelessWidget {
  final String selectedNama;
  final String selectedProdi;
  final String selectedAngkatan;
  final DateTime selectedTanggal;
  final bool agreedToPromise;
  final ValueChanged<String?> onNamaChanged;
  final ValueChanged<String?> onProdiChanged;
  final VoidCallback onPickTanggal;
  final VoidCallback onPromiseToggled;

  const KebaikanIdentityCard({
    super.key,
    required this.selectedNama,
    required this.selectedProdi,
    required this.selectedAngkatan,
    required this.selectedTanggal,
    required this.agreedToPromise,
    required this.onNamaChanged,
    required this.onProdiChanged,
    required this.onPickTanggal,
    required this.onPromiseToggled,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  color: Color(0xFFE11D48),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Identitas Mahasiswa',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Angkatan (Badge Statis)
          Row(
            children: [
              const Text(
                'Tahun Angkatan:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  selectedAngkatan,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF374151),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Dropdown Nama
          const Text(
            'Nama Lengkap',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedNama,
                isExpanded: true,
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 20,
                  color: Color(0xFF6B7280),
                ),
                items: PoinKebaikanConfig.namaList.map((name) {
                  return DropdownMenuItem<String>(
                    value: name,
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                    ),
                  );
                }).toList(),
                onChanged: onNamaChanged,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Dropdown Prodi
          const Text(
            'Program Studi',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedProdi,
                isExpanded: true,
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 20,
                  color: Color(0xFF6B7280),
                ),
                items: PoinKebaikanConfig.prodiList.map((prodi) {
                  return DropdownMenuItem<String>(
                    value: prodi,
                    child: Text(
                      prodi,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF111827),
                      ),
                    ),
                  );
                }).toList(),
                onChanged: onProdiChanged,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Tanggal Kegiatan Yang Dilaporkan
          Builder(
            builder: (context) {
              final now = DateTime.now();
              final isToday = selectedTanggal.year == now.year &&
                  selectedTanggal.month == now.month &&
                  selectedTanggal.day == now.day;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Tanggal Kegiatan Yang Dilaporkan',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      if (isToday)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle_outline_rounded,
                                size: 11,
                                color: Color(0xFF15803D),
                              ),
                              SizedBox(width: 3),
                              Text(
                                'Hari Ini',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF15803D),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: onPickTanggal,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 11,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            size: 18,
                            color: Color(0xFFE11D48),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              AppDateUtils.formatDateIndo(selectedTanggal),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF111827),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: const Color(0xFFD1D5DB),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.edit_calendar_rounded,
                                  size: 13,
                                  color: Color(0xFF4B5563),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Ubah',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF4B5563),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '*Otomatis terisi tanggal hari ini saat Anda mengisi. Tekan Ubah jika ingin melaporkan kegiatan kemarin.',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: Color(0xFF9CA3AF),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 14),

          // Janji Kejujuran
          InkWell(
            onTap: onPromiseToggled,
            borderRadius: BorderRadius.circular(8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: agreedToPromise,
                    activeColor: const Color(0xFF16A34A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    onChanged: (_) => onPromiseToggled(),
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Bismillahirrahmaanirrahiim. Saya berjanji mengisi laporan ini dengan jujur tanpa manipulasi.',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF374151),
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
