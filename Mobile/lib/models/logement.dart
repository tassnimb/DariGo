
class PhotoLogement {
  final int id;
  final String image;

  PhotoLogement({
    required this.id,
    required this.image,
  });

  factory PhotoLogement.fromJson(Map<String, dynamic> json) {
    final image = json['image']?.toString() ?? '';

    final url = image.startsWith('http')
        ? image
        : Uri.parse(Logement.serveur).resolve(
            image.startsWith('/')
                ? image
                : '/media/$image',
          ).toString();

    return PhotoLogement(
      id: int.tryParse(json['id'].toString()) ?? 0,
      image: url,
    );
  }
}

class Logement {
  final int id;
  final String titre;
  final String description;
  final String adresse;
  final double prix;

  final String typeLogement;
  final String typeHebergement;
  final String pays;
  final String ville;
  final String gouvernorat;
  final String codePostal;

  final int nombreVoyageurs;
  final int chambres;
  final int lits;
  final int sallesBain;

  // URLs utilisées dans les écrans de liste et de détails
  final List<String> photos;

  // Photos avec leurs identifiants
  final List<PhotoLogement> photoDetails;

  static const String serveur = 'http://127.0.0.1:8000';

  Logement({
    required this.id,
    required this.titre,
    required this.description,
    required this.adresse,
    required this.prix,
    this.typeLogement = 'appartement',
    this.typeHebergement = 'entier',
    this.pays = 'Tunisie',
    this.ville = '',
    this.gouvernorat = '',
    this.codePostal = '',
    this.nombreVoyageurs = 1,
    this.chambres = 1,
    this.lits = 1,
    this.sallesBain = 1,
    this.photos = const [],
    this.photoDetails = const [],
  });

  factory Logement.fromJson(Map<String, dynamic> json) {
    final List<PhotoLogement> details = [];

    if (json['photos'] is List) {
      for (final photo in json['photos']) {
        if (photo is Map) {
          details.add(
            PhotoLogement.fromJson(
              Map<String, dynamic>.from(photo),
            ),
          );
        }
      }
    }

    return Logement(
      id: int.tryParse(json['id'].toString()) ?? 0,
      titre: json['titre']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      adresse: json['adresse']?.toString() ?? '',
      prix: double.tryParse(json['prix'].toString()) ?? 0.0,

      typeLogement:
          json['type_logement']?.toString() ?? 'appartement',
      typeHebergement:
          json['type_hebergement']?.toString() ?? 'entier',
      pays: json['pays']?.toString() ?? 'Tunisie',
      ville: json['ville']?.toString() ?? '',
      gouvernorat: json['gouvernorat']?.toString() ?? '',
      codePostal: json['code_postal']?.toString() ?? '',

      nombreVoyageurs:
          int.tryParse(json['nombre_voyageurs'].toString()) ?? 1,
      chambres:
          int.tryParse(json['chambres'].toString()) ?? 1,
      lits:
          int.tryParse(json['lits'].toString()) ?? 1,
      sallesBain:
          int.tryParse(json['salles_bain'].toString()) ?? 1,

      photoDetails: details,
      photos: details.map((photo) => photo.image).toList(),
    );
  }
}
