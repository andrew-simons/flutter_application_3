import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'dart:developer';

class AdminImageUploadDialog extends StatefulWidget {
  const AdminImageUploadDialog({super.key});

  @override
  AdminImageUploadDialogState createState() => AdminImageUploadDialogState();
}

class AdminImageUploadDialogState extends State<AdminImageUploadDialog> {
  final ImagePicker picker = ImagePicker();
  File? _imageFile;
  String _uploadStatus = '';

  Future<void> _pickImage() async {
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
      log('Image path: ${_imageFile!.path}'); // Log the path to verify
    } else {
      log('No image selected.');
      setState(() {
        _imageFile = null; // Explicitly set to null if no image selected
      });
    }
  }

  Future<void> _uploadImage() async {
    if (_imageFile == null) {
      setState(() {
        _uploadStatus = 'No image selected.';
      });
      return;
    }

    final fileName = DateTime.now().millisecondsSinceEpoch.toString();
    final storageRef =
        FirebaseStorage.instance.ref().child('uploads/$fileName');
    try {
      final uploadTask = storageRef.putFile(_imageFile!);
      final snapshot = await uploadTask.whenComplete(() => {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      final firestoreRef =
          FirebaseFirestore.instance.collection('highlights').doc('images');
      await firestoreRef.update({
        'urls': FieldValue.arrayUnion([downloadUrl])
      });

      setState(() {
        _uploadStatus = 'Upload successful!';
      });
    } catch (e) {
      setState(() {
        _uploadStatus = 'Upload failed: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton(
          onPressed: _pickImage,
          child: const Text('Pick Image'),
        ),
        if (_imageFile != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Image.file(_imageFile!),
          ),
        ElevatedButton(
          onPressed: _uploadImage,
          child: const Text('Upload Image'),
        ),
        if (_uploadStatus.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(_uploadStatus),
          ),
      ],
    );
  }
}
