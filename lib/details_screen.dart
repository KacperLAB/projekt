import 'package:flutter/material.dart';
import 'package:firebase_project/models/student_model.dart';
import 'package:firebase_project/models/comment_model.dart';
import 'package:firebase_database/firebase_database.dart';

class OfferDetailsScreen extends StatefulWidget {
  final Student student;
  OfferDetailsScreen({required this.student});

  @override
  _OfferDetailsScreenState createState() => _OfferDetailsScreenState();
}

class _OfferDetailsScreenState extends State<OfferDetailsScreen> {
  final TextEditingController _commentController = TextEditingController();
  DatabaseReference dbRef = FirebaseDatabase.instance.reference();
  List<Comment> comments = [];

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
          TextField(controller: _commentController),
          ElevatedButton(
            onPressed: () {
              String commentText = _commentController.text;
              String timestamp = DateTime.now().toUtc().toString();

              Comment newComment = Comment(
                author: "Testowy", // Tutaj możesz ustawić autora komentarza
                text: commentText,
                timestamp: timestamp,
              );

              dbRef.child('Oferty/${widget.student.key}/komentarze').push().set(newComment.toJson());
              _commentController.clear();
              fetchComments();
            },
            child: Text("Dodaj komentarz"),
          ),
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
