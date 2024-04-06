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

  final List<String> allCategories = [
    "Fruits",
    "Vegetables",
    "Meat",
    "Dairy",
    "Beverages",
    "Sweets",
    "Other"
  ];

  TextEditingController priceFromController = TextEditingController();
  TextEditingController priceToController = TextEditingController();
  TextEditingController distanceController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Filter offers"),
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ExpansionTile(
                title: const Text("Categories"),
                children: [
                  ListView.builder(
                    shrinkWrap: true,
                    itemCount: allCategories.length,
                    itemBuilder: (context, index) {
                      final category = allCategories[index];
                      return CheckboxListTile(
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
                      );
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: priceFromController,
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  priceFrom = value.isNotEmpty ? value : null;
                },
                decoration: const InputDecoration(labelText: "Price from"),
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
                decoration: const InputDecoration(labelText: "Price to"),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: distanceController,
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  maxDistance = value.isNotEmpty ? double.parse(value) : null;
                },
                decoration: const InputDecoration(
                  labelText: "Max distance (km)",
                ),
              ),
            ),
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
              child: const Text("Apply"),
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
                  selectedCategories.clear();
                });
              },
              child: const Text("Clear"),
            ),
          ],
        ),
      ),
    );
  }
}
