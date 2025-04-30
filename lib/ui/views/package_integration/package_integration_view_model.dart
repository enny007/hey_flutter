import 'package:file_picker/file_picker.dart';
import 'package:heyflutter/app/app.locator.dart';
import 'package:heyflutter/core/services/package_integration_service.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

class PackageIntegrationViewModel extends ReactiveViewModel {
  final _packageIntegrationService = locator<PackageIntegrationService>();
  final _snackbarService = locator<SnackbarService>();

  // List of available packages with their versions
  final List<Map<String, String>> availablePackages = [
    {'name': 'dotted_border', 'version': '^2.1.0'},
    {'name': 'http', 'version': '^0.13.5'},
    {'name': 'shared_preferences', 'version': '^2.0.18'},
    {'name': 'provider', 'version': '^6.0.5'},
    {'name': 'flutter_bloc', 'version': '^8.1.2'},
    {'name': 'path_provider', 'version': '^2.0.13'},
    {'name': 'sqflite', 'version': '^2.2.6'},
    {'name': 'permission_handler', 'version': '^10.2.0'},
    {'name': 'flutter_svg', 'version': '^2.0.5'},
    {'name': 'url_launcher', 'version': '^6.1.10'},
  ];

  // Currently selected package
  Map<String, String>? _selectedPackage;
  Map<String, String>? get selectedPackage => _selectedPackage;

  String? get selectedProjectPath =>
      _packageIntegrationService.selectedProjectPath;
  bool get isValidProject => _packageIntegrationService.isValidProject;
  bool get isIntegrating => _packageIntegrationService.isIntegrating;
  bool get integrationComplete =>
      _packageIntegrationService.integrationComplete;
  String? get errorMessage => _packageIntegrationService.errorMessage;
  String? get apiKey => _packageIntegrationService.apiKey;
  bool get isApiKeyRequired => _packageIntegrationService.isApiKeyRequired;
  bool get isApiKeyConfigured => _packageIntegrationService.isApiKeyConfigured;
  bool get needsSpecialConfig => _packageIntegrationService.needsSpecialConfig;
  String get packageName => _packageIntegrationService.packageName;

  Future<void> selectProjectDirectory() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select Flutter Project Directory',
    );

    if (selectedDirectory != null) {
      await _packageIntegrationService.setProjectPath(selectedDirectory);

      if (_packageIntegrationService.isValidProject) {
        _snackbarService.showSnackbar(
          title: 'Project Selected',
          message: 'Flutter project selected successfully',
          duration: const Duration(seconds: 2),
        );
      }
    }
  }

  void selectPackage(Map<String, String> package) {
    _selectedPackage = package;
    _packageIntegrationService.setPackageDetails(
      package['name']!,
      package['version']!,
    );

    _snackbarService.showSnackbar(
      title: 'Package Selected',
      message: '${package['name']} selected for integration',
      duration: const Duration(seconds: 2),
    );

    notifyListeners();
  }

  void setApiKey(String key) {
    _packageIntegrationService.setApiKey(key);
  }

  Future<void> integratePackage() async {
    await _packageIntegrationService.integratePackage();

    if (_packageIntegrationService.integrationComplete) {
      _snackbarService.showSnackbar(
        title: 'Integration Complete',
        message:
            '${_packageIntegrationService.packageName} has been successfully added to your project',
        duration: const Duration(seconds: 3),
      );
    } else if (_packageIntegrationService.errorMessage != null) {
      _snackbarService.showSnackbar(
        title: 'Integration Failed',
        message: _packageIntegrationService.errorMessage!,
        duration: const Duration(seconds: 3),
      );
    }
  }

  @override
  List<ListenableServiceMixin> get listenableServices =>
      [_packageIntegrationService];
}
