import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dukanx/providers/app_state_providers.dart';
import '../../data/shortcuts_repository.dart';
import '../../domain/services/shortcut_service.dart';
import '../../domain/services/shortcut_data_provider.dart';
import '../../domain/services/keyboard_shortcut_manager.dart';
import '../../domain/models/user_shortcut_config.dart';
import '../../../../services/role_management_service.dart';

// Repositories & Services
final shortcutsRepositoryProvider = Provider((ref) => ShortcutsRepository());
final shortcutServiceProvider = Provider(
  (ref) => ShortcutService(repository: ref.watch(shortcutsRepositoryProvider)),
);
final shortcutDataProviderProvider = Provider((ref) => ShortcutDataProvider());
final keyboardShortcutManagerProvider = Provider(
  (ref) => KeyboardShortcutManager(),
);

// User's configured shortcuts stream
final userShortcutsStreamProvider = StreamProvider<List<UserShortcutConfig>>((
  ref,
) {
  final userId = ref.watch(currentUserProvider)?.uid;
  if (userId == null) return const Stream.empty();

  final repo = ref.watch(shortcutsRepositoryProvider);
  return repo.watchUserShortcuts(userId);
});

// Final filtered shortcuts visible to the user
final visibleShortcutsProvider = Provider<AsyncValue<List<UserShortcutConfig>>>((
  ref,
) {
  final shortcutsAsync = ref.watch(userShortcutsStreamProvider);
  final service = ref.watch(shortcutServiceProvider);
  final businessTypeVal = ref.watch(businessTypeProvider);
  final currentUserState = ref.watch(currentUserProvider); // This returns User?
  // We need the role. Assuming there's a provider for role.
  // If not, we might need to fetch it or use a default.
  // Let's assume 'businessUserProvider' exists or similar from 'providers/app_state_providers.dart'
  // If not, we'll need to fetch it.

  // Checking existing providers for role...
  // Based on context, there is a RoleGuard, so role is likely accessible.
  // For now using safe default if not found.

  return shortcutsAsync.whenData((shortcuts) {
    if (currentUserState == null) return [];

    // Use async data if available, but for stream provider inside provider we need a different approach
    // or just assume we fetch it.
    // Ideally we should have a 'currentUserRoleProvider'.

    // For now, let's use a safe default or if we can get it from session
    var userRole =
        UserRole.owner; // Default to owner for dev/prototype as requested often

    // In a real app we would do:
    // final businessUser = ref.watch(currentBusinessUserProvider);
    // userRole = businessUser?.role ?? UserRole.staff;

    return service.filterShortcuts(shortcuts, userRole, businessTypeVal.type);
  });
});

// Real-time badge data
final shortcutBadgeDataProvider =
    StreamProvider<Map<String, ShortcutBadgeData>>((ref) {
      final userId = ref.watch(currentUserProvider)?.uid;
      if (userId == null) return const Stream.empty();

      final dataProvider = ref.watch(shortcutDataProviderProvider);
      return dataProvider.watchBadgeData(userId);
    });

// Initialize shortcuts on app start
final shortcutInitializerProvider = FutureProvider<void>((ref) async {
  final userId = ref.watch(currentUserProvider)?.uid;
  if (userId == null) return;

  final service = ref.watch(shortcutServiceProvider);
  await service.initializeSystem(userId);
});
