
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
      id: int.parse(json['id'].toString()),
      titre: json['titre']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      adresse: json['adresse']?.toString() ?? '',
      prix: double.tryParse(json['prix'].toString()) ?? 0.0,
    );
  }
}
