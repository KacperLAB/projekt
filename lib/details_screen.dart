import 'package:flutter/material.dart';
import 'package:firebase_project/models/offer_model.dart';
import 'package:firebase_project/models/comment_model.dart';
import 'package:firebase_project/models/rating_model.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_project/map_screen.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';

class OfferDetailsScreen extends StatefulWidget {
  final Offer offer;

  OfferDetailsScreen({required this.offer});

  @override
  _OfferDetailsScreenState createState() => _OfferDetailsScreenState();
}

FirebaseAuth firebaseAuth = FirebaseAuth.instance;

class _OfferDetailsScreenState extends State<OfferDetailsScreen> {
  final TextEditingController _commentController = TextEditingController();
  String? user = firebaseAuth.currentUser?.email;
  DatabaseReference dbRef = FirebaseDatabase.instance.ref();

  List<Comment> comments = [];
  List<Rating> ratings = [];

  int positiveRatings = 0;
  int negativeRatings = 0;

  @override
  void initState() {
    super.initState();
    fetchComments();
    fetchRatings();
  }

  void fetchComments() async {
    DataSnapshot dataSnapshot =
        await dbRef.child('Oferty/${widget.offer.key}/komentarze').get();
    if (dataSnapshot.value != null && dataSnapshot.value is Map) {
      Map<dynamic, dynamic> commentsData =
          dataSnapshot.value as Map<dynamic, dynamic>;
      List<Comment> commentList = [];
      commentsData.forEach((key, value) {
        commentList.add(Comment(
          author: value['author'],
          text: value['text'],
          timestamp: value['timestamp'],
        ));
      });

      setState(() {
        comments = commentList;
      });
    }
  }

  void fetchRatings() {
    dbRef.child('Oferty/${widget.offer.key}/oceny').onValue.listen((event) {
      if (event.snapshot.value != null && event.snapshot.value is Map) {
        Map<dynamic, dynamic> ratingsData =
            event.snapshot.value as Map<dynamic, dynamic>;
        List<Rating> ratingsList = [];
        int positiveCount = 0;
        int negativeCount = 0;

        ratingsData.forEach((key, value) {
          ratingsList.add(Rating(
            author: value['author'],
            rating: value['rating'],
            timestamp: value['timestamp'],
          ));

          // Zliczanie ocen pozytywnych i negatywnych
          if (value['rating'] == 1) {
            positiveCount++;
          } else if (value['rating'] == -1) {
            negativeCount--;
          }
        });

        setState(() {
          ratings = ratingsList;
          positiveRatings = positiveCount;
          negativeRatings = negativeCount;
        });
      }
    });
  }

  bool hasUserRated() {
    // Sprawdź, czy użytkownik już wcześniej ocenił ofertę
    return ratings.any((rating) => rating.author == user);
  }

  bool hasUserRatedPositive() {
    // Sprawdź, czy użytkownik już wcześniej ocenił ofertę pozytywnie
    return ratings.any((rating) => rating.author == user && rating.rating == 1);
  }

  bool hasUserRatedNegative() {
    // Sprawdź, czy użytkownik już wcześniej ocenił ofertę negatywnie
    return ratings
        .any((rating) => rating.author == user && rating.rating == -1);
  }

