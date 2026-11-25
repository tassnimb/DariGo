
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

// ==========================================
// 1. MODELE : LOCALISATION SELECTIONNEE
// ==========================================

class PickedLocation {
  final double latitude;
  final double longitude;
  final String adresse;
  final String ville;
  final String gouvernorat;
  final String pays;
  final String codePostal;

  PickedLocation({
    required this.latitude,
    required this.longitude,
    required this.adresse,
    required this.ville,
    required this.gouvernorat,
    required this.pays,
    required this.codePostal,
  });
}

// ==========================================
// 2. ECRAN DE SELECTION DE LOCALISATION
// ==========================================

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key});

  @override
  State<MapPickerScreen> createState() =>
      _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {

  static const Color violet = Color(0xFF6C4AB6);

  GoogleMapController? mapController;

  // Position initiale : Tunis
  LatLng positionSelectionnee =
      const LatLng(36.8065, 10.1815);

  bool chargement = false;

  // ==========================================
  // 3. OBTENIR LA POSITION ACTUELLE
  // ==========================================

  Future<void> obtenirPositionActuelle() async {
    try {
      bool serviceActive =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceActive) {
        throw Exception(
          'Activez la localisation de votre navigateur.',
        );
      }

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission =
            await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception(
          'Permission de localisation refusée.',
        );
      }

      final position =
          await Geolocator.getCurrentPosition();

      final nouvellePosition = LatLng(
        position.latitude,
        position.longitude,
      );

      if (!mounted) return;

      setState(() {
        positionSelectionnee = nouvellePosition;
      });

      mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          nouvellePosition,
          16,
        ),
      );

    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ),
      );
    }
  }

  // ==========================================
  // 4. RECUPERER L'ADRESSE AVEC NOMINATIM
  // ==========================================

  Future<void> confirmerLocalisation() async {

    if (chargement) return;

    setState(() {
      chargement = true;
    });

    try {

      // Appel API OpenStreetMap Nominatim
      final url = Uri.https(
        'nominatim.openstreetmap.org',
        '/reverse',
        {
          'format': 'jsonv2',
          'lat': positionSelectionnee.latitude.toString(),
          'lon': positionSelectionnee.longitude.toString(),
          'addressdetails': '1',
          'accept-language': 'fr',
        },
      );

      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Erreur lors de la récupération de l’adresse.',
        );
      }

      final data = jsonDecode(response.body);

      if (data['address'] == null) {
        throw Exception(
          'Aucune adresse trouvée pour cet emplacement.',
        );
      }

      final Map<String, dynamic> address =
          Map<String, dynamic>.from(data['address']);

      // Fonction pour récupérer les composants
      String getAddressComponent(List<String> keys) {

        for (final key in keys) {
          final value = address[key];

          if (value != null &&
              value.toString().isNotEmpty) {
            return value.toString();
          }
        }

        return '';
      }

      // Adresse
      final adresse = [
        getAddressComponent(['house_number']),
        getAddressComponent([
          'road',
          'pedestrian',
          'footway',
        ]),
      ].where((value) => value.isNotEmpty).join(' ');

      // Ville
      final ville = getAddressComponent([
        'city',
        'town',
        'village',
        'municipality',
        'city_district',
      ]);

      // Gouvernorat
      final gouvernorat = getAddressComponent([
        'state',
        'region',
      ]);

      // Création de l'objet localisation
      final localisation = PickedLocation(
        latitude: positionSelectionnee.latitude,
        longitude: positionSelectionnee.longitude,

        adresse: adresse.isNotEmpty
            ? adresse
            : (data['display_name'] ?? '').toString(),

        ville: ville,

        gouvernorat: gouvernorat,

        pays: getAddressComponent(['country']),

        codePostal: getAddressComponent(['postcode']),
      );

      if (!mounted) return;

      // Retourner les informations à l'écran précédent
      Navigator.pop(context, localisation);

    } catch (e) {

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur : $e'),
          backgroundColor: Colors.red,
        ),
      );

    } finally {

      if (mounted) {
        setState(() {
          chargement = false;
        });
      }
    }
  }

  // ==========================================
  // 5. INTERFACE GRAPHIQUE
  // ==========================================

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text(
          'Choisir une localisation',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),

      body: Stack(
        children: [

          // GOOGLE MAP
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: positionSelectionnee,
              zoom: 13,
            ),

            onMapCreated: (controller) {
              mapController = controller;
            },

            // Sélectionner une position en cliquant
            // sur la carte
            onTap: (position) {
              setState(() {
                positionSelectionnee = position;
              });
            },

            // Marqueur déplaçable
            markers: {
              Marker(
                markerId: const MarkerId('logement'),

                position: positionSelectionnee,

                draggable: true,

                onDragEnd: (position) {
                  setState(() {
                    positionSelectionnee = position;
                  });
                },
              ),
            },

            myLocationButtonEnabled: false,
            zoomControlsEnabled: true,
            mapToolbarEnabled: false,
          ),

          // MESSAGE EN HAUT
          Positioned(
            top: 15,
            left: 15,
            right: 15,

            child: Card(
              elevation: 4,

              child: Padding(
                padding: const EdgeInsets.all(14),

                child: Row(
                  children: const [

                    Icon(
                      Icons.location_on,
                      color: violet,
                    ),

                    SizedBox(width: 10),

                    Expanded(
                      child: Text(
                        'Cliquez sur la carte ou déplacez '
                        'le marqueur pour choisir votre emplacement.',
                        style: TextStyle(
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // BOUTON POSITION ACTUELLE
          Positioned(
            right: 16,
            bottom: 115,

            child: FloatingActionButton(
              backgroundColor: Colors.white,
              foregroundColor: violet,

              onPressed: obtenirPositionActuelle,

              child: const Icon(
                Icons.my_location,
              ),
            ),
          ),

          // BOUTON CONFIRMER
          Positioned(
            left: 20,
            right: 20,
            bottom: 20,

            child: SizedBox(
              height: 52,

              child: ElevatedButton.icon(

                onPressed: chargement
                    ? null
                    : confirmerLocalisation,

                icon: chargement
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.check),

                label: Text(
                  chargement
                      ? 'Récupération de l’adresse...'
                      : 'Confirmer cette localisation',
                ),

                style: ElevatedButton.styleFrom(
                  backgroundColor: violet,
                  foregroundColor: Colors.white,

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
