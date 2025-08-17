import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:my_new_project/custom_app_bar.dart';

import 'dart:developer';

import 'package:my_new_project/loading_button.dart';

class UpcomingEventsPage extends StatefulWidget {
  const UpcomingEventsPage({super.key});

  @override
  UpcomingEventsPageState createState() => UpcomingEventsPageState();
}

class UpcomingEventsPageState extends State<UpcomingEventsPage> {
  User? user;
  bool isAdmin = false;
  List<Map<String, dynamic>> events = [];
  String location = '';
  DateTime? dateTime;
  String description = '';
  String? currentEventId;
  Set<String> signedUpEvents = {};
  Map<String, bool> attendanceMap = {};
  bool hasPassed = false;
  bool _isPageLoading = true;

  final Map<String, bool> _isLoadingSignUpMap =
      {}; // Tracks loading state per event
  final Map<String, bool> _isLoadingVolunteersMap =
      {}; // Tracks loading state for volunteers

  Future<void> _handleSignUp(String eventId) async {
    setState(() {
      _isLoadingSignUpMap[eventId] = true; // start loading
    });

    try {
      await _signUp(eventId); // your existing sign-up/cancel logic
      await _fetchEvents(); // refresh the event list
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingSignUpMap[eventId] = false; // stop loading
        });
      }
    }
  }

  Future<void> _handleVolunteers(String eventId) async {
    setState(() {
      _isLoadingSignUpMap[eventId] = true; // start loading
    });

    try {
      await _signUp(eventId); // your existing sign-up/cancel logic
      await _fetchEvents(); // refresh the event list
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingSignUpMap[eventId] = false; // stop loading
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
    _checkIfAdmin();
    _fetchEvents();
  }

// Check if the user is an admin
  Future<void> _checkIfAdmin() async {
    if (user != null) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .get();
        if (mounted) {
          setState(() {
            isAdmin = userDoc.data()?['role'] == 'admin';
          });
        }
      } catch (e) {
        log('Error checking admin status: $e');
      }
    }
  }

