import 'package:flutter/material.dart';
import 'package:firebase_project/models/offer_model.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_project/details_screen.dart';

class UserOffersScreen extends StatefulWidget {
  @override
  _UserOffersScreenState createState() => _UserOffersScreenState();
}

FirebaseAuth firebaseAuth = FirebaseAuth.instance;

class _UserOffersScreenState extends State<UserOffersScreen> {
  List<Offer> userOffersList = [];
  DatabaseReference dbRef = FirebaseDatabase.instance.ref();

  @override
  void initState() {
    super.initState();
    retrieveOffersData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Moje ogłoszenia"),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            for (int i = 0; i < userOffersList.length; i++)
              offerWidget(userOffersList[i])
          ],
        ),
      ),
    );
  }

  // Reszta kodu pozostaje bez zmian

  void retrieveOffersData() {
    userOffersList.clear();
    String? currentUserID = firebaseAuth.currentUser?.uid;
    final DateTime currentDate = DateTime.now();
    if (currentUserID != null) {
      dbRef
          .child("Oferty")
          .orderByChild("autor_id")
          .equalTo(currentUserID)
          .onChildAdded
          .listen((data) {
        OfferData offerData =
            OfferData.fromJson(data.snapshot.value as Map);
        DateTime dataOd = DateTime.parse(offerData.data_od!);
        DateTime dataDo = DateTime.parse(offerData.data_do!);
        if ((currentDate.isAfter(dataOd) && currentDate.isBefore(dataDo)) ||
            (currentDate.isBefore(dataOd) && currentDate.isBefore(dataDo))) {
          Offer offer =
              Offer(key: data.snapshot.key, offerData: offerData);
          userOffersList.add(offer);
          setState(() {});
        } else if (currentDate.isAfter(dataOd) && currentDate.isAfter(dataDo)) {
          dbRef.child("Oferty").child(data.snapshot.key!).remove();
        }
      });
    }
  }

  //widget pojedynczej oferty
  Widget offerWidget(Offer offer) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => OfferDetailsScreen(offer: offer),
        ));
      },
      child: Container(
        width: MediaQuery.of(context).size.width,
        padding: const EdgeInsets.all(5),
        margin: const EdgeInsets.only(top: 5, left: 10, right: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.black,width: 3),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Nazwa: ${offer.offerData!.nazwa!}"),
                Text("Kategoria: ${offer.offerData!.kategoria!}"),
                //Text(offer.offerData!.stara_cena!),
                Text("Cena: ${offer.offerData!.nowa_cena!} zł"),
                Text("Przecena: ${offer.offerData!.przecena!}%"),
                //Text(offer.offerData!.data_od!.split(' ')[0]),
                Text("Ważne do: ${offer.offerData!.data_do!.split(' ')[0]}"),
              ],
            ),
            if (offer.offerData!.image_path != "")
              Container(
                height: 120,
                width: 120,
                decoration: BoxDecoration(
                  border: Border.all(width: 5),
                ),
                child: Image.network(offer.offerData!.image_path!
                ),
              )
            else
              Container(
                height: 120,
                width: 120,
                decoration: BoxDecoration(
                  border: Border.all(width: 5),
                ),
                child: Image.asset('assets/placeholder_image.png' // Zastępcze zdjęcie
                ),
              ),
          ],
        ),
      ),
    );
  }
}
