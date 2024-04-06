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
  final listPickerField = ListPickerField(
    label: "Category",
    items: const ["Fruits",
      "Vegetables",
      "Meat",
      "Dairy",
      "Beverages",
      "Sweets",
      "Other"],
  );

  DatabaseReference dbRef = FirebaseDatabase.instance.ref();



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
      });
    } catch (e) {
      print("Error getting location: $e");
    }
  }

  File? _displayedImage;

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

  FirebaseStorage storage = FirebaseStorage.instance;

  Future<String> _uploadImage(String offerKey) async {
    String imagePath = "";
    if (_displayedImage != null) {
      try {
        await storage.ref('images/$offerKey.jpg').putFile(_displayedImage!); //przesłanie pliku
        imagePath = await storage.ref('images/$offerKey.jpg').getDownloadURL(); //pobranie URL
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
      });
    }
  }

  Future<void> _addOffer() async {
      double stara = double.parse(_oldPriceController.text);
      double nowa = double.parse(_newPriceController.text);
      double przecena = 100 - ((nowa * 100) / stara);
      DatabaseReference newOfferRef = dbRef.child("Oferty").push();
      String offerKey = newOfferRef.key!;
      String imagePath = await _uploadImage(offerKey);
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
      newOfferRef.set(data).then((value) {Navigator.of(context).pop();});
  }

  Future<void> _pickLocationOnMap() async {
    // Otwórz ekran z mapą do wyboru lokalizacji

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Pick location on map'),
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
              child: const Text('Cancel'),
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
        title: const Text("Add new offer"),
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
                    border: OutlineInputBorder(), hintText: "Name"),
              ),
              TextField(
                controller: _descriptionController,
                maxLines: 5,
                minLines: 2,
                decoration: const InputDecoration(
                    border: OutlineInputBorder(), hintText: "Description"),
              ),
              TextField(
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                controller: _oldPriceController,
                decoration: const InputDecoration(
                    border: OutlineInputBorder(), hintText: "Old price"),
              ),
              TextField(
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                controller: _newPriceController,
                decoration: const InputDecoration(
                    border: OutlineInputBorder(), hintText: "New price"),
              ),
              Container(
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      const Text("Date from: "),
                      ElevatedButton(
                        onPressed: () => _dateFrom(context),
                        child: Text("${dateFrom.toLocal()}".split(' ')[0]),
                      ),
                      const Text("Date to: "),
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
                child: const Text("Pick location on map"),
              ),
              Container(
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: _pickImageFromGallery,
                        child: const Text("Pick photo"),
                      ),
                      ElevatedButton(
                        onPressed: _pickImageFromCamera,
                        child: const Text("Take photo"),
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
                              child: const Text("Delete photo")),
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
                      ? const Text("Scan barcode")
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
