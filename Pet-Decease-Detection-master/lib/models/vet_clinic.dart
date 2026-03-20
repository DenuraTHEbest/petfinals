class VetClinic {
  final String id;
  final String name;
  final String address;
  final String phone;
  final double latitude;
  final double longitude;
  final double rating;

  const VetClinic({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.latitude,
    required this.longitude,
    required this.rating,
  });

  static List<VetClinic> getSriLankanClinics() {
    return const [
      VetClinic(
        id: 'vet1',
        name: 'Happy Paws Veterinary Clinic',
        address: '12 Galle Road, Colombo 03',
        phone: '+94 11 234 5678',
        latitude: 6.9271,
        longitude: 79.8612,
        rating: 4.5,
      ),
      VetClinic(
        id: 'vet2',
        name: 'Colombo Animal Hospital',
        address: '45 Duplication Road, Colombo 04',
        phone: '+94 11 345 6789',
        latitude: 6.8950,
        longitude: 79.8575,
        rating: 4.8,
      ),
      VetClinic(
        id: 'vet3',
        name: 'Paws & Claws Vet Center',
        address: '78 Havelock Road, Colombo 05',
        phone: '+94 11 456 7890',
        latitude: 6.8820,
        longitude: 79.8680,
        rating: 4.3,
      ),
      VetClinic(
        id: 'vet4',
        name: 'Lanka Pet Care Clinic',
        address: '23 Baseline Road, Borella',
        phone: '+94 11 567 8901',
        latitude: 6.9150,
        longitude: 79.8750,
        rating: 4.6,
      ),
      VetClinic(
        id: 'vet5',
        name: 'Royal Veterinary Care',
        address: '56 Bauddhaloka Mawatha, Colombo 07',
        phone: '+94 11 678 9012',
        latitude: 6.9050,
        longitude: 79.8620,
        rating: 4.7,
      ),
      VetClinic(
        id: 'vet6',
        name: 'City Animal Clinic',
        address: '34 Union Place, Colombo 02',
        phone: '+94 11 789 0123',
        latitude: 6.9180,
        longitude: 79.8530,
        rating: 4.2,
      ),
    ];
  }
}
