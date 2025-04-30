import 'package:flutter/material.dart';
import 'package:heyflutter/ui/views/package_integration/package_integration_view_model.dart';
import 'package:stacked/stacked.dart';
import 'package:dotted_border/dotted_border.dart';

class PackageIntegrationView extends StackedView<PackageIntegrationViewModel> {
  const PackageIntegrationView({super.key});

  @override
  Widget builder(BuildContext context, PackageIntegrationViewModel viewModel,
      Widget? child) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Package Integrator'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Step 1: Project Selection
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Step 1: Select Flutter Project',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              viewModel.selectedProjectPath ??
                                  'No project selected',
                              style: TextStyle(
                                color: viewModel.isValidProject
                                    ? Colors.green
                                    : Colors.grey,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton(
                            onPressed: viewModel.isIntegrating
                                ? null
                                : viewModel.selectProjectDirectory,
                            child: const Text('Browse'),
                          ),
                        ],
                      ),
                      if (viewModel.selectedProjectPath != null &&
                          !viewModel.isValidProject)
                        const Padding(
                          padding: EdgeInsets.only(top: 8.0),
                          child: Text(
                            'Invalid Flutter project. Please select a directory with a pubspec.yaml file.',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Step 2: Package Selection
              if (viewModel.isValidProject)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Step 2: Select Package to Integrate',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<Map<String, String>>(
                          decoration: const InputDecoration(
                            labelText: 'Select Package',
                            border: OutlineInputBorder(),
                          ),
                          value: viewModel.selectedPackage,
                          items: viewModel.availablePackages.map((package) {
                            return DropdownMenuItem<Map<String, String>>(
                              value: package,
                              child: Text(
                                  '${package['name']} (${package['version']})'),
                            );
                          }).toList(),
                          onChanged: viewModel.isIntegrating
                              ? null
                              : (value) {
                                  if (value != null) {
                                    viewModel.selectPackage(value);
                                  }
                                },
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // Step 3: Integration Button
              if (viewModel.isValidProject && viewModel.selectedPackage != null)
                ElevatedButton(
                  onPressed: viewModel.isIntegrating
                      ? null
                      : viewModel.integratePackage,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: viewModel.isIntegrating
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('Integrating...'),
                          ],
                        )
                      : Text(
                          'Integrate ${viewModel.selectedPackage?['name'] ?? ''} Package'),
                ),

              const SizedBox(height: 16),

              // Status and Error Messages
              if (viewModel.errorMessage != null)
                Card(
                  color: Colors.red.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      viewModel.errorMessage!,
                      style: TextStyle(color: Colors.red.shade800),
                    ),
                  ),
                ),

              if (viewModel.integrationComplete)
                Card(
                  color: Colors.green.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Integration Complete!',
                          style: TextStyle(
                            color: Colors.green.shade800,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'The ${viewModel.packageName} package has been successfully integrated into your project. ${viewModel.needsSpecialConfig ? 'Platform-specific configurations have been applied. ' : ''}A sample implementation has been added to main.dart.',
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Run your project with: flutter run',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),

              // Show Dotted Border Example (when dotted_border package is integrated)
              if (viewModel.integrationComplete &&
                  viewModel.packageName == 'dotted_border')
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    const Text(
                      'Dotted Border Example',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: DottedBorder(
                        borderType: BorderType.RRect,
                        radius: const Radius.circular(12),
                        padding: const EdgeInsets.all(6),
                        color: Colors.blue,
                        strokeWidth: 2,
                        dashPattern: const [8, 4],
                        child: ClipRRect(
                          borderRadius:
                              const BorderRadius.all(Radius.circular(12)),
                          child: Container(
                            height: 120,
                            width: 250,
                            color: Colors.blue.shade50,
                            child: const Center(
                              child: Text(
                                'Dotted Border Package\nIntegrated Successfully!',
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
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: DottedBorder(
                        borderType: BorderType.Circle,
                        color: Colors.green,
                        strokeWidth: 2,
                        dashPattern: const [6, 3, 2, 3],
                        child: Container(
                          height: 100,
                          width: 100,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.lightGreen,
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 50,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        DottedBorder(
                          borderType: BorderType.Rect,
                          color: Colors.purple,
                          strokeWidth: 2,
                          dashPattern: const [4, 4],
                          child: Container(
                            height: 80,
                            width: 80,
                            color: Colors.purple.shade100,
                            child: const Center(
                              child: Text(
                                'Rectangle',
                                textAlign: TextAlign.center,
                              ),
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
                    const SizedBox(height: 24),
                    const Text(
                      'Code Example:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: const Text(
                        '''
DottedBorder(
  borderType: BorderType.RRect,
  radius: Radius.circular(12),
  padding: EdgeInsets.all(6),
  color: Colors.blue,
  strokeWidth: 2,
  dashPattern: [8, 4],
  child: Container(
    height: 120,
    width: 250,
    color: Colors.blue.shade50,
    child: Center(
      child: Text('Dotted Border Example'),
    ),
  ),
)''',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
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

  @override
  PackageIntegrationViewModel viewModelBuilder(BuildContext context) {
    return PackageIntegrationViewModel();
  }
}
