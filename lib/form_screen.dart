import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:list_picker/list_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';

class FormScreen extends StatefulWidget {
  FormScreen({super.key});

  @override
  State<FormScreen> createState() => _FormScreenState();
}

FirebaseAuth firebaseAuth = FirebaseAuth.instance;

class _FormScreenState extends State<FormScreen> {
  String selectedLocationText = ""; //do testu lokalizacji
  final listPickerField = ListPickerField(
    label: "Kategoria",
    items: const ["Owoce", "Warzywa", "Mięso", "Nabiał", "Napoje", "Inne"],
  );

  DatabaseReference dbRef = FirebaseDatabase.instance.ref();
  FirebaseStorage storage = FirebaseStorage.instance;

  File? _displayedImage;
  String barcode = "";

  late GoogleMapController _mapController;
  LocationData? _currentLocation;
  LatLng? _selectedLocation;

  Future<void> _getCurrentLocation() async {
    Location location = Location();
    try {
      _currentLocation = await location.getLocation();

      setState(() {
        _selectedLocation =
            LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!);
        selectedLocationText =
            "Latitude: ${_selectedLocation!.latitude}, Longitude: ${_selectedLocation!.longitude}";
      });
    } catch (e) {
      print("Error getting location: $e");
    }
  }

  Future<void> _pickImageFromGallery() async {
    XFile? pickedImage =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        _displayedImage = File(pickedImage.path);
      });
    }
  }

  Future<void> _pickImageFromCamera() async {
    XFile? pickedImage =
        await ImagePicker().pickImage(source: ImageSource.camera);
    if (pickedImage != null) {
      setState(() {
        _displayedImage = File(pickedImage.path);
      });
    }
  }

  Future<String> _uploadImage(String offerKey) async {
    String imagePath = "";
    if (_displayedImage != null) {
      try {
        await storage.ref('images/$offerKey.jpg').putFile(_displayedImage!);
        imagePath = await storage.ref('images/$offerKey.jpg').getDownloadURL();
      } on FirebaseException catch (e) {
        print("Error uploading image: $e");
      }
    }
    if (imagePath.isEmpty) {
      return "";
    } else {
      return imagePath;
    }
  }

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _oldPriceController = TextEditingController();
  final TextEditingController _newPriceController = TextEditingController();

  DateTime dateFrom = DateTime.now();
  DateTime dateTo = DateTime.now().add(const Duration(days: 1));
  int ts = 0;
  int ts2 = 0;

  Future<void> _dateFrom(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: dateFrom,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        dateFrom = picked;
        ts = dateFrom.millisecondsSinceEpoch;
      });
    }
  }

  Future<void> _dateTo(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: dateFrom.add(const Duration(days: 1)),
      firstDate: dateFrom.add(const Duration(days: 1)),
      lastDate: DateTime(2101),
    );

    if (picked != null) {
      setState(() {
        dateTo = picked;
        ts2 = dateTo.millisecondsSinceEpoch;
      });
    }
  }

  Future<void> _addOffer() async {
    if (ts2 >= ts) {
      double stara = double.parse(_oldPriceController.text);
      double nowa = double.parse(_newPriceController.text);
      double przecena = 100 - ((nowa * 100) / stara);

      // Pobierz klucz nowo dodanej oferty
      DatabaseReference newOfferRef = dbRef.child("Oferty").push();
      String offerKey = newOfferRef.key!;

      // Prześlij zdjęcie do Cloud Storage
      String imagePath = await _uploadImage(offerKey);

      // Utwórz mapę danych oferty
      Map<String, dynamic> data = {
        "nazwa": _nameController.text.toString(),
        "kategoria": listPickerField.value,
        "stara_cena": _oldPriceController.text.toString(),
        "nowa_cena": _newPriceController.text.toString(),
        "przecena": przecena.toStringAsFixed(0),
        "data_od": dateFrom.toString(),
        "data_do": dateTo.toString(),
        "autor_id": firebaseAuth.currentUser!.uid,
        "image_path": imagePath,
        "latitude": _selectedLocation!.latitude,
        "longitude": _selectedLocation!.longitude,
        "code": barcode,
        "opis": _descriptionController.text.toString()
      };

      // Zapisz ofertę w bazie danych
      newOfferRef.set(data).then((value) {
        Navigator.of(context).pop();
      });
    } else {
      // Obsługa błędu - użytkownik musi wybrać daty
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Błąd"),
            content: const Text("Proszę wybrać daty"),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("OK"),
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> _pickLocationOnMap() async {
    // Otwórz ekran z mapą do wyboru lokalizacji

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Wybierz lokalizację na mapie'),
          content: SizedBox(
            height: 300,
            width: 300,
            child: GoogleMap(
              onMapCreated: (controller) {
                setState(() {
                  _mapController = controller;
                });
              },
              initialCameraPosition: CameraPosition(
                target: _selectedLocation ?? const LatLng(0, 0),
                zoom: 15.0,
              ),
              onTap: (LatLng point) {
                setState(() {
                  _selectedLocation = point;
                  selectedLocationText =
                      "Latitude: ${point.latitude}, Longitude: ${point.longitude}";
                });
                Navigator.of(context).pop();
              },
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Anuluj'),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dodaj nowe ogłoszenie"),
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              listPickerField,
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                    border: OutlineInputBorder(), hintText: "Nazwa"),
              ),
              TextField(
                controller: _descriptionController,
                maxLines: 5,
                minLines: 2,
                decoration: const InputDecoration(
                    border: OutlineInputBorder(), hintText: "Opis"),
              ),
              TextField(
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                controller: _oldPriceController,
                decoration: const InputDecoration(
                    border: OutlineInputBorder(), hintText: "Stara cena"),
              ),
              TextField(
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                controller: _newPriceController,
                decoration: const InputDecoration(
                    border: OutlineInputBorder(), hintText: "Nowa cena"),
              ),
              Container(
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Text("Data od: "),
                      ElevatedButton(
                        onPressed: () => _dateFrom(context),
                        child: Text("${dateFrom.toLocal()}".split(' ')[0]),
                      ),
                      Text("Data do: "),
                      ElevatedButton(
                        onPressed: () => _dateTo(context),
                        child: Text("${dateTo.toLocal()}".split(' ')[0]),
                      ),
                    ],
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: _pickLocationOnMap,
                child: const Text("Wskaż lokalizacje na mapie"),
              ),
              Container(
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: _pickImageFromGallery,
                        child: const Text("Wybierz zdjęcie"),
                      ),
                      ElevatedButton(
                        onPressed: _pickImageFromCamera,
                        child: const Text("Zrob zdjęcie"),
                      ),
                    ],
                  ),
                ),
              ),
              _displayedImage != null
                  ? Container(
                      decoration: BoxDecoration(
                        border: Border.all(width: 5),
                      ),
                      child: Column(
                        children: [
                          Image.file(
                            _displayedImage!,
                            height: 120,
                          ),
                          ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _displayedImage = null;
                                });
                              },
                              child: Text("Usuń zdjęcie")),
                        ],
                      ))
                  : Container(),
              ElevatedButton(
                  onPressed: () async {
                    var res = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const SimpleBarcodeScannerPage(),
                        ));
                    setState(() {
                      if (res is String) {
                        barcode = res;
                      }
                    });
                  },
                  child: (barcode.isEmpty || barcode == "-1")
                      ? const Text("Skanuj kod")
                      : Text(barcode)),
              ElevatedButton(
                onPressed: _addOffer,
                child: const Icon(Icons.add),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
