import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/io.dart';

import '../config/api_config.dart';
import 'auth_service.dart';

class RealtimeAlertService {
  RealtimeAlertService._();

  static final RealtimeAlertService instance = RealtimeAlertService._();

  final StreamController<Map<String, dynamic>> _alertsController =
      StreamController<Map<String, dynamic>>.broadcast();

  IOWebSocketChannel? _channel;
  StreamSubscription<dynamic>? _channelSubscription;
  Timer? _pingTimer;
  Timer? _reconnectTimer;

  bool _isConnecting = false;
  bool _stoppedByUser = false;

  Stream<Map<String, dynamic>> get alertsStream => _alertsController.stream;

  Future<void> connect() async {
    if (_isConnecting) return;
    if (_channel != null) return;

    final token = AuthService.accessToken;
    if (token == null || token.trim().isEmpty) {
      debugPrint('RealtimeAlertService: no access token; socket not started.');
      return;
    }

    _isConnecting = true;
    _stoppedByUser = false;

    try {
      final uri = _buildWsUri(token);
      _channel = IOWebSocketChannel.connect(uri);
      _channelSubscription = _channel!.stream.listen(
        _handleMessage,
        onError: (error) {
          debugPrint('RealtimeAlertService socket error: $error');
          _cleanupSocket();
          _scheduleReconnect();
        },
        onDone: () {
          _cleanupSocket();
          _scheduleReconnect();
        },
        cancelOnError: true,
      );
      _startHeartbeat();
    } catch (error) {
      debugPrint('RealtimeAlertService connect failed: $error');
      _cleanupSocket();
      _scheduleReconnect();
    } finally {
      _isConnecting = false;
    }
  }

  Future<void> disconnect() async {
    _stoppedByUser = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    _pingTimer?.cancel();
    _pingTimer = null;

    await _channelSubscription?.cancel();
    _channelSubscription = null;

    await _channel?.sink.close();
    _channel = null;
  }

  Future<void> dispose() async {
    await disconnect();
    await _alertsController.close();
  }

  Uri _buildWsUri(String token) {
    final baseUri = Uri.parse(ApiConfig.baseUrl);
    final wsScheme = baseUri.scheme == 'https' ? 'wss' : 'ws';
    return baseUri.replace(
      scheme: wsScheme,
      path: '/ws',
      queryParameters: {'token': token},
    );
  }

  void _handleMessage(dynamic message) {
    if (message == null) return;

    if (message is String) {
      if (message == 'pong') return;

      try {
        final decoded = jsonDecode(message);
        if (decoded is Map<String, dynamic>) {
          _alertsController.add(decoded);
        }
      } catch (_) {
        // Ignore non-JSON text frames.
      }
      return;
    }

    if (message is Map) {
      _alertsController.add(
        message.map((key, value) => MapEntry('$key', value)),
      );
    }
  }

  void _startHeartbeat() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 25), (_) {
      try {
        _channel?.sink.add('ping');
      } catch (_) {
        _cleanupSocket();
        _scheduleReconnect();
      }
    });
  }

  void _scheduleReconnect() {
    if (_stoppedByUser) return;
    if (_reconnectTimer?.isActive ?? false) return;

    _reconnectTimer = Timer(const Duration(seconds: 4), () async {
      _reconnectTimer = null;
      await connect();
    });
  }

  void _cleanupSocket() {
    _pingTimer?.cancel();
    _pingTimer = null;

    _channelSubscription?.cancel();
    _channelSubscription = null;

    _channel = null;
  }
}
