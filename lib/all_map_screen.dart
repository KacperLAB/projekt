import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_project/models/student_model.dart';

class AllMapScreen extends StatefulWidget {
  const AllMapScreen({Key? key, required this.studentList}) : super(key: key);

  final List<Student> studentList;

  @override
  _AllMapScreenState createState() => _AllMapScreenState();
}

class _AllMapScreenState extends State<AllMapScreen> {
  late GoogleMapController _mapController;
  Set<Marker> _markers = Set();

  @override
  void initState() {
    super.initState();
    _populateMarkers();
  }

  void _populateMarkers() {
    for (var student in widget.studentList) {
      if (student.studentData!.latitude != null &&
          student.studentData!.longitude != null) {
        _markers.add(
          Marker(
            markerId: MarkerId(student.key!),
            position: LatLng(
              student.studentData!.latitude!,
              student.studentData!.longitude!,
            ),
            infoWindow: InfoWindow(title: student.studentData!.nazwa!),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Mapa Ogłoszeń"),
      ),
      body: GoogleMap(
        onMapCreated: (controller) {
          setState(() {
            _mapController = controller;
          });
        },
        markers: _markers,
        initialCameraPosition: CameraPosition(
          target: LatLng(52.5200, 13.4050), // Początkowe współrzędne mapy
          zoom: 15,
        ),
      ),
    );
  }
}