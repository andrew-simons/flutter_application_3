// import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';

Future<String> generateAndUploadPdf({
  required String userName,
  required int volunteerHours,
  required List<Map<String, dynamic>> eventsParticipated,
}) async {
  // Create the PDF document
  final pdf = pw.Document();
  pdf.addPage(
    pw.Page(
      build: (pw.Context context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Volunteer Hours Certificate',
              style:
                  pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 20),
          pw.Text('Name: $userName', style: const pw.TextStyle(fontSize: 18)),
          pw.Text('Total Volunteer Hours: $volunteerHours',
              style: const pw.TextStyle(fontSize: 18)),
          pw.SizedBox(height: 20),
          pw.Text('Events Participated:',
              style: const pw.TextStyle(fontSize: 18)),
          pw.Column(
            children: eventsParticipated.map((event) {
              return pw.Text(
                '- ${event['name']} on ${DateFormat('MMM d, yyyy \'at\' h:mm a').format(event['date'])}',
                style: const pw.TextStyle(fontSize: 16),
              );
            }).toList(),
          ),
        ],
      ),
    ),
  );

  // Save the PDF locally
  final directory = await getTemporaryDirectory();
  final file = File('${directory.path}/volunteer_hours.pdf');
  await file.writeAsBytes(await pdf.save());

  // Upload the PDF to Firebase Storage
  final firebaseStorage = FirebaseStorage.instance;
  final storageRef = firebaseStorage.ref().child(
      'pdfs/volunteer_hours_${DateTime.now().millisecondsSinceEpoch}.pdf');
  final uploadTask = storageRef.putFile(file);

  final snapshot = await uploadTask.whenComplete(() {});
  final pdfUrl = await snapshot.ref.getDownloadURL();

  return pdfUrl;
}
