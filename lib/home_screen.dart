import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_project/all_map_screen.dart';
import 'package:firebase_project/auth_gate.dart';
import 'package:firebase_project/barcode_offers_screen.dart';
import 'package:firebase_project/form_screen.dart';
import 'package:firebase_project/models/offer_model.dart';
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
import 'package:firebase_storage/firebase_storage.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';


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

  List<Offer> offerList = [];
  List<Offer> filteredOfferList = [];
  bool ascending = true;
  bool isLoading = false;
  String barcode="";

  @override
  void initState() {
    super.initState();
    retrieveOfferData();
    user = firebaseAuth.currentUser?.email;
    filteredOfferList.addAll(offerList);
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
        title: const Text("PROMOCJE"),
        actions: [

          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              if(firebaseAuth.currentUser?.email != null)
              {
                Navigator.push(
                context,
                MaterialPageRoute<ProfileScreen>(
                  builder: (context) => ProfileScreen(
                    appBar: AppBar(
                      title: const Text("Mój profil"),
                    ),
                    actions: [
                      SignedOutAction((context) {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const HomeScreen()));
                      })
                    ],
                  ),
                ),
              );
              } else {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const AuthGate()));
              }
            },
            tooltip: "Profil",
          ),
          if(firebaseAuth.currentUser?.email != null)
          IconButton(onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => FollowedOffersScreen()));
          }, icon: const Icon(Icons.favorite),
          tooltip: "Obserwowane",),
          if(firebaseAuth.currentUser?.email != null)
          IconButton(onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => UserOffersScreen()));
          }, icon: const Icon(Icons.my_library_add),
          tooltip: "Moje ogłoszenia",),
          IconButton(onPressed: () async {
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
            Navigator.push(context, MaterialPageRoute(builder: (context) => BarcodeOffersScreen(barcode: barcode)));
          }, icon: const Icon(Icons.barcode_reader),
          tooltip: "Szukaj po kodzie"),
        ],
        automaticallyImplyLeading: false,
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
                      offerList: offerList,
                      sortOfferList: sortOfferList,
                    ),
                  ),
                );
              },
              child: const Text("Sortuj"),
            ),
            /*if (firebaseAuth.currentUser?.email != null)
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
              ),*/
            /*if (firebaseAuth.currentUser?.email != null)
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
              ),*/
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
                              AllMapScreen(offerList: filteredOfferList)));
                },
                child: const Text("Mapa")),
            if (isLoading)
              const CircularProgressIndicator()
            else
              for (int i = 0; i < filteredOfferList.length; i++)
                offerWidget(filteredOfferList[i]),
            ElevatedButton(
                onPressed: () {
                  offerList.clear();
                  retrieveOfferData();
                },
                child: const Icon(Icons.refresh)),
            /*if (firebaseAuth.currentUser?.email == null)
              ElevatedButton(
                  onPressed: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) => const AuthGate(),
                        )
                    );
                  },
                  child: const Text("Logowanie"))

            else
              Container(),*/
            /*ElevatedButton(
                onPressed: () {
                  setState(() {
                    user = firebaseAuth.currentUser?.email;
                  });
                },
                child: const Text("aktu")),*/
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
                MaterialPageRoute(builder: (context) => const AuthGate()));
          }
        },
        child: const Icon(Icons.add),
        tooltip: "Dodaj ogłoszenie",
      ),
    );
  }

  //wczytywanie ofert z bazy
  void retrieveOfferData() {
    offerList.clear();
    filteredOfferList.clear(); // Wyczyść również filteredStOfferList
    final DateTime currentDate = DateTime.now();
    dbRef.child("Oferty").onChildAdded.listen((data) async {
      OfferData offerData =
          OfferData.fromJson(data.snapshot.value as Map);
      DateTime dataOd = DateTime.parse(offerData.data_od!);
      DateTime dataDo = DateTime.parse(offerData.data_do!);
      if (currentDate.isAfter(dataOd) && currentDate.isBefore(dataDo)) {
        Offer offer =
            Offer(key: data.snapshot.key, offerData: offerData);
        offerList.add(offer);
        filteredOfferList.add(offer); // Dodaj ofertę do filteredOfferList
        setState(() {});
      } else if (currentDate.isAfter(dataOd) && currentDate.isAfter(dataDo)) {
        String imagePath = offerData.image_path ?? "";
        // Usuń obraz z Firebase Storage
        if (imagePath.isNotEmpty) {
          await FirebaseStorage.instance.refFromURL(imagePath).delete();
        }
        dbRef.child("Oferty").child(data.snapshot.key!).remove();
      }
    });
  }

  //widget pojedynczej oferty
  Widget offerWidget(Offer offer) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => OfferDetailsScreen(offer: offer),
        ));
      },
      child: Container(
        width: MediaQuery.of(context).size.width,
        padding: const EdgeInsets.all(3),
        margin: const EdgeInsets.only(top: 5, left: 10, right: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.black,width: 3),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Nazwa: ${offer.offerData!.nazwa!}"),
                Text("Kategoria: ${offer.offerData!.kategoria!}"),
                //Text(offer.offerData!.stara_cena!),
                Text("Cena: ${offer.offerData!.nowa_cena!} zł"),
                Text("Przecena: ${offer.offerData!.przecena!}%"),
                //Text(offer.offerData!.data_od!.split(' ')[0]),
                Text("Ważne do: ${offer.offerData!.data_do!.split(' ')[0]}"),
              ],
            ),
            if (offer.offerData!.image_path != "")
              Container(
                height: 120,
                width: 120,
                decoration: BoxDecoration(
                  border: Border.all(width: 5),
                ),
                child: Image.network(offer.offerData!.image_path!
                ),
              )
            else
              Container(
                height: 120,
                width: 120,
                decoration: BoxDecoration(
                  border: Border.all(width: 5),
                ),
                child: Image.asset('assets/placeholder_image.png' // Zastępcze zdjęcie
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Funkcja sortująca oferty
  void sortOfferList(String sortBy, bool ascending) {
    switch (sortBy) {
      case "nazwa":
        filteredOfferList.sort(
            (a, b) => a.offerData!.nazwa!.compareTo(b.offerData!.nazwa!));
        break;
      case "data_od":
        filteredOfferList.sort((a, b) =>
            DateTime.parse(a.offerData!.data_od!)
                .compareTo(DateTime.parse(b.offerData!.data_od!)));
        break;
      case "przecena":
        filteredOfferList.sort((a, b) => int.parse(a.offerData!.przecena!)
            .compareTo(int.parse(b.offerData!.przecena!)));
        break;
      case "cena":
        filteredOfferList.sort((a, b) => int.parse(a.offerData!.nowa_cena!)
            .compareTo(int.parse(b.offerData!.nowa_cena!)));
        break;
      default:
        break;
    }

    if (!ascending) {
      filteredOfferList = filteredOfferList.reversed.toList();
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

    filteredOfferList.clear();
    LocationData? userLocation = await getUserLocation();

    if (userLocation != null) {
      filteredOfferList.addAll(offerList.where((offer) {
        // Filtruj kategorie
        bool categoryFilter = categories.isEmpty ||
            categories.contains(offer.offerData!.kategoria!);

        // Filtruj cenę
        bool priceFilter = true;
        if (priceFrom != null && priceTo != null) {
          int offerPrice = int.parse(offer.offerData!.nowa_cena ?? "0");
          int from = int.parse(priceFrom);
          int to = int.parse(priceTo);
          priceFilter = offerPrice >= from && offerPrice <= to;
        }

        // Filtruj odległość
        bool distanceFilter = true;
        if (maxDistance != null) {
          if (offer.offerData!.latitude != null &&
              offer.offerData!.longitude != null) {
            double offerDistance = calculateDistance(
              userLocation.latitude!,
              userLocation.longitude!,
              offer.offerData!.latitude!,
              offer.offerData!.longitude!,
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
