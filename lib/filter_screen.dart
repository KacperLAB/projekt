import 'package:flutter/material.dart';

class FilterScreen extends StatefulWidget {
  final Function({
    List<String> categories,
    String? priceFrom,
    String? priceTo,
    double? maxDistance,
  }) applyFilter;

  const FilterScreen({Key? key, required this.applyFilter}) : super(key: key);

  @override
  _FilterScreenState createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  List<String> selectedCategories = [];
  String? priceFrom;
  String? priceTo;
  double? maxDistance;

  // Lista dostępnych kategorii
  final List<String> allCategories = [
    "Owoce",
    "Warzywa",
    "Mięso",
    "Nabiał",
    "Napoje",
    "Inne"
  ];

  TextEditingController priceFromController = TextEditingController();
  TextEditingController priceToController = TextEditingController();
  TextEditingController distanceController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Filtruj oferty"),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: () {
              widget.applyFilter(
                categories: selectedCategories,
                priceFrom: priceFrom,
                priceTo: priceTo,
                maxDistance: maxDistance,
              );
              Navigator.pop(context);
            },
            child: const Text("Zastosuj filtry"),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                selectedCategories.clear();
              });
            },
            child: const Text("Wyczyść kategorie"),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                priceFromController.clear();
                priceToController.clear();
                distanceController.clear();
                priceFrom = null;
                priceTo = null;
                maxDistance = null;
              });
            },
            child: const Text("Wyczyść filtry"),
          ),
          // Rozwijana lista kategorii
          ExpansionTile(
            title: const Text("Kategorie"),
            children: [
              for (final category in allCategories)
                CheckboxListTile(
                  title: Text(category),
                  value: selectedCategories.contains(category),
                  onChanged: (value) {
                    setState(() {
                      if (value!) {
                        selectedCategories.add(category);
                      } else {
                        selectedCategories.remove(category);
                      }
                    });
                  },
                ),
            ],
          ),
          // Kontrolki do wprowadzenia wartości filtru cenowego
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: priceFromController,
              keyboardType: TextInputType.number,
              onChanged: (value) {
                priceFrom = value.isNotEmpty ? value : null;
              },
              decoration: const InputDecoration(labelText: "Cena od"),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: priceToController,
              keyboardType: TextInputType.number,
              onChanged: (value) {
                priceTo = value.isNotEmpty ? value : null;
              },
              decoration: const InputDecoration(labelText: "Cena do"),
            ),
          ),
          // Kontrolka do wprowadzenia maksymalnej odległości
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: distanceController,
              keyboardType: TextInputType.number,
              onChanged: (value) {
                maxDistance = value.isNotEmpty ? double.parse(value) : null;
              },
              decoration:
                  const InputDecoration(labelText: "Maksymalna odległość (km)"),
            ),
          ),
        ],
      ),
    );
  }
}
