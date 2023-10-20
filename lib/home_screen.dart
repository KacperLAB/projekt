import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_project/form_screen.dart';
import 'package:firebase_project/models/student_model.dart';
import 'package:flutter/material.dart';
import 'package:list_picker/list_picker.dart';
import 'package:firebase_project/details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  DatabaseReference dbRef = FirebaseDatabase.instance.ref();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _oldPriceController = TextEditingController();
  final TextEditingController _newPriceController = TextEditingController();

  List<Student> studentList=[];

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
              for(int i=0;i<studentList.length;i++)
                studentWidget(studentList[i]),
              ElevatedButton(onPressed: () {
                studentList.clear();
                retrieveStudentData();
              }, child: Text("Odswiez"))
            ],
          ),
        ),
      floatingActionButton: FloatingActionButton(onPressed: () async {
        _nameController.text = "";
        _oldPriceController.text = "";
        _newPriceController.text = "";
        Navigator.push(context, MaterialPageRoute(builder: (context) => FormScreen()));
      },child: const Icon(Icons.add),),
    );
  }

  //studentList.clear();
  //retrieveStudentData();

  //ekran dodawania
  /*void studentDialog({String? key}) {
    showDialog(context: context, builder: (context) {
      return Dialog(
        child: Container(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: _nameController, decoration: const InputDecoration(labelText: "Nazwa")),
              TextField(keyboardType: TextInputType.numberWithOptions(decimal: true),controller: _oldPriceController,decoration: const InputDecoration(labelText: "Stara cena")),
              TextField(keyboardType: TextInputType.numberWithOptions(decimal: true),controller: _newPriceController,decoration: const InputDecoration(labelText: "Nowa cena")),
              listPickerField,


              const SizedBox(height: 10,),
              ElevatedButton(onPressed: (){

                double stara = double.parse(_oldPriceController.text);
                double nowa = double.parse(_newPriceController.text);
                double przecena = 100-((nowa * 100)/stara);

                Map<String,dynamic> data = {
                  "nazwa": _nameController.text.toString(),
                  "kategoria": listPickerField.value,
                  "stara_cena": _oldPriceController.text.toString(),
                  "nowa_cena": _newPriceController.text.toString(),
                  "przecena" : przecena.toStringAsFixed(0),
                };

                if(updateStudent){
                  dbRef.child("Oferty").child(key!).update(data).then((value) {
                    int index = studentList.indexWhere((element) => element.key == key);
                    studentList.removeAt(index);
                    studentList.insert(index,Student(key: key, studentData: StudentData.fromJson(data)));
                    setState(() {

                    });
                    Navigator.of(context).pop();
                  });
                }
                else{
                  dbRef.child("Oferty").push().set(data).then((value) {
                    Navigator.of(context).pop();
                  });
                }
              }, child: Text(updateStudent ? "Update data" : "Save Data"))
            ],
          ),
        ),
      );
    });
  }*/

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
      onTap: (){
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => OfferDetailsScreen(student: student),
        ));
      },
      child: Container(
        width: MediaQuery.of(context).size.width,
        padding: const EdgeInsets.all(5),
        margin: const EdgeInsets.only(top:5,left:10,right:10),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.black)),
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
        )
      ),
    );
  }
}
