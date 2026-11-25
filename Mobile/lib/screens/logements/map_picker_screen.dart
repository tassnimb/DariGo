
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
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

  final MapController mapController = MapController();
  final GlobalKey mapKey = GlobalKey();

  LatLng positionSelectionnee =
      const LatLng(36.8065, 10.1815);

  bool chargement = false;

  // ==========================================
  // 3. OBTENIR LA POSITION ACTUELLE
  // ==========================================

  Future<void> obtenirPositionActuelle() async {
    try {
      final serviceActive =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceActive) {
        throw Exception(
          'Activez le service de localisation.',
        );
      }

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
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

      mapController.move(nouvellePosition, 16);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  // ==========================================
  // 4. DEPLACER LE MARQUEUR
  // ==========================================

  void deplacerMarqueur(DragUpdateDetails details) {
    final renderObject =
        mapKey.currentContext?.findRenderObject();

    if (renderObject is! RenderBox) return;

    final positionLocale =
        renderObject.globalToLocal(details.globalPosition);

    final nouvellePosition = mapController.camera
        .screenOffsetToLatLng(positionLocale);

    setState(() {
      positionSelectionnee = nouvellePosition;
    });
  }

  // ==========================================
  // 5. RECUPERER L'ADRESSE AVEC NOMINATIM
  // ==========================================

  Future<void> confirmerLocalisation() async {
    if (chargement) return;

    setState(() {
      chargement = true;
    });

    try {
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
          'User-Agent': 'DariGo/1.0',
        },
      ).timeout(const Duration(seconds: 15));

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

      final adresse = [
        getAddressComponent(['house_number']),
        getAddressComponent([
          'road',
          'pedestrian',
          'footway',
        ]),
      ].where((value) => value.isNotEmpty).join(' ');

      final ville = getAddressComponent([
        'city',
        'town',
        'village',
        'municipality',
        'city_district',
      ]);

      final gouvernorat = getAddressComponent([
        'state',
        'region',
      ]);

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
  // 6. INTERFACE GRAPHIQUE
  // ==========================================

  @override
  void dispose() {
    mapController.dispose();
    super.dispose();
  }

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
          // CARTE OPENSTREETMAP

          FlutterMap(
            key: mapKey,
            mapController: mapController,
            options: MapOptions(
              initialCenter: positionSelectionnee,
              initialZoom: 13,
              onTap: (tapPosition, position) {
                setState(() {
                  positionSelectionnee = position;
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.darigo',
              ),

              MarkerLayer(
                markers: [
                  Marker(
                    point: positionSelectionnee,
                    width: 60,
                    height: 70,
                    child: GestureDetector(
                      onPanUpdate: deplacerMarqueur,
                      child: const Icon(
                        Icons.location_pin,
                        color: violet,
                        size: 55,
                      ),
                    ),
                  ),
                ],
              ),

              RichAttributionWidget(
                attributions: [
                  TextSourceAttribution(
                    '© OpenStreetMap contributors',
                    onTap: () {},
                  ),
                ],
              ),
            ],
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
                        style: TextStyle(fontSize: 13),
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
              child: const Icon(Icons.my_location),
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
