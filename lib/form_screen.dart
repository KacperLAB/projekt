import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:list_picker/list_picker.dart';

class FormScreen extends StatefulWidget {
  FormScreen({super.key});

  @override
  State<FormScreen> createState() => _FormScreenState();
}

FirebaseAuth firebaseAuth = FirebaseAuth.instance;

class _FormScreenState extends State<FormScreen> {
  final listPickerField = ListPickerField(
    label: "Kategoria",
    items: const ["Owoce", "Warzywa", "Mięso", "Nabiał", "Napoje", "Inne"],
  );

  DatabaseReference dbRef = FirebaseDatabase.instance.ref();
  FirebaseStorage storage = FirebaseStorage.instance;

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

  Future<String> _uploadImage(String offerKey) async {
    String imagePath="";
    if (_displayedImage != null) {
      try {
        await storage.ref('images/$offerKey.jpg').putFile(_displayedImage!);
        imagePath = await storage.ref('images/$offerKey.jpg').getDownloadURL();
      } on FirebaseException catch (e) {
        print("Error uploading image: $e");
      }
    }
    if(imagePath.isEmpty)
      return "https://firebasestorage.googleapis.com/v0/b/aplikacja-promocje-87e96.appspot.com/o/images%2Fplaceholder_image.png?alt=media&token=2b162981-1df6-4bf0-b73a-1fd294c3ed64";
    else
      return imagePath;
  }

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _oldPriceController = TextEditingController();
  final TextEditingController _newPriceController = TextEditingController();

  DateTime selectedDate = DateTime.now();
  DateTime selectedDate2 = DateTime.now();
  int ts = 0;
  int ts2 = 0;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: selectedDate,
        firstDate: DateTime.now(),
        lastDate: DateTime(2101));
    if (picked != null) {
      setState(() {
        selectedDate = picked;
        ts = selectedDate.millisecondsSinceEpoch;
      });
    }
  }

  Future<void> _selectDate2(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: selectedDate,
        firstDate: selectedDate,
        lastDate: DateTime(2101));
    if (picked != null) {
      setState(() {
        selectedDate2 = picked;
        ts2 = selectedDate2.millisecondsSinceEpoch;
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
        "data_od": selectedDate.toString(),
        "data_do": selectedDate2.toString(),
        "ocena": 0,
        "autor_id": firebaseAuth.currentUser!.uid,
        "image_path": imagePath
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
            title: Text("Błąd"),
            content: Text("Proszę wybrać daty"),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text("OK"),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Formularz"),
      ),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Nazwa"),
              ),
              TextField(
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                controller: _oldPriceController,
                decoration: const InputDecoration(labelText: "Stara cena"),
              ),
              TextField(
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                controller: _newPriceController,
                decoration: const InputDecoration(labelText: "Nowa cena"),
              ),
              listPickerField,
              Text("${selectedDate.toLocal()}".split(' ')[0]),
              Text("ts_int:" + "${ts}"),
              ElevatedButton(
                onPressed: () => _selectDate(context),
                child: const Text('Data od'),
              ),
              Text("${selectedDate2.toLocal()}".split(' ')[0]),
              Text("ts2_int" + "${ts2}"),
              ElevatedButton(
                onPressed: () => _selectDate2(context),
                child: const Text('Data do'),
              ),
              ElevatedButton(
                onPressed: _addOffer,
                child: Text("Dodaj ogłoszenie"),
              ),
              ElevatedButton(
                onPressed: _pickImageFromGallery,
                child: Text("Wybierz obraz z galerii"),
              ),
              ElevatedButton(
                onPressed: _pickImageFromCamera,
                child: Text("Zrób zdjęcie"),
              ),
              _displayedImage != null
                  ? Image.file(
                      _displayedImage!,
                      height: 100,
                    )
                  : Container(),
            ],
          ),
        ),
      ),
    );
  }
}
