import 'package:dukanx/guards/license_guard.dart';
import 'package:dukanx/models/business_type.dart';
import 'package:dukanx/services/license_service.dart';
import 'package:dukanx/core/di/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/mockito.dart';

// Manual Mock to avoid code Gen dependencies in this isolated test
class MockLicenseService extends Mock implements LicenseService {
  LicenseValidationResult? _mockValidationResult;
  LicenseActivationResult? _mockActivationResult;

  void setValidationResult(LicenseValidationResult result) {
    _mockValidationResult = result;
  }

  void setActivationResult(LicenseActivationResult result) {
    _mockActivationResult = result;
  }

  @override
  Future<LicenseValidationResult> validateLicense({
    required BusinessType requiredBusinessType,
  }) async {
    // Determine result based on whether we were activated or not
    // Simple state machine for test:
    // 1. Initial: notFound
    // 2. Activates -> Success
    // 3. Next Check -> valid
    if (_mockValidationResult != null) return Future.value(_mockValidationResult!);
    
    return Future.value(LicenseValidationResult.invalid(
      LicenseStatus.notFound,
      'No license found',
    ));
  }

  @override
  Future<LicenseActivationResult> activateLicense({
    required String licenseKey,
    required BusinessType businessType,
  }) async {
    // If successful, update the next validation result to be valid
    if (_mockActivationResult?.isSuccess ?? true) {
       _mockValidationResult = LicenseValidationResult.valid(
        license: LicenseCacheEntity(
           id: 'mock_id',
           licenseKey: licenseKey,
           businessType: businessType.name,
           customerId: 'cust_1',
           enabledModulesJson: '["billing"]',
           issueDate: DateTime.now(),
           expiryDate: DateTime.now().add(const Duration(days: 365)),
           deviceFingerprint: 'mock_fp',
           deviceId: 'dev_1',
           lastValidatedAt: DateTime.now(),
           validationToken: 'tok',
           tokenSignature: 'sig',
           createdAt: DateTime.now(),
           updatedAt: DateTime.now(),
        ),
        enabledModules: ['billing'],
      );
      return Future.value(_mockActivationResult ?? LicenseActivationResult.success(_mockValidationResult!.license!));
    }
    return Future.value(_mockActivationResult!);
  }
}

// Since LicenseCacheEntity is needed for the mock, we might need to import it
// But it's part of drift database. Tests usually shouldn't depend on generated drift files if avoidable.
// However, the LicenseService returns it.
// To avoid complex mocking of Drift entities, we can use a simpler approach or just rely on 'dynamic' behavior if possible, 
// BUT Dart is typed.
// The LicenseCacheEntity is likely generated.
// If we can't easily instantiate LicenseCacheEntity without drift imports, we might strike a compile error.
// Let's verify if we can import LicenseCacheEntity.
// It's in core/database/app_database.dart usually.

// We need to check if LicenseCacheEntity is importable
import 'package:dukanx/core/database/app_database.dart'; 
// (Assuming this file exports it, which it usually does in Drift)

void main() {
  setUp(() async {
    await sl.reset();
  });

  testWidgets('LicenseGuard Activation Flow', (WidgetTester tester) async {
    // 1. Setup Mock
    final mockService = MockLicenseService();
    // Initial state: No License
    mockService.setValidationResult(LicenseValidationResult.invalid(
      LicenseStatus.notFound,
      'No license found',
    ));

    // Register Mock
    GetIt.instance.registerSingleton<LicenseService>(mockService);

    // 2. Pump Widget (LicenseGuard wrapping a simple child)
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: LicenseGuard(
            businessType: BusinessType.petrolPump,
            child: const Scaffold(
              body: Center(child: Text('Protected Content')),
            ),
          ),
        ),
      ),
    );

    // 3. Verify Locking Screen
    await tester.pumpAndSettle(); // Wait for async validation
    expect(find.text('License Required'), findsOneWidget);
    expect(find.text('Protected Content'), findsNothing);

    // 4. Tap "Enter License Key"
    await tester.tap(find.text('Enter License Key'));
    await tester.pumpAndSettle();

    // 5. Verify Dialog
    expect(find.text('Enter License Key'), findsNWidgets(2)); // Title and Button label (or label text)

    // 6. Enter Key
    await tester.enterText(find.byType(TextField), 'APP-PETROL-DESK-TEST1-2026');
    await tester.pump();

    // 7. Tap Activate
    await tester.tap(find.text('Activate'));
    
    // 8. Wait for "Network Call" and Retry logic
    // The Guard calls _retry() on success, which calls validateLicense again.
    // Our Mock state machine updates validateLicense to return 'valid' after activation.
    await tester.pumpAndSettle();

    // 9. Verify Success -> Should show Protected Content
    expect(find.text('Protected Content'), findsOneWidget);
    expect(find.text('License Required'), findsNothing);
  });
}
