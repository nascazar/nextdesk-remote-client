import 'dart:async';
import 'dart:convert';
import 'dart:io';

class RemoteSessionTracker {
  RemoteSessionTracker._(this._endpoint, this._token);

  final Uri _endpoint;
  final String _token;
  Timer? _heartbeat;
  bool _connected = false;
  bool _ended = false;

  static RemoteSessionTracker? create(String? apiUrl, String? token) {
    final endpoint = Uri.tryParse(apiUrl ?? '');
    final cleanToken = (token ?? '').trim();
    if (endpoint == null || endpoint.scheme != 'https' ||
        endpoint.path != '/api/remote-support/events' || cleanToken.isEmpty) {
      return null;
    }
    return RemoteSessionTracker._(endpoint, cleanToken);
  }

  Future<void> connected() async {
    if (_connected || _ended) return;
    _connected = true;
    await _send('connected');
    _heartbeat = Timer.periodic(const Duration(seconds: 30), (_) {
      unawaited(_send('heartbeat'));
    });
  }

  Future<void> ended() async {
    if (_ended) return;
    _ended = true;
    _heartbeat?.cancel();
    await _send('ended');
  }

  Future<void> _send(String event) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 7);
    try {
      final request = await client.postUrl(_endpoint).timeout(const Duration(seconds: 8));
      request.headers.contentType = ContentType.json;
      request.add(utf8.encode(jsonEncode({'token': _token, 'event': event})));
      final response = await request.close().timeout(const Duration(seconds: 8));
      await response.drain<void>();
    } catch (_) {
      // Remote support must continue even if its audit callback is temporarily unavailable.
    } finally {
      client.close(force: true);
    }
  }
}