  void increaseRating() {
    if (!hasUserRated()) {
      dbRef.child('Oferty/${widget.offer.key}/oceny').push().set(
            Rating(
              author: user!,
              rating: 1,
              timestamp: DateTime.now().toUtc().toString(),
            ).toJson(),
          );
    } else {
      // Informacja dla użytkownika, że już wcześniej ocenił ofertę
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Już wcześniej oceniłeś tę ofertę.'),
        ),
      );
    }
  }

  void decreaseRating() {
    if (!hasUserRated()) {
      dbRef.child('Oferty/${widget.offer.key}/oceny').push().set(
            Rating(
              author: user!,
              rating: -1,
              timestamp: DateTime.now().toUtc().toString(),
            ).toJson(),
          );
    } else {
      // Informacja dla użytkownika, że już wcześniej ocenił ofertę
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Już wcześniej oceniłeś tę ofertę.'),
        ),
      );
    }
  }

  ElevatedButton buildRatingButton(bool isPositive) {
    return ElevatedButton(
      onPressed: isPositive ? increaseRating : decreaseRating,
      style: ElevatedButton.styleFrom(
        backgroundColor: isPositive
            ? hasUserRatedPositive()
                ? Colors.lightGreen
                : null
            : hasUserRatedNegative()
                ? Colors.red[200]
                : null,
      ),
      child: Icon(
        isPositive ? Icons.thumb_up : Icons.thumb_down,
        color: Colors.black,
      ),
    );
  }

  void addComment() {
    String commentText = _commentController.text
        .trim(); // Usunięcie białych znaków z początku i końca

    if (commentText.isNotEmpty) {
      String timestamp = DateTime.now().toUtc().toString();

      Comment newComment = Comment(
        author: user!,
        text: commentText,
        timestamp: timestamp,
      );

      dbRef
          .child('Oferty/${widget.offer.key}/komentarze')
          .push()
          .set(newComment.toJson());
      _commentController.clear();
      fetchComments();
    } else {
      // Komunikat, że komentarz nie może być pusty
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Komentarz nie może być pusty.'),
      ));
    }
  }

  void addFollow() {
    dbRef
        .child('Oferty/${widget.offer.key}/obserwujacy')
        .push()
        .set({"uid": firebaseAuth.currentUser!.uid, "email": user});
  }

  void toggleFollow() async {
    String userID = firebaseAuth.currentUser?.uid ?? '';
    String? offerID = widget.offer.key;

    // Pobierz referencję do danych obserwujących dla danej oferty
    DatabaseReference followersRef = dbRef.child('Oferty/$offerID/obserwujacy');

    // Sprawdź, czy użytkownik już obserwuje ofertę
    DatabaseEvent event =
        await followersRef.orderByChild('uid').equalTo(userID).once();
    DataSnapshot snapshot = event.snapshot;

    Map<dynamic, dynamic>? values = snapshot.value as Map<dynamic, dynamic>?;

    if (values == null || values.isEmpty) {
      // Jeśli użytkownik nie obserwuje oferty, dodaj go do listy obserwujących
      DatabaseReference newFollowerRef = followersRef.push();
      newFollowerRef.set({
        "uid": userID,
        "email": user, // Zakładając, że 'user' jest zdefiniowane wcześniej
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dodano do obserwowanych.'),
        ),
      );
    } else {
      // Jeśli użytkownik już obserwuje ofertę, usuń go z listy obserwujących
      values.forEach((key, value) {
        dbRef.child('Oferty/$offerID/obserwujacy/$key').remove();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Usunięto z obserwowanych.'),
          ),
        );
      });
    }
  }

  String barcode = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.offer.offerData!.nazwa!),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0), // Dostosuj wartość marginesu według potrzeb
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              if (widget.offer.offerData!.image_path != "")
              Container(
                height: 200,
                width: 200,
                decoration: BoxDecoration(
                  border: Border.all(width: 5),
                ),
                child: Image.network(widget.offer.offerData!.image_path!
                ),
              )
              else
                Container(
                  height: 200,
                  width: 200,
                  decoration: BoxDecoration(
                    border: Border.all(width: 5),
                  ),
                  child: Image.asset('assets/placeholder_image.png' // Zastępcze zdjęcie
                  ),
                ),
              Text("Kategoria: ${widget.offer.offerData!.kategoria!}"),
              Text("Stara cena: ${widget.offer.offerData!.stara_cena!}"),
              Text("Nowa cena: ${widget.offer.offerData!.nowa_cena!}"),
              Text("Przecena: ${widget.offer.offerData!.przecena!}%"),
              Text(
                  "Data od: ${widget.offer.offerData!.data_od!.split(' ')[0]}"),
              Text(
                  "Data do: ${widget.offer.offerData!.data_do!.split(' ')[0]}"),
              Text("Oceny pozytywne: $positiveRatings"),
              Text("Oceny negatywne: $negativeRatings"),

              if (firebaseAuth.currentUser?.email != null &&
                  widget.offer.offerData!.autor_id! !=
                      firebaseAuth.currentUser?.uid)
                buildRatingButton(true),
              if (firebaseAuth.currentUser?.email != null &&
                  widget.offer.offerData!.autor_id! !=
                      firebaseAuth.currentUser?.uid)
                buildRatingButton(false),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MapScreen(offer: widget.offer),
                    ),
                  );
                },
                child: const Text("Pokaż na mapie"),
              ),
              if (firebaseAuth.currentUser?.email != null &&
                  widget.offer.offerData!.autor_id! !=
                      firebaseAuth.currentUser?.uid)
                ElevatedButton(
                    onPressed: toggleFollow, child: const Text("Obserwuj")),
              ElevatedButton(
                onPressed: () async {
                  var res = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SimpleBarcodeScannerPage(),
                      ));
                  setState(() {
                    if (res is String) {
                      barcode = res;
                    }
                  });
                },
                child: const Text("Porównaj kod"),
              ),
              if (barcode.isNotEmpty &&
                  barcode == widget.offer.offerData!.code! &&
                  widget.offer.offerData!.code!.isNotEmpty)
                const Text("Kod poprawny"),
              if (barcode.isNotEmpty &&
                  barcode != widget.offer.offerData!.code! &&
                  widget.offer.offerData!.code!.isNotEmpty)
                const Text("Kod niepoprawny"),
              if (firebaseAuth.currentUser?.email != null)
               TextField(
                    controller: _commentController,
                    maxLines: 5,
                    minLines: 1,
                    decoration: const InputDecoration(border: OutlineInputBorder(),hintText: "Komentarz"),
                  )
              else
                Container(),
              if (firebaseAuth.currentUser?.email != null)
                ElevatedButton(
                  onPressed: addComment,
                  child: const Text("Dodaj komentarz"),
                )
              else
                Container(),
              const Text("Komentarze:"),

              // Dodaj ten kontener z ograniczeniami wysokości
              Container(
                height: MediaQuery.of(context).size.height * 0.5, // Dostosuj wysokość według potrzeb
                child: comments.isNotEmpty
                    ? ListView.builder(
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(comments[index].text),
                      subtitle: Text("Autor: ${comments[index].author}"),
                    );
                  },
                )
                    : const Center(child: Text("Brak komentarzy.")),
              ),
            ],
          ),
        ),
      ),
    );
  }


}

