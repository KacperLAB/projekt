import 'package:flutter/material.dart';
import 'package:firebase_project/models/student_model.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_project/details_screen.dart';

class FollowedOffersScreen extends StatefulWidget {
  @override
  _FollowedOffersScreenState createState() => _FollowedOffersScreenState();
}

FirebaseAuth firebaseAuth = FirebaseAuth.instance;

class _FollowedOffersScreenState extends State<FollowedOffersScreen> {
  List<Student> followedOffersList = [];
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
        title: const Text("Obserwowane ogłoszenia"),
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

  // Reszta kodu pozostaje bez zmian

  void retrieveOffersData() {
    followedOffersList.clear();
    String? currentUserID = firebaseAuth.currentUser?.uid;
    final DateTime currentDate = DateTime.now();

    if (currentUserID != null) {
      dbRef.child("Oferty").onChildAdded.listen((data) {
        StudentData studentData =
            StudentData.fromJson(data.snapshot.value as Map);
        DateTime dataOd = DateTime.parse(studentData.data_od!);
        DateTime dataDo = DateTime.parse(studentData.data_do!);

        // Sprawdź, czy obserwujący aktualnie zalogowanego użytkownika znajduje się w liście obserwujących oferty
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
            // Oferta jest aktualna
            if (followerData != null && followerData.isNotEmpty) {
              // Znaleziono obserwującego, dodaj ofertę do listy
              Student student =
                  Student(key: data.snapshot.key, studentData: studentData);
              followedOffersList.add(student);
              setState(() {});
            }
          } else if (currentDate.isAfter(dataOd) &&
              currentDate.isAfter(dataDo)) {
            // Oferta przeterminowana, usuń z bazy danych
            dbRef.child("Oferty").child(data.snapshot.key!).remove();
          }
        });
      });
    }
  }

  //widget pojedynczej oferty
  Widget offerWidget(Student student) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => OfferDetailsScreen(student: student),
        ));
      },
      child: Container(
        width: MediaQuery.of(context).size.width,
        padding: const EdgeInsets.all(5),
        margin: const EdgeInsets.only(top: 5, left: 10, right: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.black),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(student.studentData!.nazwa!),
                Text(student.studentData!.kategoria!),
                Text(student.studentData!.stara_cena!),
                Text(student.studentData!.nowa_cena!),
                Text("${student.studentData!.przecena!}%"),
                Text(student.studentData!.data_od!.split(' ')[0]),
                Text(student.studentData!.data_do!.split(' ')[0]),
              ],
            ),
            if (student.studentData!.image_path != "")
              Image.network(
                student.studentData!.image_path!,
                height: 100,
                width: 100,
                fit: BoxFit.cover,
              )
            else
              Image.asset(
                'assets/placeholder_image.png', // Zastępcze zdjęcie
                height: 100,
                width: 100,
                fit: BoxFit.cover,
              ),
          ],
        ),
      ),
    );
  }
}
