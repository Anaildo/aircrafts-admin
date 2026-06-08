import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class BrokerService {
  static const String _sseUrl = 'http://localhost:8000/eventos/stream';

  static Stream<Map<String, dynamic>> ouvirEventos() {
    final controller = StreamController<Map<String, dynamic>>.broadcast();
    _conectarLoop(controller);
    return controller.stream;
  }

  static Future<void> _conectarLoop(
      StreamController<Map<String, dynamic>> controller) async {
    while (!controller.isClosed) {
      try {
        final client = http.Client();
        final request = http.Request('GET', Uri.parse(_sseUrl));
        final response = await client.send(request);

        String buffer = '';
        await for (final chunk in response.stream.transform(utf8.decoder)) {
          if (controller.isClosed) break;
          buffer += chunk;

          final lines = buffer.split('\n');
          buffer = lines.last;

          for (final line in lines.sublist(0, lines.length - 1)) {
            if (line.startsWith('data: ')) {
              final jsonStr = line.substring(6).trim();
              if (jsonStr.isNotEmpty) {
                try {
                  final data = jsonDecode(jsonStr) as Map<String, dynamic>;
                  controller.add(data);
                } catch (_) {}
              }
            }
          }
        }
        client.close();
      } catch (_) {
        await Future.delayed(const Duration(seconds: 5));
      }
    }
  }
}
