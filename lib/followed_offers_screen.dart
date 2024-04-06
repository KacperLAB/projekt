import 'package:flutter/material.dart';
import 'package:firebase_project/models/offer_model.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_project/details_screen.dart';

class FollowedOffersScreen extends StatefulWidget {
  @override
  _FollowedOffersScreenState createState() => _FollowedOffersScreenState();
}

FirebaseAuth firebaseAuth = FirebaseAuth.instance;

class _FollowedOffersScreenState extends State<FollowedOffersScreen> {
  List<Offer> followedOffersList = [];
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
        title: const Text("Followed offers"),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            for (int i = 0; i < followedOffersList.length; i++)
              offerWidget(followedOffersList[i])
          ],
        ),
      ),
    );
  }

  void retrieveOffersData() {
    followedOffersList.clear();
    String? currentUserID = firebaseAuth.currentUser?.uid;
    final DateTime currentDate = DateTime.now();

    if (currentUserID != null) {
      dbRef.child("Oferty").onChildAdded.listen((data) {
        OfferData offerData = OfferData.fromJson(data.snapshot.value as Map);
        DateTime dataOd = DateTime.parse(offerData.data_od!);
        DateTime dataDo = DateTime.parse(offerData.data_do!);
        dbRef
            .child('Oferty/${data.snapshot.key}/obserwujacy')
            .orderByChild('uid')
            .equalTo(currentUserID)
            .once()
            .then((event) {
          DataSnapshot snapshot = event.snapshot;
          Map<dynamic, dynamic>? followerData =
              snapshot.value as Map<dynamic, dynamic>?;

          if (currentDate.isAfter(dataOd) && currentDate.isBefore(dataDo)) {
            if (followerData != null && followerData.isNotEmpty) {
              Offer offer = Offer(key: data.snapshot.key, offerData: offerData);
              followedOffersList.add(offer);
              setState(() {});
            }
          } else if (currentDate.isAfter(dataOd) &&
              currentDate.isAfter(dataDo)) {
            dbRef.child("Oferty").child(data.snapshot.key!).remove();
          }
        });
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
          border: Border.all(color: Colors.black, width: 3),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Name: ${offer.offerData!.nazwa!}"),
                Text("Category: ${offer.offerData!.kategoria!}"),
                //Text(offer.offerData!.stara_cena!),
                Text("Price: ${offer.offerData!.nowa_cena!} zł"),
                Text("Discount: ${offer.offerData!.przecena!}%"),
                //Text(offer.offerData!.data_od!.split(' ')[0]),
                Text("Valid to: ${offer.offerData!.data_do!.split(' ')[0]}"),
              ],
            ),
            if (offer.offerData!.image_path != "")
              Container(
                height: 120,
                width: 120,
                decoration: BoxDecoration(
                  border: Border.all(width: 5),
                ),
                child: Image.network(offer.offerData!.image_path!),
              )
            else
              Container(
                height: 120,
                width: 120,
                decoration: BoxDecoration(
                  border: Border.all(width: 5),
                ),
                child: Image.asset(
                    'assets/placeholder_image.png' // Zastępcze zdjęcie
                    ),
              ),
          ],
        ),
      ),
    );
  }
}
