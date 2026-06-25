import 'dart:convert';

int getUserIdFromToken(String token) {
  final parts = token.split('.');
  final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
  final data = jsonDecode(payload);
  return int.parse(data['sub'].toString());
}