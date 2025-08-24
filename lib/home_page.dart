import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  late final Stream<List<String>> _imageUrlsStream;
  final PageController _pageController = PageController();
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();

    _imageUrlsStream = FirebaseFirestore.instance
        .collection('highlights')
        .doc('images')
        .snapshots()
        .map((snapshot) => List<String>.from(snapshot.data()?['urls'] ?? []));

    _checkIfAdmin();
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel the timer
    _pageController.dispose(); // Dispose PageController
    super.dispose();
  }

  Future<void> _checkIfAdmin() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (mounted) {
        if (userDoc.exists) {
          final userData = userDoc.data();
          if (userData != null && userData['role'] == 'admin') {
            setState(() {
              _isAdmin = true;
            });
          }
        }
      }
    }
  }

  Future<void> _showImageUploadDialog() async {
    if (mounted) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Upload Images'),
            content: const SingleChildScrollView(
              child: SizedBox(
                width: double.maxFinite,
                child: AdminImageUploadDialog(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Close'),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60.0),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(30.0),
            bottomRight: Radius.circular(30.0),
            topLeft: Radius.circular(30.0),
            topRight: Radius.circular(30.0),
          ),
          child: AppBar(
            title: const Text(
              'Home',
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
                letterSpacing: 1.1,
              ),
            ),
            backgroundColor: Colors.purpleAccent,
            elevation: 5.0,
            shadowColor: Colors.black,
            centerTitle: true,
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue, Colors.lightBlueAccent],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 30),
            Container(
              alignment: Alignment.bottomLeft,
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: const Text(
                'Recommended Pages',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.left,
              ),
            ),
            const SizedBox(height: 20),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildActionCard(
                    title: 'Sign up for performances!',
                    icon: Icons.event,
                    color: Colors.blueAccent,
                    onTap: () {
                      Navigator.pushNamed(context, '/upcoming_events');
                    },
                  ),
                  _buildActionCard(
                    title: 'View performance instructions!',
                    icon: Icons.description,
                    color: const Color.fromARGB(255, 34, 185, 112),
                    onTap: () {
                      Navigator.pushNamed(context, '/instructions');
                    },
                  ),
                  _buildActionCard(
                    title: 'Claim your volunteer hours!',
                    icon: Icons.access_time,
                    color: Colors.orangeAccent,
                    onTap: () {
                      Navigator.pushNamed(context, '/claim_volunteer_hours');
                    },
                  ),
                  _buildActionCard(
                    title: 'Visit our website!',
                    icon: Icons.web,
                    color: Colors.pinkAccent,
                    onTap: () {
                      _launchURL();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Highlights Section (not working yet)
            Container(
              alignment: Alignment.bottomLeft,
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: const Text(
                'Highlights',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.left,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              height: 200,
              color: Colors.grey[300],
              child: StreamBuilder<List<String>>(
                stream: _imageUrlsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text(
                        'Coming soon!',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                        ),
                      ),
                    );
                  }

                  return PageView.builder(
                    controller: _pageController,
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final url = snapshot.data![index];
                      return Image.network(
                        url,
                        fit: BoxFit.cover,
                      );
                    },
                  );
                },
              ),
            ),
            if (_isAdmin) // Only show if the user is an admin

              Align(
                alignment: Alignment.bottomRight,
                child: FloatingActionButton(
                  onPressed: _showImageUploadDialog,
                  backgroundColor: Colors.lightBlue,
                  foregroundColor: Colors.white,
                  tooltip: 'Upload Images',
                  child: const Icon(Icons.upload),
                ),
              ),
            const SizedBox(height: 30),

            // Updates Section
            Container(
              alignment: Alignment.bottomLeft,
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: const Text(
                'Updates',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.left,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: const Text(
                'Stay tuned for upcoming performances and events! Make sure to check the performance schedule regularly for updates.',
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
      backgroundColor: Colors.white,
    );
  }

  Widget _buildActionCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        height: 150,
        margin: const EdgeInsets.symmetric(horizontal: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(4, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 40,
              color: Colors.white,
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchURL() async {
    final Uri url = Uri.parse('https://childrensmusicbrigade.com/');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}

class AdminImageUploadDialog extends StatefulWidget {
  const AdminImageUploadDialog({super.key});

  @override
  AdminImageUploadDialogState createState() => AdminImageUploadDialogState();
}

class AdminImageUploadDialogState extends State<AdminImageUploadDialog> {
  final ImagePicker _picker = ImagePicker();
  List<File> _selectedImages = [];
  bool _isUploading = false; // Track upload status
  String _errorMessage = ''; // Track error messages
  bool _imagesPicked = false;

  Future<void> _selectImages() async {
    try {
      final List<XFile> pickedFiles = await _picker
          .pickMultiImage(); // Handle case when no images are selected

      setState(() {
        _selectedImages = pickedFiles.map((file) => File(file.path)).toList();
        _errorMessage = ''; // Clear any previous errors
        _imagesPicked = true;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to select images: $e';
      });
    }
  }

  Future<void> _uploadImages() async {
    if (_selectedImages.isEmpty) {
      return; // Prevent upload if no images are selected
    }

    setState(() {
      _isUploading = true; // Set uploading status
      _errorMessage = ''; // Clear any previous errors
    });

    try {
      final storageRef = FirebaseStorage.instance.ref();
      final uploadTasks = <Future<String>>[]; // Collect URLs for new images

      for (final image in _selectedImages) {
        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}_${image.uri.pathSegments.last}';
        final fileRef = storageRef.child('highlights/$fileName');
        final uploadTask = fileRef.putFile(image);

        // Collect URLs of the uploaded images
        final uploadUrlTask = uploadTask.then((snapshot) async {
          final imageUrl = await fileRef.getDownloadURL();
          return imageUrl;
        });

        uploadTasks.add(uploadUrlTask);
      }

      final List<String> imageUrls = await Future.wait(uploadTasks);

      // Update Firestore with new image URLs and clear existing ones
      await FirebaseFirestore.instance
          .collection('highlights')
          .doc('images')
          .set({
        'urls': imageUrls,
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to upload images: $e';
      });
    } finally {
      setState(() {
        _isUploading = false; // Reset uploading status
        Fluttertoast.showToast(
          msg: "Upload was successful!",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: _selectImages,
              child: const Text('Select Images'),
            ),
            const SizedBox(height: 20),
            _imagesPicked
                ? ElevatedButton(
                    onPressed: _isUploading
                        ? null
                        : _uploadImages, // Disable button while uploading
                    child: _isUploading
                        ? const CircularProgressIndicator()
                        : const Text('Upload Images'),
                  )
                : const SizedBox
                    .shrink(), // Hides the button when images are not picked

            if (_errorMessage.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                _errorMessage,
                style: const TextStyle(color: Colors.red),
              ),
            ],
            const SizedBox(height: 20),
            if (_selectedImages.isNotEmpty)
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImages.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: Image.file(
                            _selectedImages[index],
                            fit: BoxFit.cover,
                          ),
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
