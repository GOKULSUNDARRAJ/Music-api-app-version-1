import 'package:flutter/foundation.dart';

class AdModel {
  final int id;
  final String adTitle;
  final String adType;
  final String mediaUrl;
  final String imageUrl;
  final String redirectUrl;

  AdModel({
    required this.id,
    required this.adTitle,
    required this.adType,
    required this.mediaUrl,
    required this.imageUrl,
    required this.redirectUrl,
  });

  factory AdModel.fromJson(Map<String, dynamic> json) {
    String mUrl = json['mediaUrl'] ?? '';
    if (mUrl.isNotEmpty && mUrl.startsWith('/')) {
      mUrl = 'https://music-app-api-1.onrender.com$mUrl';
    }
    String iUrl = json['imageUrl'] ?? '';
    if (iUrl.isNotEmpty && iUrl.startsWith('/')) {
      iUrl = 'https://music-app-api-1.onrender.com$iUrl';
    }

    return AdModel(
      id: json['id'],
      adTitle: json['adTitle'],
      adType: json['adType'] ?? 'audio',
      mediaUrl: mUrl,
      imageUrl: iUrl,
      redirectUrl: json['redirectUrl'] ?? '',
    );
  }
}
