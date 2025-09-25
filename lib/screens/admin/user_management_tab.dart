import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/firestore_service.dart';

class UserManagementTab extends StatefulWidget {
  const UserManagementTab({super.key});

  @override
  State<UserManagementTab> createState() => _UserManagementTabState();
}

class _UserManagementTabState extends State<UserManagementTab>
    with TickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchUsersController = TextEditingController();
  
  late AnimationController _listController;
  String _userSearchQuery = '';

  // Green gradient colors
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color secondaryGreen = Color(0xFF4CAF50);
  static const Color lightGreen = Color(0xFF81C784);
  static const Color darkGreen = Color(0xFF1B5E20);

  @override
  void initState() {
    super.initState();
    _listController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _searchUsersController.addListener(() {
      setState(() {
        _userSearchQuery = _searchUsersController.text;
      });
    });
    
    _listController.forward();
  }

  @override
  void dispose() {
    _listController.dispose();
    _searchUsersController.dispose();
    super.dispose();
  }

  Future<void> _deleteUser(String userId, String userName) async {
    final bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.delete, color: Colors.red, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Delete User'),
          ],
        ),
        content: Text('Are you sure you want to delete user "$userName"? This will also remove them as a representative if applicable.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      try {
        await _firestoreService.deleteUser(userId);
        _showSuccessSnackBar('User "$userName" deleted successfully!');
      } catch (e) {
        _showErrorSnackBar('Failed to delete user');
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: secondaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -0.3),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: _listController,
              curve: Curves.easeOutBack,
            )),
            child: _buildHeader(),
          ),
          const SizedBox(height: 24),
          SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.3),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: _listController,
              curve: Interval(0.2, 1.0, curve: Curves.easeOutBack),
            )),
            child: _buildUsersList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFE8F5E8),
            Color(0xFFF1F8E9),
            Color(0xFFE8F5E8),
          ],
          stops: [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: lightGreen.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryGreen.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [darkGreen, primaryGreen],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: primaryGreen.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.people_alt,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'User Management',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: darkGreen,
                      ),
                    ),
                    Text(
                      'Manage all users and roles',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: primaryGreen.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: primaryGreen.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextFormField(
              controller: _searchUsersController,
              decoration: InputDecoration(
                labelText: 'Search Users',
                labelStyle: TextStyle(color: primaryGreen.withOpacity(0.7)),
                prefixIcon: Icon(Icons.search, color: primaryGreen),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: lightGreen.withOpacity(0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: lightGreen.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: primaryGreen, width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _firestoreService.getAllUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primaryGreen),
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState('No users available', Icons.people_outline);
        }

        final users = snapshot.data!;
        final filteredUsers = users.where((user) {
          final nameLower = (user['name'] ?? '').toLowerCase();
          final emailLower = (user['email'] ?? '').toLowerCase();
          final roleLower = (user['role'] ?? '').toLowerCase();
          final queryLower = _userSearchQuery.toLowerCase();
          return nameLower.contains(queryLower) ||
              emailLower.contains(queryLower) ||
              roleLower.contains(queryLower);
        }).toList();

        if (filteredUsers.isEmpty) {
          return _buildEmptyState('No matching users found', Icons.search_off);
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filteredUsers.length,
          itemBuilder: (context, index) {
            final user = filteredUsers[index];
            return _buildUserCard(user, index);
          },
        );
      },
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user, int index) {
    final role = user['role'] ?? 'user';
    final roleColor = _getRoleColor(role);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Color(0xFFFAFDFA),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: lightGreen.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryGreen.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        roleColor.withOpacity(0.1),
                        roleColor.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: roleColor.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    _getRoleIcon(role),
                    color: roleColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user['name'] ?? 'N/A',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: darkGreen,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        user['email'] ?? 'N/A',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: primaryGreen.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        roleColor.withOpacity(0.1),
                        roleColor.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: roleColor.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    role.toUpperCase(),
                    style: TextStyle(
                      color: roleColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.red.withOpacity(0.1),
                        Colors.red.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.red.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      _deleteUser(user['id'], user['name'] ?? 'Unknown User');
                    },
                    constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.red;
      case 'representative':
        return primaryGreen;
      default:
        return Colors.grey;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Icons.admin_panel_settings;
      case 'representative':
        return Icons.person_pin;
      default:
        return Icons.person;
    }
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  lightGreen.withOpacity(0.1),
                  primaryGreen.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              icon,
              size: 64,
              color: primaryGreen.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: primaryGreen.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
