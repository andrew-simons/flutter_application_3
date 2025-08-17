import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final double height;
  final List<Color> gradientColors;
  final String helpMessage; // Add this field

  const CustomAppBar({
    super.key,
    required this.title,
    this.height = 100.0, // Default height
    this.gradientColors = const [Colors.blueAccent, Colors.lightBlue],
    required this.helpMessage, // Add this field
  });

  @override
  Widget build(BuildContext context) {
    return PreferredSize(
      preferredSize: Size.fromHeight(height),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30.0),
          bottomRight: Radius.circular(30.0),
          topLeft: Radius.circular(30.0),
          topRight: Radius.circular(30.0),
        ),
        child: AppBar(
          backgroundColor: Colors.blue,
          elevation: 5.0,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 32.5),
                  child: Center(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Color.fromARGB(255, 242, 244, 247),
                        fontSize: 24.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(
                Icons.help_outline,
                size: 30.0,
                color: Colors.white70,
              ),
              onPressed: () {
                _showHelpDialog(context, helpMessage); // Show help dialog
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showHelpDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Help'),
          content: Text(message),
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

  @override
  Size get preferredSize => Size.fromHeight(height);
}
