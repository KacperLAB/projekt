import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_project/all_map_screen.dart';
import 'package:firebase_project/auth_gate.dart';
import 'package:firebase_project/form_screen.dart';
import 'package:firebase_project/models/student_model.dart';
import 'package:firebase_project/user_offers_screen.dart';
import 'package:firebase_project/followed_offers_screen.dart';
import 'package:flutter/material.dart';
import 'package:list_picker/list_picker.dart';
import 'package:firebase_project/details_screen.dart';
import 'package:firebase_project/login_screen.dart';
import 'package:firebase_project/sort_screen.dart';
import 'package:firebase_project/filter_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:location/location.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';


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
  bool ascending = true;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    retrieveStudentData();
    user = firebaseAuth.currentUser?.email;
    filteredStudentList.addAll(studentList);
    _getCurrentLocation();
  }

  LocationData? _currentLocation;
  LatLng? _selectedLocation; // do filtrowania po zasiegu

  Future<void> _getCurrentLocation() async {
    Location location = Location();
    try {
      _currentLocation = await location.getLocation();
      setState(() {
        _selectedLocation =
            LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!);
      });
      //print(_currentLocation!.latitude);
      //print(_currentLocation!.longitude);
      //print(_selectedLocation!.latitude);
      //print(_selectedLocation!.longitude);
    } catch (e) {
      print("Error getting location: $e");
    }
  }

  final listPickerField = ListPickerField(
    label: "Kategoria",
    items: const ["Owoce", "Warzywa", "Mięso", "Nabiał", "Napoje", "Inne"],
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Promocje"),
        actions: [
          if(firebaseAuth.currentUser?.email != null)
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute<ProfileScreen>(
                  builder: (context) => ProfileScreen(
                    appBar: AppBar(
                      title: const Text("Profil użytkownika"),
                    ),
                    actions: [
                      SignedOutAction((context) {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => HomeScreen()));
                      })
                    ],
                  ),
                ),
              );
            },
          )
        ],
        automaticallyImplyLeading: false,
      ),

      body: SingleChildScrollView(
        child: Column(
          children: [
            if (firebaseAuth.currentUser?.email == null)
              Container()
            else
              Text("Zalogowano jako: ${firebaseAuth.currentUser?.email!}"),
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
              child: const Text("Sortuj"),
            ),
            if (firebaseAuth.currentUser?.email != null)
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UserOffersScreen(),
                    ),
                  );
                },
                child: const Text("Moje ogloszenia"),
              ),
            if (firebaseAuth.currentUser?.email != null)
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FollowedOffersScreen(),
                    ),
                  );
                },
                child: const Text("Obserwowane"),
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
              child: const Text("Filtruj"),
            ),
            ElevatedButton(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              AllMapScreen(studentList: filteredStudentList)));
                },
                child: const Text("Pokaz na mapie")),
            if (isLoading)
              const CircularProgressIndicator()
            else
              for (int i = 0; i < filteredStudentList.length; i++)
                studentWidget(filteredStudentList[i]),
            ElevatedButton(
                onPressed: () {
                  studentList.clear();
                  retrieveStudentData();
                },
                child: const Icon(Icons.refresh)),
            if (firebaseAuth.currentUser?.email == null)
              ElevatedButton(
                  onPressed: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) => AuthGate(),
                        )
                    );
                  },
                  child: const Text("Logowanie"))

            else
              Container(),
            ElevatedButton(
                onPressed: () {
                  setState(() {
                    user = firebaseAuth.currentUser?.email;
                  });
                },
                child: const Text("aktu")),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          _nameController.text = "";
          _oldPriceController.text = "";
          _newPriceController.text = "";
          if (firebaseAuth.currentUser?.email != null) {
            Navigator.push(
                context, MaterialPageRoute(builder: (context) => FormScreen()));
          } else {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => AuthGate()));
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  //wczytywanie ofert z bazy
  void retrieveStudentData() {
    studentList.clear();
    filteredStudentList.clear(); // Wyczyść również filteredStudentList
    final DateTime currentDate = DateTime.now();
    dbRef.child("Oferty").onChildAdded.listen((data) {
      StudentData studentData =
          StudentData.fromJson(data.snapshot.value as Map);
      DateTime dataOd = DateTime.parse(studentData.data_od!);
      DateTime dataDo = DateTime.parse(studentData.data_do!);
      if (currentDate.isAfter(dataOd) && currentDate.isBefore(dataDo)) {
        Student student =
            Student(key: data.snapshot.key, studentData: studentData);
        studentList.add(student);
        filteredStudentList.add(student); // Dodaj ofertę do filteredStudentList
        setState(() {});
      } else if (currentDate.isAfter(dataOd) && currentDate.isAfter(dataDo)) {
        dbRef.child("Oferty").child(data.snapshot.key!).remove();
      }
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

  // Funkcja sortująca oferty
  void sortStudentList(String sortBy, bool ascending) {
    switch (sortBy) {
      case "nazwa":
        filteredStudentList.sort(
            (a, b) => a.studentData!.nazwa!.compareTo(b.studentData!.nazwa!));
        break;
      case "data_od":
        filteredStudentList.sort((a, b) =>
            DateTime.parse(a.studentData!.data_od!)
                .compareTo(DateTime.parse(b.studentData!.data_od!)));
        break;
      case "przecena":
        filteredStudentList.sort((a, b) => int.parse(a.studentData!.przecena!)
            .compareTo(int.parse(b.studentData!.przecena!)));
        break;
      case "cena":
        filteredStudentList.sort((a, b) => int.parse(a.studentData!.nowa_cena!)
            .compareTo(int.parse(b.studentData!.nowa_cena!)));
        break;
      default:
        break;
    }

    if (!ascending) {
      filteredStudentList = filteredStudentList.reversed.toList();
    }

    setState(() {});
  }

  //Funkcja filtrujaca
  void applyFilter({
    List<String> categories = const [],
    String? priceFrom,
    String? priceTo,
    double? maxDistance,
  }) async {
    setState(() {
      isLoading = true;
    });

    filteredStudentList.clear();
    LocationData? userLocation = await getUserLocation();

    if (userLocation != null) {
      filteredStudentList.addAll(studentList.where((student) {
        // Filtruj kategorie
        bool categoryFilter = categories.isEmpty ||
            categories.contains(student.studentData!.kategoria!);

        // Filtruj cenę
        bool priceFilter = true;
        if (priceFrom != null && priceTo != null) {
          int studentPrice = int.parse(student.studentData!.nowa_cena ?? "0");
          int from = int.parse(priceFrom);
          int to = int.parse(priceTo);
          priceFilter = studentPrice >= from && studentPrice <= to;
        }

        // Filtruj odległość
        bool distanceFilter = true;
        if (maxDistance != null) {
          if (student.studentData!.latitude != null &&
              student.studentData!.longitude != null) {
            double offerDistance = calculateDistance(
              userLocation.latitude!,
              userLocation.longitude!,
              student.studentData!.latitude!,
              student.studentData!.longitude!,
            );
            distanceFilter = offerDistance <= maxDistance;
          } else {
            distanceFilter =
                false; // Brak współrzędnych oferty, nie uwzględniaj jej w filtrze odległości
          }
        }

        return categoryFilter && priceFilter && distanceFilter;
      }));
    }

    setState(() {
      isLoading = false;
    });
  }
}

double calculateDistance(
  double userLatitude,
  double userLongitude,
  double offerLatitude,
  double offerLongitude,
) {
  double distanceInMeters = Geolocator.distanceBetween(
    userLatitude,
    userLongitude,
    offerLatitude,
    offerLongitude,
  );
  // zamiana z metrow na kilometry
  double distanceInKilometers = distanceInMeters / 1000;
  return distanceInKilometers;
}

Future<LocationData?> getUserLocation() async {
  Location location = Location();

  try {
    return await location.getLocation();
  } catch (e) {
    print("Error getting location: $e");
    return null;
  }
}
