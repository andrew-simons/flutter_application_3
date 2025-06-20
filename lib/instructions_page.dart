import 'package:flutter/material.dart';
import 'custom_app_bar.dart';

class InstructionsPage extends StatelessWidget {
  const InstructionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(100.0),
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(30.0),
            bottomRight: Radius.circular(30.0),
            topLeft: Radius.circular(30.0),
            topRight: Radius.circular(30.0),
          ),
          child: CustomAppBar(
            title: 'Instructions',
            gradientColors: [Colors.lightBlueAccent, Colors.blueAccent],
            height: 100.0,
            helpMessage:
                'This page underlines all of our nonprofit\'s features, clarifies information, and answers common questions.',
          ),
        ),
      ),
      body: Stack(
        children: [
          // The content with the instructions and boxes
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                const SizedBox(height: 20.0), // Spacing below the app bar
                _buildInstructionBox(
                  title: 'Preparation',
                  content: [
                    _buildRichText('Choose any genre:',
                        ' pop, classical, jazz, solos, or chamber music. All styles are welcome and encouraged!'),
                    _buildRichText('Sign up to perform:',
                        ' Go to the "Upcoming Events" page after tapping the menu icon in the top left corner of your screen.'),
                    _buildRichText('Prepare as best as you can:',
                        ' Our audience is polite and supportive, so don’t hesitate to perform!'),
                  ],
                  color: Colors.lightBlue.withOpacity(0.2),
                ),
                const SizedBox(height: 16.0),
                _buildInstructionBox(
                  title: 'On performance day',
                  content: [
                    _buildRichText('Arrive:',
                        ' 10-15 minutes before the event starts. We\'ll meet and wait for each other outside the main entrance of the building.'),
                    _buildRichText('Wear concert black attire:',
                        ' If possible; otherwise, just wear all black.'),
                    _buildRichText('Questions:',
                        ' If you have any questions, feel free to ask!'),
                  ],
                  color: Colors.greenAccent.withOpacity(0.2),
                ),
                const SizedBox(height: 16.0),
                _buildInstructionBox(
                  title: 'Afterwards',
                  content: [
                    _buildRichText('Congratulations:',
                        ' Thanks to your performance, we can spread the joy of music in our community.'),
                    _buildRichText('Community Service Hours:',
                        ' After each performance, 2 hours of community service are added to your account. To receive a PDF formally documenting your hours, go to the "Claim Volunteer Hours" page and click the "Claim Hours" button.'),
                  ],
                  color: Colors.orangeAccent.withOpacity(0.2),
                ),
                const SizedBox(height: 20.0), // Spacing at the bottom
              ],
            ),
          ),
          // Gradient overlay at the top
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              height: 50.0, // Adjust height for top fade effect
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(0.9), // Top fade color
                    Colors.white.withOpacity(0.0), // Fully transparent
                  ],
                ),
              ),
            ),
          ),
          // Gradient overlay at the bottom
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 50.0, // Adjust height for bottom fade effect
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.white.withOpacity(0.9), // Bottom fade color
                    Colors.white.withOpacity(0.0), // Fully transparent
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionBox(
      {required String title,
      required List<Widget> content,
      required Color color}) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(15.0),
        //border: Border.all(color: Colors.grey.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8.0),
          ...content,
        ],
      ),
    );
  }

  Widget _buildRichText(String boldText, String regularText) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: boldText,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            TextSpan(
              text: regularText,
              style: const TextStyle(
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
