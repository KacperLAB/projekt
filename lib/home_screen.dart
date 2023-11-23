import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_project/all_map_screen.dart';
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
  //String _sortBy = "data_od"; // Domyślne sortowanie
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _oldPriceController = TextEditingController();
  final TextEditingController _newPriceController = TextEditingController();
  String? user = firebaseAuth.currentUser?.email;

  List<Student> studentList = [];
  List<Student> filteredStudentList = [];

  @override
  void initState() {
    super.initState();
    retrieveStudentData();
    user = firebaseAuth.currentUser?.email;
    filteredStudentList.addAll(studentList);
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
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SortScreen(
                      studentList: studentList,
                      sortStudentList: sortStudentList,
                    ),
                  ),
                );
              },
              child: Text("Sortuj"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FilterScreen(
                      applyFilter: applyFilter,
                    ),
                  ),
                );
              },
              child: Text("Filtruj"),
            ),
            for (int i = 0; i < filteredStudentList.length; i++)
              studentWidget(filteredStudentList[i]),
            ElevatedButton(
                onPressed: () {
                  studentList.clear();
                  retrieveStudentData();
                },
                child: Text("Odswiez")),
            if(firebaseAuth.currentUser?.email == null)
            ElevatedButton(
                onPressed: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => LoginScreen()));
                },
                child: Text("Logowanie i rejestracja"))
            else
              Container(),
            if (firebaseAuth.currentUser?.email != null)
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
            if (firebaseAuth.currentUser?.email == null)
              Container()
            else
              Text("Zalogowano jako: ${firebaseAuth.currentUser?.email!}"),
            ElevatedButton(onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => AllMapScreen(studentList: studentList)));
            }, child: Text("Pokaz na mapie"))
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          _nameController.text = "";
          _oldPriceController.text = "";
          _newPriceController.text = "";
          if (firebaseAuth.currentUser?.email != null)
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
      StudentData studentData = StudentData.fromJson(data.snapshot.value as Map);
      Student student = Student(key: data.snapshot.key, studentData: studentData);
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
                Text(student.studentData!.przecena! + "%"),
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

  // Funkcja sortująca oferty
  void sortStudentList(String sortBy) {
    switch (sortBy) {
      case "nazwa":
        filteredStudentList.sort((a, b) => a.studentData!.nazwa!.compareTo(b.studentData!.nazwa!));
        break;
      case "data_od":
        filteredStudentList.sort((a, b) => DateTime.parse(a.studentData!.data_od!).compareTo(DateTime.parse(b.studentData!.data_od!)));
        break;
      case "przecena":
        filteredStudentList.sort((a, b) => int.parse(a.studentData!.przecena!).compareTo(int.parse(b.studentData!.przecena!)));
        break;
      default:
        break;
    }
    setState(() {});
  }

  // Funkcja filtrująca oferty
  void applyFilter(String category) {
    filteredStudentList.clear();
    if (category == "Wszystkie") {
      filteredStudentList.addAll(studentList);
    } else {
      filteredStudentList.addAll(studentList.where((student) => student.studentData!.kategoria == category));
    }
    setState(() {});
  }


}

class SortScreen extends StatelessWidget {
  final List<Student> studentList;
  final Function(String) sortStudentList;

  const SortScreen({Key? key, required this.studentList, required this.sortStudentList}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Sortuj oferty"),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: () {
              sortStudentList("nazwa");
              Navigator.pop(context);
            },
            child: Text("Sortuj po nazwie"),
          ),
          ElevatedButton(
            onPressed: () {
              sortStudentList("data_od");
              Navigator.pop(context);
            },
            child: Text("Sortuj po dacie rozpoczęcia"),
          ),
          ElevatedButton(
            onPressed: () {
              sortStudentList("przecena");
              Navigator.pop(context);
            },
            child: Text("Sortuj po przecenie"),
          ),
        ],
      ),
    );
  }
}

class FilterScreen extends StatelessWidget {
  final Function(String) applyFilter;

  const FilterScreen({Key? key, required this.applyFilter}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Filtruj oferty"),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: () {
              applyFilter("Wszystkie");
              Navigator.pop(context);
            },
            child: Text("Wszystkie"),
          ),
          ElevatedButton(
            onPressed: () {
              applyFilter("Owoce");
              Navigator.pop(context);
            },
            child: Text("Owoce"),
          ),
          ElevatedButton(
            onPressed: () {
              applyFilter("Warzywa");
              Navigator.pop(context);
            },
            child: Text("Warzywa"),
          ),
          ElevatedButton(onPressed: () {
            applyFilter("Inne");
          }, child: Text("Inne"))

          // Dodaj inne kategorie
        ],
      ),
    );
  }
}

