import 'package:flutter/material.dart';
import 'package:ortopedi_ai/utils/api_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ortopedi_ai/views/DoctorViews/dfile_page.dart';
import 'package:ortopedi_ai/views/DoctorViews/dpatient_page.dart';
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
    final storage = const FlutterSecureStorage();
    final dioClient = DioClient(storage: storage);
    dioClient.clearToken();

    if (context.mounted) {
      Navigator.pushReplacementNamed(context, '/promotion');
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

  Widget _buildMenuCard(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Doktor Ana Sayfası'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.pushNamed(context, '/doctor/profile');
            },
            tooltip: 'Profil',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _handleLogout(context),
            tooltip: 'Çıkış Yap',
          ),
        ],
      ),
      body: _isLoading
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
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
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
                    const SizedBox(height: 32),
                    Text(
                      'Hızlı Erişim',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
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
                        _buildMenuCard(
                          context,
                          'Ekip Yönetimi',
                          Icons.people,
                          () => Navigator.pushNamed(context, '/doctor/team'),
                        ),
                        _buildMenuCard(
                          context,
                          'Dosyalar',
                          Icons.folder,
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const DFilePage()),
                          ),
                        ),
                        _buildMenuCard(
                          context,
                          'Hastalar',
                          Icons.person_outline,
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const DPatientPage()),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
