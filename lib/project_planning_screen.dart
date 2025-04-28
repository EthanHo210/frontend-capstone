import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';


class ProjectPlanningScreen extends StatefulWidget {
  const ProjectPlanningScreen({super.key});

  @override
  State<ProjectPlanningScreen> createState() => _ProjectPlanningScreenState();
}

class _ProjectPlanningScreenState extends State<ProjectPlanningScreen> {
  final Map<String, bool> _responsibilities = {
    'Report Writing': false,
    'Development': false,
    'Data Elicitation': false,
    'Slide Preparation': false,
    'Developer': false,
    'Project Manager': false,
  };

  void _goNext() {
    Navigator.pushNamed(context, '/courseTeams');
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEFBEA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                'Project Planning',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal[900],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Before starting your project, please arrange the project responsibilities.',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.teal[800],
                ),
              ),
              const SizedBox(height: 30),
              Text(
                'Select Your Responsibilities:',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.teal[800],
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView(
                  children: _responsibilities.keys.map((key) {
                    return CheckboxListTile(
                      title: Text(
                        key,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          color: Colors.teal[900],
                        ),
                      ),
                      value: _responsibilities[key],
                      activeColor: Colors.teal,
                      onChanged: (value) {
                        setState(() {
                          _responsibilities[key] = value ?? false;
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _goNext,
        backgroundColor: Colors.black,
        child: const Icon(Icons.arrow_forward, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
