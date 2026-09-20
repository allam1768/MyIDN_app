import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/online_user_model.dart';
import 'dashboard_providers.dart';

class PenggunaAktifPage extends ConsumerStatefulWidget {
  const PenggunaAktifPage({super.key});

  @override
  ConsumerState<PenggunaAktifPage> createState() => _PenggunaAktifPageState();
}

class _PenggunaAktifPageState extends ConsumerState<PenggunaAktifPage> {
  String _searchQuery = '';

  static bool _isUserList(List list) {
    if (list.isEmpty) return false;
    final first = list.first;
    if (first is! Map) return false;
    return first.containsKey('user_id') ||
        first.containsKey('user') ||
        first.containsKey('device') ||
        first.containsKey('platform') ||
        first.containsKey('browser') ||
        first.containsKey('user_agent') ||
        first.containsKey('last_activity') ||
        first.containsKey('last_seen') ||
        (first.containsKey('name') &&
            !first.containsKey('nama_kelas') &&
            !first.containsKey('kode_kelas'));
  }

  ({List<OnlineUserModel> users, int total, int currentPage, int lastPage})
  _extractOnlineUsersData(dynamic dashboardData) {
    if (dashboardData is! Map) {
      return (
        users: <OnlineUserModel>[],
        total: 0,
        currentPage: 1,
        lastPage: 1,
      );
    }

    final Map props = (dashboardData['props'] is Map)
        ? (dashboardData['props'] as Map)
        : dashboardData;

    // 1. Cek semua key yang relevan
    for (final entry in props.entries) {
      final keyName = entry.key.toString().toLowerCase();
      final val = entry.value;

      if (keyName.contains('online') ||
          keyName.contains('aktif') ||
          keyName.contains('active') ||
          keyName.contains('pengguna') ||
          keyName.contains('session') ||
          keyName.contains('tracker') ||
          keyName.contains('login') ||
          keyName.contains('user')) {
        if (val is Map) {
          final rawList =
              val['data'] ?? val['users'] ?? val['items'] ?? val['list'];
          if (rawList is List) {
            final users = rawList
                .map((x) => OnlineUserModel.fromMap(x))
                .toList();
            final total =
                int.tryParse(val['total']?.toString() ?? '') ?? users.length;
            final curPage =
                int.tryParse(val['current_page']?.toString() ?? '') ?? 1;
            final lastPage =
                int.tryParse(val['last_page']?.toString() ?? '') ?? 1;
            return (
              users: users,
              total: total,
              currentPage: curPage,
              lastPage: lastPage,
            );
          }
        } else if (val is List) {
          final users = val.map((x) => OnlineUserModel.fromMap(x)).toList();
          return (
            users: users,
            total: users.length,
            currentPage: 1,
            lastPage: 1,
          );
        }
      }
    }

    // 2. Scan otomatis ke seluruh Map di props yang bertipe paginator / list user
    for (final entry in props.entries) {
      final val = entry.value;

      if (val is Map && val['data'] is List) {
        final rawList = val['data'] as List;
        if (rawList.isNotEmpty && _isUserList(rawList)) {
          final users = rawList.map((x) => OnlineUserModel.fromMap(x)).toList();
          final total =
              int.tryParse(val['total']?.toString() ?? '') ?? users.length;
          final curPage =
              int.tryParse(val['current_page']?.toString() ?? '') ?? 1;
          final lastPage =
              int.tryParse(val['last_page']?.toString() ?? '') ?? 1;
          return (
            users: users,
            total: total,
            currentPage: curPage,
            lastPage: lastPage,
          );
        }
      } else if (val is List && val.isNotEmpty && _isUserList(val)) {
        final users = val.map((x) => OnlineUserModel.fromMap(x)).toList();
        return (users: users, total: users.length, currentPage: 1, lastPage: 1);
      }
    }

    return (users: <OnlineUserModel>[], total: 0, currentPage: 1, lastPage: 1);
  }

  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(dashboardMahasiswaProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Pengguna Aktif',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF111827),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: dashboardAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF1F81FF),
            strokeWidth: 2.5,
          ),
        ),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.red,
                  size: 48,
                ),
                const SizedBox(height: 12),
                Text(
                  'Gagal memuat pengguna aktif:\n$err',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => ref.refresh(dashboardMahasiswaProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Coba Lagi'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1F81FF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        data: (dashboardData) {
          final dataInfo = _extractOnlineUsersData(dashboardData);
          final allUsers = dataInfo.users;

          final filteredUsers = allUsers.where((u) {
            if (_searchQuery.trim().isEmpty) return true;
            final q = _searchQuery.toLowerCase();
            return u.name.toLowerCase().contains(q) ||
                u.device.toLowerCase().contains(q);
          }).toList();

          final Map props =
              (dashboardData is Map && dashboardData['props'] is Map)
              ? (dashboardData['props'] as Map)
              : (dashboardData is Map ? dashboardData : {});

          return RefreshIndicator(
            color: const Color(0xFF1F81FF),
            onRefresh: () async =>
                ref.refresh(dashboardMahasiswaProvider.future),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              children: [
                // Header Info Banner
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
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
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.people_alt_rounded,
                          color: Color(0xFF16A34A),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pengguna Aktif (${dataInfo.total > 0 ? dataInfo.total : allUsers.length})',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF111827),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              dataInfo.lastPage > 1
                                  ? 'Menampilkan Hal ${dataInfo.currentPage}/${dataInfo.lastPage}'
                                  : 'Mahasiswa & dosen yang sedang online di LMS',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFBBF7D0)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 4,
                              backgroundColor: Color(0xFF16A34A),
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Online',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF16A34A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Search Bar
                TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Cari nama atau perangkat...',
                    hintStyle: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF9CA3AF),
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: Color(0xFF9CA3AF),
                      size: 22,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.clear,
                              size: 18,
                              color: Color(0xFF9CA3AF),
                            ),
                            onPressed: () => setState(() => _searchQuery = ''),
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: Color(0xFF1F81FF),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Info Box Diagnostik Props hanya muncul saat kDebugMode jika list kosong
                if (kDebugMode && allUsers.isEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.sync_problem_rounded,
                              color: Colors.blue.shade700,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Diagnostik Data LMS (Debug Mode)',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade900,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'URL: /my/dashboard\n'
                          'Component: ${dashboardData is Map ? dashboardData['component'] : '-'}\n'
                          'Key Props Tersedia: ${props.keys.toList()}',
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.4,
                            fontFamily: 'monospace',
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // List Pengguna Aktif
                if (filteredUsers.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 36,
                      horizontal: 20,
                    ),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.person_off_rounded,
                          size: 44,
                          color: Color(0xFF9CA3AF),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'Tidak ada pengguna yang cocok dengan "$_searchQuery"'
                              : 'Tidak ada data pengguna aktif yang terdeteksi.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredUsers.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final user = filteredUsers[index];
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.015),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Green Active Dot
                            Container(
                              width: 9,
                              height: 9,
                              decoration: const BoxDecoration(
                                color: Color(0xFF16A34A),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 14),

                            // User Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.name,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF111827),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    user.device,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF6B7280),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 12),

                            // Relative Time
                            Text(
                              user.lastActive,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF9CA3AF),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
