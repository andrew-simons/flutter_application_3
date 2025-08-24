import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_new_project/claim_volunteer_hours_page.dart';
import 'Functionalities/custom_app_bar.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  SettingsPageState createState() => SettingsPageState();
}

class SettingsPageState extends State<SettingsPage> {
  bool isAdmin = false;
  String? username;
  String firstName = "";
  String lastName = "";
  int eventsParticipated = 0;
  int volunteerHours = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      DocumentSnapshot<Map<String, dynamic>> userDoc = await FirebaseFirestore
          .instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data()!;
        if (mounted) {
          setState(() {
            username = user.email ?? "Username";
            firstName = data['firstName'] ?? "First Name";
            lastName = data['lastName'] ?? "Last Name";
            eventsParticipated = data.containsKey('eventsParticipatedList')
                ? (data['eventsParticipatedList'] as List).length
                : 0;
            volunteerHours = eventsParticipated * 2;
            isAdmin = data['role'] == 'admin';
          });
        }
      }
    }
  }

  Future<void> _updateUserField(String field, String newValue) async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({field: newValue});
        // Reload data to reflect the changes
        await _loadUserData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating $field: $e')),
          );
        }
      }
    }
  }

  void editFirstName() {
    _showEditDialog("First Name", firstName, (newValue) {
      _updateUserField('firstName', newValue);
    });
  }

  void editLastName() {
    _showEditDialog("Last Name", lastName, (newValue) {
      _updateUserField('lastName', newValue);
    });
  }

  Future<void> _showEditDialog(
      String field, String currentValue, ValueChanged<String> onSave) async {
    TextEditingController controller =
        TextEditingController(text: currentValue);

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit $field'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: field,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Save'),
              onPressed: () {
                onSave(controller.text);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void toggleNotifications(bool value) {
    // Functionality to toggle notifications (not implemented yet)
  }

  void navigateToClaimVolunteerHoursPage() {
    // Implement navigation to the Claim Volunteer Hours page
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => const ClaimVolunteerHoursPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Account / Settings',
        gradientColors: [Colors.black38, Colors.black12],
        height: 100.0,
        helpMessage: 'View your account stats and toggle settings here!',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isAdmin) buildAdminBadge(),
            const SizedBox(height: 24.0),
            buildAccountInfoCard(),
            const SizedBox(height: 24.0),
            buildParticipationInfoCard(),
            const Divider(height: 32.0, thickness: 2.0),
            buildNotificationSettingsCard(),
          ],
        ),
      ),
    );
  }

  Widget buildAdminBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      decoration: BoxDecoration(
        color: Colors.red.shade100,
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: const Text(
        "Admin Account",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18.0,
          color: Colors.red,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget buildAccountInfoCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            buildAccountInfoRow("Email: ${username ?? "Username"}"),
            const SizedBox(height: 16.0),
            buildEditableField(
              label: "First Name: $firstName",
              onEdit: editFirstName,
            ),
            const SizedBox(height: 16.0),
            buildEditableField(
              label: "Last Name: $lastName",
              onEdit: editLastName,
            ),
          ],
        ),
      ),
    );
  }

  Widget buildAccountInfoRow(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 16.0,
        color: Colors.blue,
        fontWeight: FontWeight.w600,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget buildEditableField(
      {required String label, required VoidCallback onEdit}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16.0),
        ),
        IconButton(
          icon: const Icon(Icons.edit, color: Colors.blue),
          onPressed: onEdit,
        ),
      ],
    );
  }

  Widget buildParticipationInfoCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              "Events Participated: $eventsParticipated",
              style: const TextStyle(
                fontSize: 16.0,
                color: Colors.blue,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8.0),
            Text(
              "($volunteerHours Volunteer Hours)",
              style: const TextStyle(fontSize: 14.0, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: navigateToClaimVolunteerHoursPage,
              child: const Text("View Details"),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildNotificationSettingsCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Notifications",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18.0,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Receive Notifications",
                  style: TextStyle(fontSize: 16.0), // Adjusted text size
                ),
                const Text(
                  "(Coming Soon!)",
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.black54), // Adjusted text size
                ),
                Switch(
                  value: false, // Set based on current notification setting
                  onChanged: toggleNotifications,
                  activeColor: Colors.blue,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
