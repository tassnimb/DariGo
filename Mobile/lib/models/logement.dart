class Logement {
  final int id;
  final String titre;
  final String description;
  final String adresse;
  final double prix;

  Logement({
    required this.id,
    required this.titre,
    required this.description,
    required this.adresse,
    required this.prix,
  });

  factory Logement.fromJson(Map<String, dynamic> json) {
    return Logement(
      id: json['id'],
      titre: json['titre'],
      description: json['description'],
      adresse: json['adresse'],
      prix: double.parse(json['prix'].toString()),
    );
  }
}