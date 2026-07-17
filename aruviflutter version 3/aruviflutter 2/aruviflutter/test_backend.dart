import 'package:http/http.dart' as http;

void main() async {
  try {
    final response = await http.get(Uri.parse('https://music-app-api-1.onrender.com/api/user/collaborative-playlists'));
    print('Playlists Status: ${response.statusCode}');
    
    // We can't easily test the exact endpoint without auth, but we can check if it returns 404 vs 401
    final res2 = await http.get(Uri.parse('https://music-app-api-1.onrender.com/api/user/collaborative-playlist/cpl_001/members'));
    print('Members endpoint status: ${res2.statusCode}');
  } catch (e) {
    print('Error: $e');
  }
}
