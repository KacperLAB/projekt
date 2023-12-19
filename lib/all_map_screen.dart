import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_project/models/offer_model.dart';
import 'package:location/location.dart';

class AllMapScreen extends StatefulWidget {
  const AllMapScreen({Key? key, required this.offerList}) : super(key: key);

  final List<Offer> offerList;

  @override
  _AllMapScreenState createState() => _AllMapScreenState();
}

class _AllMapScreenState extends State<AllMapScreen> {
  late GoogleMapController _mapController;
  Set<Marker> _markers = Set();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _populateMarkers();
  }

  void _populateMarkers() {
    for (var offer in widget.offerList) {
      if (offer.offerData!.latitude != null &&
          offer.offerData!.longitude != null) {
        _markers.add(
          Marker(
            markerId: MarkerId(offer.key!),
            position: LatLng(
              offer.offerData!.latitude!,
              offer.offerData!.longitude!,
            ),
            infoWindow: InfoWindow(title: offer.offerData!.nazwa!),
          ),
        );
      }
    }
  }

  LocationData? _currentLocation;
  LatLng? _selectedLocation;

  Future<void> _getCurrentLocation() async {
    setState(() {
      isLoading = true;
    });
    Location location = Location();
    try {
      _currentLocation = await location.getLocation();
      setState(() {
        _selectedLocation =
            LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!);
        isLoading=false;
      });
    } catch (e) {
      print("Error getting location: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 350,
              width: 350,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
            ElevatedButton(onPressed: () {Navigator.of(context).pop();}, child: Text("Anuluj"))
          ],
        ),
      );
  }
    else {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Mapa Ogłoszeń"),
        ),
        body:
        GoogleMap(
          onMapCreated: (controller) {
            setState(() {
              _mapController = controller;
            });
          },
          markers: _markers,
          initialCameraPosition: CameraPosition(
            target:
            LatLng(_selectedLocation!.latitude, _selectedLocation!.longitude),
            // Początkowe współrzędne mapy
            zoom: 10,
          ),
        ),
      );
    }
  }
}
