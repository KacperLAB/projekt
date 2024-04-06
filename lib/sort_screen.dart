import 'package:flutter/material.dart';
import 'package:firebase_project/models/offer_model.dart';

class SortScreen extends StatelessWidget {
  final List<Offer> offerList;
  final Function(String, bool) sortOfferList;

  const SortScreen(
      {Key? key, required this.offerList, required this.sortOfferList})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Sort offers"),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  sortOfferList("nazwa", true);
                  Navigator.pop(context);
                },
                child: const Text("Sort by name A-Z"),
              ),
              ElevatedButton(
                onPressed: () {
                  sortOfferList("nazwa", false);
                  Navigator.pop(context);
                },
                child: const Text("Sort by name Z-A"),
              ),
              ElevatedButton(
                onPressed: () {
                  sortOfferList("data_od", true);
                  Navigator.pop(context);
                },
                child: const Text("Latest added"),
              ),
              ElevatedButton(
                onPressed: () {
                  sortOfferList("data_od", false);
                  Navigator.pop(context);
                },
                child: const Text("Earliest added"),
              ),
              ElevatedButton(
                onPressed: () {
                  sortOfferList("przecena", false);
                  Navigator.pop(context);
                },
                child: const Text("Discount descending"),
              ),
              ElevatedButton(
                onPressed: () {
                  sortOfferList("przecena", true);
                  Navigator.pop(context);
                },
                child: const Text("Discount ascending"),
              ),
              ElevatedButton(
                onPressed: () {
                  sortOfferList("cena", true);
                  Navigator.pop(context);
                },
                child: const Text("Price ascending"),
              ),
              ElevatedButton(
                onPressed: () {
                  sortOfferList("cena", false);
                  Navigator.pop(context);
                },
                child: const Text("Price descending"),
              ),
            ],
          ),
        ));
  }
}
