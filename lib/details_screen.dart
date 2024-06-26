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


  List<Rating> ratings = [];

  int positiveRatings = 0;
  int negativeRatings = 0;
  bool isFollowing = true;

  @override
  void initState() {
    super.initState();
    fetchComments();
    fetchRatings();
    hasUserFollowed();
  }

  List<Comment> comments = [];
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
          content: Text('Offer already rated'),
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
          content: Text('Offer already rated'),
        ),
      );
    }
  }

  void addComment() {
    String commentText = _commentController.text.trim();
    if (commentText.isNotEmpty) {
      String timestamp = DateTime.now().toUtc().toString();
      Comment newComment = Comment(
        author: user!,
        text: commentText,
        timestamp: timestamp,
      );
      dbRef.child('Oferty/${widget.offer.key}/komentarze').push()
          .set(newComment.toJson());
      _commentController.clear();
      fetchComments();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Comment can't be empty !"),
      ));
    }
  }

  void toggleFollow() async {
    String userID = firebaseAuth.currentUser?.uid ?? '';
    String? offerID = widget.offer.key;
    DatabaseReference followersRef = dbRef.child('Oferty/$offerID/obserwujacy');
    DatabaseEvent event = await followersRef.orderByChild('uid').equalTo(userID).once();
    DataSnapshot snapshot = event.snapshot;
    Map<dynamic, dynamic>? values = snapshot.value as Map<dynamic, dynamic>?;
    if (values == null || values.isEmpty) {
      DatabaseReference newFollowerRef = followersRef.push();
      newFollowerRef.set({
        "uid": userID,
        "email": user,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Added to followed'),
        ),
      );
    } else {
      values.forEach((key, value) {
        dbRef.child('Oferty/$offerID/obserwujacy/$key').remove();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Removed from followed'),
          ),
        );
      });
    }
  }

  void hasUserFollowed() async {
    String userID = firebaseAuth.currentUser?.uid ?? '';
    String? offerID = widget.offer.key;
    DatabaseReference followersRef = dbRef.child('Oferty/$offerID/obserwujacy');
    DatabaseEvent event =
        await followersRef.orderByChild('uid').equalTo(userID).once();
    DataSnapshot snapshot = event.snapshot;
    Map<dynamic, dynamic>? values = snapshot.value as Map<dynamic, dynamic>?;
    if (values == null || values.isEmpty) {
      setState(() {
        isFollowing = false;
      });
    } else {
      setState(() {
        isFollowing = true;
      });
    }
  }

  String barcode = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            "${widget.offer.offerData!.nazwa!} - ${widget.offer.offerData!.kategoria!}"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (widget.offer.offerData!.image_path != "")
                  Container(
                    height: 200,
                    width: 200,
                    decoration: BoxDecoration(
                      border: Border.all(width: 5),
                    ),
                    child: Image.network(widget.offer.offerData!.image_path!),
                  )
                else
                  Container(
                    height: 200,
                    width: 200,
                    decoration: BoxDecoration(
                      border: Border.all(width: 5),
                    ),
                    child: Image.asset('assets/placeholder_image.png'),
                  ),
                const Text("Description: "),
                Text(widget.offer.offerData!.opis!),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Price: "),
                      Text("${widget.offer.offerData!.stara_cena!} zł",
                          style: const TextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: Colors.red)),
                      const Icon(Icons.arrow_forward),
                      Text("${widget.offer.offerData!.nowa_cena!} zł",
                          style: const TextStyle(color: Colors.green)),
                    ],
                  ),
                ),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Discount: "),
                      Text(
                        "-${widget.offer.offerData!.przecena!}%",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Valid from "),
                      Text("${widget.offer.offerData!.data_od!.split(' ')[0]}",
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      const Text(" to "),
                      Text("${widget.offer.offerData!.data_do!.split(' ')[0]}",
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                if (firebaseAuth.currentUser?.email != null &&
                    widget.offer.offerData!.autor_id! !=
                        firebaseAuth.currentUser?.uid)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          if (!hasUserRated()) {
                            increaseRating();
                          } else {
                            // Informacja dla użytkownika, że już wcześniej ocenił ofertę
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Offer already rated'),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.thumb_up),
                        label: Text(": $positiveRatings"),
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all(
                            hasUserRatedPositive() ? Colors.green : null,
                          ),
                          side: MaterialStateProperty.all(
                            BorderSide(
                              color: hasUserRatedPositive()
                                  ? Colors.black
                                  : Colors.transparent,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: () {
                          if (!hasUserRated()) {
                            decreaseRating();
                          } else {
                            // Informacja dla użytkownika, że już wcześniej ocenił ofertę
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Offer already rated'),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.thumb_down),
                        label: Text(": $negativeRatings"),
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all(
                            hasUserRatedNegative() ? Colors.red : null,
                          ),
                          side: MaterialStateProperty.all(
                            BorderSide(
                              color: hasUserRatedNegative()
                                  ? Colors.black
                                  : Colors.transparent,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MapScreen(offer: widget.offer),
                      ),
                    );
                  },
                  child: const Text("Show on map"),
                ),
                if (firebaseAuth.currentUser?.email != null &&
                    widget.offer.offerData!.autor_id! !=
                        firebaseAuth.currentUser?.uid)
                  ElevatedButton(
                      onPressed: () {
                        toggleFollow();
                        setState(() {
                          isFollowing = !isFollowing;
                        });
                      },
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all(
                          isFollowing ? Colors.red : null,
                        ),
                        side: MaterialStateProperty.all(
                          BorderSide(
                            color:
                                isFollowing ? Colors.black : Colors.transparent,
                          ),
                        ),
                      ),
                      child: Icon(Icons.favorite)),
                ElevatedButton(
                  onPressed: () async {
                    var res = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const SimpleBarcodeScannerPage(),
                        ));
                    setState(() {
                      if (res is String) {
                        barcode = res;
                      }
                    });
                  },
                  child: const Text("Compare barcode"),
                ),
                if (barcode.isNotEmpty &&
                    barcode == widget.offer.offerData!.code! &&
                    widget.offer.offerData!.code!.isNotEmpty)
                  const Text("Matching barcode"),
                if (barcode.isNotEmpty &&
                    barcode != widget.offer.offerData!.code! &&
                    widget.offer.offerData!.code!.isNotEmpty)
                  const Text("Barcode not matching"),
                if (firebaseAuth.currentUser?.email != null)
                  TextField(
                    controller: _commentController,
                    maxLines: 5,
                    minLines: 1,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: "Comment",
                    ),
                  )
                else
                  Container(),
                if (firebaseAuth.currentUser?.email != null)
                  ElevatedButton(
                    onPressed: addComment,
                    child: const Text("Add comment"),
                  )
                else
                  Container(),
                const Text("Comments:"),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.5,
                  child: comments.isNotEmpty
                      ? ListView.builder(
                          itemCount: comments.length,
                          itemBuilder: (context, index) {
                            return ListTile(
                              title: Text(comments[index].text),
                              subtitle:
                                  Text("Author: ${comments[index].author}"),
                            );
                          },
                        )
                      : const Center(child: Text("No comments.")),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
