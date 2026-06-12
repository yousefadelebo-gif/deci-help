/// Decision Companion - Manage Users Screen
/// Admin view for user account management

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_tokens.dart';
import '../../utils/export_helpers.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/app_cards.dart';
import '../../widgets/app_text_field.dart';
import '../../services/api_service.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  final _searchController = TextEditingController();
  String _selectedFilter = 'All';
  String _selectedSort = 'Recent';

  List<_UserData> _users = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await ApiService.getAdminUsers();
      if (response.isSuccess && response.data != null) {
        final List<dynamic> usersJson = response.data['users'] ?? [];
        setState(() {
          _users = usersJson.map((json) => _UserData.fromJson(json)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response.error ?? 'Failed to load users';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: 'Manage Users',
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded),
            onPressed: () => _showExportDialog(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          color: AppColors.error, size: 48),
                      const SizedBox(height: AppSpacing.md),
                      Text(_error!, style: AppTypography.bodyMedium),
                      const SizedBox(height: AppSpacing.md),
                      ElevatedButton(
                        onPressed: _loadUsers,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Search and Filters
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.screenPadding),
                      color: AppColors.surface,
                      child: Column(
                        children: [
                          AppTextField(
                            controller: _searchController,
                            hint: 'Search users...',
                            prefixIcon: const Icon(Icons.search_rounded),
                            onChanged: (value) => setState(() {}),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Row(
                            children: [
                              Expanded(
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: [
                                      'All',
                                      'Active',
                                      'Inactive',
                                      'Suspended'
                                    ].map((filter) {
                                      final isSelected =
                                          _selectedFilter == filter;
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                            right: AppSpacing.xs),
                                        child: FilterChip(
                                          label: Text(filter),
                                          selected: isSelected,
                                          onSelected: (selected) {
                                            setState(
                                                () => _selectedFilter = filter);
                                          },
                                          backgroundColor: AppColors.background,
                                          selectedColor:
                                              AppColors.primarySurface,
                                          labelStyle:
                                              AppTypography.labelSmall.copyWith(
                                            color: isSelected
                                                ? AppColors.primary
                                                : AppColors.textSecondary,
                                          ),
                                          checkmarkColor: AppColors.primary,
                                          showCheckmark: false,
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.sort_rounded,
                                    color: AppColors.textSecondary),
                                onSelected: (value) =>
                                    setState(() => _selectedSort = value),
                                itemBuilder: (context) => [
                                  _buildSortMenuItem('Recent', 'Recent'),
                                  _buildSortMenuItem('Name A-Z', 'Name A-Z'),
                                  _buildSortMenuItem(
                                      'Most Active', 'Most Active'),
                                  _buildSortMenuItem('Oldest', 'Oldest'),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Stats Summary
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.screenPadding),
                      child: Row(
                        children: [
                          _buildStatBadge(
                              '${_users.length}', 'Total', AppColors.primary),
                          const SizedBox(width: AppSpacing.sm),
                          _buildStatBadge(
                            '${_users.where((u) => u.status == 'Active').length}',
                            'Active',
                            AppColors.success,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          _buildStatBadge(
                            '${_users.where((u) => u.status == 'Suspended').length}',
                            'Suspended',
                            AppColors.error,
                          ),
                        ],
                      ),
                    ),

                    // User List
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _loadUsers,
                        child: _filteredUsers.isEmpty
                            ? Center(
                                child: Text(
                                  'No users found',
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.screenPadding),
                                itemCount: _filteredUsers.length,
                                itemBuilder: (context, index) {
                                  final user = _filteredUsers[index];
                                  return _buildUserCard(user);
                                },
                              ),
                      ),
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddUserDialog(),
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Add User'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  List<_UserData> get _filteredUsers {
    var filtered = _users.where((user) {
      if (_selectedFilter != 'All' && user.status != _selectedFilter) {
        return false;
      }
      if (_searchController.text.isNotEmpty) {
        final query = _searchController.text.toLowerCase();
        return user.name.toLowerCase().contains(query) ||
            user.email.toLowerCase().contains(query);
      }
      return true;
    }).toList();

    return filtered;
  }

  Widget _buildUserCard(_UserData user) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        onTap: () => _showUserDetailsSheet(user),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primarySurface,
              child: Text(
                user.avatar,
                style: AppTypography.h4.copyWith(color: AppColors.primary),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(user.name, style: AppTypography.labelLarge),
                      const SizedBox(width: AppSpacing.xs),
                      _buildStatusBadge(user.status),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    user.email,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    '${user.decisions} decisions • Active ${user.lastActive}',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
              onSelected: (value) => _handleUserAction(value, user),
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'view', child: Text('View Details')),
                const PopupMenuItem(value: 'edit', child: Text('Edit User')),
                PopupMenuItem(
                  value: user.status == 'Suspended' ? 'activate' : 'suspend',
                  child:
                      Text(user.status == 'Suspended' ? 'Activate' : 'Suspend'),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child:
                      Text('Delete', style: TextStyle(color: AppColors.error)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'Active':
        color = AppColors.success;
        break;
      case 'Inactive':
        color = AppColors.warning;
        break;
      case 'Suspended':
        color = AppColors.error;
        break;
      default:
        color = AppColors.textTertiary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Text(
        status,
        style: AppTypography.labelSmall.copyWith(
          color: color,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildStatBadge(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: AppTypography.labelLarge.copyWith(color: color),
          ),
          const SizedBox(width: AppSpacing.xxs),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(color: color),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _buildSortMenuItem(String value, String label) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          if (_selectedSort == value)
            const Icon(Icons.check, size: 16, color: AppColors.primary)
          else
            const SizedBox(width: 16),
          const SizedBox(width: AppSpacing.xs),
          Text(label),
        ],
      ),
    );
  }

  void _showUserDetailsSheet(_UserData user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusXl),
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: AppColors.primarySurface,
                      child: Text(
                        user.avatar,
                        style:
                            AppTypography.h2.copyWith(color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(user.name, style: AppTypography.h3),
                    Text(
                      user.email,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _buildStatusBadge(user.status),
                    const SizedBox(height: AppSpacing.xl),
                    _buildDetailRow('Joined', user.joinDate),
                    _buildDetailRow('Last Active', user.lastActive),
                    _buildDetailRow('Total Decisions', '${user.decisions}'),
                    _buildDetailRow('Account Type', 'Premium'),
                    const SizedBox(height: AppSpacing.xl),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              Navigator.pop(context);
                              await Clipboard.setData(
                                ClipboardData(text: user.email),
                              );
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Email copied: ${user.email}',
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.email_rounded),
                            label: const Text('Email'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.sm,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _showEditUserDialog(user);
                            },
                            icon: const Icon(Icons.edit_rounded),
                            label: const Text('Edit'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.sm,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Text(value, style: AppTypography.labelMedium),
        ],
      ),
    );
  }

  void _handleUserAction(String action, _UserData user) {
    switch (action) {
      case 'view':
        _showUserDetailsSheet(user);
        break;
      case 'delete':
        _showDeleteConfirmation(user);
        break;
      case 'edit':
        _showEditUserDialog(user);
        break;
      case 'suspend':
        _updateUserStatus(user, 'Suspended');
        break;
      case 'activate':
        _updateUserStatus(user, 'Active');
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$action action for ${user.name}')),
        );
    }
  }

  void _updateUserStatus(_UserData user, String status) {
    setState(() {
      final index = _users.indexWhere((u) => u.id == user.id);
      if (index != -1) {
        _users[index] = _UserData(
          id: user.id,
          name: user.name,
          email: user.email,
          avatar: user.avatar,
          status: status,
          decisions: user.decisions,
          joinDate: user.joinDate,
          lastActive: user.lastActive,
          isStaff: user.isStaff,
          isVerified: user.isVerified,
        );
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${user.name} marked as $status')),
    );
  }

  void _showEditUserDialog(_UserData user) {
    final nameController = TextEditingController(text: user.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit User'),
        content: AppTextField(
          controller: nameController,
          label: 'Display Name',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              setState(() {
                final index = _users.indexWhere((u) => u.id == user.id);
                if (index != -1) {
                  _users[index] = _UserData(
                    id: user.id,
                    name: name,
                    email: user.email,
                    avatar: name.isNotEmpty ? name[0].toUpperCase() : user.avatar,
                    status: user.status,
                    decisions: user.decisions,
                    joinDate: user.joinDate,
                    lastActive: user.lastActive,
                    isStaff: user.isStaff,
                    isVerified: user.isVerified,
                  );
                }
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('User updated')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(_UserData user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User?'),
        content: Text(
            'Are you sure you want to delete ${user.name}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _users.removeWhere((u) => u.id == user.id));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${user.name} removed from list')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Users'),
        content: const Text('Choose export format:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _exportUsers(asCsv: true);
            },
            child: const Text('CSV'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _exportUsers(asCsv: false);
            },
            child: const Text('JSON'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportUsers({required bool asCsv}) async {
    final rows = _users
        .map(
          (u) => {
            'id': u.id,
            'name': u.name,
            'email': u.email,
            'status': u.status,
            'decisions': u.decisions,
            'join_date': u.joinDate,
            'last_active': u.lastActive,
          },
        )
        .toList();

    if (asCsv) {
      await ExportHelpers.copyCsvToClipboard(rows);
    } else {
      await ExportHelpers.copyJsonToClipboard(rows);
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Exported ${_users.length} users as ${asCsv ? 'CSV' : 'JSON'} to clipboard',
        ),
      ),
    );
  }

  void _showAddUserDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              final email = emailController.text.trim();
              if (name.isEmpty || email.isEmpty) return;
              setState(() {
                _users.insert(
                  0,
                  _UserData(
                    id: DateTime.now().millisecondsSinceEpoch,
                    name: name,
                    email: email,
                    avatar: name[0].toUpperCase(),
                    status: 'Active',
                    decisions: 0,
                    joinDate: 'Today',
                    lastActive: 'Never',
                  ),
                );
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Added $name to user list')),
              );
            },
            child: const Text('Invite'),
          ),
        ],
      ),
    );
  }
}

class _UserData {
  final int id;
  final String name;
  final String email;
  final String avatar;
  final String status;
  final int decisions;
  final String joinDate;
  final String lastActive;
  final bool isStaff;
  final bool isVerified;

  _UserData({
    required this.id,
    required this.name,
    required this.email,
    required this.avatar,
    required this.status,
    required this.decisions,
    required this.joinDate,
    required this.lastActive,
    this.isStaff = false,
    this.isVerified = false,
  });

  factory _UserData.fromJson(Map<String, dynamic> json) {
    return _UserData(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Unknown',
      email: json['email'] ?? '',
      avatar: json['avatar'] ?? '',
      status: json['status'] ?? 'Active',
      decisions: json['decisions'] ?? 0,
      joinDate: json['join_date'] ?? '',
      lastActive: json['last_active'] ?? 'Never',
      isStaff: json['is_staff'] ?? false,
      isVerified: json['is_verified'] ?? false,
    );
  }
}
