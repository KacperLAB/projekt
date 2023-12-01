import 'package:flutter/material.dart';
import 'package:firebase_project/models/student_model.dart';

class SortScreen extends StatelessWidget {
  final List<Student> studentList;
  final Function(String,bool) sortStudentList;

  const SortScreen(
      {Key? key, required this.studentList, required this.sortStudentList})
      : super(key: key);





  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sortuj oferty"),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: () {
              sortStudentList("nazwa",true);
              Navigator.pop(context);
            },
            child: const Text("Sortuj po nazwie A-Z"),
          ),
          ElevatedButton(
            onPressed: () {
              sortStudentList("nazwa",false);
              Navigator.pop(context);
            },
            child: const Text("Sortuj po nazwie Z-A"),
          ),
          ElevatedButton(
            onPressed: () {
              sortStudentList("data_od",true);
              Navigator.pop(context);
            },
            child: const Text("Dodane najpozniej"),
          ),
          ElevatedButton(
            onPressed: () {
              sortStudentList("data_od",false);
              Navigator.pop(context);
            },
            child: const Text("Dodane najwczesniej"),
          ),
          ElevatedButton(
            onPressed: () {
              sortStudentList("przecena",false);
              Navigator.pop(context);
            },
            child: const Text("Przecena malejąco"),
          ),
          ElevatedButton(
            onPressed: () {
              sortStudentList("przecena",true);
              Navigator.pop(context);
            },
            child: const Text("Przecena rosnąco"),
          ),
          ElevatedButton(
            onPressed: () {
              sortStudentList("cena",true);
              Navigator.pop(context);
            },
            child: const Text("Cena rosnąco"),
          ),
          ElevatedButton(
            onPressed: () {
              sortStudentList("cena",false);
              Navigator.pop(context);
            },
            child: const Text("Cena malejąco"),
          ),
        ],
      ),
    );
  }
}



