import 'package:flutter/material.dart';

class ProgressPage extends StatelessWidget {
  const ProgressPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center( // 👈 Centers the whole column
        child: Column(
          mainAxisSize: MainAxisSize.min, // 👈 Ensures tight vertical centering
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Centered linear progress indicator
            const SizedBox(height: 24),

            // Text button below the progress bar
            GestureDetector(
              onTap: () {
                // TODO: handle navigation here, e.g.
                // Navigator.push(context, PlatformFlipPageRoute(...));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Navigating to Corporate...')),
                );
              },
              child: const Text(
                'Switching to Corporate',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.indigo,
                ),
              ),
            ),
            SizedBox(height: 24,),
            SizedBox(
              width: 220,
              child: LinearProgressIndicator(
                backgroundColor: Colors.grey.shade300,
                color: Colors.indigo,
                minHeight: 6,
                borderRadius: BorderRadius.circular(8),
              ),
            ),


          ],
        ),
      ),
    );
  }
}
