/// Gig-economy partner API integration & documentation.
///
/// Enables two-wheeler gig riders (Rapido, Ola, Uber, Swiggy, Zomato, Blinkit)
/// to dispatch customer pickup & drop coordinates directly into ProjectHUD.
///
/// Channels:
///   1. Android Share Sheet (Intent.ACTION_SEND)
///   2. Deep Link scheme: `projecthud://navigate?destName=...&lat=...&lng=...&mode=pickup|drop`
///   3. Partner REST API stub (for native app SDK embedding)

import 'dart:convert';
import 'package:flutter/foundation.dart';

class GigOrderPayload {
  const GigOrderPayload({
    required this.orderId,
    required this.partnerApp, // 'rapido', 'ola', 'uber', etc.
    required this.stage, // 'pickup' or 'drop'
    required this.destinationName,
    required this.destinationAddress,
    required this.latitude,
    required this.longitude,
    this.customerPhone,
  });

  final String orderId;
  final String partnerApp;
  final String stage;
  final String destinationName;
  final String destinationAddress;
  final double latitude;
  final double longitude;
  final String? customerPhone;

  factory GigOrderPayload.fromUri(Uri uri) {
    return GigOrderPayload(
      orderId: uri.queryParameters['orderId'] ?? 'RAPIDO_${DateTime.now().millisecondsSinceEpoch}',
      partnerApp: uri.queryParameters['partner'] ?? 'rapido',
      stage: uri.queryParameters['stage'] ?? 'pickup',
      destinationName: uri.queryParameters['destName'] ?? 'Pickup Point',
      destinationAddress: uri.queryParameters['destAddress'] ?? '',
      latitude: double.tryParse(uri.queryParameters['lat'] ?? '') ?? 26.8528,
      longitude: double.tryParse(uri.queryParameters['lng'] ?? '') ?? 75.8084,
      customerPhone: uri.queryParameters['phone'],
    );
  }

  factory GigOrderPayload.fromSharedText(String text) {
    // Parses shared text from Google Maps or gig dispatchers
    // E.g. "Dropped pin near Sitapura https://maps.google.com/?q=26.8528,75.8084"
    final coordsMatch = RegExp(r'q=(-?\d+\.\d+),(-?\d+\.\d+)').firstMatch(text);
    if (coordsMatch != null) {
      return GigOrderPayload(
        orderId: 'SHARE_${DateTime.now().millisecondsSinceEpoch}',
        partnerApp: 'share_sheet',
        stage: 'navigation',
        destinationName: 'Shared Destination',
        destinationAddress: text,
        latitude: double.parse(coordsMatch.group(1)!),
        longitude: double.parse(coordsMatch.group(2)!),
      );
    }

    return GigOrderPayload(
      orderId: 'SHARE_${DateTime.now().millisecondsSinceEpoch}',
      partnerApp: 'share_sheet',
      stage: 'navigation',
      destinationName: text.split('\n').first,
      destinationAddress: text,
      latitude: 26.8764,
      longitude: 75.7640,
    );
  }
}

/// Partner API Stub for Native Apps (Rapido, Ola, Uber)
abstract class GigPartnerApiInterface {
  /// Dispatch a new trip into ProjectHUD
  Future<bool> sendTripToHUD(GigOrderPayload order);

  /// Cancel or update an active navigation session
  Future<bool> cancelActiveTrip(String orderId);
}

class GigPartnerApiStub implements GigPartnerApiInterface {
  @override
  Future<bool> sendTripToHUD(GigOrderPayload order) async {
    debugPrint('[GIG_PARTNER_API] Received trip: ${order.orderId} from ${order.partnerApp}');
    return true;
  }

  @override
  Future<bool> cancelActiveTrip(String orderId) async {
    debugPrint('[GIG_PARTNER_API] Cancelled trip: $orderId');
    return true;
  }
}
