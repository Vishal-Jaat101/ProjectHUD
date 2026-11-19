/// Google Maps / Directions / Places API service for ProjectHUD.
///
/// All REST API calls are centralised here so the rest of the app
/// never touches raw HTTP for map data.

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../app/constants/app_constants.dart';
import '../models/navigation_models.dart';

/// Represents a place autocomplete suggestion.
class PlaceSuggestion {
  final String placeId;
  final String mainText;
  final String secondaryText;

  const PlaceSuggestion({
    required this.placeId,
    required this.mainText,
    required this.secondaryText,
  });

  factory PlaceSuggestion.fromJson(Map<String, dynamic> json) {
    final structured =
        json['structured_formatting'] as Map<String, dynamic>? ?? {};
    return PlaceSuggestion(
      placeId: json['place_id'] as String? ?? '',
      mainText: structured['main_text'] as String? ?? '',
      secondaryText: structured['secondary_text'] as String? ?? '',
    );
  }
}

/// Lat/Lng pair returned from place details.
class PlaceLocation {
  final double lat;
  final double lng;
  final String name;
  final String address;

  const PlaceLocation({
    required this.lat,
    required this.lng,
    required this.name,
    required this.address,
  });
}

/// Service layer for Google Maps Platform APIs.
class MapsService {
  MapsService({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  static const _baseUrl = 'https://maps.googleapis.com/maps/api';
  String get _key => AppConstants.googleMapsApiKey;

  // ── Places Autocomplete ───────────────────────────────────────────

  /// Returns autocomplete suggestions for [query].
  ///
  /// Results are biased toward India and limited to geocode/establishment
  /// types for rider-friendly destinations.
  Future<List<PlaceSuggestion>> autocomplete(
    String query, {
    double? lat,
    double? lng,
    int radiusMeters = 50000,
  }) async {
    if (query.trim().isEmpty) return [];

    final params = <String, String>{
      'input': query,
      'key': _key,
      'components': 'country:in',
      'language': 'en',
    };
    if (lat != null && lng != null) {
      params['location'] = '$lat,$lng';
      params['radius'] = '$radiusMeters';
    }

    final uri = Uri.parse('$_baseUrl/place/autocomplete/json')
        .replace(queryParameters: params);
    final response = await _client.get(uri);

    if (response.statusCode != 200) return [];

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final predictions = json['predictions'] as List<dynamic>? ?? [];

    return predictions
        .map((p) => PlaceSuggestion.fromJson(p as Map<String, dynamic>))
        .toList();
  }

  // ── Place Details ─────────────────────────────────────────────────

  /// Fetches lat/lng and name for a [placeId].
  Future<PlaceLocation?> placeDetails(String placeId) async {
    final uri = Uri.parse('$_baseUrl/place/details/json').replace(
      queryParameters: {
        'place_id': placeId,
        'fields': 'geometry,name,formatted_address',
        'key': _key,
      },
    );
    final response = await _client.get(uri);
    if (response.statusCode != 200) return null;

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final result = json['result'] as Map<String, dynamic>?;
    if (result == null) return null;

    final geometry = result['geometry'] as Map<String, dynamic>?;
    final location = geometry?['location'] as Map<String, dynamic>?;
    if (location == null) return null;

    return PlaceLocation(
      lat: (location['lat'] as num).toDouble(),
      lng: (location['lng'] as num).toDouble(),
      name: result['name'] as String? ?? '',
      address: result['formatted_address'] as String? ?? '',
    );
  }

  // ── Directions ────────────────────────────────────────────────────

  /// Fetches a driving route from [originLat],[originLng] to
  /// [destLat],[destLng] via the Directions API.
  ///
  /// [mode] should be `'TWO_WHEELER'` for bikes or `'DRIVING'` for autos.
  Future<RouteData?> getDirections({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
    required String destinationName,
    String mode = 'driving',
  }) async {
    final uri = Uri.parse('$_baseUrl/directions/json').replace(
      queryParameters: {
        'origin': '$originLat,$originLng',
        'destination': '$destLat,$destLng',
        'mode': mode,
        'key': _key,
        'language': 'en',
        'region': 'in',
      },
    );
    final response = await _client.get(uri);
    if (response.statusCode != 200) return null;

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final routes = json['routes'] as List<dynamic>? ?? [];
    if (routes.isEmpty) return null;

    final route = routes[0] as Map<String, dynamic>;
    final legs = route['legs'] as List<dynamic>? ?? [];
    if (legs.isEmpty) return null;

    final leg = legs[0] as Map<String, dynamic>;
    final apiSteps = leg['steps'] as List<dynamic>? ?? [];

    final steps = apiSteps
        .map((s) => NavigationStep.fromDirectionsApi(s as Map<String, dynamic>))
        .toList();

    final polyline =
        route['overview_polyline']?['points'] as String? ?? '';

    return RouteData(
      summary: route['summary'] as String? ?? '',
      totalDistanceMeters:
          (leg['distance']?['value'] as num?)?.toDouble() ?? 0,
      totalDurationSeconds:
          (leg['duration']?['value'] as num?)?.toDouble() ?? 0,
      steps: steps,
      encodedPolyline: polyline,
      destinationName: destinationName,
      destinationLat: destLat,
      destinationLng: destLng,
    );
  }

  /// Cleans up the HTTP client.
  void dispose() {
    _client.close();
  }
}
