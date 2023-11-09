import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_project/form_screen.dart';
import 'package:firebase_project/models/student_model.dart';
import 'package:flutter/material.dart';
import 'package:list_picker/list_picker.dart';
import 'package:firebase_project/details_screen.dart';
import 'package:firebase_project/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

FirebaseAuth firebaseAuth = FirebaseAuth.instance;

class _HomeScreenState extends State<HomeScreen> {
  DatabaseReference dbRef = FirebaseDatabase.instance.ref();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _oldPriceController = TextEditingController();
  final TextEditingController _newPriceController = TextEditingController();
  String? user = firebaseAuth.currentUser?.email;

  List<Student> studentList = [];

  @override
  void initState() {
    super.initState();
    retrieveStudentData();
  }

  final listPickerField = ListPickerField(
    label: "Kategoria",
    items: const ["Owoce", "Warzywa", "Mięso", "Nabiał", "Napoje", "Inne"],
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Promocje"),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            for (int i = 0; i < studentList.length; i++)
              studentWidget(studentList[i]),
            ElevatedButton(
                onPressed: () {
                  studentList.clear();
                  retrieveStudentData();
                },
                child: Text("Odswiez")),
            ElevatedButton(
                onPressed: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => LoginScreen()));
                },
                child: Text("Logowanie i rejestracja")),
            if (user != null)
              ElevatedButton(
                  onPressed: () {
                    firebaseAuth.signOut();
                    setState(() {
                      user = null;
                    });
                  },
                  child: Text("Wyloguj")),
            ElevatedButton(
                onPressed: () {
                  setState(() {
                    user = firebaseAuth.currentUser?.email;
                  });
                },
                child: Text("aktu")),
            if (user == null) Text("") else Text("Zalogowano jako:" + user!),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          _nameController.text = "";
          _oldPriceController.text = "";
          _newPriceController.text = "";
          if (user != null)
            Navigator.push(
                context, MaterialPageRoute(builder: (context) => FormScreen()));
          else
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => LoginScreen()));
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  //wczytywanie ofert z bazy
  void retrieveStudentData() {
    studentList.clear();
    dbRef.child("Oferty").onChildAdded.listen((data) {
      StudentData studentData =
          StudentData.fromJson(data.snapshot.value as Map);
      Student student =
          Student(key: data.snapshot.key, studentData: studentData);
      studentList.add(student);
      setState(() {});
    });
  }

  //widget pojedynczej oferty
  Widget studentWidget(Student student) {
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
              border: Border.all(color: Colors.black)),
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
                  Text(student.studentData!.przecena! + "%"),
                  Text(student.studentData!.data_od!.split(' ')[0]),
                  Text(student.studentData!.data_do!.split(' ')[0]),
                ],
              ),
            ],
          )),
    );
  }
}
