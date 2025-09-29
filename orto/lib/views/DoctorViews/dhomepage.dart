import 'package:flutter/material.dart';
import 'package:ortopedi_ai/utils/api_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ortopedi_ai/views/DoctorViews/dfile_page.dart';
import 'package:ortopedi_ai/views/DoctorViews/dpatient_page.dart';
import 'package:ortopedi_ai/views/DoctorViews/dprofile_page.dart';
import 'package:ortopedi_ai/views/DoctorViews/dteam_page.dart';
import 'package:ortopedi_ai/views/promotion_page.dart';
import 'package:ortopedi_ai/services/doctor_service.dart';
import 'package:ortopedi_ai/services/patient_service.dart';
import 'package:ortopedi_ai/services/file_service.dart';
import 'package:ortopedi_ai/services/form_service.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class DHomePage extends StatefulWidget {
  const DHomePage({super.key});

  @override
  State<DHomePage> createState() => _DHomePageState();
}

class _DHomePageState extends State<DHomePage> {
  int _currentIndex = 0;
  final _storage = const FlutterSecureStorage();
  late final DoctorService _doctorService;
  late final PatientService _patientService;
  late final FileService _fileService;
  late final FormService _formService;
  bool _isLoading = true;
  Map<String, int> _statistics = {
    'subDoctors': 0,
    'totalPatients': 0,
    'totalFiles': 0,
    'totalForms': 0,
  };

  @override
  void initState() {
    super.initState();
    _doctorService = DoctorService(
      dioClient: DioClient(storage: _storage),
      secureStorage: _storage,
    );
    _patientService = PatientService(
      dioClient: DioClient(storage: _storage),
    );
    _fileService = FileService(
      dioClient: DioClient(storage: _storage),
    );
    _formService = FormService(
      dioClient: DioClient(storage: _storage),
    );
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) {
        throw Exception('Token bulunamadı');
      }

      final decodedToken = JwtDecoder.decode(token);
      final doctorId = decodedToken['id'];

      final doctors = await _doctorService.getAllDoctors();
      final patients = await _patientService.getAllPatients();
      final files = await _fileService.getAllFiles();
      final forms = await _formService.getAllForms();

      setState(() {
        _statistics = {
          'subDoctors':
              doctors.where((d) => d['created_by'] == doctorId).length,
          'totalPatients': patients.where((p) => p.doctorId == doctorId).length,
          'totalFiles': files.length,
          'totalForms': forms.where((f) => f.createdBy == doctorId).length,
        };
        _isLoading = false;
      });
    } catch (e) {
      print('İstatistik yükleme hatası: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('İstatistikler yüklenirken hata oluştu: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  void _handleLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Çıkış Yap'),
        content: const Text('Uygulamadan çıkmak istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Çıkış Yap'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final storage = const FlutterSecureStorage();
      final dioClient = DioClient(storage: storage);
      await dioClient.clearToken();

      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const PromotionPage()),
          (route) => false,
        );
      }
    }
  }

  Widget _buildStatCard(String title, int value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 24, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              value.toString(),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPages() {
    return [
      _buildHomePage(),
      const DPatientPage(),
      const DFilePage(),
      const DTeamPage(),
      const DProfilePage(),
    ];
  }

  Widget _buildHomePage() {
    return _isLoading
        ? Center(
            child: CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
          )
        : RefreshIndicator(
            onRefresh: _loadStatistics,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Genel İstatistikler',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 24),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    children: [
                      _buildStatCard(
                        'Alt Doktorlar',
                        _statistics['subDoctors'] ?? 0,
                        Icons.people,
                        Theme.of(context).colorScheme.primary,
                      ),
                      _buildStatCard(
                        'Toplam Hasta',
                        _statistics['totalPatients'] ?? 0,
                        Icons.person,
                        Theme.of(context).colorScheme.secondary,
                      ),
                      _buildStatCard(
                        'Toplam Dosya',
                        _statistics['totalFiles'] ?? 0,
                        Icons.folder,
                        Theme.of(context).colorScheme.tertiary,
                      ),
                      _buildStatCard(
                        'Toplam Form',
                        _statistics['totalForms'] ?? 0,
                        Icons.description,
                        Theme.of(context).colorScheme.error,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
  }

  void _showAddDoctorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Doktor Ekle'),
        content: const Text('Doktor ekleme özelliği yakında eklenecek.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = _buildPages();
    final titles = [
      'Ana Sayfa',
      'Hastalar',
      'Dosyalar',
      'Ekip Yönetimi',
      'Profil'
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_currentIndex]),
        centerTitle: true,
        actions: [
          if (_currentIndex == 0) // Ana sayfa için logout butonu
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => _handleLogout(context),
              tooltip: 'Çıkış Yap',
            ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor:
            Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Ana Sayfa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'Hastalar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.folder_outlined),
            activeIcon: Icon(Icons.folder),
            label: 'Dosyalar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.groups_outlined),
            activeIcon: Icon(Icons.groups),
            label: 'Ekip',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
