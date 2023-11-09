class Student {
  String? key;
  StudentData? studentData;

  Student({this.key, this.studentData});
}

class StudentData {
  String? nazwa;
  String? kategoria;
  String? stara_cena;
  String? nowa_cena;
  String? przecena;
  String? data_od;
  String? data_do;
  String? komentarze;
  int? ocena;
  String? image_path;

  StudentData(
      {this.nazwa,
      this.kategoria,
      this.stara_cena,
      this.nowa_cena,
      this.przecena,
      this.data_od,
      this.data_do,
      this.ocena,
      this.image_path});

  StudentData.fromJson(Map<dynamic, dynamic> json) {
    nazwa = json["nazwa"];
    kategoria = json["kategoria"];
    stara_cena = json["stara_cena"];
    nowa_cena = json["nowa_cena"];
    przecena = json["przecena"];
    data_od = json["data_od"];
    data_do = json["data_do"];
    ocena = json["ocena"];
    image_path = json["image_path"];
  }
}
