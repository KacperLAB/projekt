import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_project/models/student_model.dart';

class MapScreen extends StatelessWidget {
  final Student student;

  const MapScreen({Key? key, required this.student}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double? latitude = student.studentData?.latitude;
    double? longitude = student.studentData?.longitude;

    if (latitude != null && longitude != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text("Lokalizacja oferty"),
        ),
        body: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: LatLng(latitude, longitude),
            zoom: 15,
          ),
          markers: {
            Marker(
              markerId: MarkerId(student.key!),
              position: LatLng(latitude, longitude),
              infoWindow: InfoWindow(
                title: student.studentData!.nazwa!,
              ),
            ),
          },
        ),
      );
    } else {
      // gdy latitude lub longitude są null
      return Scaffold(
        appBar: AppBar(
          title: Text("Błąd"),
        ),
        body: Center(
          child: Text("Brak dostępnych danych o lokalizacji."),
        ),
      );
    }
  }
}

