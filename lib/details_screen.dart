import 'package:flutter/material.dart';
import 'package:firebase_project/models/student_model.dart';
import 'package:firebase_project/models/comment_model.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OfferDetailsScreen extends StatefulWidget {
  final Student student;
  OfferDetailsScreen({required this.student});

  @override
  _OfferDetailsScreenState createState() => _OfferDetailsScreenState();
}

FirebaseAuth firebaseAuth = FirebaseAuth.instance;

class _OfferDetailsScreenState extends State<OfferDetailsScreen> {
  final TextEditingController _commentController = TextEditingController();
  String? user = firebaseAuth.currentUser?.email;
  DatabaseReference dbRef = FirebaseDatabase.instance.ref();

  List<Comment> comments = [];
  int offerRating = 0;

  @override
  void initState() {
    super.initState();
    fetchComments();
  }

  void fetchComments() async {
    DataSnapshot dataSnapshot = await dbRef.child('Oferty/${widget.student.key}/komentarze').get();
    if (dataSnapshot.value != null && dataSnapshot.value is Map) {
      Map<dynamic, dynamic> commentsData = dataSnapshot.value as Map<dynamic, dynamic>;
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

    // Dodaj StreamBuilder do nasłuchiwania na zmiany w ocenie oferty
    dbRef.child('Oferty/${widget.student.key}/ocena').onValue.listen((event) {
      if (event.snapshot.value != null) {
        setState(() {
          offerRating = (event.snapshot.value as int?) ?? 0;
        });
      }
    });
  }

  void increaseRating() {
    dbRef.child('Oferty/${widget.student.key}/ocena').set(offerRating + 1);
  }

  void decreaseRating() {
    dbRef.child('Oferty/${widget.student.key}/ocena').set(offerRating - 1);
  }

  void addComment() {
    String commentText = _commentController.text.trim(); // Usunięcie białych znaków z początku i końca

    if (commentText.isNotEmpty) {
      String timestamp = DateTime.now().toUtc().toString();

      Comment newComment = Comment(
        author: user!,
        text: commentText,
        timestamp: timestamp,
      );

      dbRef.child('Oferty/${widget.student.key}/komentarze').push().set(newComment.toJson());
      _commentController.clear();
      fetchComments();
    } else {
      // Wyświetl komunikat, że komentarz nie może być pusty
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Komentarz nie może być pusty.'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.student.studentData!.nazwa!),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Kategoria: ${widget.student.studentData!.kategoria!}"),
          Text("Stara cena: ${widget.student.studentData!.stara_cena!}"),
          Text("Nowa cena: ${widget.student.studentData!.nowa_cena!}"),
          Text("Przecena: ${widget.student.studentData!.przecena!}%"),
          Text("Data od: ${widget.student.studentData!.data_od!.split(' ')[0]}"),
          Text("Data do: ${widget.student.studentData!.data_do!.split(' ')[0]}"),
          Text("Ocena oferty: $offerRating"),
          if (widget.student.studentData!.image_path != null)
            Image.network(
              widget.student.studentData!.image_path!,
              height: 100,
              width: 100,
              fit: BoxFit.cover,
            ),
          if (widget.student.studentData!.image_path == null)
            Image.asset(
              'assets/placeholder_image.png', // Zastępcze zdjęcie
              height: 100,
              width: 100,
              fit: BoxFit.cover,
            ),
          if(user != null)
          ElevatedButton(
            onPressed: increaseRating,
            child: Text("Zwiększ ocenę")
          )
          else
            Container(),
          if(user != null)
          ElevatedButton(
            onPressed: () {
              decreaseRating();
              if(offerRating<-5) {
                dbRef.child('Oferty/${widget.student.key}').remove();
                Navigator.of(context).pop();
              }
            },
            child: Text("Zmniejsz ocenę")
          )
          else
            Container(),
          if(user != null)
          TextField(controller: _commentController)
          else
            Container(),
          if(user != null)
          ElevatedButton(
            onPressed: addComment,
            child: Text("Dodaj komentarz"),
          )
          else
            Container(),
          Text("Komentarze:"),
          Expanded(
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
                : Center(child: Text("Brak komentarzy.")),
          ),
        ],
      ),
    );
  }
}
