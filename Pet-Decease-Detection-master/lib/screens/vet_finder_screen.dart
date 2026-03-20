import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/vet_clinic.dart';
import '../widgets/book_appointment_dialog.dart';
import '../services/appointment_manager.dart';
import '../utils/pet_todo_list.dart';

class VetFinderScreen extends StatefulWidget {
  const VetFinderScreen({super.key});

  @override
  State<VetFinderScreen> createState() => _VetFinderScreenState();
}

class _VetFinderScreenState extends State<VetFinderScreen> {
  GoogleMapController? _mapController;
  LatLng _currentPosition = const LatLng(6.9271, 79.8612); // Default: Colombo
  Set<Marker> _markers = {};
  bool _isLoading = true;
  List<VetClinic> _clinics = [];

  @override
  void initState() {
    super.initState();
    _clinics = VetClinic.getSriLankanClinics();
    _loadMarkers();
    _getUserLocation();
    AppointmentManager.instance.addListener(_onAppointmentsChanged);
  }

  @override
  void dispose() {
    AppointmentManager.instance.removeListener(_onAppointmentsChanged);
    super.dispose();
  }

  void _onAppointmentsChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _getUserLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _isLoading = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() => _isLoading = false);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _isLoading = false;
      });

      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_currentPosition, 13),
      );
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _loadMarkers() {
    final markers = <Marker>{};
    for (final clinic in _clinics) {
      markers.add(
        Marker(
          markerId: MarkerId(clinic.id),
          position: LatLng(clinic.latitude, clinic.longitude),
          infoWindow: InfoWindow(
            title: clinic.name,
            snippet: 'Tap for details',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          onTap: () => _showClinicBottomSheet(clinic),
        ),
      );
    }
    setState(() => _markers = markers);
  }

  void _showClinicBottomSheet(VetClinic clinic) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Clinic name
            Text(
              clinic.name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Address
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.teal, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    clinic.address,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Phone
            Row(
              children: [
                const Icon(Icons.phone, color: Colors.teal, size: 20),
                const SizedBox(width: 8),
                Text(
                  clinic.phone,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Rating
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 20),
                const SizedBox(width: 8),
                Text(
                  '${clinic.rating} / 5.0',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _getDirections(clinic),
                    icon: const Icon(Icons.directions),
                    label: const Text('Directions'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.teal,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context); // Close bottom sheet
                      _openBookingDialog(clinic);
                    },
                    icon: const Icon(Icons.calendar_month),
                    label: const Text('Book'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _getDirections(VetClinic clinic) async {
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${clinic.latitude},${clinic.longitude}',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openBookingDialog(VetClinic clinic) async {
    final booked = await showDialog<bool>(
      context: context,
      builder: (context) => BookAppointmentDialog(clinic: clinic),
    );

    if (booked == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Appointment booked successfully!'),
          backgroundColor: Colors.teal,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appointments = AppointmentManager.instance.getDoctorAppointments();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Vets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            tooltip: 'My Location',
            onPressed: _getUserLocation,
          ),
        ],
      ),
      body: Column(
        children: [
          // Map section
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _currentPosition,
                    zoom: 13,
                  ),
                  markers: _markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                ),
                if (_isLoading)
                  const Center(
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(color: Colors.teal),
                      ),
                    ),
                  ),
                // Clinic count chip
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.medical_services, color: Colors.teal, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          '${_clinics.length} vet clinics nearby',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Appointments section
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_month, color: Colors.teal, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Your Appointments',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        if (appointments.isNotEmpty)
                          Chip(
                            label: Text('${appointments.length}'),
                            backgroundColor: Colors.teal.shade50,
                            labelStyle: const TextStyle(
                              color: Colors.teal,
                              fontWeight: FontWeight.bold,
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: appointments.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.event_note, size: 48, color: Colors.grey.shade300),
                                const SizedBox(height: 8),
                                Text(
                                  'No appointments yet',
                                  style: TextStyle(color: Colors.grey.shade500),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Tap a vet marker to book one',
                                  style: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            itemCount: appointments.length,
                            itemBuilder: (context, index) {
                              final appt = appointments[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: appt.isCompleted
                                        ? Colors.green.shade50
                                        : Colors.red.shade50,
                                    child: Icon(
                                      appt.isCompleted
                                          ? Icons.check_circle
                                          : Icons.medical_services,
                                      color: appt.isCompleted ? Colors.green : Colors.red,
                                      size: 22,
                                    ),
                                  ),
                                  title: Text(
                                    appt.title,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      decoration: appt.isCompleted
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${PetTodoListHelpers.formatDate(appt.dueDate)}'
                                    '${appt.dueTime != null ? ' at ${PetTodoListHelpers.formatTime(appt.dueTime)}' : ''}'
                                    '${appt.petName != null ? ' - ${appt.petName}' : ''}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  trailing: Checkbox(
                                    value: appt.isCompleted,
                                    onChanged: (_) {
                                      AppointmentManager.instance
                                          .toggleTaskCompletion(appt.id);
                                    },
                                    activeColor: Colors.teal,
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
