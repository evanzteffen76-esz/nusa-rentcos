import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_id.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('id'),
    Locale('ja'),
    Locale('ko'),
    Locale('zh'),
  ];

  /// No description provided for @adminFoundationBadge.
  ///
  /// In id, this message translates to:
  /// **'Siap untuk modul berikutnya'**
  String get adminFoundationBadge;

  /// No description provided for @adminFoundationDescription.
  ///
  /// In id, this message translates to:
  /// **'Akses admin dan Cosrent Owner dilindungi middleware khusus, dengan modul katalog kostum, stok, dan persetujuan pesanan.'**
  String get adminFoundationDescription;

  /// No description provided for @adminFoundationTitle.
  ///
  /// In id, this message translates to:
  /// **'Fondasi admin sudah aktif'**
  String get adminFoundationTitle;

  /// No description provided for @adminHeaderEyebrow.
  ///
  /// In id, this message translates to:
  /// **'CosplayNusa / Ruang kendali'**
  String get adminHeaderEyebrow;

  /// No description provided for @adminHeaderTitle.
  ///
  /// In id, this message translates to:
  /// **'Dashboard admin'**
  String get adminHeaderTitle;

  /// No description provided for @adminHeroDescription.
  ///
  /// In id, this message translates to:
  /// **'Pusat kendali CosplayNusa siap digunakan. Kelola akses, pantau aktivitas akun, dan siapkan ruang untuk katalog kostum serta pesanan.'**
  String get adminHeroDescription;

  /// No description provided for @adminHeroGreeting.
  ///
  /// In id, this message translates to:
  /// **'Halo, :name.'**
  String get adminHeroGreeting;

  /// No description provided for @adminHeroLanding.
  ///
  /// In id, this message translates to:
  /// **'Lihat landing page'**
  String get adminHeroLanding;

  /// No description provided for @adminHeroProfile.
  ///
  /// In id, this message translates to:
  /// **'Atur profil'**
  String get adminHeroProfile;

  /// No description provided for @adminHeroWelcome.
  ///
  /// In id, this message translates to:
  /// **'Selamat datang kembali'**
  String get adminHeroWelcome;

  /// No description provided for @adminQuickAccount.
  ///
  /// In id, this message translates to:
  /// **'Informasi akun'**
  String get adminQuickAccount;

  /// No description provided for @adminQuickDashboard.
  ///
  /// In id, this message translates to:
  /// **'Dashboard pengguna'**
  String get adminQuickDashboard;

  /// No description provided for @adminQuickEyebrow.
  ///
  /// In id, this message translates to:
  /// **'Aksi cepat'**
  String get adminQuickEyebrow;

  /// No description provided for @adminQuickTitle.
  ///
  /// In id, this message translates to:
  /// **'Mulai dari sini'**
  String get adminQuickTitle;

  /// No description provided for @adminStatsAdminAccess.
  ///
  /// In id, this message translates to:
  /// **'Akses admin'**
  String get adminStatsAdminAccess;

  /// No description provided for @adminStatsAdminDesc.
  ///
  /// In id, this message translates to:
  /// **'akun dengan akses admin'**
  String get adminStatsAdminDesc;

  /// No description provided for @adminStatsOwnerAccess.
  ///
  /// In id, this message translates to:
  /// **'Cosrent Owner'**
  String get adminStatsOwnerAccess;

  /// No description provided for @adminStatsOwnerDesc.
  ///
  /// In id, this message translates to:
  /// **'akun penyedia kostum'**
  String get adminStatsOwnerDesc;

  /// No description provided for @adminStatsRegular.
  ///
  /// In id, this message translates to:
  /// **'Pelanggan'**
  String get adminStatsRegular;

  /// No description provided for @adminStatsRegularDesc.
  ///
  /// In id, this message translates to:
  /// **'akun tanpa akses khusus'**
  String get adminStatsRegularDesc;

  /// No description provided for @adminStatsUsers.
  ///
  /// In id, this message translates to:
  /// **'Total pengguna'**
  String get adminStatsUsers;

  /// No description provided for @adminStatsUsersDesc.
  ///
  /// In id, this message translates to:
  /// **'akun terdaftar'**
  String get adminStatsUsersDesc;

  /// No description provided for @appDescription.
  ///
  /// In id, this message translates to:
  /// **'CosplayNusa menyediakan rental cosplay premium untuk convention, photoshoot, dan kreasi karakter.'**
  String get appDescription;

  /// No description provided for @appName.
  ///
  /// In id, this message translates to:
  /// **'CosplayNusa'**
  String get appName;

  /// No description provided for @authConfirmDescription.
  ///
  /// In id, this message translates to:
  /// **'Ini adalah area aman aplikasi. Konfirmasi passwordmu sebelum melanjutkan.'**
  String get authConfirmDescription;

  /// No description provided for @authConfirmSubmit.
  ///
  /// In id, this message translates to:
  /// **'Konfirmasi'**
  String get authConfirmSubmit;

  /// No description provided for @authForgotBack.
  ///
  /// In id, this message translates to:
  /// **'Kembali ke halaman masuk'**
  String get authForgotBack;

  /// No description provided for @authForgotDescription.
  ///
  /// In id, this message translates to:
  /// **'Lupa password? Tidak masalah. Beri tahu kami alamat emailmu dan kami akan mengirim tautan untuk mengatur password baru.'**
  String get authForgotDescription;

  /// No description provided for @authForgotSubmit.
  ///
  /// In id, this message translates to:
  /// **'Kirim tautan reset password'**
  String get authForgotSubmit;

  /// No description provided for @authLoginEmail.
  ///
  /// In id, this message translates to:
  /// **'Email'**
  String get authLoginEmail;

  /// No description provided for @authLoginForgot.
  ///
  /// In id, this message translates to:
  /// **'Lupa password?'**
  String get authLoginForgot;

  /// No description provided for @authLoginPassword.
  ///
  /// In id, this message translates to:
  /// **'Password'**
  String get authLoginPassword;

  /// No description provided for @authLoginRemember.
  ///
  /// In id, this message translates to:
  /// **'Ingat saya'**
  String get authLoginRemember;

  /// No description provided for @authLoginSubmit.
  ///
  /// In id, this message translates to:
  /// **'Masuk'**
  String get authLoginSubmit;

  /// No description provided for @authRegisterAccountType.
  ///
  /// In id, this message translates to:
  /// **'Jenis akun'**
  String get authRegisterAccountType;

  /// No description provided for @authRegisterAccountTypeDescription.
  ///
  /// In id, this message translates to:
  /// **'Pilih cara Anda menggunakan CosplayNusa.'**
  String get authRegisterAccountTypeDescription;

  /// No description provided for @authRegisterAlready.
  ///
  /// In id, this message translates to:
  /// **'Sudah punya akun?'**
  String get authRegisterAlready;

  /// No description provided for @authRegisterConfirm.
  ///
  /// In id, this message translates to:
  /// **'Konfirmasi password'**
  String get authRegisterConfirm;

  /// No description provided for @authRegisterCosrentOwner.
  ///
  /// In id, this message translates to:
  /// **'Cosrent Owner'**
  String get authRegisterCosrentOwner;

  /// No description provided for @authRegisterCosrentOwnerDescription.
  ///
  /// In id, this message translates to:
  /// **'Kelola stok kostum dan tinjau pesanan pelanggan.'**
  String get authRegisterCosrentOwnerDescription;

  /// No description provided for @authRegisterCustomer.
  ///
  /// In id, this message translates to:
  /// **'Pelanggan'**
  String get authRegisterCustomer;

  /// No description provided for @authRegisterCustomerDescription.
  ///
  /// In id, this message translates to:
  /// **'Jelajahi kostum dan kirim pesanan sewa.'**
  String get authRegisterCustomerDescription;

  /// No description provided for @authRegisterEmail.
  ///
  /// In id, this message translates to:
  /// **'Email'**
  String get authRegisterEmail;

  /// No description provided for @authRegisterName.
  ///
  /// In id, this message translates to:
  /// **'Nama'**
  String get authRegisterName;

  /// No description provided for @authRegisterPassword.
  ///
  /// In id, this message translates to:
  /// **'Password'**
  String get authRegisterPassword;

  /// No description provided for @authRegisterSubmit.
  ///
  /// In id, this message translates to:
  /// **'Daftar'**
  String get authRegisterSubmit;

  /// No description provided for @authResetSubmit.
  ///
  /// In id, this message translates to:
  /// **'Atur ulang password'**
  String get authResetSubmit;

  /// No description provided for @authVerifyDescription.
  ///
  /// In id, this message translates to:
  /// **'Terima kasih sudah mendaftar! Sebelum mulai, verifikasi alamat emailmu dengan klik tautan yang kami kirim. Jika tidak diterima, kami dapat mengirim ulang.'**
  String get authVerifyDescription;

  /// No description provided for @authVerifyResend.
  ///
  /// In id, this message translates to:
  /// **'Kirim ulang email verifikasi'**
  String get authVerifyResend;

  /// No description provided for @authVerifySent.
  ///
  /// In id, this message translates to:
  /// **'Tautan verifikasi baru telah dikirim ke alamat email yang kamu daftarkan.'**
  String get authVerifySent;

  /// No description provided for @commonActions.
  ///
  /// In id, this message translates to:
  /// **'Aksi'**
  String get commonActions;

  /// No description provided for @commonCancel.
  ///
  /// In id, this message translates to:
  /// **'Batal'**
  String get commonCancel;

  /// No description provided for @commonConfirmPassword.
  ///
  /// In id, this message translates to:
  /// **'Konfirmasi password'**
  String get commonConfirmPassword;

  /// No description provided for @commonConnected.
  ///
  /// In id, this message translates to:
  /// **'Terhubung'**
  String get commonConnected;

  /// No description provided for @commonDatabaseConnection.
  ///
  /// In id, this message translates to:
  /// **'Koneksi database'**
  String get commonDatabaseConnection;

  /// No description provided for @commonEmail.
  ///
  /// In id, this message translates to:
  /// **'Email'**
  String get commonEmail;

  /// No description provided for @commonForgotPassword.
  ///
  /// In id, this message translates to:
  /// **'Lupa password?'**
  String get commonForgotPassword;

  /// No description provided for @commonLiveOverview.
  ///
  /// In id, this message translates to:
  /// **'Ringkasan langsung'**
  String get commonLiveOverview;

  /// No description provided for @commonLogin.
  ///
  /// In id, this message translates to:
  /// **'Masuk'**
  String get commonLogin;

  /// No description provided for @commonName.
  ///
  /// In id, this message translates to:
  /// **'Nama lengkap'**
  String get commonName;

  /// No description provided for @commonPassword.
  ///
  /// In id, this message translates to:
  /// **'Password'**
  String get commonPassword;

  /// No description provided for @commonRegister.
  ///
  /// In id, this message translates to:
  /// **'Daftar'**
  String get commonRegister;

  /// No description provided for @commonRememberMe.
  ///
  /// In id, this message translates to:
  /// **'Ingat saya'**
  String get commonRememberMe;

  /// No description provided for @commonSecureArea.
  ///
  /// In id, this message translates to:
  /// **'Area aman'**
  String get commonSecureArea;

  /// No description provided for @commonToggleTheme.
  ///
  /// In id, this message translates to:
  /// **'Ganti mode terang/gelap'**
  String get commonToggleTheme;

  /// No description provided for @commonView.
  ///
  /// In id, this message translates to:
  /// **'Lihat'**
  String get commonView;

  /// No description provided for @customerBookingBack.
  ///
  /// In id, this message translates to:
  /// **'Kembali ke katalog'**
  String get customerBookingBack;

  /// No description provided for @customerBookingCostumeDetails.
  ///
  /// In id, this message translates to:
  /// **'Detail kostum'**
  String get customerBookingCostumeDetails;

  /// No description provided for @customerBookingCreated.
  ///
  /// In id, this message translates to:
  /// **'Pesanan berhasil dikirim dan menunggu persetujuan pemilik.'**
  String get customerBookingCreated;

  /// No description provided for @customerBookingCreatedWithCode.
  ///
  /// In id, this message translates to:
  /// **'Pesanan berhasil dikirim. Tunjukkan kode pesanan kepada pemilik kostum saat membayar di tempat.'**
  String get customerBookingCreatedWithCode;

  /// No description provided for @customerBookingCustomerNote.
  ///
  /// In id, this message translates to:
  /// **'Catatan untuk pemilik'**
  String get customerBookingCustomerNote;

  /// No description provided for @customerBookingCustomerNotePlaceholder.
  ///
  /// In id, this message translates to:
  /// **'Ceritakan occasion, lokasi pengambilan, atau kebutuhan khusus.'**
  String get customerBookingCustomerNotePlaceholder;

  /// No description provided for @customerBookingDescription.
  ///
  /// In id, this message translates to:
  /// **'Pesanan akan dikirim ke pemilik kostum untuk ditinjau sebelum dikonfirmasi.'**
  String get customerBookingDescription;

  /// No description provided for @customerBookingEstimate.
  ///
  /// In id, this message translates to:
  /// **'Estimasi total'**
  String get customerBookingEstimate;

  /// No description provided for @customerBookingEstimateHint.
  ///
  /// In id, this message translates to:
  /// **'Total final dihitung server dari harga dan jumlah unit.'**
  String get customerBookingEstimateHint;

  /// No description provided for @customerBookingFixedPeriod.
  ///
  /// In id, this message translates to:
  /// **'Setelah disetujui, customer mendapat 3 hari pemakaian. Pengembalian paling lambat 1 hari setelah hari ke-3.'**
  String get customerBookingFixedPeriod;

  /// No description provided for @customerBookingFixedPeriodShort.
  ///
  /// In id, this message translates to:
  /// **'Periode final: 3 hari setelah approval.'**
  String get customerBookingFixedPeriodShort;

  /// No description provided for @customerBookingPeriod.
  ///
  /// In id, this message translates to:
  /// **'Periode sewa'**
  String get customerBookingPeriod;

  /// No description provided for @customerBookingQuantity.
  ///
  /// In id, this message translates to:
  /// **'Jumlah unit'**
  String get customerBookingQuantity;

  /// No description provided for @customerBookingQuantityHint.
  ///
  /// In id, this message translates to:
  /// **'Minimal 1 dan maksimal 100 unit.'**
  String get customerBookingQuantityHint;

  /// No description provided for @customerBookingSubmit.
  ///
  /// In id, this message translates to:
  /// **'Kirim pesanan'**
  String get customerBookingSubmit;

  /// No description provided for @customerBookingTitle.
  ///
  /// In id, this message translates to:
  /// **'Ajukan sewa'**
  String get customerBookingTitle;

  /// No description provided for @customerBookingUnavailable.
  ///
  /// In id, this message translates to:
  /// **'Jumlah tersebut tidak tersedia untuk periode yang dipilih.'**
  String get customerBookingUnavailable;

  /// No description provided for @customerBookingUnit.
  ///
  /// In id, this message translates to:
  /// **'unit'**
  String get customerBookingUnit;

  /// No description provided for @customerCostumeBack.
  ///
  /// In id, this message translates to:
  /// **'Kembali ke katalog'**
  String get customerCostumeBack;

  /// No description provided for @customerCostumeDescription.
  ///
  /// In id, this message translates to:
  /// **'Tentang set kostum'**
  String get customerCostumeDescription;

  /// No description provided for @customerCostumeDescriptionEmpty.
  ///
  /// In id, this message translates to:
  /// **'Pemilik kostum belum menambahkan deskripsi untuk set ini.'**
  String get customerCostumeDescriptionEmpty;

  /// No description provided for @customerCostumeOwnerNote.
  ///
  /// In id, this message translates to:
  /// **'Pesanan dikirim ke pemilik kostum dan akan ditinjau sebelum dikonfirmasi.'**
  String get customerCostumeOwnerNote;

  /// No description provided for @customerCostumePriceNote.
  ///
  /// In id, this message translates to:
  /// **'Harga sewa yang ditetapkan pemilik kostum, sudah termasuk periode 3 hari.'**
  String get customerCostumePriceNote;

  /// No description provided for @customerCostumeVideos.
  ///
  /// In id, this message translates to:
  /// **'Video set kostum'**
  String get customerCostumeVideos;

  /// No description provided for @customerDashboardBook.
  ///
  /// In id, this message translates to:
  /// **'Pesan kostum'**
  String get customerDashboardBook;

  /// No description provided for @customerDashboardBrowseCatalog.
  ///
  /// In id, this message translates to:
  /// **'Jelajahi kostum'**
  String get customerDashboardBrowseCatalog;

  /// No description provided for @customerDashboardCatalog.
  ///
  /// In id, this message translates to:
  /// **'Kostum tersedia'**
  String get customerDashboardCatalog;

  /// No description provided for @customerDashboardCatalogDescription.
  ///
  /// In id, this message translates to:
  /// **'Kostum yang saat ini dipublikasikan oleh Cosrent Owner.'**
  String get customerDashboardCatalogDescription;

  /// No description provided for @customerDashboardDescription.
  ///
  /// In id, this message translates to:
  /// **'Pilih kostum yang sesuai, tentukan jadwal, lalu tunggu persetujuan pemilik rental.'**
  String get customerDashboardDescription;

  /// No description provided for @customerDashboardEmptyCatalogDescription.
  ///
  /// In id, this message translates to:
  /// **'Kostum baru akan tampil setelah Cosrent Owner menerbitkannya.'**
  String get customerDashboardEmptyCatalogDescription;

  /// No description provided for @customerDashboardEmptyCatalogTitle.
  ///
  /// In id, this message translates to:
  /// **'Belum ada kostum tayang'**
  String get customerDashboardEmptyCatalogTitle;

  /// No description provided for @customerDashboardEyebrow.
  ///
  /// In id, this message translates to:
  /// **'Koleksi CosplayNusa'**
  String get customerDashboardEyebrow;

  /// No description provided for @customerDashboardGreeting.
  ///
  /// In id, this message translates to:
  /// **'Halo, :name.'**
  String get customerDashboardGreeting;

  /// No description provided for @customerDashboardNoOrdersDescription.
  ///
  /// In id, this message translates to:
  /// **'Pilih kostum di atas untuk membuat permintaan sewa pertama Anda.'**
  String get customerDashboardNoOrdersDescription;

  /// No description provided for @customerDashboardNoOrdersTitle.
  ///
  /// In id, this message translates to:
  /// **'Belum ada pesanan'**
  String get customerDashboardNoOrdersTitle;

  /// No description provided for @customerDashboardOwner.
  ///
  /// In id, this message translates to:
  /// **'Disediakan oleh'**
  String get customerDashboardOwner;

  /// No description provided for @customerDashboardRecentOrders.
  ///
  /// In id, this message translates to:
  /// **'Pesanan terbaru'**
  String get customerDashboardRecentOrders;

  /// No description provided for @customerDashboardTitle.
  ///
  /// In id, this message translates to:
  /// **'Temukan karakter berikutnya'**
  String get customerDashboardTitle;

  /// No description provided for @customerIssuesAlreadyReported.
  ///
  /// In id, this message translates to:
  /// **'Pesanan ini sudah memiliki laporan masalah yang sedang diproses.'**
  String get customerIssuesAlreadyReported;

  /// No description provided for @customerIssuesDescription.
  ///
  /// In id, this message translates to:
  /// **'Kronologi kehilangan'**
  String get customerIssuesDescription;

  /// No description provided for @customerIssuesDescriptionPlaceholder.
  ///
  /// In id, this message translates to:
  /// **'Jelaskan lokasi, waktu, dan kronologi kehilangan kostum.'**
  String get customerIssuesDescriptionPlaceholder;

  /// No description provided for @customerIssuesLostDescription.
  ///
  /// In id, this message translates to:
  /// **'Laporkan kehilangan dan kirim bukti pembelian kostum pengganti. Owner akan memverifikasi sebelum menutup laporan.'**
  String get customerIssuesLostDescription;

  /// No description provided for @customerIssuesLostStatusError.
  ///
  /// In id, this message translates to:
  /// **'Laporan kehilangan hanya dapat dibuat untuk pesanan yang sedang disewa.'**
  String get customerIssuesLostStatusError;

  /// No description provided for @customerIssuesLostSubmitted.
  ///
  /// In id, this message translates to:
  /// **'Laporan kehilangan dan bukti kostum pengganti telah dikirim.'**
  String get customerIssuesLostSubmitted;

  /// No description provided for @customerIssuesLostTitle.
  ///
  /// In id, this message translates to:
  /// **'Laporkan kostum hilang'**
  String get customerIssuesLostTitle;

  /// No description provided for @customerIssuesPaymentInstruction.
  ///
  /// In id, this message translates to:
  /// **'Denda harus dibayar kepada owner. Hubungi owner untuk konfirmasi pembayaran.'**
  String get customerIssuesPaymentInstruction;

  /// No description provided for @customerIssuesProofHint.
  ///
  /// In id, this message translates to:
  /// **'Unggah foto atau PDF maksimal 5 MB.'**
  String get customerIssuesProofHint;

  /// No description provided for @customerIssuesReplacementCost.
  ///
  /// In id, this message translates to:
  /// **'Estimasi biaya pembelian pengganti'**
  String get customerIssuesReplacementCost;

  /// No description provided for @customerIssuesReplacementEvidenceError.
  ///
  /// In id, this message translates to:
  /// **'Bukti pembelian kostum pengganti wajib dilampirkan.'**
  String get customerIssuesReplacementEvidenceError;

  /// No description provided for @customerIssuesReplacementProof.
  ///
  /// In id, this message translates to:
  /// **'Bukti pembelian / foto kostum pengganti'**
  String get customerIssuesReplacementProof;

  /// No description provided for @customerIssuesReplacementRequired.
  ///
  /// In id, this message translates to:
  /// **'Kostum pengganti wajib dibeli dan dikembalikan ke owner.'**
  String get customerIssuesReplacementRequired;

  /// No description provided for @customerIssuesReplacementUnderReview.
  ///
  /// In id, this message translates to:
  /// **'Bukti pengganti sedang diverifikasi owner.'**
  String get customerIssuesReplacementUnderReview;

  /// No description provided for @customerIssuesSubmit.
  ///
  /// In id, this message translates to:
  /// **'Kirim laporan kehilangan'**
  String get customerIssuesSubmit;

  /// No description provided for @customerPaymentBankAccountHolder.
  ///
  /// In id, this message translates to:
  /// **'Atas nama'**
  String get customerPaymentBankAccountHolder;

  /// No description provided for @customerPaymentBankAccountNumber.
  ///
  /// In id, this message translates to:
  /// **'Nomor rekening'**
  String get customerPaymentBankAccountNumber;

  /// No description provided for @customerPaymentBankMissing.
  ///
  /// In id, this message translates to:
  /// **'Pemilik kostum belum mengisi data rekening, jadi metode transfer belum tersedia.'**
  String get customerPaymentBankMissing;

  /// No description provided for @customerPaymentBankName.
  ///
  /// In id, this message translates to:
  /// **'Bank'**
  String get customerPaymentBankName;

  /// No description provided for @customerPaymentBankTitle.
  ///
  /// In id, this message translates to:
  /// **'Rekening pemilik kostum'**
  String get customerPaymentBankTitle;

  /// No description provided for @customerPaymentCodeDescription.
  ///
  /// In id, this message translates to:
  /// **'Kode unik dibuat setelah pesanan dikirim. Tunjukkan kode ini kepada pemilik kostum agar pesanan dapat disetujui.'**
  String get customerPaymentCodeDescription;

  /// No description provided for @customerPaymentCodeLabel.
  ///
  /// In id, this message translates to:
  /// **'Kode pesanan'**
  String get customerPaymentCodeLabel;

  /// No description provided for @customerPaymentCodeOwnerHint.
  ///
  /// In id, this message translates to:
  /// **'Cocokkan kode ini dengan kode yang ditunjukkan customer sebelum menyetujui pesanan.'**
  String get customerPaymentCodeOwnerHint;

  /// No description provided for @customerPaymentCodeReminder.
  ///
  /// In id, this message translates to:
  /// **'Tunjukkan kode ini kepada pemilik kostum.'**
  String get customerPaymentCodeReminder;

  /// No description provided for @customerPaymentCodeTitle.
  ///
  /// In id, this message translates to:
  /// **'Kode pesanan otomatis'**
  String get customerPaymentCodeTitle;

  /// No description provided for @customerPaymentMethodBankTransfer.
  ///
  /// In id, this message translates to:
  /// **'Transfer bank'**
  String get customerPaymentMethodBankTransfer;

  /// No description provided for @customerPaymentMethodBankTransferHint.
  ///
  /// In id, this message translates to:
  /// **'Transfer ke rekening pemilik kostum, lalu unggah bukti pembayaran berupa gambar atau PDF.'**
  String get customerPaymentMethodBankTransferHint;

  /// No description provided for @customerPaymentMethodDescription.
  ///
  /// In id, this message translates to:
  /// **'Pilih cara pembayaran yang diinginkan. Pembayaran diverifikasi pemilik kostum sebelum pesanan disetujui.'**
  String get customerPaymentMethodDescription;

  /// No description provided for @customerPaymentMethodPayAtOwner.
  ///
  /// In id, this message translates to:
  /// **'Bayar di tempat owner'**
  String get customerPaymentMethodPayAtOwner;

  /// No description provided for @customerPaymentMethodPayAtOwnerHint.
  ///
  /// In id, this message translates to:
  /// **'Tunjukkan kode unik yang dibuat sistem kepada pemilik kostum saat mengambil kostum.'**
  String get customerPaymentMethodPayAtOwnerHint;

  /// No description provided for @customerPaymentMethodTitle.
  ///
  /// In id, this message translates to:
  /// **'Metode pembayaran'**
  String get customerPaymentMethodTitle;

  /// No description provided for @customerPaymentOwnerTitle.
  ///
  /// In id, this message translates to:
  /// **'Pembayaran'**
  String get customerPaymentOwnerTitle;

  /// No description provided for @customerPaymentProofAwaitingReview.
  ///
  /// In id, this message translates to:
  /// **'Menunggu ditinjau pemilik kostum'**
  String get customerPaymentProofAwaitingReview;

  /// No description provided for @customerPaymentProofHint.
  ///
  /// In id, this message translates to:
  /// **'Unggah bukti transfer dalam bentuk gambar (screenshot mobile/i-banking atau foto bukti transfer fisik) atau PDF, maksimal 5 MB.'**
  String get customerPaymentProofHint;

  /// No description provided for @customerPaymentProofInvalid.
  ///
  /// In id, this message translates to:
  /// **'Bukti pembayaran harus berupa JPG, PNG, WEBP, atau PDF.'**
  String get customerPaymentProofInvalid;

  /// No description provided for @customerPaymentProofLabel.
  ///
  /// In id, this message translates to:
  /// **'Bukti pembayaran'**
  String get customerPaymentProofLabel;

  /// No description provided for @customerPaymentProofMissing.
  ///
  /// In id, this message translates to:
  /// **'Bukti pembayaran belum diunggah.'**
  String get customerPaymentProofMissing;

  /// No description provided for @customerPaymentProofRequired.
  ///
  /// In id, this message translates to:
  /// **'Bukti pembayaran wajib diunggah untuk metode transfer bank.'**
  String get customerPaymentProofRequired;

  /// No description provided for @customerPaymentProofRequiredBadge.
  ///
  /// In id, this message translates to:
  /// **'Wajib'**
  String get customerPaymentProofRequiredBadge;

  /// No description provided for @customerPaymentProofTooLarge.
  ///
  /// In id, this message translates to:
  /// **'Ukuran bukti pembayaran maksimal 5 MB.'**
  String get customerPaymentProofTooLarge;

  /// No description provided for @customerPaymentProofView.
  ///
  /// In id, this message translates to:
  /// **'Lihat bukti pembayaran'**
  String get customerPaymentProofView;

  /// No description provided for @customerPaymentProofViewOwn.
  ///
  /// In id, this message translates to:
  /// **'Lihat bukti yang saya kirim'**
  String get customerPaymentProofViewOwn;

  /// No description provided for @customerReturnDescription.
  ///
  /// In id, this message translates to:
  /// **'Kirim pengembalian setelah masa sewa selesai. Owner akan memeriksa kostum saat diterima.'**
  String get customerReturnDescription;

  /// No description provided for @customerReturnDue.
  ///
  /// In id, this message translates to:
  /// **'Batas pengembalian'**
  String get customerReturnDue;

  /// No description provided for @customerReturnNote.
  ///
  /// In id, this message translates to:
  /// **'Catatan pengembalian'**
  String get customerReturnNote;

  /// No description provided for @customerReturnNotePlaceholder.
  ///
  /// In id, this message translates to:
  /// **'Contoh: kostum dikembalikan dalam kondisi baik.'**
  String get customerReturnNotePlaceholder;

  /// No description provided for @customerReturnOverdue.
  ///
  /// In id, this message translates to:
  /// **'Pengembalian terlambat'**
  String get customerReturnOverdue;

  /// No description provided for @customerReturnStatusError.
  ///
  /// In id, this message translates to:
  /// **'Pesanan ini tidak dalam status siap dikembalikan.'**
  String get customerReturnStatusError;

  /// No description provided for @customerReturnSubmit.
  ///
  /// In id, this message translates to:
  /// **'Kirim pengembalian'**
  String get customerReturnSubmit;

  /// No description provided for @customerReturnSubmitted.
  ///
  /// In id, this message translates to:
  /// **'Pengembalian telah dikirim dan menunggu pemeriksaan owner.'**
  String get customerReturnSubmitted;

  /// No description provided for @customerReturnTitle.
  ///
  /// In id, this message translates to:
  /// **'Kembalikan kostum'**
  String get customerReturnTitle;

  /// No description provided for @customerReturnTooEarly.
  ///
  /// In id, this message translates to:
  /// **'Pengembalian baru dapat dilakukan setelah masa sewa selesai.'**
  String get customerReturnTooEarly;

  /// No description provided for @dashboardLoggedIn.
  ///
  /// In id, this message translates to:
  /// **'Kamu sudah masuk!'**
  String get dashboardLoggedIn;

  /// No description provided for @languageSelect.
  ///
  /// In id, this message translates to:
  /// **'Pilih bahasa'**
  String get languageSelect;

  /// No description provided for @navAdmin.
  ///
  /// In id, this message translates to:
  /// **'Admin'**
  String get navAdmin;

  /// No description provided for @navCosrentOwner.
  ///
  /// In id, this message translates to:
  /// **'Cosrent Owner'**
  String get navCosrentOwner;

  /// No description provided for @navCostumes.
  ///
  /// In id, this message translates to:
  /// **'Kostum'**
  String get navCostumes;

  /// No description provided for @navDashboard.
  ///
  /// In id, this message translates to:
  /// **'Dashboard'**
  String get navDashboard;

  /// No description provided for @navLogOut.
  ///
  /// In id, this message translates to:
  /// **'Keluar'**
  String get navLogOut;

  /// No description provided for @navOrders.
  ///
  /// In id, this message translates to:
  /// **'Pesanan'**
  String get navOrders;

  /// No description provided for @navProfile.
  ///
  /// In id, this message translates to:
  /// **'Profil'**
  String get navProfile;

  /// No description provided for @ownerCostumeFormCategory.
  ///
  /// In id, this message translates to:
  /// **'Kategori'**
  String get ownerCostumeFormCategory;

  /// No description provided for @ownerCostumeFormCharacter.
  ///
  /// In id, this message translates to:
  /// **'Nama karakter'**
  String get ownerCostumeFormCharacter;

  /// No description provided for @ownerCostumeFormCreateDescription.
  ///
  /// In id, this message translates to:
  /// **'Lengkapi informasi agar pelanggan dapat memahami isi paket dan biaya sewanya.'**
  String get ownerCostumeFormCreateDescription;

  /// No description provided for @ownerCostumeFormCreateTitle.
  ///
  /// In id, this message translates to:
  /// **'Tambah kostum'**
  String get ownerCostumeFormCreateTitle;

  /// No description provided for @ownerCostumeFormDescription.
  ///
  /// In id, this message translates to:
  /// **'Deskripsi'**
  String get ownerCostumeFormDescription;

  /// No description provided for @ownerCostumeFormDescriptionPlaceholder.
  ///
  /// In id, this message translates to:
  /// **'Sebutkan komponen kostum, aksesori, dan kondisi paket.'**
  String get ownerCostumeFormDescriptionPlaceholder;

  /// No description provided for @ownerCostumeFormDropHint.
  ///
  /// In id, this message translates to:
  /// **'Tarik file ke sini atau klik untuk memilih.'**
  String get ownerCostumeFormDropHint;

  /// No description provided for @ownerCostumeFormEditDescription.
  ///
  /// In id, this message translates to:
  /// **'Perbarui detail kostum tanpa mengubah riwayat pesanan sebelumnya.'**
  String get ownerCostumeFormEditDescription;

  /// No description provided for @ownerCostumeFormEditTitle.
  ///
  /// In id, this message translates to:
  /// **'Edit kostum'**
  String get ownerCostumeFormEditTitle;

  /// No description provided for @ownerCostumeFormFileInvalidType.
  ///
  /// In id, this message translates to:
  /// **'Tipe file :name tidak didukung.'**
  String get ownerCostumeFormFileInvalidType;

  /// No description provided for @ownerCostumeFormFileTooLarge.
  ///
  /// In id, this message translates to:
  /// **':name melebihi :max MB.'**
  String get ownerCostumeFormFileTooLarge;

  /// No description provided for @ownerCostumeFormImageInvalid.
  ///
  /// In id, this message translates to:
  /// **'Semua file foto harus berupa gambar JPG, PNG, atau WEBP.'**
  String get ownerCostumeFormImageInvalid;

  /// No description provided for @ownerCostumeFormImageLimitError.
  ///
  /// In id, this message translates to:
  /// **'Galeri foto maksimal :max file. Hapus foto lama atau kurangi jumlah unggahan.'**
  String get ownerCostumeFormImageLimitError;

  /// No description provided for @ownerCostumeFormImageTooLarge.
  ///
  /// In id, this message translates to:
  /// **'Ukuran setiap foto maksimal :max MB.'**
  String get ownerCostumeFormImageTooLarge;

  /// No description provided for @ownerCostumeFormImageUrl.
  ///
  /// In id, this message translates to:
  /// **'URL foto (opsional)'**
  String get ownerCostumeFormImageUrl;

  /// No description provided for @ownerCostumeFormImageUrlHint.
  ///
  /// In id, this message translates to:
  /// **'Gunakan URL HTTPS dari sumber foto yang Anda miliki atau memiliki izin untuk gunakan.'**
  String get ownerCostumeFormImageUrlHint;

  /// No description provided for @ownerCostumeFormImageUrlPlaceholder.
  ///
  /// In id, this message translates to:
  /// **'https://contoh.com/foto-kostum.jpg'**
  String get ownerCostumeFormImageUrlPlaceholder;

  /// No description provided for @ownerCostumeFormImages.
  ///
  /// In id, this message translates to:
  /// **'Galeri foto'**
  String get ownerCostumeFormImages;

  /// No description provided for @ownerCostumeFormImagesHint.
  ///
  /// In id, this message translates to:
  /// **'Unggah maksimal :max gambar (JPG, PNG, WEBP · 5 MB per file). Foto pertama menjadi sampul katalog.'**
  String get ownerCostumeFormImagesHint;

  /// No description provided for @ownerCostumeFormLimitReached.
  ///
  /// In id, this message translates to:
  /// **'Jumlah maksimal file sudah tercapai.'**
  String get ownerCostumeFormLimitReached;

  /// No description provided for @ownerCostumeFormName.
  ///
  /// In id, this message translates to:
  /// **'Nama paket'**
  String get ownerCostumeFormName;

  /// No description provided for @ownerCostumeFormPrice.
  ///
  /// In id, this message translates to:
  /// **'Harga'**
  String get ownerCostumeFormPrice;

  /// No description provided for @ownerCostumeFormPriceHint.
  ///
  /// In id, this message translates to:
  /// **'Harga sewa yang akan dibayar customer, sesuai ketentuan Anda sebagai pemilik rental.'**
  String get ownerCostumeFormPriceHint;

  /// No description provided for @ownerCostumeFormPublication.
  ///
  /// In id, this message translates to:
  /// **'Publikasi'**
  String get ownerCostumeFormPublication;

  /// No description provided for @ownerCostumeFormPublicationHint.
  ///
  /// In id, this message translates to:
  /// **'Kostum tayang dapat ditemukan dan dipesan pelanggan.'**
  String get ownerCostumeFormPublicationHint;

  /// No description provided for @ownerCostumeFormRemainingCount.
  ///
  /// In id, this message translates to:
  /// **'Sisa :count file'**
  String get ownerCostumeFormRemainingCount;

  /// No description provided for @ownerCostumeFormRemoveMedia.
  ///
  /// In id, this message translates to:
  /// **'Hapus'**
  String get ownerCostumeFormRemoveMedia;

  /// No description provided for @ownerCostumeFormRemoveMediaHint.
  ///
  /// In id, this message translates to:
  /// **'Centang media yang ingin dihapus, lalu simpan.'**
  String get ownerCostumeFormRemoveMediaHint;

  /// No description provided for @ownerCostumeFormSave.
  ///
  /// In id, this message translates to:
  /// **'Simpan kostum'**
  String get ownerCostumeFormSave;

  /// No description provided for @ownerCostumeFormSavedMedia.
  ///
  /// In id, this message translates to:
  /// **'Media tersimpan'**
  String get ownerCostumeFormSavedMedia;

  /// No description provided for @ownerCostumeFormSize.
  ///
  /// In id, this message translates to:
  /// **'Ukuran'**
  String get ownerCostumeFormSize;

  /// No description provided for @ownerCostumeFormStock.
  ///
  /// In id, this message translates to:
  /// **'Jumlah stok'**
  String get ownerCostumeFormStock;

  /// No description provided for @ownerCostumeFormStockHint.
  ///
  /// In id, this message translates to:
  /// **'Jumlah unit yang dapat dipesan untuk periode yang sama.'**
  String get ownerCostumeFormStockHint;

  /// No description provided for @ownerCostumeFormVideoInvalid.
  ///
  /// In id, this message translates to:
  /// **'Semua file video harus berupa video MP4, MOV, WEBM, atau MKV.'**
  String get ownerCostumeFormVideoInvalid;

  /// No description provided for @ownerCostumeFormVideoLimitError.
  ///
  /// In id, this message translates to:
  /// **'Video maksimal :max file. Hapus video lama atau kurangi jumlah unggahan.'**
  String get ownerCostumeFormVideoLimitError;

  /// No description provided for @ownerCostumeFormVideoTooLarge.
  ///
  /// In id, this message translates to:
  /// **'Ukuran setiap video maksimal :max MB.'**
  String get ownerCostumeFormVideoTooLarge;

  /// No description provided for @ownerCostumeFormVideos.
  ///
  /// In id, this message translates to:
  /// **'Video'**
  String get ownerCostumeFormVideos;

  /// No description provided for @ownerCostumeFormVideosHint.
  ///
  /// In id, this message translates to:
  /// **'Unggah maksimal :max video (MP4, MOV, WEBM · 25 MB per file).'**
  String get ownerCostumeFormVideosHint;

  /// No description provided for @ownerCostumesAdd.
  ///
  /// In id, this message translates to:
  /// **'Tambah kostum'**
  String get ownerCostumesAdd;

  /// No description provided for @ownerCostumesCreated.
  ///
  /// In id, this message translates to:
  /// **'Kostum berhasil ditambahkan.'**
  String get ownerCostumesCreated;

  /// No description provided for @ownerCostumesDelete.
  ///
  /// In id, this message translates to:
  /// **'Hapus'**
  String get ownerCostumesDelete;

  /// No description provided for @ownerCostumesDeleteConfirm.
  ///
  /// In id, this message translates to:
  /// **'Hapus kostum ini dari katalog aktif? Pesanan lama tetap tersimpan.'**
  String get ownerCostumesDeleteConfirm;

  /// No description provided for @ownerCostumesDeleted.
  ///
  /// In id, this message translates to:
  /// **'Kostum berhasil diarsipkan.'**
  String get ownerCostumesDeleted;

  /// No description provided for @ownerCostumesEdit.
  ///
  /// In id, this message translates to:
  /// **'Edit'**
  String get ownerCostumesEdit;

  /// No description provided for @ownerCostumesEmptyDescription.
  ///
  /// In id, this message translates to:
  /// **'Tambahkan kostum pertama agar pelanggan dapat menemukan dan memesannya.'**
  String get ownerCostumesEmptyDescription;

  /// No description provided for @ownerCostumesEmptyTitle.
  ///
  /// In id, this message translates to:
  /// **'Belum ada kostum'**
  String get ownerCostumesEmptyTitle;

  /// No description provided for @ownerCostumesEyebrow.
  ///
  /// In id, this message translates to:
  /// **'Katalog & stok'**
  String get ownerCostumesEyebrow;

  /// No description provided for @ownerCostumesOrders.
  ///
  /// In id, this message translates to:
  /// **'Pesanan'**
  String get ownerCostumesOrders;

  /// No description provided for @ownerCostumesPublished.
  ///
  /// In id, this message translates to:
  /// **'Tayang'**
  String get ownerCostumesPublished;

  /// No description provided for @ownerCostumesRentalPrice.
  ///
  /// In id, this message translates to:
  /// **'Harga sewa'**
  String get ownerCostumesRentalPrice;

  /// No description provided for @ownerCostumesSize.
  ///
  /// In id, this message translates to:
  /// **'Ukuran'**
  String get ownerCostumesSize;

  /// No description provided for @ownerCostumesStock.
  ///
  /// In id, this message translates to:
  /// **'Stok'**
  String get ownerCostumesStock;

  /// No description provided for @ownerCostumesSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Kelola informasi, harga, stok, dan status tayang setiap kostum.'**
  String get ownerCostumesSubtitle;

  /// No description provided for @ownerCostumesTitle.
  ///
  /// In id, this message translates to:
  /// **'Kostum yang disewakan'**
  String get ownerCostumesTitle;

  /// No description provided for @ownerCostumesUnpublished.
  ///
  /// In id, this message translates to:
  /// **'Draft'**
  String get ownerCostumesUnpublished;

  /// No description provided for @ownerCostumesUpdated.
  ///
  /// In id, this message translates to:
  /// **'Kostum berhasil diperbarui.'**
  String get ownerCostumesUpdated;

  /// No description provided for @ownerEmptyOrdersDescription.
  ///
  /// In id, this message translates to:
  /// **'Pesanan baru dari pelanggan akan muncul di sini untuk disetujui atau ditolak.'**
  String get ownerEmptyOrdersDescription;

  /// No description provided for @ownerEmptyOrdersTitle.
  ///
  /// In id, this message translates to:
  /// **'Semua pesanan sudah ditinjau'**
  String get ownerEmptyOrdersTitle;

  /// No description provided for @ownerHeaderEyebrow.
  ///
  /// In id, this message translates to:
  /// **'CosplayNusa / Owner workspace'**
  String get ownerHeaderEyebrow;

  /// No description provided for @ownerHeaderTitle.
  ///
  /// In id, this message translates to:
  /// **'Dashboard Cosrent Owner'**
  String get ownerHeaderTitle;

  /// No description provided for @ownerHeroAddCostume.
  ///
  /// In id, this message translates to:
  /// **'Tambah kostum'**
  String get ownerHeroAddCostume;

  /// No description provided for @ownerHeroDescription.
  ///
  /// In id, this message translates to:
  /// **'Kelola kostum yang Anda sewakan, pantau pesanan masuk, dan pastikan pelanggan mendapat karakter yang siap tampil.'**
  String get ownerHeroDescription;

  /// No description provided for @ownerHeroGreeting.
  ///
  /// In id, this message translates to:
  /// **'Halo, :name.'**
  String get ownerHeroGreeting;

  /// No description provided for @ownerHeroReviewOrders.
  ///
  /// In id, this message translates to:
  /// **'Tinjau pesanan'**
  String get ownerHeroReviewOrders;

  /// No description provided for @ownerHeroWelcome.
  ///
  /// In id, this message translates to:
  /// **'Ruang kerja Anda'**
  String get ownerHeroWelcome;

  /// No description provided for @ownerIssuesEvidenceHint.
  ///
  /// In id, this message translates to:
  /// **'Bukti disimpan secara privat dan hanya digunakan untuk penyelesaian laporan.'**
  String get ownerIssuesEvidenceHint;

  /// No description provided for @ownerIssuesFinePaid.
  ///
  /// In id, this message translates to:
  /// **'Denda dibayar'**
  String get ownerIssuesFinePaid;

  /// No description provided for @ownerIssuesFinePaymentRequired.
  ///
  /// In id, this message translates to:
  /// **'Tandai denda sudah dibayar sebelum menyelesaikan kasus.'**
  String get ownerIssuesFinePaymentRequired;

  /// No description provided for @ownerIssuesFineUnpaid.
  ///
  /// In id, this message translates to:
  /// **'Denda belum dibayar'**
  String get ownerIssuesFineUnpaid;

  /// No description provided for @ownerIssuesIssueStatusOpen.
  ///
  /// In id, this message translates to:
  /// **'Menunggu penyelesaian'**
  String get ownerIssuesIssueStatusOpen;

  /// No description provided for @ownerIssuesIssueStatusResolved.
  ///
  /// In id, this message translates to:
  /// **'Selesai'**
  String get ownerIssuesIssueStatusResolved;

  /// No description provided for @ownerIssuesIssueTitle.
  ///
  /// In id, this message translates to:
  /// **'Laporan masalah'**
  String get ownerIssuesIssueTitle;

  /// No description provided for @ownerIssuesIssueTypeLost.
  ///
  /// In id, this message translates to:
  /// **'Kostum hilang'**
  String get ownerIssuesIssueTypeLost;

  /// No description provided for @ownerIssuesIssueTypeStain.
  ///
  /// In id, this message translates to:
  /// **'Noda / kerusakan'**
  String get ownerIssuesIssueTypeStain;

  /// No description provided for @ownerIssuesMarkFinePaid.
  ///
  /// In id, this message translates to:
  /// **'Denda sudah dibayar customer'**
  String get ownerIssuesMarkFinePaid;

  /// No description provided for @ownerIssuesMarkReplacementReceived.
  ///
  /// In id, this message translates to:
  /// **'Kostum pengganti sudah diterima'**
  String get ownerIssuesMarkReplacementReceived;

  /// No description provided for @ownerIssuesReplacementCost.
  ///
  /// In id, this message translates to:
  /// **'Biaya kostum pengganti'**
  String get ownerIssuesReplacementCost;

  /// No description provided for @ownerIssuesReplacementPending.
  ///
  /// In id, this message translates to:
  /// **'Pengganti belum diterima'**
  String get ownerIssuesReplacementPending;

  /// No description provided for @ownerIssuesReplacementReceiptRequired.
  ///
  /// In id, this message translates to:
  /// **'Pastikan kostum pengganti sudah diterima sebelum menyelesaikan kasus.'**
  String get ownerIssuesReplacementReceiptRequired;

  /// No description provided for @ownerIssuesReplacementReceived.
  ///
  /// In id, this message translates to:
  /// **'Pengganti diterima owner'**
  String get ownerIssuesReplacementReceived;

  /// No description provided for @ownerIssuesReplacementSubmitted.
  ///
  /// In id, this message translates to:
  /// **'Bukti pengganti dikirim'**
  String get ownerIssuesReplacementSubmitted;

  /// No description provided for @ownerIssuesReporter.
  ///
  /// In id, this message translates to:
  /// **'Dilaporkan oleh'**
  String get ownerIssuesReporter;

  /// No description provided for @ownerIssuesResolutionNote.
  ///
  /// In id, this message translates to:
  /// **'Catatan penyelesaian'**
  String get ownerIssuesResolutionNote;

  /// No description provided for @ownerIssuesResolutionNotePlaceholder.
  ///
  /// In id, this message translates to:
  /// **'Catat pembayaran atau serah terima kostum pengganti.'**
  String get ownerIssuesResolutionNotePlaceholder;

  /// No description provided for @ownerIssuesResolve.
  ///
  /// In id, this message translates to:
  /// **'Selesaikan laporan'**
  String get ownerIssuesResolve;

  /// No description provided for @ownerIssuesResolveTitle.
  ///
  /// In id, this message translates to:
  /// **'Tindakan penyelesaian'**
  String get ownerIssuesResolveTitle;

  /// No description provided for @ownerIssuesResolved.
  ///
  /// In id, this message translates to:
  /// **'Laporan masalah telah diselesaikan.'**
  String get ownerIssuesResolved;

  /// No description provided for @ownerIssuesStainDescription.
  ///
  /// In id, this message translates to:
  /// **'Kronologi noda'**
  String get ownerIssuesStainDescription;

  /// No description provided for @ownerIssuesStainDescriptionPlaceholder.
  ///
  /// In id, this message translates to:
  /// **'Jelaskan bagian kostum yang terkena noda dan kapan ditemukan.'**
  String get ownerIssuesStainDescriptionPlaceholder;

  /// No description provided for @ownerIssuesStainEvidence.
  ///
  /// In id, this message translates to:
  /// **'Foto kondisi kostum'**
  String get ownerIssuesStainEvidence;

  /// No description provided for @ownerIssuesStainEvidenceError.
  ///
  /// In id, this message translates to:
  /// **'Bukti kondisi dan nominal denda wajib diisi.'**
  String get ownerIssuesStainEvidenceError;

  /// No description provided for @ownerIssuesStainFine.
  ///
  /// In id, this message translates to:
  /// **'Denda yang harus dibayar customer'**
  String get ownerIssuesStainFine;

  /// No description provided for @ownerIssuesStainStatusError.
  ///
  /// In id, this message translates to:
  /// **'Laporan noda hanya dapat dibuat setelah customer mengembalikan kostum.'**
  String get ownerIssuesStainStatusError;

  /// No description provided for @ownerIssuesStainSubmitted.
  ///
  /// In id, this message translates to:
  /// **'Laporan noda dan nominal denda telah dikirim.'**
  String get ownerIssuesStainSubmitted;

  /// No description provided for @ownerIssuesViewEvidence.
  ///
  /// In id, this message translates to:
  /// **'Lihat bukti'**
  String get ownerIssuesViewEvidence;

  /// No description provided for @ownerOrdersActions.
  ///
  /// In id, this message translates to:
  /// **'Aksi'**
  String get ownerOrdersActions;

  /// No description provided for @ownerOrdersAll.
  ///
  /// In id, this message translates to:
  /// **'Semua'**
  String get ownerOrdersAll;

  /// No description provided for @ownerOrdersApprove.
  ///
  /// In id, this message translates to:
  /// **'Setujui'**
  String get ownerOrdersApprove;

  /// No description provided for @ownerOrdersApproveNotePlaceholder.
  ///
  /// In id, this message translates to:
  /// **'Opsional: konfirmasi lokasi pengambilan dan jadwal.'**
  String get ownerOrdersApproveNotePlaceholder;

  /// No description provided for @ownerOrdersApproveTitle.
  ///
  /// In id, this message translates to:
  /// **'Setujui pesanan'**
  String get ownerOrdersApproveTitle;

  /// No description provided for @ownerOrdersApproved.
  ///
  /// In id, this message translates to:
  /// **'Pesanan berhasil disetujui.'**
  String get ownerOrdersApproved;

  /// No description provided for @ownerOrdersBack.
  ///
  /// In id, this message translates to:
  /// **'Kembali ke pesanan'**
  String get ownerOrdersBack;

  /// No description provided for @ownerOrdersCleanReturn.
  ///
  /// In id, this message translates to:
  /// **'Selesaikan pengembalian'**
  String get ownerOrdersCleanReturn;

  /// No description provided for @ownerOrdersCodeHint.
  ///
  /// In id, this message translates to:
  /// **'Minta kode kepada customer, lalu masukkan di sini. Kode wajib cocok sebelum pesanan disetujui.'**
  String get ownerOrdersCodeHint;

  /// No description provided for @ownerOrdersCodeInputLabel.
  ///
  /// In id, this message translates to:
  /// **'Kode pesanan dari customer'**
  String get ownerOrdersCodeInputLabel;

  /// No description provided for @ownerOrdersCodeInputPlaceholder.
  ///
  /// In id, this message translates to:
  /// **'COSPAY-XXXX-XXXX'**
  String get ownerOrdersCodeInputPlaceholder;

  /// No description provided for @ownerOrdersCodeMismatch.
  ///
  /// In id, this message translates to:
  /// **'Kode pesanan tidak cocok. Minta customer menunjukkan kode yang benar.'**
  String get ownerOrdersCodeMismatch;

  /// No description provided for @ownerOrdersCodeRequired.
  ///
  /// In id, this message translates to:
  /// **'Kode pesanan wajib diisi untuk pembayaran di tempat.'**
  String get ownerOrdersCodeRequired;

  /// No description provided for @ownerOrdersComplete.
  ///
  /// In id, this message translates to:
  /// **'Selesaikan'**
  String get ownerOrdersComplete;

  /// No description provided for @ownerOrdersCompleteStatusError.
  ///
  /// In id, this message translates to:
  /// **'Pesanan belum dalam status menunggu pemeriksaan owner.'**
  String get ownerOrdersCompleteStatusError;

  /// No description provided for @ownerOrdersCompleted.
  ///
  /// In id, this message translates to:
  /// **'Selesai'**
  String get ownerOrdersCompleted;

  /// No description provided for @ownerOrdersCompletedAt.
  ///
  /// In id, this message translates to:
  /// **'Diselesaikan pada'**
  String get ownerOrdersCompletedAt;

  /// No description provided for @ownerOrdersCostume.
  ///
  /// In id, this message translates to:
  /// **'Kostum'**
  String get ownerOrdersCostume;

  /// No description provided for @ownerOrdersCustomer.
  ///
  /// In id, this message translates to:
  /// **'Pelanggan'**
  String get ownerOrdersCustomer;

  /// No description provided for @ownerOrdersCustomerNote.
  ///
  /// In id, this message translates to:
  /// **'Catatan pelanggan'**
  String get ownerOrdersCustomerNote;

  /// No description provided for @ownerOrdersDecidedAt.
  ///
  /// In id, this message translates to:
  /// **'Keputusan pada'**
  String get ownerOrdersDecidedAt;

  /// No description provided for @ownerOrdersDecisionDescription.
  ///
  /// In id, this message translates to:
  /// **'Periksa pembayaran sebelum memutuskan pesanan ini.'**
  String get ownerOrdersDecisionDescription;

  /// No description provided for @ownerOrdersDecisionNote.
  ///
  /// In id, this message translates to:
  /// **'Catatan keputusan'**
  String get ownerOrdersDecisionNote;

  /// No description provided for @ownerOrdersDecisionTitle.
  ///
  /// In id, this message translates to:
  /// **'Keputusan pesanan'**
  String get ownerOrdersDecisionTitle;

  /// No description provided for @ownerOrdersDetailTitle.
  ///
  /// In id, this message translates to:
  /// **'Detail pesanan'**
  String get ownerOrdersDetailTitle;

  /// No description provided for @ownerOrdersEvidence.
  ///
  /// In id, this message translates to:
  /// **'Bukti foto kondisi kostum'**
  String get ownerOrdersEvidence;

  /// No description provided for @ownerOrdersEvidenceHint.
  ///
  /// In id, this message translates to:
  /// **'Unggah foto atau PDF maksimal 5 MB.'**
  String get ownerOrdersEvidenceHint;

  /// No description provided for @ownerOrdersEyebrow.
  ///
  /// In id, this message translates to:
  /// **'Persetujuan pelanggan'**
  String get ownerOrdersEyebrow;

  /// No description provided for @ownerOrdersFineAmount.
  ///
  /// In id, this message translates to:
  /// **'Nominal denda'**
  String get ownerOrdersFineAmount;

  /// No description provided for @ownerOrdersInventoryError.
  ///
  /// In id, this message translates to:
  /// **'Jumlah kostum tidak mencukupi untuk tanggal tersebut.'**
  String get ownerOrdersInventoryError;

  /// No description provided for @ownerOrdersIssueOpenError.
  ///
  /// In id, this message translates to:
  /// **'Selesaikan laporan masalah sebelum menutup pesanan.'**
  String get ownerOrdersIssueOpenError;

  /// No description provided for @ownerOrdersNeedAttention.
  ///
  /// In id, this message translates to:
  /// **'Periksa ketersediaan sebelum memberikan konfirmasi final.'**
  String get ownerOrdersNeedAttention;

  /// No description provided for @ownerOrdersNoNote.
  ///
  /// In id, this message translates to:
  /// **'Belum ada catatan'**
  String get ownerOrdersNoNote;

  /// No description provided for @ownerOrdersNoOrdersDescription.
  ///
  /// In id, this message translates to:
  /// **'Pesanan pelanggan untuk kostum yang Anda tawarkan akan tampil di halaman ini.'**
  String get ownerOrdersNoOrdersDescription;

  /// No description provided for @ownerOrdersNoOrdersTitle.
  ///
  /// In id, this message translates to:
  /// **'Belum ada pesanan'**
  String get ownerOrdersNoOrdersTitle;

  /// No description provided for @ownerOrdersOrderNumber.
  ///
  /// In id, this message translates to:
  /// **'Nomor pesanan'**
  String get ownerOrdersOrderNumber;

  /// No description provided for @ownerOrdersOwnerNote.
  ///
  /// In id, this message translates to:
  /// **'Catatan pemilik'**
  String get ownerOrdersOwnerNote;

  /// No description provided for @ownerOrdersOwnerNotePlaceholder.
  ///
  /// In id, this message translates to:
  /// **'Tambahkan instruksi pengambilan atau informasi penting lainnya.'**
  String get ownerOrdersOwnerNotePlaceholder;

  /// No description provided for @ownerOrdersPaymentChecked.
  ///
  /// In id, this message translates to:
  /// **'Terverifikasi'**
  String get ownerOrdersPaymentChecked;

  /// No description provided for @ownerOrdersPaymentWaiting.
  ///
  /// In id, this message translates to:
  /// **'Menunggu verifikasi'**
  String get ownerOrdersPaymentWaiting;

  /// No description provided for @ownerOrdersPending.
  ///
  /// In id, this message translates to:
  /// **'Menunggu'**
  String get ownerOrdersPending;

  /// No description provided for @ownerOrdersReject.
  ///
  /// In id, this message translates to:
  /// **'Tolak'**
  String get ownerOrdersReject;

  /// No description provided for @ownerOrdersRejectTitle.
  ///
  /// In id, this message translates to:
  /// **'Tolak pesanan'**
  String get ownerOrdersRejectTitle;

  /// No description provided for @ownerOrdersRejected.
  ///
  /// In id, this message translates to:
  /// **'Pesanan berhasil ditolak.'**
  String get ownerOrdersRejected;

  /// No description provided for @ownerOrdersReportStain.
  ///
  /// In id, this message translates to:
  /// **'Laporkan noda'**
  String get ownerOrdersReportStain;

  /// No description provided for @ownerOrdersReturnDue.
  ///
  /// In id, this message translates to:
  /// **'Batas pengembalian'**
  String get ownerOrdersReturnDue;

  /// No description provided for @ownerOrdersReturnNote.
  ///
  /// In id, this message translates to:
  /// **'Catatan customer'**
  String get ownerOrdersReturnNote;

  /// No description provided for @ownerOrdersReturnOverdue.
  ///
  /// In id, this message translates to:
  /// **'Terlambat dikembalikan'**
  String get ownerOrdersReturnOverdue;

  /// No description provided for @ownerOrdersReturnWindow.
  ///
  /// In id, this message translates to:
  /// **'Jadwal pengembalian'**
  String get ownerOrdersReturnWindow;

  /// No description provided for @ownerOrdersReturnWindowDescription.
  ///
  /// In id, this message translates to:
  /// **'Customer memiliki 3 hari setelah approval dan 1 hari tambahan untuk mengembalikan.'**
  String get ownerOrdersReturnWindowDescription;

  /// No description provided for @ownerOrdersReturned.
  ///
  /// In id, this message translates to:
  /// **'Dikembalikan'**
  String get ownerOrdersReturned;

  /// No description provided for @ownerOrdersReturnedAt.
  ///
  /// In id, this message translates to:
  /// **'Dikembalikan pada'**
  String get ownerOrdersReturnedAt;

  /// No description provided for @ownerOrdersSchedule.
  ///
  /// In id, this message translates to:
  /// **'Jadwal sewa'**
  String get ownerOrdersSchedule;

  /// No description provided for @ownerOrdersStainTitle.
  ///
  /// In id, this message translates to:
  /// **'Laporan kostum bernoda'**
  String get ownerOrdersStainTitle;

  /// No description provided for @ownerOrdersStatusError.
  ///
  /// In id, this message translates to:
  /// **'Pesanan ini sudah memiliki keputusan.'**
  String get ownerOrdersStatusError;

  /// No description provided for @ownerOrdersTitle.
  ///
  /// In id, this message translates to:
  /// **'Pesanan masuk'**
  String get ownerOrdersTitle;

  /// No description provided for @ownerOrdersTotal.
  ///
  /// In id, this message translates to:
  /// **'Total'**
  String get ownerOrdersTotal;

  /// No description provided for @ownerOrdersUnavailableError.
  ///
  /// In id, this message translates to:
  /// **'Kostum sedang tidak dipublikasikan atau telah diarsipkan.'**
  String get ownerOrdersUnavailableError;

  /// No description provided for @ownerOrdersVerifyAndApprove.
  ///
  /// In id, this message translates to:
  /// **'Verifikasi & Setujui'**
  String get ownerOrdersVerifyAndApprove;

  /// No description provided for @ownerOrdersView.
  ///
  /// In id, this message translates to:
  /// **'Tinjau detail'**
  String get ownerOrdersView;

  /// No description provided for @ownerQuickCostumes.
  ///
  /// In id, this message translates to:
  /// **'Katalog kostum'**
  String get ownerQuickCostumes;

  /// No description provided for @ownerQuickEyebrow.
  ///
  /// In id, this message translates to:
  /// **'Aksi cepat'**
  String get ownerQuickEyebrow;

  /// No description provided for @ownerQuickOrders.
  ///
  /// In id, this message translates to:
  /// **'Pesanan pelanggan'**
  String get ownerQuickOrders;

  /// No description provided for @ownerQuickProfile.
  ///
  /// In id, this message translates to:
  /// **'Profil pemilik'**
  String get ownerQuickProfile;

  /// No description provided for @ownerQuickTitle.
  ///
  /// In id, this message translates to:
  /// **'Kelola hari ini'**
  String get ownerQuickTitle;

  /// No description provided for @ownerStatsApproved.
  ///
  /// In id, this message translates to:
  /// **'Pesanan disetujui'**
  String get ownerStatsApproved;

  /// No description provided for @ownerStatsApprovedDesc.
  ///
  /// In id, this message translates to:
  /// **'booking terkonfirmasi'**
  String get ownerStatsApprovedDesc;

  /// No description provided for @ownerStatsCostumes.
  ///
  /// In id, this message translates to:
  /// **'Total kostum'**
  String get ownerStatsCostumes;

  /// No description provided for @ownerStatsCostumesDesc.
  ///
  /// In id, this message translates to:
  /// **'listing milik Anda'**
  String get ownerStatsCostumesDesc;

  /// No description provided for @ownerStatsPending.
  ///
  /// In id, this message translates to:
  /// **'Perlu ditinjau'**
  String get ownerStatsPending;

  /// No description provided for @ownerStatsPendingDesc.
  ///
  /// In id, this message translates to:
  /// **'pesanan menunggu'**
  String get ownerStatsPendingDesc;

  /// No description provided for @ownerStatsPublished.
  ///
  /// In id, this message translates to:
  /// **'Kostum tayang'**
  String get ownerStatsPublished;

  /// No description provided for @ownerStatsPublishedDesc.
  ///
  /// In id, this message translates to:
  /// **'siap dipesan pelanggan'**
  String get ownerStatsPublishedDesc;

  /// No description provided for @ownerStatsRevenue.
  ///
  /// In id, this message translates to:
  /// **'Nilai disetujui'**
  String get ownerStatsRevenue;

  /// No description provided for @ownerStatsRevenueDesc.
  ///
  /// In id, this message translates to:
  /// **'dari pesanan aktif'**
  String get ownerStatsRevenueDesc;

  /// No description provided for @profileBankAccountHolder.
  ///
  /// In id, this message translates to:
  /// **'Atas nama'**
  String get profileBankAccountHolder;

  /// No description provided for @profileBankAccountNumber.
  ///
  /// In id, this message translates to:
  /// **'Nomor rekening'**
  String get profileBankAccountNumber;

  /// No description provided for @profileBankDescription.
  ///
  /// In id, this message translates to:
  /// **'Dipakai customer untuk transfer biaya sewa ke akun Anda.'**
  String get profileBankDescription;

  /// No description provided for @profileBankName.
  ///
  /// In id, this message translates to:
  /// **'Nama bank'**
  String get profileBankName;

  /// No description provided for @profileBankTitle.
  ///
  /// In id, this message translates to:
  /// **'Data rekening pembayaran'**
  String get profileBankTitle;

  /// No description provided for @profileCancel.
  ///
  /// In id, this message translates to:
  /// **'Batal'**
  String get profileCancel;

  /// No description provided for @profileConfirmPassword.
  ///
  /// In id, this message translates to:
  /// **'Konfirmasi password'**
  String get profileConfirmPassword;

  /// No description provided for @profileCurrentPassword.
  ///
  /// In id, this message translates to:
  /// **'Password saat ini'**
  String get profileCurrentPassword;

  /// No description provided for @profileDeleteConfirmDescription.
  ///
  /// In id, this message translates to:
  /// **'Semua data akun akan dihapus permanen. Masukkan password untuk mengonfirmasi.'**
  String get profileDeleteConfirmDescription;

  /// No description provided for @profileDeleteConfirmTitle.
  ///
  /// In id, this message translates to:
  /// **'Apakah kamu yakin ingin menghapus akun?'**
  String get profileDeleteConfirmTitle;

  /// No description provided for @profileDeleteDescription.
  ///
  /// In id, this message translates to:
  /// **'Setelah akun dihapus, semua resource dan data akan hilang permanen. Unduh hal yang ingin kamu simpan sebelum menghapus akun.'**
  String get profileDeleteDescription;

  /// No description provided for @profileDeleteTitle.
  ///
  /// In id, this message translates to:
  /// **'Hapus akun'**
  String get profileDeleteTitle;

  /// No description provided for @profileEmail.
  ///
  /// In id, this message translates to:
  /// **'Email'**
  String get profileEmail;

  /// No description provided for @profileInfoDescription.
  ///
  /// In id, this message translates to:
  /// **'Perbarui informasi profil dan alamat email akunmu.'**
  String get profileInfoDescription;

  /// No description provided for @profileInfoTitle.
  ///
  /// In id, this message translates to:
  /// **'Informasi profil'**
  String get profileInfoTitle;

  /// No description provided for @profileName.
  ///
  /// In id, this message translates to:
  /// **'Nama'**
  String get profileName;

  /// No description provided for @profileNewPassword.
  ///
  /// In id, this message translates to:
  /// **'Password baru'**
  String get profileNewPassword;

  /// No description provided for @profilePasswordDescription.
  ///
  /// In id, this message translates to:
  /// **'Gunakan password panjang dan acak agar akunmu tetap aman.'**
  String get profilePasswordDescription;

  /// No description provided for @profilePasswordTitle.
  ///
  /// In id, this message translates to:
  /// **'Perbarui password'**
  String get profilePasswordTitle;

  /// No description provided for @profileResend.
  ///
  /// In id, this message translates to:
  /// **'Klik di sini untuk mengirim ulang email verifikasi.'**
  String get profileResend;

  /// No description provided for @profileSave.
  ///
  /// In id, this message translates to:
  /// **'Simpan'**
  String get profileSave;

  /// No description provided for @profileSaved.
  ///
  /// In id, this message translates to:
  /// **'Tersimpan.'**
  String get profileSaved;

  /// No description provided for @profileTitle.
  ///
  /// In id, this message translates to:
  /// **'Profil'**
  String get profileTitle;

  /// No description provided for @profileUnverified.
  ///
  /// In id, this message translates to:
  /// **'Alamat emailmu belum diverifikasi.'**
  String get profileUnverified;

  /// No description provided for @profileVerificationSent.
  ///
  /// In id, this message translates to:
  /// **'Tautan verifikasi baru telah dikirim ke alamat emailmu.'**
  String get profileVerificationSent;

  /// No description provided for @rentalIssuesDuplicateError.
  ///
  /// In id, this message translates to:
  /// **'Pesanan ini sudah memiliki laporan masalah.'**
  String get rentalIssuesDuplicateError;

  /// No description provided for @rentalIssuesResolvedError.
  ///
  /// In id, this message translates to:
  /// **'Laporan masalah ini sudah diselesaikan.'**
  String get rentalIssuesResolvedError;

  /// No description provided for @siteAuthAccountType.
  ///
  /// In id, this message translates to:
  /// **'Daftar sebagai'**
  String get siteAuthAccountType;

  /// No description provided for @siteAuthAccountTypeDescription.
  ///
  /// In id, this message translates to:
  /// **'Pilih akses yang paling sesuai dengan kebutuhanmu.'**
  String get siteAuthAccountTypeDescription;

  /// No description provided for @siteAuthConfirm.
  ///
  /// In id, this message translates to:
  /// **'Konfirmasi'**
  String get siteAuthConfirm;

  /// No description provided for @siteAuthConfirmPlaceholder.
  ///
  /// In id, this message translates to:
  /// **'Ulangi password'**
  String get siteAuthConfirmPlaceholder;

  /// No description provided for @siteAuthCosrentOwner.
  ///
  /// In id, this message translates to:
  /// **'Cosrent Owner'**
  String get siteAuthCosrentOwner;

  /// No description provided for @siteAuthCosrentOwnerDescription.
  ///
  /// In id, this message translates to:
  /// **'Sediakan kostum dan kelola persetujuan pesanan.'**
  String get siteAuthCosrentOwnerDescription;

  /// No description provided for @siteAuthCustomer.
  ///
  /// In id, this message translates to:
  /// **'Pelanggan'**
  String get siteAuthCustomer;

  /// No description provided for @siteAuthCustomerDescription.
  ///
  /// In id, this message translates to:
  /// **'Sewa kostum dan pantau status pesanan.'**
  String get siteAuthCustomerDescription;

  /// No description provided for @siteAuthDashboard.
  ///
  /// In id, this message translates to:
  /// **'Buka dashboard'**
  String get siteAuthDashboard;

  /// No description provided for @siteAuthDescription.
  ///
  /// In id, this message translates to:
  /// **'Simpan pesananmu dan lanjutkan petualangan karaktermu kapan saja.'**
  String get siteAuthDescription;

  /// No description provided for @siteAuthEmail.
  ///
  /// In id, this message translates to:
  /// **'Email'**
  String get siteAuthEmail;

  /// No description provided for @siteAuthEmailPlaceholder.
  ///
  /// In id, this message translates to:
  /// **'nama@email.com'**
  String get siteAuthEmailPlaceholder;

  /// No description provided for @siteAuthErrorDescription.
  ///
  /// In id, this message translates to:
  /// **'Periksa kembali informasi yang kamu masukkan.'**
  String get siteAuthErrorDescription;

  /// No description provided for @siteAuthErrorTitle.
  ///
  /// In id, this message translates to:
  /// **'Ada yang perlu diperbaiki.'**
  String get siteAuthErrorTitle;

  /// No description provided for @siteAuthForgot.
  ///
  /// In id, this message translates to:
  /// **'Lupa password?'**
  String get siteAuthForgot;

  /// No description provided for @siteAuthLoginButton.
  ///
  /// In id, this message translates to:
  /// **'Masuk ke akun'**
  String get siteAuthLoginButton;

  /// No description provided for @siteAuthLoginTitle.
  ///
  /// In id, this message translates to:
  /// **'Masuk ke akunmu.'**
  String get siteAuthLoginTitle;

  /// No description provided for @siteAuthMemberAccess.
  ///
  /// In id, this message translates to:
  /// **'Akses anggota'**
  String get siteAuthMemberAccess;

  /// No description provided for @siteAuthPassword.
  ///
  /// In id, this message translates to:
  /// **'Password'**
  String get siteAuthPassword;

  /// No description provided for @siteAuthPasswordPlaceholder.
  ///
  /// In id, this message translates to:
  /// **'Masukkan password'**
  String get siteAuthPasswordPlaceholder;

  /// No description provided for @siteAuthRegisterButton.
  ///
  /// In id, this message translates to:
  /// **'Buat akun gratis'**
  String get siteAuthRegisterButton;

  /// No description provided for @siteAuthRegisterDescription.
  ///
  /// In id, this message translates to:
  /// **'Pilih akses pelanggan atau penyedia kostum, lalu mulai pesanan pertamamu.'**
  String get siteAuthRegisterDescription;

  /// No description provided for @siteAuthRegisterName.
  ///
  /// In id, this message translates to:
  /// **'Nama lengkap'**
  String get siteAuthRegisterName;

  /// No description provided for @siteAuthRegisterNamePlaceholder.
  ///
  /// In id, this message translates to:
  /// **'Nama panggilanmu'**
  String get siteAuthRegisterNamePlaceholder;

  /// No description provided for @siteAuthRegisterPasswordPlaceholder.
  ///
  /// In id, this message translates to:
  /// **'Minimal 8 karakter'**
  String get siteAuthRegisterPasswordPlaceholder;

  /// No description provided for @siteAuthRegisterTitle.
  ///
  /// In id, this message translates to:
  /// **'Buat akun CosplayNusa.'**
  String get siteAuthRegisterTitle;

  /// No description provided for @siteAuthRemember.
  ///
  /// In id, this message translates to:
  /// **'Ingat saya'**
  String get siteAuthRemember;

  /// No description provided for @siteAuthSecure.
  ///
  /// In id, this message translates to:
  /// **'Datamu tersimpan aman di CosplayNusa'**
  String get siteAuthSecure;

  /// No description provided for @siteAuthTabLogin.
  ///
  /// In id, this message translates to:
  /// **'Masuk'**
  String get siteAuthTabLogin;

  /// No description provided for @siteAuthTabRegister.
  ///
  /// In id, this message translates to:
  /// **'Daftar'**
  String get siteAuthTabRegister;

  /// No description provided for @siteAuthTerms.
  ///
  /// In id, this message translates to:
  /// **'Dengan membuat akun, kamu setuju mengikuti alur pemesanan dan care guide dari CosplayNusa.'**
  String get siteAuthTerms;

  /// No description provided for @siteAuthWelcomeBack.
  ///
  /// In id, this message translates to:
  /// **'Selamat datang kembali'**
  String get siteAuthWelcomeBack;

  /// No description provided for @siteAuthWelcomeDescription.
  ///
  /// In id, this message translates to:
  /// **'Koleksi pilihanmu sudah menunggu. Lanjutkan petualangan cosplay berikutnya.'**
  String get siteAuthWelcomeDescription;

  /// No description provided for @siteAuthWelcomeTitle.
  ///
  /// In id, this message translates to:
  /// **'Siap jadi karakter lagi, :name?'**
  String get siteAuthWelcomeTitle;

  /// No description provided for @siteBenefitsBookingDesc.
  ///
  /// In id, this message translates to:
  /// **'Pilih ukuran, jadwalkan, dan tinggal tampil.'**
  String get siteBenefitsBookingDesc;

  /// No description provided for @siteBenefitsBookingTitle.
  ///
  /// In id, this message translates to:
  /// **'Pemesanan mudah'**
  String get siteBenefitsBookingTitle;

  /// No description provided for @siteBenefitsEyebrow.
  ///
  /// In id, this message translates to:
  /// **'Dibuat untuk acara berikutnya'**
  String get siteBenefitsEyebrow;

  /// No description provided for @siteBenefitsQualityDesc.
  ///
  /// In id, this message translates to:
  /// **'Setiap set dirapikan dan dicek sebelum dikirim.'**
  String get siteBenefitsQualityDesc;

  /// No description provided for @siteBenefitsQualityTitle.
  ///
  /// In id, this message translates to:
  /// **'Kualitas diperiksa'**
  String get siteBenefitsQualityTitle;

  /// No description provided for @siteBenefitsReadyDesc.
  ///
  /// In id, this message translates to:
  /// **'Pengambilan fleksibel untuk rencana mendadak.'**
  String get siteBenefitsReadyDesc;

  /// No description provided for @siteBenefitsReadyTitle.
  ///
  /// In id, this message translates to:
  /// **'Siap lebih cepat'**
  String get siteBenefitsReadyTitle;

  /// No description provided for @siteBenefitsTitleLine1.
  ///
  /// In id, this message translates to:
  /// **'Nyaman dipakai.'**
  String get siteBenefitsTitleLine1;

  /// No description provided for @siteBenefitsTitleLine2.
  ///
  /// In id, this message translates to:
  /// **'Bold saat tampil.'**
  String get siteBenefitsTitleLine2;

  /// No description provided for @siteCollectionAction.
  ///
  /// In id, this message translates to:
  /// **'Mulai dari akunmu'**
  String get siteCollectionAction;

  /// No description provided for @siteCollectionEyebrow.
  ///
  /// In id, this message translates to:
  /// **'Pilihan kostum'**
  String get siteCollectionEyebrow;

  /// No description provided for @siteCollectionFantasy.
  ///
  /// In id, this message translates to:
  /// **'01 / Fantasi'**
  String get siteCollectionFantasy;

  /// No description provided for @siteCollectionFantasyDesc.
  ///
  /// In id, this message translates to:
  /// **'Siluet · sayap · sihir lembut'**
  String get siteCollectionFantasyDesc;

  /// No description provided for @siteCollectionHeroic.
  ///
  /// In id, this message translates to:
  /// **'02 / Pahlawan'**
  String get siteCollectionHeroic;

  /// No description provided for @siteCollectionHeroicDesc.
  ///
  /// In id, this message translates to:
  /// **'Armor · jubah · ciri khas'**
  String get siteCollectionHeroicDesc;

  /// No description provided for @siteCollectionModern.
  ///
  /// In id, this message translates to:
  /// **'03 / Modern'**
  String get siteCollectionModern;

  /// No description provided for @siteCollectionModernDesc.
  ///
  /// In id, this message translates to:
  /// **'Streetwear · detail · gaya'**
  String get siteCollectionModernDesc;

  /// No description provided for @siteCollectionTitle.
  ///
  /// In id, this message translates to:
  /// **'Pilih cerita yang ingin kamu pakai.'**
  String get siteCollectionTitle;

  /// No description provided for @siteFooterTagline.
  ///
  /// In id, this message translates to:
  /// **'Pakai ceritanya. Buat kenangan.'**
  String get siteFooterTagline;

  /// No description provided for @siteHeroBadge.
  ///
  /// In id, this message translates to:
  /// **'Kostum rental siap memukau'**
  String get siteHeroBadge;

  /// No description provided for @siteHeroCompleteSet.
  ///
  /// In id, this message translates to:
  /// **'Set lengkap · 4 bagian'**
  String get siteHeroCompleteSet;

  /// No description provided for @siteHeroCuratedDrop.
  ///
  /// In id, this message translates to:
  /// **'Pilihan terkurasi'**
  String get siteHeroCuratedDrop;

  /// No description provided for @siteHeroDescription.
  ///
  /// In id, this message translates to:
  /// **'Sewa set cosplay premium untuk convention, photoshoot, dan kreasi konten. Pilih karaktermu, kami siapkan detailnya sampai kamu siap masuk panggung.'**
  String get siteHeroDescription;

  /// No description provided for @siteHeroEditorPick.
  ///
  /// In id, this message translates to:
  /// **'Pilihan editor / 01'**
  String get siteHeroEditorPick;

  /// No description provided for @siteHeroExplore.
  ///
  /// In id, this message translates to:
  /// **'Jelajahi koleksi'**
  String get siteHeroExplore;

  /// No description provided for @siteHeroHow.
  ///
  /// In id, this message translates to:
  /// **'Lihat cara kerja'**
  String get siteHeroHow;

  /// No description provided for @siteHeroImageLabel.
  ///
  /// In id, this message translates to:
  /// **'Kostum cosplay pilihan dari CosplayNusa'**
  String get siteHeroImageLabel;

  /// No description provided for @siteHeroPriceSuffix.
  ///
  /// In id, this message translates to:
  /// **'/hari'**
  String get siteHeroPriceSuffix;

  /// No description provided for @siteHeroStatRating.
  ///
  /// In id, this message translates to:
  /// **'rating pencinta'**
  String get siteHeroStatRating;

  /// No description provided for @siteHeroStatSets.
  ///
  /// In id, this message translates to:
  /// **'set siap pakai'**
  String get siteHeroStatSets;

  /// No description provided for @siteHeroStatSupport.
  ///
  /// In id, this message translates to:
  /// **'bantuan responsif'**
  String get siteHeroStatSupport;

  /// No description provided for @siteHeroTitleFirst.
  ///
  /// In id, this message translates to:
  /// **'Busanaikan'**
  String get siteHeroTitleFirst;

  /// No description provided for @siteHeroTitleSecond.
  ///
  /// In id, this message translates to:
  /// **'karaktermu.'**
  String get siteHeroTitleSecond;

  /// No description provided for @siteNavBenefits.
  ///
  /// In id, this message translates to:
  /// **'Keunggulan'**
  String get siteNavBenefits;

  /// No description provided for @siteNavCollection.
  ///
  /// In id, this message translates to:
  /// **'Koleksi'**
  String get siteNavCollection;

  /// No description provided for @siteNavHome.
  ///
  /// In id, this message translates to:
  /// **'Kembali ke beranda'**
  String get siteNavHome;

  /// No description provided for @siteNavHowItWorks.
  ///
  /// In id, this message translates to:
  /// **'Cara kerja'**
  String get siteNavHowItWorks;

  /// No description provided for @siteNavMenu.
  ///
  /// In id, this message translates to:
  /// **'Buka menu navigasi'**
  String get siteNavMenu;

  /// No description provided for @siteStepsAction.
  ///
  /// In id, this message translates to:
  /// **'Siap berubah?'**
  String get siteStepsAction;

  /// No description provided for @siteStepsChooseDesc.
  ///
  /// In id, this message translates to:
  /// **'Telusuri koleksi dan temukan ukuran yang terasa seperti kamu.'**
  String get siteStepsChooseDesc;

  /// No description provided for @siteStepsChooseTitle.
  ///
  /// In id, this message translates to:
  /// **'Pilih kostum'**
  String get siteStepsChooseTitle;

  /// No description provided for @siteStepsEyebrow.
  ///
  /// In id, this message translates to:
  /// **'Tiga langkah sederhana'**
  String get siteStepsEyebrow;

  /// No description provided for @siteStepsSceneDesc.
  ///
  /// In id, this message translates to:
  /// **'Ambil setmu dan buat momen yang tidak biasa dilupakan.'**
  String get siteStepsSceneDesc;

  /// No description provided for @siteStepsSceneTitle.
  ///
  /// In id, this message translates to:
  /// **'Masuk ke scene'**
  String get siteStepsSceneTitle;

  /// No description provided for @siteStepsScheduleDesc.
  ///
  /// In id, this message translates to:
  /// **'Pilih tanggal pemesanan, konfirmasi booking, lalu bersiap tampil.'**
  String get siteStepsScheduleDesc;

  /// No description provided for @siteStepsScheduleTitle.
  ///
  /// In id, this message translates to:
  /// **'Atur jadwal'**
  String get siteStepsScheduleTitle;

  /// No description provided for @siteStepsTitle.
  ///
  /// In id, this message translates to:
  /// **'Dari checkout ke karakter dalam 3 langkah.'**
  String get siteStepsTitle;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'id', 'ja', 'ko', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'id':
      return AppLocalizationsId();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
