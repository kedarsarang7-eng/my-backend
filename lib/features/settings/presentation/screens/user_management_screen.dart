// ============================================================================
// USER MANAGEMENT SCREEN (RBAC UI)
// ============================================================================
// Manage shop staff and their roles (Admin, Manager, Cashier).
// ============================================================================

import 'package:flutter/material.dart';

import '../../../../core/theme/futuristic_colors.dart';
import '../../../../widgets/desktop/desktop_content_container.dart';

// Mock User Model for UI Prototype
class ShopUser {
  final String id;
  final String name;
  final String role; // 'Admin', 'Manager', 'Cashier'
  final bool isActive;
  final String lastActive;

  ShopUser({
    required this.id,
    required this.name,
    required this.role,
    required this.isActive,
    required this.lastActive,
  });
}

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  // Mock Data
  final List<ShopUser> _users = [
    ShopUser(
        id: 'u1',
        name: 'Sarang (Owner)',
        role: 'Admin',
        isActive: true,
        lastActive: 'Now'),
    ShopUser(
        id: 'u2',
        name: 'Ramesh Kumar',
        role: 'Manager',
        isActive: true,
        lastActive: '2h ago'),
    ShopUser(
        id: 'u3',
        name: 'Suresh Bill',
        role: 'Cashier',
        isActive: true,
        lastActive: '5m ago'),
    ShopUser(
        id: 'u4',
        name: 'New Staff',
        role: 'Cashier',
        isActive: false,
        lastActive: 'Never'),
  ];

  @override
  Widget build(BuildContext context) {
    return DesktopContentContainer(
      title: "Team & Access",
      subtitle: "Manage roles and permissions",
      actions: [
        DesktopIconButton(
          icon: Icons.person_add,
          tooltip: 'Add Staff',
          onPressed: () => _showAddUserDialog(),
        )
      ],
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryStats(),
            const SizedBox(height: 24),
            Expanded(child: _buildUserList()),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryStats() {
    return Row(
      children: [
        _buildStatCard("Total Staff", "${_users.length}", Icons.people_outline,
            Colors.blue),
        const SizedBox(width: 16),
        _buildStatCard("Active Now", "2", Icons.circle, Colors.green),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: FuturisticColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white)),
              Text(title,
                  style: TextStyle(
                      fontSize: 12, color: FuturisticColors.textSecondary)),
            ],
          )
        ],
      ),
    );
  }

  void _showAddUserDialog() {
    final nameController = TextEditingController();
    String selectedRole = 'Cashier';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: FuturisticColors.surface,
        title: Text('Add New Staff',
            style: TextStyle(color: FuturisticColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Name',
                labelStyle: TextStyle(color: FuturisticColors.textSecondary),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedRole,
              dropdownColor: FuturisticColors.surface,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Role',
                labelStyle: TextStyle(color: FuturisticColors.textSecondary),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              items: ['Admin', 'Manager', 'Cashier']
                  .map((role) => DropdownMenuItem(
                        value: role,
                        child: Text(role),
                      ))
                  .toList(),
              onChanged: (val) {
                if (val != null) selectedRole = val;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: TextStyle(color: FuturisticColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                setState(() {
                  _users.add(ShopUser(
                    id: 'u${_users.length + 1}',
                    name: nameController.text.trim(),
                    role: selectedRole,
                    isActive: true,
                    lastActive: 'Now',
                  ));
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          '${nameController.text.trim()} added as $selectedRole')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: FuturisticColors.primary),
            child: const Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildUserList() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 400,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.8,
      ),
      itemCount: _users.length,
      itemBuilder: (context, index) {
        final user = _users[index];
        return _buildUserCard(user);
      },
    );
  }

  Widget _buildUserCard(ShopUser user) {
    return Container(
      // Replaced GlassContainer with standard Container/ModernCard style
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: FuturisticColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: _getRoleColor(user.role).withOpacity(0.2),
                child: Text(
                  user.name[0],
                  style: TextStyle(
                      color: _getRoleColor(user.role),
                      fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: TextStyle(
                          // Removed GoogleFonts
                          color: FuturisticColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 16),
                    ),
                    Text(
                      user.role,
                      style: TextStyle(
                          // Removed GoogleFonts
                          color: _getRoleColor(user.role),
                          fontSize: 12),
                    ),
                  ],
                ),
              ),
              Switch(
                value: user.isActive,
                onChanged: (val) {
                  setState(() {
                    // Update mock data
                    final index = _users.indexWhere((u) => u.id == user.id);
                    if (index != -1) {
                      _users[index] = ShopUser(
                        id: user.id,
                        name: user.name,
                        role: user.role,
                        isActive: val,
                        lastActive: user.lastActive,
                      );
                    }
                  });
                },
                activeColor: FuturisticColors.success,
              )
            ],
          ),
          const Spacer(),
          const Divider(color: Colors.white10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Last active: ${user.lastActive}",
                style: TextStyle(
                    // Removed GoogleFonts
                    color: FuturisticColors.textSecondary,
                    fontSize: 12),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined,
                    size: 18, color: FuturisticColors.textSecondary),
                onPressed: () {},
                tooltip: "Edit Permissions",
              )
            ],
          )
        ],
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return FuturisticColors.error; // Red for high power
      case 'manager':
        return FuturisticColors.accent1; // Cyan
      default:
        return FuturisticColors.success; // Green for standard
    }
  }
}
