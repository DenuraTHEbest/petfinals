import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../widgets/feature_card.dart';
import '../widgets/animated_paw.dart';
import 'todo_screen.dart';

import 'weight_chart_screen.dart';
import 'vet_finder_screen.dart';
import 'diet_plan_screen.dart';
import 'training_screen.dart';
import 'placeholder_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void openScreen(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pet Care Dashboard 🐾'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // 🐾 Background paws
          const AnimatedPaw(top: 90, left: 20),
          const AnimatedPaw(top: 260, left: 280, size: 26),
          const AnimatedPaw(top: 520, left: 120),

          Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                FeatureCard(
                  title: 'Disease Detection',
                  icon: Icons.health_and_safety,
                  onTap: () => openScreen(
                    context,
                    const PlaceholderScreen(title: 'Disease Detection'),
                  ),
                ),

                FeatureCard(
                  title: 'Symptom Checker',
                  icon: Icons.search,
                  onTap: () => openScreen(
                    context,
                    const PlaceholderScreen(title: 'Symptom Checker'),
                  ),
                ),

                FeatureCard(
                  title: 'To-Do & Reminders',
                  icon: Icons.checklist,
                  onTap: () => openScreen(
                    context,
                    const TodoScreen(),
                  ),
                ),

                FeatureCard(
                  title: 'Doctor Appointments',
                  icon: Icons.local_hospital,
                  onTap: () => openScreen(
                    context,
                    const VetFinderScreen(),
                  ),
                ),

                FeatureCard(
                  title: 'Vet Visit Records',
                  icon: Icons.folder,
                  onTap: () => openScreen(
                    context,
                    const PlaceholderScreen(title: 'Vet Records'),
                  ),
                ),

                FeatureCard(
                  title: 'Weight Chart',
                  icon: Icons.monitor_weight,
                  onTap: () => openScreen(
                    context,
                    const WeightChartScreen(),
                  ),
                ),

                FeatureCard(
                  title: 'Diet Plans',
                  icon: Icons.restaurant,
                  onTap: () => openScreen(
                    context,
                    const DietPlanScreen(),
                  ),
                ),

                FeatureCard(
                  title: 'Adoption / Buying',
                  icon: Icons.pets,
                  onTap: () => openScreen(
                    context,
                    const PlaceholderScreen(title: 'Adoption & Buying'),
                  ),
                ),

                FeatureCard(
                  title: 'Shop',
                  icon: Icons.shopping_cart,
                  onTap: () => openScreen(
                    context,
                    const PlaceholderScreen(title: 'Pet Shop'),
                  ),
                ),

                FeatureCard(
                  title: 'Training & Fun',
                  icon: Icons.play_circle,
                  onTap: () => openScreen(
                    context,
                    const TrainingScreen(),
                  ),
                ),

                FeatureCard(
                  title: 'Emergency Help',
                  icon: Icons.warning,
                  onTap: () => openScreen(
                    context,
                    const PlaceholderScreen(title: 'Emergency Resources'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}