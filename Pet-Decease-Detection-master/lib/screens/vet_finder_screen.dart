import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class VetFinderScreen extends StatelessWidget {
  const VetFinderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nearby Vets')),
      body: GoogleMap(
        initialCameraPosition: const CameraPosition(
          target: LatLng(6.9271, 79.8612), // Sri Lanka default
          zoom: 12,
        ),
        markers: {
          const Marker(
            markerId: MarkerId('vet1'),
            position: LatLng(6.93, 79.86),
            infoWindow: InfoWindow(
              title: 'Happy Paws Vet',
              snippet: 'Open Now 🟢',
            ),
          ),
        },
      ),
    );
  }
}