// Fetch events from Firestore
  Future<void> _fetchEvents() async {
    try {
      final eventsCollection = FirebaseFirestore.instance.collection('events');
      final querySnapshot = await eventsCollection.get();
      if (mounted) {
        setState(() {
          events = querySnapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();
          _isPageLoading = false;
        });
      }

      if (user != null) {
        try {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user!.uid)
              .get();
          final signedUpEventIds =
              List<String>.from(userDoc.data()?['signedUpEvents'] ?? []);
          if (mounted) {
            setState(() {
              signedUpEvents = signedUpEventIds.toSet();
            });
          }
        } catch (e) {
          log('Error fetching signed up events: $e');
          if (mounted) {
            setState(() {
              _isPageLoading = false;
            });
          }
        }
      }
    } catch (e) {
      log('Error fetching events: $e');
    }
  }

  Future<void> _pickTime(DateTime selectedDate) async {
    if (!mounted) return;

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (selectedTime != null) {
      if (mounted) {
        setState(() {
          dateTime = DateTime(
            selectedDate.year,
            selectedDate.month,
            selectedDate.day,
            selectedTime.hour,
            selectedTime.minute,
          );
        });
      }
    }
  }

  Future<void> _addEvent() async {
    if (!isAdmin) return;

    Future<void> pickDate(StateSetter dialogSetState) async {
      if (!mounted) return;

      final selectedDate = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2101),
      );

      if (selectedDate != null) {
        await _pickTime(selectedDate);
        if (mounted) {
          dialogSetState(() {});
        }
      }
    }

    Future<void> handleAddEvent() async {
      if (location.isNotEmpty && dateTime != null) {
        try {
          final eventRef = FirebaseFirestore.instance.collection('events');
          await eventRef.add({
            'eventLocation': location,
            'eventDate': Timestamp.fromDate(dateTime!),
            'eventDescription': description,
            'volunteersIDList': [],
            'hasPassed': hasPassed,
          });

          if (mounted) {
            Navigator.of(context).pop();
            await _fetchEvents();
          }
        } catch (e) {
          log('Error adding event: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to add event.'),
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enter all required fields.'),
            ),
          );
        }
      }
    }

    if (mounted) {
      showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          return StatefulBuilder(
            builder: (BuildContext context, StateSetter dialogSetState) {
              return AlertDialog(
                title: const Text('Add New Event'),
                content: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        decoration:
                            const InputDecoration(labelText: 'Location'),
                        onChanged: (value) {
                          location = value;
                        },
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextButton(
                            onPressed: () async {
                              await pickDate(dialogSetState);
                            },
                            child: const Text('Select Date and Time'),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            dateTime != null
                                ? 'Selected Time: ${DateFormat('MMM d, yyyy \'at\' h:mm a').format(dateTime!)}'
                                : 'No Time Selected',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                      TextFormField(
                        decoration:
                            const InputDecoration(labelText: 'Description'),
                        onChanged: (value) {
                          description = value;
                        },
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                    },
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      handleAddEvent();
                    },
                    child: const Text('Add Event'),
                  ),
                ],
              );
            },
          );
        },
      );
    }
  }

  Future<void> _editEvent(String eventId, Map<String, dynamic> event) async {
    if (!isAdmin) return;

    // Set initial values
    location = event['eventLocation'];
    dateTime = event['eventDate'].toDate();
    description = event['eventDescription'] ?? '';

    Future<void> pickDate(StateSetter dialogSetState) async {
      if (!mounted) return;

      final selectedDate = await showDatePicker(
        context: context,
        initialDate: dateTime ?? DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2101),
      );

      if (selectedDate != null) {
        await _pickTime(selectedDate);
        if (mounted) {
          dialogSetState(() {}); // Update the dialog state
        }
      }
    }

    Future<void> handleUpdateEvent() async {
      if (location.isNotEmpty && dateTime != null) {
        try {
          await FirebaseFirestore.instance
              .collection('events')
              .doc(eventId)
              .update({
            'eventLocation': location,
            'eventDate': Timestamp.fromDate(dateTime!),
            'eventDescription': description,
          });

          if (mounted) {
            Navigator.of(context).pop(); // Close the dialog first
            await _fetchEvents();
          }
        } catch (e) {
          log('Error updating event: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to update event.'),
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enter all required fields.'),
            ),
          );
        }
      }
    }

    // Show the edit dialog
    if (mounted) {
      showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          return StatefulBuilder(
            builder: (BuildContext context, StateSetter dialogSetState) {
              return AlertDialog(
                title: const Text('Edit Event'),
                content: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        initialValue: location,
                        decoration:
                            const InputDecoration(labelText: 'Location'),
                        onChanged: (value) {
                          location = value;
                        },
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextButton(
                            onPressed: () async {
                              await pickDate(dialogSetState);
                            },
                            child: const Text('Select Date and Time'),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            dateTime != null
                                ? 'Selected Time: ${DateFormat('MMM d, yyyy \'at\' h:mm a').format(dateTime!)}'
                                : 'No Time Selected',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                      TextFormField(
                        initialValue: description,
                        decoration:
                            const InputDecoration(labelText: 'Description'),
                        onChanged: (value) {
                          description = value;
                        },
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                    },
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: handleUpdateEvent,
                    child: const Text('Save Changes'),
                  ),
                ],
              );
            },
          );
        },
      );
    }
  }

  Future<void> _deleteEvent(String eventId) async {
    if (!isAdmin) return;

    if (mounted) {
      showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: const Text('Delete Event'),
            content: const Text('Are you sure you want to delete this event?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(dialogContext).pop(); // Close the dialog first

                  try {
                    await FirebaseFirestore.instance
                        .collection('events')
                        .doc(eventId)
                        .delete();

                    if (mounted) {
                      await _fetchEvents();
                    }
                  } catch (e) {
                    log('Error deleting event: $e');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Failed to delete event.'),
                        ),
                      );
                    }
                  }
                },
                child: const Text('Delete'),
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> _viewVolunteers(String eventId) async {
    // Fetch the event document and list of volunteer IDs
    final eventDoc = await FirebaseFirestore.instance
        .collection('events')
        .doc(eventId)
        .get();
    List<String> volunteersIdList =
        List<String>.from(eventDoc.data()?['volunteersIDList'] ?? []);

    // Fetch volunteers' details
    final volunteersDocs = await Future.wait(
      volunteersIdList.map((volunteerId) => FirebaseFirestore.instance
          .collection('users')
          .doc(volunteerId)
          .get()),
    );

    final volunteers = volunteersDocs.map((doc) {
      final data = doc.data();
      return '${data?['firstName']} ${data?['lastName']}';
    }).toList();

    // Show the dialog to view volunteers
    if (mounted) {
      _showVolunteersDialog(eventId, volunteers, volunteersIdList);
    }
  }

  void _showVolunteersDialog(
    String eventId,
    List<String> volunteers,
    List<String> volunteersIdList,
  ) {
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('View Volunteers'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...volunteers.map((volunteer) => ListTile(
                      title: Text(volunteer),
                      trailing: isAdmin
                          ? IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () async {
                                Navigator.of(dialogContext).pop();

                                final confirm = await showDialog<bool>(
                                  context: dialogContext,
                                  builder: (BuildContext innerDialogContext) {
                                    return AlertDialog(
                                      title: const Text('Confirm Deletion'),
                                      content: const Text(
                                          'Are you sure you want to remove this volunteer?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(innerDialogContext)
                                                .pop(false);
                                          },
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(innerDialogContext)
                                                .pop(true);
                                          },
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    );
                                  },
                                );

                                if (confirm == true) {
                                  await _removeVolunteer(
                                      eventId, volunteersIdList, volunteer);

                                  // Refresh the event list and update UI
                                  if (mounted) {
                                    setState(() {
                                      // Refresh the event list to reflect the changes
                                      _fetchEvents();
                                    });
                                  }
                                }
                              },
                            )
                          : null,
                    )),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close the dialog
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _removeVolunteer(
      String eventId, List<String> volunteersIdList, String volunteer) async {
    try {
      final volunteerName = volunteer.split(' ');
      log('Attempting to remove volunteer: $volunteerName from event: $eventId');

      final volunteerDoc = await FirebaseFirestore.instance
          .collection('users')
          .where('firstName', isEqualTo: volunteerName[0])
          .where('lastName', isEqualTo: volunteerName[1])
          .limit(1)
          .get();

      if (volunteerDoc.docs.isNotEmpty) {
        final volunteerId = volunteerDoc.docs.first.id;
        log('Volunteer ID found: $volunteerId');
        volunteersIdList.remove(volunteerId);

        // Update the event's volunteersIDList
        await FirebaseFirestore.instance
            .collection('events')
            .doc(eventId)
            .update({
          'volunteersIDList': volunteersIdList,
        });

        // Update the user's signedUpEvents list
        final userDocRef =
            FirebaseFirestore.instance.collection('users').doc(volunteerId);
        final userDoc = await userDocRef.get();
        final signedUpEvents =
            List<String>.from(userDoc.data()?['signedUpEvents'] ?? []);

        if (signedUpEvents.contains(eventId)) {
          signedUpEvents.remove(eventId);
          log('Updating signedUpEvents for user $volunteerId');

          await userDocRef.update({'signedUpEvents': signedUpEvents});
          log('signedUpEvents updated successfully.');
        } else {
          log('Event ID not found in user\'s signedUpEvents.');
        }

        Fluttertoast.showToast(msg: 'Volunteer removed successfully.');

        // Synchronize the local state with Firestore if necessary
        if (user != null && volunteerId == user!.uid) {
          setState(() {
            signedUpEvents.remove(eventId); // Update local state
          });
        }

        await _fetchEvents(); // Refresh the event list to reflect the changes
      } else {
        log('Volunteer document not found.');
        Fluttertoast.showToast(msg: 'Volunteer not found.');
      }
    } catch (e) {
      log('Error removing volunteer: $e');
      Fluttertoast.showToast(msg: 'Failed to remove volunteer.');
    }
  }

  Future<void> _signUp(String eventId) async {
    if (user == null) return;

    final eventRef =
        FirebaseFirestore.instance.collection('events').doc(eventId);
    final userRef =
        FirebaseFirestore.instance.collection('users').doc(user!.uid);

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final eventDoc = await transaction.get(eventRef);
        final userDoc = await transaction.get(userRef);

        if (eventDoc.exists && userDoc.exists) {
          final eventVolunteers =
              List<String>.from(eventDoc.data()?['volunteersIDList'] ?? []);
          final userSignedUpEvents =
              List<String>.from(userDoc.data()?['signedUpEvents'] ?? []);

          bool isUserSignedUp = eventVolunteers.contains(user!.uid);

          if (isUserSignedUp) {
            eventVolunteers.remove(user!.uid);
            userSignedUpEvents.remove(eventId);
            Fluttertoast.showToast(
              msg: "Canceled signup for the event.",
              toastLength: Toast.LENGTH_LONG,
              gravity: ToastGravity.BOTTOM,
            );
          } else {
            eventVolunteers.add(user!.uid);
            userSignedUpEvents.add(eventId);
            Fluttertoast.showToast(
              msg: "Signed up for the event!",
              toastLength: Toast.LENGTH_LONG,
              gravity: ToastGravity.BOTTOM,
            );
          }

          transaction.update(eventRef, {'volunteersIDList': eventVolunteers});
          transaction.update(userRef, {'signedUpEvents': userSignedUpEvents});
        }
      });

      if (mounted) {
        setState(() {
          // Refresh the event list or update UI as needed
          _fetchEvents();
        });
      }
    } catch (e) {
      log('Error signing up or canceling signup: $e');
    }
  }

  Future<bool> _checkUserSignedUp(String eventId) async {
    try {
      final eventDoc = await FirebaseFirestore.instance
          .collection('events')
          .doc(eventId)
          .get();

      final eventVolunteers =
          List<String>.from(eventDoc.data()?['volunteersIDList'] ?? []);
      return eventVolunteers.contains(user!.uid);
    } catch (e) {
      log('Error checking user signup status: $e');
      return false;
    }
  }

  void _showAttendanceDialog(String eventId, List<String> volunteersIdList) {
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        // Create a local map to manage attendance within the dialog
        final localAttendanceMap = Map<String, bool>.from(attendanceMap);

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text('Take Attendance'),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: volunteersIdList.map((volunteerId) {
                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(volunteerId)
                          .get(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const CircularProgressIndicator();
                        }

                        // Fix for full name retrieval
                        final volunteerData =
                            snapshot.data?.data() as Map<String, dynamic>?;
                        final fullName =
                            '${volunteerData?['firstName']} ${volunteerData?['lastName']}';

                        return CheckboxListTile(
                          title: Text(fullName),
                          value: localAttendanceMap[volunteerId] ?? false,
                          onChanged: (bool? value) {
                            setState(() {
                              localAttendanceMap[volunteerId] = value ?? false;
                            });
                          },
                        );
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop(); // Close the dialog
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.of(dialogContext).pop(); // Close the dialog
                    await _markEventAsPassed(eventId, localAttendanceMap);
                  },
                  child: const Text('Mark as Passed'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _markEventAsPassed(
      String eventId, Map<String, bool> localAttendanceMap) async {
    try {
      for (var entry in localAttendanceMap.entries) {
        final userId = entry.key;
        final attended = entry.value;

        final userDocRef =
            FirebaseFirestore.instance.collection('users').doc(userId);
        final userDoc = await userDocRef.get();
        final signedUpEvents =
            List<String>.from(userDoc.data()?['signedUpEvents'] ?? []);
        final eventsParticipatedList =
            List<String>.from(userDoc.data()?['eventsParticipatedList'] ?? []);

        if (attended) {
          if (!eventsParticipatedList.contains(eventId)) {
            eventsParticipatedList.add(eventId);
          }
        }

        signedUpEvents.remove(eventId);

        await userDocRef.update({
          'signedUpEvents': signedUpEvents,
          'eventsParticipatedList': eventsParticipatedList,
        });
      }
      // Update the event to mark it as passed
      final eventDocRef =
          FirebaseFirestore.instance.collection('events').doc(eventId);

      await eventDocRef.update({
        'hasPassed': true, // Set the `hasPassed` field to true
      });

      setState(() {
        _fetchEvents();
      });

      Fluttertoast.showToast(
          msg: 'Event marked as passed and attendance recorded.');
    } catch (e) {
      log('Error marking event as passed: $e');
      Fluttertoast.showToast(msg: 'Failed to mark event as passed.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final hasPassedEvents =
        events.where((event) => event['hasPassed'] == true).toList();
    final hasNotPassedEvents =
        events.where((event) => event['hasPassed'] == false).toList();
    if (_isPageLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Sign Up for Events',
        gradientColors: [Colors.lightBlueAccent, Colors.blueAccent],
        height: 100.0,
        helpMessage:
            'With the click of a button, you can sign up for a performance that fits into your schedule. After signing up, all you have to do is make sure you show up on the performance. See you there!',
      ),
      body: ListView(
        children: [
          // Divider between sections
          const SizedBox(height: 20),
          const Divider(
            height: 2,
            color: Colors.black,
            indent: 20,
            endIndent: 20,
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                'Upcoming Events',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
              ),
            ),
          ),
          const Divider(
            height: 2,
            color: Colors.black,
            indent: 20,
            endIndent: 20,
          ),
          const SizedBox(height: 20),

          // Display events that have not passed
          ...hasNotPassedEvents.map((event) {
            final eventId = event['id'];
            final eventName = event['eventLocation'];
            final eventDate = (event['eventDate'] as Timestamp).toDate();
            final eventDescription = event['eventDescription'];
            final volunteersIdList =
                List<String>.from(event['volunteersIDList'] ?? []);

            // Determine the background color based on whether the user has signed up for the event
            final isUserSignedUp = volunteersIdList.contains(userId);
            final backgroundColor =
                isUserSignedUp ? Colors.green.shade100 : Colors.white;

            return Container(
              height: 220,
              margin: const EdgeInsets.all(8.0),
              child: Card(
                color: backgroundColor, // Apply tint based on sign-up status
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        eventName,
                        style: const TextStyle(
                            fontFamily: 'CustomFontNameModerustic',
                            fontWeight: FontWeight.w500,
                            fontSize: 24),
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        DateFormat('MMM d, yyyy \'at\' h:mm a')
                            .format(eventDate),
                        style: const TextStyle(
                            fontFamily: 'CustomFontNameModerustic',
                            fontWeight: FontWeight.w300,
                            fontSize: 16),
                      ),
                      if (eventDescription != null &&
                          eventDescription.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            eventDescription,
                            style: const TextStyle(
                                fontFamily: 'CustomFontNameModerustic',
                                fontSize: 12,
                                color: Colors.black54),
                          ),
                        ),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (isAdmin) ...[
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _editEvent(eventId, event),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _deleteEvent(eventId),
                            ),
                            IconButton(
                              icon: const Icon(Icons.check),
                              onPressed: () => _showAttendanceDialog(
                                  eventId, volunteersIdList),
                            ),
                          ],
                          Expanded(
                            child: LoadingButton(
                              isLoading: _isLoadingSignUpMap[eventId] ??
                                  false, // track loading per event
                              onPressed: () async {
                                setState(() {
                                  _isLoadingSignUpMap[eventId] =
                                      true; // start loading
                                });

                                try {
                                  await _signUp(
                                      eventId); // toggles sign up in Firebase
                                  await _fetchEvents(); // refresh local state
                                } finally {
                                  if (mounted) {
                                    setState(() {
                                      _isLoadingSignUpMap[eventId] =
                                          false; // stop loading
                                    });
                                  }
                                }
                              },
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  isUserSignedUp ? 'Cancel Sign Up' : 'Sign Up',
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8.0),
                          Expanded(
                            child: LoadingButton(
                              isLoading: _isLoadingVolunteersMap[eventId] ??
                                  false, // track loading per event
                              onPressed: () async {
                                setState(() {
                                  _isLoadingVolunteersMap[eventId] =
                                      true; // start loading
                                });

                                try {
                                  await _viewVolunteers(
                                      eventId); // your existing function
                                } finally {
                                  if (mounted) {
                                    setState(() {
                                      _isLoadingVolunteersMap[eventId] =
                                          false; // stop loading
                                    });
                                  }
                                }
                              },
                              child: const FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text('View Volunteers'),
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
          }),

          // Divider between sections
          const SizedBox(height: 20),
          const Divider(
            height: 2,
            color: Colors.black,
            indent: 20,
            endIndent: 20,
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                'Past Events',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
              ),
            ),
          ),
          const Divider(
            height: 2,
            color: Colors.black,
            indent: 20,
            endIndent: 20,
          ),
          const SizedBox(height: 20),

          // Display events that have passed
          ...hasPassedEvents.map((event) {
            final eventId = event['id'];
            final eventName = event['eventLocation'];
            final eventDate = (event['eventDate'] as Timestamp).toDate();
            final eventDescription = event['eventDescription'];
            final volunteersIdList =
                List<String>.from(event['volunteersIDList'] ?? []);

            // Determine the background color for passed events
            final isUserSignedUp = volunteersIdList.contains(userId);
            final backgroundColor =
                isUserSignedUp ? Colors.green.shade100 : Colors.red.shade100;

            return Container(
              height: 220,
              margin: const EdgeInsets.all(8.0),
              child: Card(
                color: backgroundColor,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        eventName,
                        style: const TextStyle(
                            fontFamily: 'CustomFontNameModerustic',
                            fontWeight: FontWeight.w500,
                            fontSize: 24),
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        DateFormat('MMM d, yyyy \'at\' h:mm a')
                            .format(eventDate),
                        style: const TextStyle(
                            fontFamily: 'CustomFontNameModerustic',
                            fontWeight: FontWeight.w300,
                            fontSize: 16),
                      ),
                      if (eventDescription != null &&
                          eventDescription.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            eventDescription,
                            style: const TextStyle(
                                fontFamily: 'CustomFontNameModerustic',
                                fontSize: 12,
                                color: Colors.black54),
                          ),
                        ),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (isAdmin) ...[
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _editEvent(eventId, event),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _deleteEvent(eventId),
                            ),
                            IconButton(
                              icon: const Icon(Icons.check),
                              onPressed: () => _showAttendanceDialog(
                                  eventId, volunteersIdList),
                            ),
                          ],
                          const Expanded(
                            child: SizedBox.shrink(),
                          ),
                          const SizedBox(width: 8.0),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _viewVolunteers(eventId),
                              child: const FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text('View Volunteers'),
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
          }),
        ],
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: _addEvent,
              icon: const Icon(Icons.add),
              label: const Text('Add Event'),
              tooltip: 'Add Event',
              extendedPadding: const EdgeInsets.symmetric(horizontal: 16.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 6.0,
            )
          : null,
    );
  }
}
