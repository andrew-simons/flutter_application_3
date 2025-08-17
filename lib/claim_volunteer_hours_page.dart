import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'custom_app_bar.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
//import 'package:firebase_storage/firebase_storage.dart';
import 'package:my_new_project/loading_button.dart';

class ClaimVolunteerHoursPage extends StatefulWidget {
  const ClaimVolunteerHoursPage({super.key});

  @override
  ClaimVolunteerHoursPageState createState() => ClaimVolunteerHoursPageState();
}

class ClaimVolunteerHoursPageState extends State<ClaimVolunteerHoursPage> {
  late String userId;
  List<Map<String, dynamic>> eventsParticipated = [];
  List<Map<String, dynamic>> signedUpEvents = [];
  int volunteerHours = 0;
  bool _isLoading = false; // button spinner
  bool _isPageLoading = true; // page loading spinner

  @override
  void initState() {
    super.initState();
    _getUserIdAndFetchEvents();
  }

  Future<void> _getUserIdAndFetchEvents() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        userId = user.uid;
        await _fetchUserEvents();
        if (mounted) {
          setState(() {
            _isPageLoading = false;
          });
        }
      } else {
        Fluttertoast.showToast(
          msg: "No user is currently signed in.",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
        if (mounted) {
          setState(() {
            _isPageLoading = false;
          });
        }
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Failed to get user ID.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      if (mounted) {
        setState(() {
          _isPageLoading = false;
        });
      }
    }
  }

  Future<void> _fetchUserEvents() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      final userData = userDoc.data();
      final participatedEvents =
          List<String>.from(userData?['eventsParticipatedList'] ?? []);
      final signedUpEventsList =
          List<String>.from(userData?['signedUpEvents'] ?? []);

      final eventDocs = await Future.wait(participatedEvents.map((eventId) =>
          FirebaseFirestore.instance.collection('events').doc(eventId).get()));
      final signedUpEventDocs = await Future.wait(signedUpEventsList.map(
          (eventId) => FirebaseFirestore.instance
              .collection('events')
              .doc(eventId)
              .get()));

      setState(() {
        eventsParticipated = eventDocs
            .where((doc) => doc.exists)
            .map((doc) => {
                  'id': doc.id,
                  'name': doc['eventLocation'],
                  'date': (doc['eventDate'] as Timestamp).toDate(),
                })
            .toList();
        signedUpEvents = signedUpEventDocs
            .where((doc) => doc.exists)
            .map((doc) => {
                  'id': doc.id,
                  'name': doc['eventLocation'],
                  'date': (doc['eventDate'] as Timestamp).toDate(),
                })
            .toList();
        volunteerHours = 2 * eventsParticipated.length;
      });
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Failed to fetch events.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }

  Future<void> _claimHours() async {
    // Check if the user has participated in any events
    if (eventsParticipated.isEmpty) {
      Fluttertoast.showToast(
        msg:
            "You need to participate in at least one event to claim your volunteer hours.",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      return; // Exit the method early if no events are participated in
    }

    setState(() {
      _isLoading = true; // Set loading state to true
    });

    try {
      final pdfFile = await generatePdf(
        userName: FirebaseAuth.instance.currentUser?.displayName ?? '',
        volunteerHours: volunteerHours,
        eventsParticipated: eventsParticipated,
      );

      final response = await http.post(
        Uri.parse(
            'https://us-central1-childrensmusicbrigade3.cloudfunctions.net/sendVolunteerHoursEmail'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'recipient':
              FirebaseAuth.instance.currentUser?.email ?? 'default@example.com',
          'subject': 'Volunteer Hours Certificate',
          'body': 'Attached is your volunteer hours certificate.',
          'attachment': base64Encode(
              await pdfFile.readAsBytes()), // Ensure this is base64 encoded
        }),
      );

      if (response.statusCode == 200) {
        Fluttertoast.showToast(
          msg: "Email sent successfully",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      } else {
        Fluttertoast.showToast(
          msg: "Failed to send email: ${response.body}",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "An error occurred: $e",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    } finally {
      setState(() {
        _isLoading = false; // Reset loading state
      });
    }
  }

  Future<File> generatePdf({
    required int volunteerHours,
    required List<Map<String, dynamic>> eventsParticipated,
    required String userName,
  }) async {
    // Get the current user's UID
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      throw Exception("User not logged in");
    }

    // Fetch the user's name from Firestore
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    final userName =
        userDoc.data()?['firstName'] + ' ' + userDoc.data()?['lastName'] ??
            'Unknown User';

    final pdf = pw.Document();

    // Load logo and signature images
    final logo = pw.MemoryImage(
      (await rootBundle.load('images/CmbLogo.png')).buffer.asUint8List(),
    );

    final signature = pw.MemoryImage(
      (await rootBundle.load('images/Signature.png')).buffer.asUint8List(),
    );

    // Add content to the PDF
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Header with logo
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Image(logo, width: 100, height: 100),
                pw.Text(
                  "Children's Music Brigade Inc.",
                  style: pw.TextStyle(
                      fontSize: 24, fontWeight: pw.FontWeight.bold),
                ),
              ],
            ),
            pw.SizedBox(height: 30),

            // Official Message
            pw.Text(
              'To Whom It May Concern,\n\n'
              'This certificate is to certify that $userName has completed a total of $volunteerHours hours, '
              'performing in ${eventsParticipated.length} event(s) (each lasting about 2 hours) on behalf of the Children\'s Music Brigade Inc. nonprofit organization.\n\n'
              'The mission of Children\'s Music Brigade Inc. is to spread love, hope, and happiness through music by performing '
              'for elderly residents in nursing homes and children in hospitals, providing companionship, entertainment, and cognitive stimulation '
              'to make them feel valued and connected.\n\n'
              '$userName has generously and compassionately volunteered at the following event(s):',
              style: const pw.TextStyle(fontSize: 12),
            ),
            pw.SizedBox(height: 20),

            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: eventsParticipated.map((event) {
                return pw.Text(
                  '- ${event['name']} on ${DateFormat('MMM d, yyyy \'at\' h:mm a').format(event['date'])}',
                  style: const pw.TextStyle(fontSize: 9),
                );
              }).toList(),
            ),
            pw.SizedBox(height: 30),

            // Signature Section
            pw.Text('Sincerely,', style: const pw.TextStyle(fontSize: 12)),
            pw.Image(signature, width: 110, height: 50),
            pw.SizedBox(height: 5),
            pw.Text('Andrew Simons',
                style:
                    pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            pw.Text('Founder & CEO of Children\'s Music Brigade Inc.',
                style: const pw.TextStyle(fontSize: 12)),
            pw.SizedBox(height: 20),
            pw.Text('childrensmusicbrigade@gmail.com',
                style: const pw.TextStyle(fontSize: 11)),
            pw.Text('(516) 434-0034', style: const pw.TextStyle(fontSize: 11)),
          ],
        ),
      ),
    );

    // Save the PDF locally
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/volunteer_hours.pdf');
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Claim Volunteer Hours',
        gradientColors: [Colors.tealAccent, Colors.teal],
        height: 100.0,
        helpMessage:
            'With the click of a button, you will receive an email with your volunteer hours formally documented. You can only claim volunteer hours once you have performed at least one time.',
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.teal, width: 2),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'You have $volunteerHours total volunteer hours!',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Divider(
                        height: 2,
                        color: Colors.black45,
                        indent: 5,
                        endIndent: 5,
                        thickness: 3,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Events You Have Participated In:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height:
                            150, // Set a fixed height for the scrollable area
                        child: Scrollbar(
                          thumbVisibility: true, // Show scrollbar thumb
                          child: SingleChildScrollView(
                            child: ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: eventsParticipated.length,
                              itemBuilder: (context, index) {
                                final event = eventsParticipated[index];
                                return ListTile(
                                  title: Text(event['name']),
                                  subtitle: Text(
                                    DateFormat('MMM d, yyyy \'at\' h:mm a')
                                        .format(event['date']),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _isLoading
                          ? const Center(
                              child: CircularProgressIndicator(),
                            )
                          : Center(
                              child: LoadingButton(
                                isLoading: _isLoading,
                                onPressed: _claimHours,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 50, vertical: 15),
                                  textStyle: const TextStyle(fontSize: 18),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30.0),
                                  ),
                                ),
                                child: const Text(
                                  'Claim Hours',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.teal, width: 2),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Future Events You Are Signed Up For:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height:
                            150, // Set a fixed height for the scrollable area
                        child: Scrollbar(
                          child: SingleChildScrollView(
                            child: ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: signedUpEvents.length,
                              itemBuilder: (context, index) {
                                final event = signedUpEvents[index];
                                return ListTile(
                                  title: Text(
                                    event['name'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                  subtitle: Text(
                                    DateFormat('MMM d, yyyy \'at\' h:mm a')
                                        .format(event['date']),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_isPageLoading)
            Container(
              color: Colors.white.withOpacity(0.8),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
      backgroundColor: Colors.white,
    );
  }
}
