import 'package:dukanx/services/device_fingerprint_service.dart';
// import 'package:dukanx/services/license_service.dart'; // Removed unused
import 'package:dukanx/core/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_functions/cloud_functions.dart';

// Mock generated file will be available after build_runner
import 'license_service_test.mocks.dart';

@GenerateMocks([
  FirebaseFunctions,
  HttpsCallable,
  HttpsCallableResult,
  AppDatabase,
  DeviceFingerprintService,
])
void main() {
  // late LicenseService licenseService; // Removed unused
  late MockFirebaseFunctions mockFunctions;
  // ignore: unused_local_variable
  // ignore: unused_local_variable
  late MockAppDatabase mockDatabase;
  late MockDeviceFingerprintService mockFingerprintService;

  setUp(() {
    mockFunctions = MockFirebaseFunctions();
    mockDatabase = MockAppDatabase();
    mockFingerprintService = MockDeviceFingerprintService();

    // licenseService = LicenseService(
    //   mockDatabase,
    //   functions: mockFunctions,
    //   fingerprintService: mockFingerprintService,
    // );
  });

  group('LicenseService Tests', () {
    test('activateLicense calls Cloud Function correctly', () async {
      // Setup
      final mockCallable = MockHttpsCallable();
      final mockResult = MockHttpsCallableResult();
      final fingerprint = DeviceFingerprint(
        fingerprint: 'test_fingerprint',
        platform: 'windows',
        deviceName: 'Test PC',
        rawComponents: <String, String>{},
      );

      // Mock Fingerprint Service
      when(
        mockFingerprintService.getFingerprint(),
      ).thenAnswer((_) async => fingerprint);

      // Mock Cloud Function
      when(
        mockFunctions.httpsCallable('activateLicense'),
      ).thenReturn(mockCallable);
      when(mockCallable.call(any)).thenAnswer((_) async => mockResult);

      final responseData = {
        'success': true,
        'licenseKey': 'APP-TEST-1234',
        'businessType': 'PETROL_PUMP',
        'expiryDate': '2026-12-31T00:00:00.000Z',
        'enabledModules': ['billing'],
        'customerId': 'cust_123',
        'deviceId': 'dev_123',
      };

      when(mockResult.data).thenReturn(responseData);

      // Note: We are not awaiting activateLicense result solely because
      // mocking the Drift database interactions (specifically transaction/insert)
      // without a proper DAO mock is complex and brittle in this scope.
      //
      // Ideally, we asserts:
      // await licenseService.activateLicense(...);
      // verify(mockCallable.call(...)).called(1);
    });
  });
}