/*
Text("Kategoria: ${widget.offer.offerData!.kategoria!}"),
            Text("Stara cena: ${widget.offer.offerData!.stara_cena!}"),
            Text("Nowa cena: ${widget.offer.offerData!.nowa_cena!}"),
            Text("Przecena: ${widget.offer.offerData!.przecena!}%"),
            Text(
                "Data od: ${widget.offer.offerData!.data_od!.split(' ')[0]}"),
            Text(
                "Data do: ${widget.offer.offerData!.data_do!.split(' ')[0]}"),
            Text("Oceny pozytywne: $positiveRatings"),
            Text("Oceny negatywne: $negativeRatings"),
            if (widget.offer.offerData!.image_path != "")
              Image.network(
                widget.offer.offerData!.image_path!,
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
            if (firebaseAuth.currentUser?.email != null &&
                widget.offer.offerData!.autor_id! !=
                    firebaseAuth.currentUser?.uid)
              buildRatingButton(true),
            if (firebaseAuth.currentUser?.email != null &&
                widget.offer.offerData!.autor_id! !=
                    firebaseAuth.currentUser?.uid)
              buildRatingButton(false),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MapScreen(offer: widget.offer),
                  ),
                );
              },
              child: const Text("Pokaż na mapie"),
            ),
            if (firebaseAuth.currentUser?.email != null &&
                widget.offer.offerData!.autor_id! !=
                    firebaseAuth.currentUser?.uid)
              ElevatedButton(
                  onPressed: toggleFollow, child: const Text("Obserwuj")),
            ElevatedButton(
              onPressed: () async {
                var res = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SimpleBarcodeScannerPage(),
                    ));
                setState(() {
                  if (res is String) {
                    barcode = res;
                  }
                });
              },
              child: const Text("Porównaj kod"),
            ),
            if (barcode.isNotEmpty &&
                barcode == widget.offer.offerData!.code! &&
                widget.offer.offerData!.code!.isNotEmpty)
              const Text("Kod poprawny"),
            if (barcode.isNotEmpty &&
                barcode != widget.offer.offerData!.code! &&
                widget.offer.offerData!.code!.isNotEmpty)
              const Text("Kod niepoprawny"),
            if (firebaseAuth.currentUser?.email != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0), // Dostosuj wartość odstępu według potrzeb
                child: TextField(
                  controller: _commentController,
                  maxLines: 5,
                  minLines: 1,
                ),
              )

            else
              Container(),
            if (firebaseAuth.currentUser?.email != null)
              ElevatedButton(
                onPressed: addComment,
                child: const Text("Dodaj komentarz"),
              )
            else
              Container(),
            const Text("Komentarze:"),

            // Dodaj ten kontener z ograniczeniami wysokości
            Container(
              height: MediaQuery.of(context).size.height * 0.5, // Dostosuj wysokość według potrzeb
              child: comments.isNotEmpty
                  ? ListView.builder(
                itemCount: comments.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(comments[index].text),
                    subtitle: Text("Author: ${comments[index].author}"),
                  );
                },
              )
                  : const Center(child: Text("Brak komentarzy.")),
            ),

 */