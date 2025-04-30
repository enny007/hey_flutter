import 'dart:core';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:stacked/stacked.dart';

class PackageIntegrationService with ListenableServiceMixin {
  String? _selectedProjectPath = '';
  bool _isValidProject = false;
  bool _isIntegrating = false;
  bool _integrationComplete = false;
  String? _errorMessage = '';

  // Package-specific fields
  String _packageName = '';
  String _packageVersion = '';
  Map<String, dynamic> _packageConfig = {};
  bool _needsSpecialConfig = false;

  // For packages requiring API keys
  String? _apiKey = '';
  bool _isApiKeyRequired = false;
  bool _isApiKeyConfigured = false;

  String? get selectedProjectPath => _selectedProjectPath;
  bool get isValidProject => _isValidProject;
  bool get isIntegrating => _isIntegrating;
  bool get integrationComplete => _integrationComplete;
  String? get errorMessage => _errorMessage;
  String get packageName => _packageName;
  String get packageVersion => _packageVersion;
  String? get apiKey => _apiKey;
  bool get isApiKeyRequired => _isApiKeyRequired;
  bool get isApiKeyConfigured => _isApiKeyConfigured;
  bool get needsSpecialConfig => _needsSpecialConfig;

  Future<void> setProjectPath(String path) async {
    _selectedProjectPath = path;
    _isValidProject = await validateProject(path);
    _errorMessage = _isValidProject ? null : 'Invalid Flutter project';

    if (_isValidProject && _isApiKeyRequired) {
      _isApiKeyConfigured = await checkIfApiKeyConfigured(path);
    }

    notifyListeners();
  }

  Future<bool> validateProject(String projectPath) async {
    try {
      final pubspecFile = File(path.join(projectPath, 'pubspec.yaml'));
      return await pubspecFile.exists();
    } catch (e) {
      _errorMessage = 'Error validating project: $e';
      return false;
    }
  }

  void setPackageDetails(String name, String version,
      {Map<String, dynamic>? config}) {
    _packageName = name;
    _packageVersion = version;
    _packageConfig = config ?? {};

    // Determine if this package needs special configuration
    _needsSpecialConfig = _specialConfigPackages.contains(name);
    _isApiKeyRequired = _apiKeyRequiredPackages.contains(name);

    notifyListeners();
  }

  void setApiKey(String key) {
    _apiKey = key;
    notifyListeners();
  }

  Future<bool> checkIfApiKeyConfigured(String projectPath) async {
    // This would be package-specific logic
    if (_packageName == 'google_maps_flutter') {
      try {
        // Check Android manifest
        final androidManifestFile = File(path.join(projectPath, 'android',
            'app', 'src', 'main', 'AndroidManifest.xml'));

        if (await androidManifestFile.exists()) {
          final content = await androidManifestFile.readAsString();
          if (content.contains('com.google.android.geo.API_KEY')) {
            return true;
          }
        }

        // Check iOS Info.plist
        final iosInfoPlistFile =
            File(path.join(projectPath, 'ios', 'Runner', 'Info.plist'));

        if (await iosInfoPlistFile.exists()) {
          final content = await iosInfoPlistFile.readAsString();
          if (content.contains('GMSApiKey')) {
            return true;
          }
        }
        return false;
      } catch (e) {
        _errorMessage = 'Error checking API key configuration: $e';
        return false;
      }
    }
    return false;
  }

