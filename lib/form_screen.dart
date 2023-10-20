import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:list_picker/list_picker.dart';

class FormScreen extends StatefulWidget {
  FormScreen({super.key});

  @override
  State<FormScreen> createState() => _FormScreenState();
}

class _FormScreenState extends State<FormScreen> {
  final listPickerField = ListPickerField(
    label: "Kategoria",
    items: const ["Owoce", "Warzywa", "Mięso", "Nabiał", "Napoje", "Inne"],
  );

  DatabaseReference dbRef = FirebaseDatabase.instance.ref();

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Formularz"),
        ),
        body: Center(
            child: Container(
          padding: const EdgeInsets.all(10),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Nazwa")),
            TextField(
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                controller: _oldPriceController,
                decoration: const InputDecoration(labelText: "Stara cena")),
            TextField(
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                controller: _newPriceController,
                decoration: const InputDecoration(labelText: "Nowa cena")),
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
                onPressed: () {
                  if (ts2 >= ts) {
                    double stara = double.parse(_oldPriceController.text);
                    double nowa = double.parse(_newPriceController.text);
                    double przecena = 100 - ((nowa * 100) / stara);

                    Map<String, dynamic> data = {
                      "nazwa": _nameController.text.toString(),
                      "kategoria": listPickerField.value,
                      "stara_cena": _oldPriceController.text.toString(),
                      "nowa_cena": _newPriceController.text.toString(),
                      "przecena": przecena.toStringAsFixed(0),
                      "data_od": selectedDate.toString(),
                      "data_do": selectedDate2.toString(),
                      "ocena": 0
                    };
                    dbRef.child("Oferty").push().set(data).then((value) {
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
                },
                child: Text("Dodaj ogłoszenie"))
          ]),
        )));
  }
}
