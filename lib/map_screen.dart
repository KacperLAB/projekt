import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_project/models/offer_model.dart';

class MapScreen extends StatelessWidget {
  final Offer offer;

  const MapScreen({Key? key, required this.offer}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double? latitude = offer.offerData?.latitude;
    double? longitude = offer.offerData?.longitude;

    if (latitude != null && longitude != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Lokalizacja oferty"),
        ),
        body: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: LatLng(latitude, longitude),
            zoom: 15,
          ),
          markers: {
            Marker(
              markerId: MarkerId(offer.key!),
              position: LatLng(latitude, longitude),
              infoWindow: InfoWindow(
                title: offer.offerData!.nazwa!,
              ),
            ),
          },
        ),
      );
    } else {
      // gdy latitude lub longitude są null
      return Scaffold(
        appBar: AppBar(
          title: const Text("Błąd"),
        ),
        body: const Center(
          child: Text("Brak dostępnych danych o lokalizacji."),
        ),
      );
    }
  }
}
