import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'Functionalities/custom_app_bar.dart';

import 'dart:developer';

class AdminPanelPage extends StatefulWidget {
  const AdminPanelPage({super.key});

  @override
  AdminPanelPageState createState() => AdminPanelPageState();
}

class AdminPanelPageState extends State<AdminPanelPage> {
  final TextEditingController _searchController = TextEditingController();
  List<DocumentSnapshot> _users = [];
  List<DocumentSnapshot> _filteredUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() {
      _isLoading = true;
    });
    try {
      QuerySnapshot<Map<String, dynamic>> querySnapshot =
          await FirebaseFirestore.instance.collection('users').get();

      setState(() {
        _users = querySnapshot.docs;
        _filteredUsers = _users;
      });
    } catch (e) {
      log("Error fetching users: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleAdminStatus(String userId, bool isAdmin) async {
    setState(() {
      _isLoading = true; // Show loading while updating
    });

    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'role': isAdmin ? 'admin' : 'user',
      });
      await _fetchUsers(); // Refresh the user list after update
    } catch (e) {
      log("Error updating user role: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterUsers(String query) {
    setState(() {
      _filteredUsers = _users.where((userDoc) {
        final data = userDoc.data()
            as Map<String, dynamic>?; // Cast to Map<String, dynamic>
        if (data == null) return false;
        final firstName = data['firstName']?.toLowerCase() ?? '';
        final lastName = data['lastName']?.toLowerCase() ?? '';
        final queryLowerCase = query.toLowerCase();

        return firstName.contains(queryLowerCase) ||
            lastName.contains(queryLowerCase);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Admin Panel',
        gradientColors: [Colors.deepOrangeAccent, Colors.redAccent],
        height: 100.0,
        helpMessage: 'This is where admins can perform administrative tasks.',
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator()) // <-- Loading indicator
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: _filterUsers,
                    decoration: const InputDecoration(
                      labelText: 'Search by First or Last Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _filteredUsers.length,
                      itemBuilder: (context, index) {
                        final userDoc = _filteredUsers[index];
                        final data = userDoc.data() as Map<String, dynamic>?;
                        if (data == null) return const SizedBox.shrink();

                        final isAdmin = data['role'] == 'admin';

                        return Card(
                          elevation: 5.0,
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          child: ListTile(
                            title: Text(
                                '${data['firstName']} ${data['lastName']}'),
                            subtitle:
                                Text('Role: ${isAdmin ? 'Admin' : 'User'}'),
                            trailing: IconButton(
                              icon: Icon(
                                isAdmin
                                    ? Icons.remove_circle
                                    : Icons.add_circle,
                                color: Colors.blue,
                              ),
                              onPressed: () =>
                                  _toggleAdminStatus(userDoc.id, !isAdmin),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
