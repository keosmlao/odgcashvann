import 'dart:convert';
import 'package:http/http.dart' as http;

class LineApiService {
  final String lineApiUrl = "https://api.line.me/v2/bot/message/push";
  final String accessToken = "YOUR_CHANNEL_ACCESS_TOKEN";

  Future<void> sendImageMessage(
      String userId, String imageUrl, String thumbnailUrl) async {
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken',
    };

    final body = {
      "to": userId,
      "messages": [
        {
          "type": "image",
          "originalContentUrl": imageUrl,
          "previewImageUrl": thumbnailUrl,
        }
      ],
    };

    final response = await http.post(
      Uri.parse(lineApiUrl),
      headers: headers,
      body: json.encode(body),
    );

    if (response.statusCode == 200) {
      print("Image sent successfully!");
    } else {
      print("Failed to send image: ${response.body}");
    }
  }
}
