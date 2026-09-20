/// Model entitas profil mahasiswa di LMS
class UserProfileModel {
  final String name;
  final String nim;
  final String username;
  final String email;
  final String prodi;
  final String semester;
  final String kelas;
  final String angkatan;
  final String status;
  final Map<String, dynamic> rawProperties;

  const UserProfileModel({
    required this.name,
    required this.nim,
    required this.username,
    required this.email,
    required this.prodi,
    required this.semester,
    required this.kelas,
    required this.angkatan,
    required this.status,
    this.rawProperties = const {},
  });

  String get semesterKelasDisplay {
    if (semester != '-' && kelas != '-') {
      return '$semester / $kelas';
    } else if (semester != '-') {
      return semester;
    } else if (kelas != '-') {
      return 'Kelas $kelas';
    }
    return '-';
  }

  factory UserProfileModel.empty() {
    return const UserProfileModel(
      name: 'Mahasiswa',
      nim: '',
      username: '',
      email: '-',
      prodi: '-',
      semester: '-',
      kelas: '-',
      angkatan: '-',
      status: 'Aktif',
    );
  }
}