  Future<void> integratePackage() async {
    if (!_isValidProject ||
        _selectedProjectPath == null ||
        _packageName.isEmpty) {
      _errorMessage = 'Please select a valid Flutter project and package first';
      notifyListeners();
      return;
    }

    _isIntegrating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _addPackageToPubspec();
      await _runPubGet();

      // Handle special configurations if needed
      if (_needsSpecialConfig) {
        await _applySpecialConfiguration();
      }

      // Add example code if available
      if (_packageConfig.containsKey('exampleCode')) {
        await _addExampleCode();
      }

      _integrationComplete = true;
    } catch (e) {
      _errorMessage = 'Integration failed: $e';
      _integrationComplete = false;
    } finally {
      _isIntegrating = false;
      notifyListeners();
    }
  }

  Future<void> _addPackageToPubspec() async {
    try {
      final pubspecFile =
          File(path.join(_selectedProjectPath!, 'pubspec.yaml'));
      String content = await pubspecFile.readAsString();

      if (!content.contains('$_packageName:')) {
        // Find dependencies section and add the package
        final dependenciesIndex = content.indexOf('dependencies:');
        if (dependenciesIndex != -1) {
          final insertPosition = content.indexOf('\n', dependenciesIndex) + 1;
          content =
              '${content.substring(0, insertPosition)}  $_packageName: $_packageVersion\n${content.substring(insertPosition)}';

          await pubspecFile.writeAsString(content);
        } else {
          throw Exception(
              'Could not find dependencies section in pubspec.yaml');
        }
      }
    } catch (e) {
      throw Exception('Failed to add package to pubspec.yaml: $e');
    }
  }

  Future<void> _runPubGet() async {
    try {
      final result = await Process.run(
        'flutter',
        ['pub', 'get'],
        workingDirectory: _selectedProjectPath,
      );

      if (result.exitCode != 0) {
        throw Exception('flutter pub get failed: ${result.stderr}');
      }
    } catch (e) {
      throw Exception('Failed to run flutter pub get: $e');
    }
  }

  Future<void> _applySpecialConfiguration() async {
    // Handle package-specific configurations
    switch (_packageName) {
      case 'google_maps_flutter':
        await _configureGoogleMaps();
        break;
      case 'firebase_core':
        await _configureFirebase();
        break;
      // Add more package-specific configurations as needed
    }
  }

  Future<void> _configureGoogleMaps() async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      throw Exception('Google Maps requires an API key');
    }

    await _configureAndroidForGoogleMaps();
    await _configureIOSForGoogleMaps();
  }

  Future<void> _configureAndroidForGoogleMaps() async {
    try {
      // Update AndroidManifest.xml
      final manifestFile = File(path.join(_selectedProjectPath!, 'android',
          'app', 'src', 'main', 'AndroidManifest.xml'));

      String content = await manifestFile.readAsString();

      if (!content.contains('com.google.android.geo.API_KEY')) {
        // Add the meta-data tag before the application closing tag
        final insertPosition = content.lastIndexOf('</application>');
        if (insertPosition != -1) {
          content =
              '${content.substring(0, insertPosition)}        <meta-data\n            android:name="com.google.android.geo.API_KEY"\n            android:value="$_apiKey" />\n${content.substring(insertPosition)}';

          await manifestFile.writeAsString(content);
        }
      }

      // Update build.gradle for minSdkVersion
      final buildGradleFile = File(
          path.join(_selectedProjectPath!, 'android', 'app', 'build.gradle'));

      String gradleContent = await buildGradleFile.readAsString();

      // Ensure minSdkVersion is at least 20
      final minSdkRegex = RegExp(r'minSdkVersion\s+(\d+)');
      final match = minSdkRegex.firstMatch(gradleContent);

      if (match != null) {
        final currentMinSdk = int.parse(match.group(1)!);
        if (currentMinSdk < 20) {
          gradleContent =
              gradleContent.replaceFirst(minSdkRegex, 'minSdkVersion 20');
          await buildGradleFile.writeAsString(gradleContent);
        }
      }
    } catch (e) {
      throw Exception('Failed to configure Android platform: $e');
    }
  }

  Future<void> _configureIOSForGoogleMaps() async {
    try {
      // Update Info.plist
      final infoPlistFile =
          File(path.join(_selectedProjectPath!, 'ios', 'Runner', 'Info.plist'));

      String content = await infoPlistFile.readAsString();

      if (!content.contains('GMSApiKey')) {
        // Add the API key before the closing dict tag
        final insertPosition = content.lastIndexOf('</dict>');
        if (insertPosition != -1) {
          content =
              '${content.substring(0, insertPosition)}\t<key>GMSApiKey</key>\n\t<string>$_apiKey</string>\n${content.substring(insertPosition)}';

          await infoPlistFile.writeAsString(content);
        }
      }

      // Update AppDelegate.swift if it exists
      final appDelegateFile = File(path.join(
          _selectedProjectPath!, 'ios', 'Runner', 'AppDelegate.swift'));

      if (await appDelegateFile.exists()) {
        String appDelegateContent = await appDelegateFile.readAsString();

        if (!appDelegateContent.contains('GMSServices')) {
          // Add import
          if (!appDelegateContent.contains('import GoogleMaps')) {
            final importPosition = appDelegateContent.indexOf('import Flutter');
            if (importPosition != -1) {
              final endOfLine =
                  appDelegateContent.indexOf('\n', importPosition) + 1;
              appDelegateContent =
                  '${appDelegateContent.substring(0, endOfLine)}import GoogleMaps\n${appDelegateContent.substring(endOfLine)}';
            }
          }

          // Add initialization
          final didFinishLaunchingPosition =
              appDelegateContent.indexOf('didFinishLaunchingWithOptions');
          if (didFinishLaunchingPosition != -1) {
            final openBracePosition =
                appDelegateContent.indexOf('{', didFinishLaunchingPosition);
            if (openBracePosition != -1) {
              final insertPosition =
                  appDelegateContent.indexOf('\n', openBracePosition) + 1;
              appDelegateContent =
                  '${appDelegateContent.substring(0, insertPosition)}    GMSServices.provideAPIKey("$_apiKey")\n${appDelegateContent.substring(insertPosition)}';
            }
          }

          await appDelegateFile.writeAsString(appDelegateContent);
        }
      }
    } catch (e) {
      throw Exception('Failed to configure iOS platform: $e');
    }
  }

  Future<void> _configureFirebase() async {
    // Firebase configuration logic would go here
    throw Exception('Firebase configuration not yet implemented');
  }

  Future<void> _addExampleCode() async {
    try {
      // Get example code from package config or use a default
      String exampleCode =
          _packageConfig['exampleCode'] ?? _getDefaultExampleCode();

      // Create a new example file or update main.dart
      final mainFile =
          File(path.join(_selectedProjectPath!, 'lib', 'main.dart'));
      await mainFile.writeAsString(exampleCode);
    } catch (e) {
      throw Exception('Failed to add example code: $e');
    }
  }

  String _getDefaultExampleCode() {
    // Return package-specific example code
    switch (_packageName) {
      case 'dotted_border':
        return '''
import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dotted Border Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const DottedBorderDemo(),
    );
  }
}

class DottedBorderDemo extends StatelessWidget {
  const DottedBorderDemo({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dotted Border Demo'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            DottedBorder(
              borderType: BorderType.RRect,
              radius: const Radius.circular(12),
              padding: const EdgeInsets.all(6),
              color: Colors.blue,
              strokeWidth: 2,
              dashPattern: const [8, 4],
              child: ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(12)),
                child: Container(
                  height: 120,
                  width: 250,
                  color: Colors.blue.shade50,
                  child: const Center(
                    child: Text(
                      'Dotted Border Package\\nIntegrated Successfully!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                DottedBorder(
                  borderType: BorderType.Circle,
                  color: Colors.green,
                  strokeWidth: 2,
                  dashPattern: const [6, 3, 2, 3],
                  child: Container(
                    height: 80,
                    width: 80,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.lightGreen,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
                DottedBorder(
                  borderType: BorderType.Oval,
                  color: Colors.orange,
                  strokeWidth: 2,
                  dashPattern: const [8, 4],
                  child: Container(
                    height: 80,
                    width: 140,
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: const Center(
                      child: Text(
                        'Oval',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
''';
      default:
        return '''
import 'package:flutter/material.dart';
import 'package:$_packageName/$_packageName.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '$_packageName Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('$_packageName Demo'),
      ),
      body: const Center(
        child: Text('$_packageName has been integrated!'),
      ),
    );
  }
}
''';
    }
  }

  // Lists of packages requiring special handling
  static const List<String> _specialConfigPackages = [
    'google_maps_flutter',
    'firebase_core',
    'camera',
    'permission_handler',
    'flutter_local_notifications',
    // Add more as needed
  ];

  static const List<String> _apiKeyRequiredPackages = [
    'google_maps_flutter',
    'firebase_core',
    'google_mobile_ads',
    // Add more as needed
  ];
}
