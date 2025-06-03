# Ortopedi AI
## 📱 Proje Tanımı

**Ortopedi AI**, ortopedi uzmanları ve klinikleri için geliştirilmiş bir mobil sağlık uygulamasıdır. Hasta takibi, dosya ve form yönetimi, ekip koordinasyonu ve **MR görüntü segmentasyonu** gibi özelliklerle donatılmıştır. Uygulama, doktorlar ve klinik yöneticileri (tenant) için farklı kullanıcı deneyimleri sunar. 
## 🧠 Öne Çıkan Özellikler

- 🔐 Güvenli giriş ve rol bazlı yönlendirme
- 🧑‍⚕️ Doktor arayüzü (hasta, dosya, form, ekip)
- 🏢 Klinik yönetim arayüzü (tenant)
- 🧠 **MR Görüntüsü Segmentasyonu**
  - Tıbbi görüntüler üzerinden *femur*, *tibia*, *fibula* gibi kemik yapılarının otomatik ayrıştırılması
  - Segmentasyon sonuçlarının görsel olarak gösterilmesi
    
<img src="https://github.com/user-attachments/assets/4787af8c-fa35-43e5-a4bd-b4ac3c8fa31e" alt="Giriş Ekranı" width="400"/>
<img src="https://github.com/user-attachments/assets/548b1303-663a-4f5a-8a83-72984ff688a9" alt="Dashboard Ekranı" width="400"/>
<img src="https://github.com/user-attachments/assets/05523cfd-699c-4e78-a3b5-22c1127caff9" alt="Dosya Sayfası" width="400"/>
<img src="https://github.com/user-attachments/assets/3b549314-8b54-4998-8d18-d07e39843c7b" alt="Form Sayfası" width="400"/>
<img src="https://github.com/user-attachments/assets/1b420141-1fe0-4088-825d-6cb3cd484d2b" alt="MR Segmentasyon" width="400"/>

### Frontend (Mobil)
- **Flutter** & Dart
- `provider`: Durum yönetimi
- `dio`: HTTP istekleri ve interceptor yönetimi
- `flutter_secure_storage`: Token ve kimlik verileri için güvenli saklama
- `shared_preferences`: Kalıcı lokal veri yönetimi
- `connectivity_plus`: Ağ bağlantı durumu kontrolü
- `flutter_svg`, `image_picker`, `file_picker`: Görsel ve dosya işlemleri
- `custom_clippers`, `animated_text_kit`: UI iyileştirmeleri

## 🗂️ Proje Yapısı

```plaintext
lib/
├── main.dart                 # Uygulamanın ana giriş noktası
│
├── models/                   # Veri modelleri
│   ├── doctor.dart          # Doktor veri modeli
│   ├── tenant.dart          # Klinik yöneticisi veri modeli
│   ├── patientmodel.dart    # Hasta veri modeli
│   ├── file_model.dart      # Dosya veri modeli
│   ├── form_model.dart      # Form veri modeli
│   └── mr_model.dart        # MR görüntüleme veri modeli
│
├── services/                # API ve iş mantığı servisleri
│   ├── tenant_service.dart  # Klinik yöneticisi servisleri
│   ├── doctor_service.dart  # Doktor servisleri
│   ├── patient_service.dart # Hasta servisleri
│   ├── file_service.dart    # Dosya servisleri
│   ├── form_service.dart    # Form servisleri
│   └── mr_service.dart      # MR görüntüleme servisleri
│
├── utils/                   # Yardımcı fonksiyonlar
│   └── api_client.dart      # API istekleri için client
│
├── views/                   # Kullanıcı arayüzü bileşenleri
│   ├── login_page.dart      # Giriş sayfası
│   ├── register_page.dart   # Kayıt sayfası
│   ├── promotion_page.dart  # Tanıtım sayfası
│   ├── splash_screen.dart   # Açılış ekranı
│   │
│   ├── DoctorViews/        # Doktor arayüzleri
│   │   ├── dhomepage.dart           # Doktor ana sayfa
│   │   ├── dprofile_page.dart       # Doktor profil sayfası
│   │   ├── dteam_page.dart          # Takım yönetimi
│   │   ├── dfile_page.dart          # Dosya yönetimi
│   │   ├── dformpage.dart           # Form yönetimi
│   │   ├── dpatient_page.dart       # Hasta listesi
│   │   ├── dpatient_detail_page.dart # Hasta detay sayfası
│   │   └── mr_analiz_page.dart      # MR analiz sayfası
│   │
│   └── TenantViews/        # Klinik yöneticisi arayüzleri
│       ├── thomepage.dart           # Tenant ana sayfa
│       ├── tprofile_page.dart       # Tenant profil sayfası
│       └── tteam_page.dart          # Tenant takım yönetimi
│
└── theme/                   # Tema yönetimi
    ├── light_mode.dart      # Açık tema
    ├── dark_mode.dart       # Koyu tema
    └── theme_provider.dart  # Tema yönetimi sağlayıcısı
```
## 🧪 MR Segmentasyon Özelliği

- Kullanıcılar, hasta profiline MR görüntüsü yükler.
- Görüntü segmentasyon servisi (NodeJs(Backend) + TensorFlow(KERAS)) görseli işler.
- Segmentasyon çıktısı: femur, tibia, fibula gibi bölgeler renkli şekilde ayrılır.
- Bu görsel uygulamada `SegmentedMRPage` üzerinde gösterilir.
