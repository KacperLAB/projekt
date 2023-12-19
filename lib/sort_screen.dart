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
        title: const Text("Sortuj oferty"),
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
              child: const Text("Sortuj po nazwie A-Z"),
            ),
            ElevatedButton(
              onPressed: () {
                sortOfferList("nazwa", false);
                Navigator.pop(context);
              },
              child: const Text("Sortuj po nazwie Z-A"),
            ),
            ElevatedButton(
              onPressed: () {
                sortOfferList("data_od", true);
                Navigator.pop(context);
              },
              child: const Text("Dodane najpozniej"),
            ),
            ElevatedButton(
              onPressed: () {
                sortOfferList("data_od", false);
                Navigator.pop(context);
              },
              child: const Text("Dodane najwczesniej"),
            ),
            ElevatedButton(
              onPressed: () {
                sortOfferList("przecena", false);
                Navigator.pop(context);
              },
              child: const Text("Przecena malejąco"),
            ),
            ElevatedButton(
              onPressed: () {
                sortOfferList("przecena", true);
                Navigator.pop(context);
              },
              child: const Text("Przecena rosnąco"),
            ),
            ElevatedButton(
              onPressed: () {
                sortOfferList("cena", true);
                Navigator.pop(context);
              },
              child: const Text("Cena rosnąco"),
            ),
            ElevatedButton(
              onPressed: () {
                sortOfferList("cena", false);
                Navigator.pop(context);
              },
              child: const Text("Cena malejąco"),
            ),
          ],
        ),
      )
    );
  }
}
