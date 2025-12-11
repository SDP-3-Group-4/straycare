import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final envFile = File('.env');
  if (!envFile.existsSync()) {
    print("FATAL: .env file not found.");
    return;
  }

  final lines = await envFile.readAsLines();
  String apiKey = '';
  for (var line in lines) {
    if (line.startsWith('ANVIL_API_KEY=')) {
      apiKey = line.split('=')[1].trim();
    }
  }

  if (apiKey.isEmpty) {
    print("FATAL: ANVIL_API_KEY is empty.");
    return;
  }

  print("Querying Google API for available models (using raw HTTP)...");

  final url = Uri.parse(
    'https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey',
  );

  try {
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final models = data['models'] as List;
      print("\n--- AVAILABLE MODELS ---");
      if (models.isEmpty) {
        print("API returned OK, but NO models found. (Region/Billing issue?)");
      }
      for (var m in models) {
        print("  - ${m['name']} (${m['displayName']})");
      }
      print("------------------------\n");
      print(
        "Pick one of the 'name' values above (without 'models/' prefix) for your .env ANVIL_MODEL.",
      );
    } else {
      print("\nFATAL ERROR: API returned status ${response.statusCode}");
      print("Response: ${response.body}");
      print("\nTROUBLESHOOTING:");
      if (response.body.contains("API has not been used in project")) {
        print(
          ">> YOUR API IS DISABLED. Go to Cloud Console and ENABLE 'Generative Language API'.",
        );
      }
      if (response.body.contains("API key not valid")) {
        print(">> YOUR KEY IS INVALID. Create a new key.");
      }
    }
  } catch (e) {
    print("FATAL NETWORK ERROR: $e");
  }
}
